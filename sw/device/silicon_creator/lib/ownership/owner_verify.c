// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "sw/device/silicon_creator/lib/ownership/owner_verify.h"

#include "sw/device/lib/base/macros.h"
#include "sw/device/silicon_creator/lib/base/util.h"
#include "sw/device/silicon_creator/lib/error.h"
#include "sw/device/silicon_creator/lib/otbn_boot_services.h"
#include "sw/device/silicon_creator/lib/sigverify/ecdsa_p256_key.h"
#include "sw/device/silicon_creator/lib/sigverify/mldsa_key.h"
#include "sw/device/silicon_creator/lib/sigverify/mldsa_verify.h"
#include "sw/device/silicon_creator/lib/sigverify/sigverify.h"
#include "sw/device/silicon_creator/lib/sigverify/sphincsplus/verify.h"

// A version of spx_verify that is tailored to ROM_EXT use cases.
// In particular:
//   - We don't care about the OTP setting for SPX+ in the ROM_EXT.
//   - We don't care about flash_exec in the ROM_EXT.
//   - We have a different series of algorithm identifier values to accommodate
//     hybrid signature schemes.
OT_WARN_UNUSED_RESULT
static rom_error_t owner_spx_verify(
    uint32_t key_alg, const sigverify_spx_key_t *key,
    const sigverify_spx_signature_t *signature, const void *msg_prefix_1,
    size_t msg_prefix_1_len, const void *msg_prefix_2, size_t msg_prefix_2_len,
    const void *msg, size_t msg_len, hmac_digest_t digest,
    uint32_t *flash_exec) {
  if (signature == NULL) {
    return kErrorSigverifySpxNotFound;
  }
  /*
   * Shares for producing kErrorOk if SPHINCS+ verification succeeds.  The first
   * three shares are generated using the `sparse-fsm-encode` script while the
   * last share is
   * `kErrorOk ^ shares[0] ^ ... ^ shares[2]`.
   *
   * Encoding generated with:
   * $ ./util/design/sparse-fsm-encode.py -d 5 -m 3 -n 32 \
   *     -s 1069420 --language=c
   *
   * Minimum Hamming distance: 14
   * Maximum Hamming distance: 20
   * Minimum Hamming weight: 14
   * Maximum Hamming weight: 16
   */

  const uint32_t shares[] = {
      0x11deb806,
      0x06457f69,
      0x647f10c4,
      0x73e4d092,
  };

  // If the key_alg is one of the hybrid algorithm, locally re-categorize as
  // an SPX+ algorithm so we can call the underlying `spx_verify` function
  // correctly.
  key_alg &= ~(uint32_t)kOwnershipKeyAlgCategoryMask;
  key_alg |= (uint32_t)kOwnershipKeyAlgCategorySpx;

  sigverify_spx_root_t actual_root;
  sigverify_spx_root_t expected_root;
  spx_public_key_root(key->data, expected_root.data);
  uint32_t i;
  for (i = 0; launder32(i) < kSigverifySpxRootNumWords; ++i) {
    expected_root.data[i] ^= shares[i];
  }

  switch (key_alg) {
    case kOwnershipKeyAlgSpxPure:
      HARDENED_RETURN_IF_ERROR(spx_verify(
          signature->data, kSpxVerifyPureDomainSep, kSpxVerifyPureDomainSepSize,
          msg_prefix_1, msg_prefix_1_len, msg_prefix_2, msg_prefix_2_len, msg,
          msg_len, key->data, actual_root.data));
      break;

    case kOwnershipKeyAlgSpxPrehash:
      util_reverse_bytes(digest.digest, sizeof(digest.digest));
      HARDENED_RETURN_IF_ERROR(
          spx_verify(signature->data, kSpxVerifyPrehashDomainSep,
                     kSpxVerifyPrehashDomainSepSize,
                     /*msg_prefix_2=*/NULL, /*msg_prefix_2_len=*/0,
                     /*msg_prefix_3=*/NULL, /*msg_prefix_3_len=*/0,
                     (unsigned char *)digest.digest, sizeof(digest.digest),
                     key->data, actual_root.data));
      break;
    default:
      return kErrorSigverifyBadSpxConfig;
  }
  uint32_t result = 0;
  uint32_t diff = 0;
  *flash_exec = kErrorOk ^ kSigverifySpxSuccess;
  for (--i; launder32(i) < kSigverifySpxRootNumWords; --i) {
    uint32_t val = expected_root.data[i] ^ actual_root.data[i];
    diff |= val ^ shares[i];
    diff |= ~diff + 1;          // Set upper bits to 1 if not 0, no change o/w.
    diff |= ~(diff >> 31) + 1;  // Set all 1s if MSB is set, no change o/w.
    result ^= val;
    result |= diff;

    *flash_exec ^= val;
    *flash_exec |= diff;
  }
  HARDENED_CHECK_EQ(i, SIZE_MAX);
  if (result != kErrorOk) {
    return kErrorSigverifyBadSpxSignature;
  }
  return result;
}

