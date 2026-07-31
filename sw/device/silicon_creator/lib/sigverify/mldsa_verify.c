// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "sw/device/silicon_creator/lib/sigverify/mldsa_verify.h"

#include "sw/device/lib/base/hardened.h"
#include "sw/device/lib/base/macros.h"
#include "sw/device/silicon_creator/lib/drivers/kmac.h"
#include "sw/device/silicon_creator/lib/drivers/otp.h"
#include "sw/device/silicon_creator/lib/otbn_boot_services.h"

#include "hw/top/otp_ctrl_regs.h"

static_assert(kSigverifyMldsaKeyDigestWords == kKmacSha3256DigestWords,
              "ML-DSA-87 key digest size must match the SHA3-256 output "
              "size.");

rom_error_t sigverify_mldsa_key_digest(const sigverify_mldsa_key_t *key,
                                       uint32_t *digest) {
  HARDENED_RETURN_IF_ERROR(kmac_sha3_256_configure());
  HARDENED_RETURN_IF_ERROR(kmac_sha3_256_start());
  kmac_sha3_256_absorb_words(key->rho, ARRAYSIZE(key->rho));
  kmac_sha3_256_absorb_words(key->t1, ARRAYSIZE(key->t1));
  kmac_sha3_256_squeeze_start();
  return kmac_sha3_256_squeeze_end(digest);
}

rom_error_t sigverify_mldsa_compute_mu(
    const sigverify_mldsa_key_t *key, const void *ctx, size_t ctx_len,
    const void *msg_prefix_1, size_t msg_prefix_1_len,
    const void *msg_prefix_2, size_t msg_prefix_2_len, const void *msg,
    size_t msg_len, sigverify_mldsa_mu_t *mu) {
  // FIPS 204 requires |ctx| <= 255 (it is encoded as a single byte below).
  HARDENED_CHECK_LE(ctx_len, UINT8_MAX);

  // tr = H(pk, 64), where pk = rho || t1.
  uint32_t tr[kSigverifyMldsaMuNumWords];
  HARDENED_RETURN_IF_ERROR(kmac_shake256_configure());
  HARDENED_RETURN_IF_ERROR(kmac_shake256_start());
  kmac_shake256_absorb_words(key->rho, ARRAYSIZE(key->rho));
  kmac_shake256_absorb_words(key->t1, ARRAYSIZE(key->t1));
  kmac_shake256_squeeze_start();
  HARDENED_RETURN_IF_ERROR(kmac_shake256_squeeze_end(tr, ARRAYSIZE(tr)));

  // mu = H(tr || 0x00 || IntegerToBytes(len(ctx), 1) || ctx || M, 64). The
  // first zero byte is `IntegerToBytes(0, 1)` (not pre-hashed), per FIPS 204.
  uint8_t mu_prefix[2] = {0x00, (uint8_t)ctx_len};
  HARDENED_RETURN_IF_ERROR(kmac_shake256_configure());
  HARDENED_RETURN_IF_ERROR(kmac_shake256_start());
  kmac_shake256_absorb_words(tr, ARRAYSIZE(tr));
  kmac_shake256_absorb(mu_prefix, sizeof(mu_prefix));
  if (ctx_len > 0) {
    kmac_shake256_absorb(ctx, ctx_len);
  }
  if (msg_prefix_1 != NULL) {
    kmac_shake256_absorb(msg_prefix_1, msg_prefix_1_len);
  }
  if (msg_prefix_2 != NULL) {
    kmac_shake256_absorb(msg_prefix_2, msg_prefix_2_len);
  }
  kmac_shake256_absorb(msg, msg_len);
  kmac_shake256_squeeze_start();
  return kmac_shake256_squeeze_end(mu->data, ARRAYSIZE(mu->data));
}

// Declared as a weak symbol so that we can override in tests.
OT_WEAK
uint32_t sigverify_mldsa_verify_enabled(lifecycle_state_t lc_state) {
  switch (launder32(lc_state)) {
    case kLcStateTest:
      HARDENED_CHECK_EQ(lc_state, kLcStateTest);
      // Don't read from OTP during manufacturing. Disable ML-DSA-87 signature
      // verification by default.
      return kSigverifyMldsaDisabledOtp;
    case kLcStateDev:
      HARDENED_CHECK_EQ(lc_state, kLcStateDev);
      return otp_read32(OTP_CTRL_PARAM_CREATOR_SW_CFG_SIGVERIFY_MLDSA_EN_OFFSET);
    case kLcStateProd:
      HARDENED_CHECK_EQ(lc_state, kLcStateProd);
      return otp_read32(OTP_CTRL_PARAM_CREATOR_SW_CFG_SIGVERIFY_MLDSA_EN_OFFSET);
    case kLcStateProdEnd:
      HARDENED_CHECK_EQ(lc_state, kLcStateProdEnd);
      return otp_read32(OTP_CTRL_PARAM_CREATOR_SW_CFG_SIGVERIFY_MLDSA_EN_OFFSET);
    case kLcStateRma:
      HARDENED_CHECK_EQ(lc_state, kLcStateRma);
      return otp_read32(OTP_CTRL_PARAM_CREATOR_SW_CFG_SIGVERIFY_MLDSA_EN_OFFSET);
    default:
      HARDENED_TRAP();
      OT_UNREACHABLE();
  }
}