// A version of sigverify_mldsa_verify tailored to ROM_EXT/ownership use
// cases. In particular:
//   - We don't care about the OTP setting for ML-DSA-87 in the ROM_EXT.
//   - We have a different series of algorithm identifier values to accommodate
//     hybrid signature schemes.
//   - `key_digest` is only a SHA3-256 digest of the owner's provisioned
//     public key (not the key itself, which is too large to store in
//     `owner_keydata_t`). `full_key` is the full key, delivered separately
//     (e.g. from the image's own manifest extension), and is validated
//     against `key_digest` before being used to verify `signature`.
//   - `full_key_digest` is the caller-precomputed SHA3-256 digest of
//     `full_key` (e.g. already computed by the caller for a keyring lookup),
//     passed in rather than recomputed here to avoid hashing the key twice per
//     verification.
OT_WARN_UNUSED_RESULT
static rom_error_t owner_mldsa_verify(
    uint32_t key_alg, const uint32_t *key_digest,
    const sigverify_mldsa_key_t *full_key,
    const uint32_t *full_key_digest,
    const sigverify_mldsa_signature_t *signature, const void *msg_prefix_1,
    size_t msg_prefix_1_len, const void *msg_prefix_2, size_t msg_prefix_2_len,
    const void *msg, size_t msg_len, uint32_t *flash_exec) {
  if (signature == NULL || full_key == NULL || full_key_digest == NULL) {
    return kErrorSigverifyMldsaNotFound;
  }

  /*
   * Shares for producing kErrorOk if ML-DSA-87 verification succeeds. The
   * first 15 shares are generated using the `sparse-fsm-encode` script while
   * the last share is `kSigverifyMldsaSuccess ^ shares[0] ^ ... ^
   * shares[14]`.
   *
   * Encoding generated with:
   * $ ./util/design/sparse-fsm-encode.py -d 5 -m 15 -n 32 \
   *     -s 246813579 --language=c
   *
   * Minimum Hamming distance: 9
   * Maximum Hamming distance: 23
   * Minimum Hamming weight: 12
   * Maximum Hamming weight: 18
   */
  const uint32_t shares[] = {
      0x6a34b53d, 0x6da41908, 0xf62aba8e, 0x1cc327a3, 0xb855ced0,
      0xb3e0730a, 0xd80e6136, 0x80431bcf, 0x87d84062, 0x8f2e4b12,
      0x9c508f4f, 0x48a3f96b, 0x10cda670, 0x6e44a638, 0xb5d685c4,
      0x24b782f4,
  };

  static_assert(ARRAYSIZE(shares) ==
                    kSigverifyMldsaSigCTildeBytes / sizeof(uint32_t),
                "Share count must match the c_tilde word count.");

  // Validate the delivered full key against the owner-provisioned digest,
  // using the caller-precomputed digest of `full_key`.
  uint32_t key_diff = 0;
  size_t k = 0;
  for (; launder32(k) < kSigverifyMldsaKeyDigestWords; ++k) {
    key_diff |= full_key_digest[k] ^ key_digest[k];
  }
  HARDENED_CHECK_EQ(k, kSigverifyMldsaKeyDigestWords);
  if (launder32(key_diff) != 0) {
    return kErrorSigverifyBadMldsaKey;
  }
  HARDENED_CHECK_EQ(key_diff, 0);

  // Compute the message representative and run the OTBN verification.
  sigverify_mldsa_mu_t mu;
  HARDENED_RETURN_IF_ERROR(sigverify_mldsa_compute_mu(
      full_key, /*ctx=*/NULL, /*ctx_len=*/0, msg_prefix_1, msg_prefix_1_len,
      msg_prefix_2, msg_prefix_2_len, msg, msg_len, &mu));
  uint32_t recovered_c_tilde_prime[ARRAYSIZE(shares)];
  HARDENED_RETURN_IF_ERROR(
      otbn_boot_mldsa87_verify_start(full_key, signature, &mu));
  HARDENED_RETURN_IF_ERROR(
      otbn_boot_mldsa87_verify_finish(recovered_c_tilde_prime));

  // Combine the recovered value with the provided signature's `c_tilde` and
  // the shares in one step: `recovered_c_tilde_prime` becomes `shares` if
  // the signature is valid, garbage otherwise.
  uint32_t i = 0;
  for (; launder32(i) < ARRAYSIZE(shares); ++i) {
    recovered_c_tilde_prime[i] ^= signature->c_tilde[i] ^ shares[i];
  }
  HARDENED_CHECK_EQ(i, ARRAYSIZE(shares));

  uint32_t result = 0;
  uint32_t diff = 0;
  *flash_exec = kErrorOk ^ kSigverifyMldsaSuccess;
  for (--i; launder32(i) < ARRAYSIZE(shares); --i) {
    diff |= recovered_c_tilde_prime[i] ^ shares[i];
    diff |= ~diff + 1;          // Set upper bits to 1 if not 0, no change o/w.
    diff |= ~(diff >> 31) + 1;  // Set all 1s if MSB is set, no change o/w.
    result ^= recovered_c_tilde_prime[i];
    result |= diff;

    *flash_exec ^= recovered_c_tilde_prime[i];
    *flash_exec |= diff;
  }
  HARDENED_CHECK_EQ(i, SIZE_MAX);
  if (result != kErrorOk) {
    return kErrorSigverifyBadMldsaSignature;
  }
  return result;
}

rom_error_t owner_verify(uint32_t key_alg, const owner_keydata_t *key,
                         const ecdsa_p256_signature_t *ecdsa_sig,
                         const sigverify_spx_signature_t *spx_sig,
                         const sigverify_mldsa_signature_t *mldsa_sig,
                         const sigverify_mldsa_key_t *mldsa_full_key,
                         const uint32_t *mldsa_full_key_digest,
                         const void *msg_prefix_1, size_t msg_prefix_1_len,
                         const void *msg_prefix_2, size_t msg_prefix_2_len,
                         const void *msg, size_t msg_len,
                         const hmac_digest_t *digest, uint32_t *flash_exec) {
  uint32_t ec_flash_exec = 0;
  uint32_t second_flash_exec = 0;
  uint32_t category = key_alg & kOwnershipKeyAlgCategoryMask;
  rom_error_t ecdsa = kErrorOwnershipInvalidAlgorithm;
  rom_error_t second = kErrorOwnershipInvalidAlgorithm;

  // Start an ECDSA verify on OTBN (if requested by the key_alg). Note: this
  // overlap with the "second algorithm" step below (computed while ECDSA
  // runs on OTBN) is only real parallelism for the SPX+ combinations, since
  // SPX+ runs on Ibex. ML-DSA-87 also uses OTBN, so the ECDSA+ML-DSA-87
  // hybrid combination cannot actually overlap the two. They still run
  // sequentially (ECDSA's `_start` is queued, then ML-DSA-87 fully runs and
  // blocks on OTBN before ECDSA's `_finish` can even be polled). This is a
  // known throughput regression versus the SPX+ scheme, not a correctness
  // issue.
  switch (launder32(category)) {
    case kOwnershipKeyAlgCategoryEcdsa:
      HARDENED_CHECK_EQ(category, kOwnershipKeyAlgCategoryEcdsa);
      HARDENED_RETURN_IF_ERROR(
          sigverify_ecdsa_p256_start(ecdsa_sig, &key->ecdsa, digest));
      break;
    case kOwnershipKeyAlgCategoryHybrid:
      HARDENED_CHECK_EQ(category, kOwnershipKeyAlgCategoryHybrid);
      HARDENED_RETURN_IF_ERROR(
          sigverify_ecdsa_p256_start(ecdsa_sig, &key->hybrid.ecdsa, digest));
      break;
    case kOwnershipKeyAlgCategoryHybridMldsa:
      HARDENED_CHECK_EQ(category, kOwnershipKeyAlgCategoryHybridMldsa);
      HARDENED_RETURN_IF_ERROR(sigverify_ecdsa_p256_start(
          ecdsa_sig, &key->hybrid_mldsa.ecdsa, digest));
      break;
    case kOwnershipKeyAlgCategorySpx:
    case kOwnershipKeyAlgCategoryMldsa:
      // No ECDSA component for this key_alg, nothing to start.
      break;
    default:
      return kErrorOwnershipInvalidAlgorithm;
  }

  // Compute the second algorithm's verification (SPX+ or ML-DSA-87).
  switch (launder32(category)) {
    case kOwnershipKeyAlgCategorySpx:
      HARDENED_CHECK_EQ(category, kOwnershipKeyAlgCategorySpx);
      second = owner_spx_verify(key_alg, &key->spx, spx_sig, msg_prefix_1,
                                msg_prefix_1_len, msg_prefix_2,
                                msg_prefix_2_len, msg, msg_len, *digest,
                                &second_flash_exec);
      break;
    case kOwnershipKeyAlgCategoryHybrid:
      HARDENED_CHECK_EQ(category, kOwnershipKeyAlgCategoryHybrid);
      second = owner_spx_verify(key_alg, &key->hybrid.spx, spx_sig,
                                msg_prefix_1, msg_prefix_1_len, msg_prefix_2,
                                msg_prefix_2_len, msg, msg_len, *digest,
                                &second_flash_exec);
      break;
    case kOwnershipKeyAlgCategoryMldsa:
      HARDENED_CHECK_EQ(category, kOwnershipKeyAlgCategoryMldsa);
      second = owner_mldsa_verify(key_alg, key->mldsa_digest, mldsa_full_key,
                                  mldsa_full_key_digest, mldsa_sig,
                                  msg_prefix_1, msg_prefix_1_len, msg_prefix_2,
                                  msg_prefix_2_len, msg, msg_len,
                                  &second_flash_exec);
      break;
    case kOwnershipKeyAlgCategoryHybridMldsa:
      HARDENED_CHECK_EQ(category, kOwnershipKeyAlgCategoryHybridMldsa);
      second = owner_mldsa_verify(
          key_alg, key->hybrid_mldsa.mldsa_digest, mldsa_full_key,
          mldsa_full_key_digest, mldsa_sig, msg_prefix_1, msg_prefix_1_len,
          msg_prefix_2, msg_prefix_2_len, msg, msg_len, &second_flash_exec);
      break;
    case kOwnershipKeyAlgCategoryEcdsa:
      HARDENED_CHECK_EQ(category, kOwnershipKeyAlgCategoryEcdsa);
      second = kErrorOk;
      second_flash_exec = kSigverifySpxSuccess;
      break;
    default:
      return kErrorOwnershipInvalidAlgorithm;
  }

  // ECDSA should be finished (if applicable). Poll for completion and get
  // the result.
  switch (launder32(category)) {
    case kOwnershipKeyAlgCategoryEcdsa:
      HARDENED_CHECK_EQ(category, kOwnershipKeyAlgCategoryEcdsa);
      ecdsa = sigverify_ecdsa_p256_finish(ecdsa_sig, &ec_flash_exec);
      break;
    case kOwnershipKeyAlgCategoryHybrid:
      HARDENED_CHECK_EQ(category, kOwnershipKeyAlgCategoryHybrid);
      ecdsa = sigverify_ecdsa_p256_finish(ecdsa_sig, &ec_flash_exec);
      break;
    case kOwnershipKeyAlgCategoryHybridMldsa:
      HARDENED_CHECK_EQ(category, kOwnershipKeyAlgCategoryHybridMldsa);
      ecdsa = sigverify_ecdsa_p256_finish(ecdsa_sig, &ec_flash_exec);
      break;
    case kOwnershipKeyAlgCategorySpx:
    case kOwnershipKeyAlgCategoryMldsa:
      ecdsa = kErrorOk;
      ec_flash_exec = kSigverifyEcdsaSuccess;
      break;
    default:
      return kErrorOwnershipInvalidAlgorithm;
  }
  HARDENED_RETURN_IF_ERROR(second);
  HARDENED_RETURN_IF_ERROR(ecdsa);
  if (flash_exec) {
    *flash_exec = ec_flash_exec ^ second_flash_exec;
  }
  // Both values should be kErrorOk. Mix them and return the result.
  return (rom_error_t)((second + ecdsa) >> 1);
}