/**
 * Shares for producing the `flash_exec_mldsa` value in
 * `sigverify_mldsa_verify()` when ML-DSA-87 signature verification is
 * enabled. First 15 shares are generated using the `sparse-fsm-encode`
 * script while the last share is `kSigverifyMldsaSuccess ^ kMldsaShares[0] ^
 * ... ^ kMldsaShares[14]` so that xor'ing all shares produces
 * `kSigverifyMldsaSuccess`.
 *
 * Encoding generated with
 * $ ./util/design/sparse-fsm-encode.py -d 5 -m 15 -n 32 \
 *     -s 918273645 --language=c
 *
 * Minimum Hamming distance: 11
 * Maximum Hamming distance: 23
 * Minimum Hamming weight: 11
 * Maximum Hamming weight: 20
 */
static const uint32_t kMldsaVerifyShares[kSigverifyMldsaSigCTildeBytes /
                                        sizeof(uint32_t)] = {
    0x8e47d5d7, 0x58ea694f, 0xfcf91572, 0xdca62fa4, 0x80a29a19, 0x9dc412ab,
    0x000d738f, 0x6936142e, 0x873335c6, 0x48c2c63a, 0x2d47670e, 0x8b8fa3b3,
    0x3abc7a4c, 0xf09ea77e, 0xe724d9aa, 0x4bfcd693,
};

rom_error_t sigverify_mldsa_verify(const sigverify_mldsa_signature_t *signature,
                                   const sigverify_mldsa_key_t *key,
                                   lifecycle_state_t lc_state,
                                   const sigverify_mldsa_mu_t *mu,
                                   uint32_t *flash_exec) {
  uint32_t mldsa_en = launder32(sigverify_mldsa_verify_enabled(lc_state));
  rom_error_t error = kErrorSigverifyBadMldsaSignature;
  if (launder32(mldsa_en) != kSigverifyMldsaDisabledOtp) {
    uint32_t recovered_c_tilde_prime[ARRAYSIZE(kMldsaVerifyShares)];
    HARDENED_RETURN_IF_ERROR(
        otbn_boot_mldsa87_verify_start(key, signature, mu));
    HARDENED_RETURN_IF_ERROR(
        otbn_boot_mldsa87_verify_finish(recovered_c_tilde_prime));

    // XOR each word of the recovered `c_tilde` with the corresponding word
    // of the provided signature's `c_tilde` and a share.
    // If they match, `recovered_c_tilde_prime` becomes `kMldsaVerifyShares`,
    // otherwise it becomes garbage that can't collide with a valid result.
    size_t i = 0;
    for (; launder32(i) < ARRAYSIZE(kMldsaVerifyShares); ++i) {
      recovered_c_tilde_prime[i] ^=
          signature->c_tilde[i] ^ kMldsaVerifyShares[i];
    }
    HARDENED_CHECK_EQ(i, ARRAYSIZE(kMldsaVerifyShares));

    uint32_t flash_exec_mldsa = 0;
    uint32_t diff = 0;
    for (--i; launder32(i) < ARRAYSIZE(kMldsaVerifyShares); --i) {
      // Following three statements set `diff` to `UINT32_MAX` if
      // `recovered_c_tilde_prime[i]` is incorrect, no change otherwise.
      diff |= recovered_c_tilde_prime[i] ^ kMldsaVerifyShares[i];
      diff |= ~diff + 1;          // Set upper bits to 1 if not 0, no change o/w.
      diff |= ~(diff >> 31) + 1;  // Set to all 1s if MSB is set, no change o/w.

      flash_exec_mldsa ^= recovered_c_tilde_prime[i];
      // Set `flash_exec_mldsa` to `UINT32_MAX` if `recovered_c_tilde_prime` is
      // incorrect.
      flash_exec_mldsa |= diff;
    }
    HARDENED_CHECK_EQ(i, SIZE_MAX);
    error = sigverify_mldsa_success_to_ok(flash_exec_mldsa);
    *flash_exec ^= flash_exec_mldsa;
  } else {
    HARDENED_CHECK_EQ(mldsa_en, kSigverifyMldsaDisabledOtp);
    *flash_exec ^= mldsa_en;
    uint32_t otp_val = sigverify_mldsa_verify_enabled(lc_state);
    // Note: `kSigverifyMldsaSuccess` is defined such that the following
    // operation produces `kErrorOk`.
    error = sigverify_mldsa_success_to_ok(otp_val);
  }
  if (error != kErrorOk) {
    return kErrorSigverifyBadMldsaSignature;
  }
  return error;
}

// Extern declarations for the inline functions in the header.
extern uint32_t sigverify_mldsa_success_to_ok(uint32_t v);
