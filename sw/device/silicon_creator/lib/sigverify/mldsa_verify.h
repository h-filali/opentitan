// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#ifndef OPENTITAN_SW_DEVICE_SILICON_CREATOR_LIB_SIGVERIFY_MLDSA_VERIFY_H_
#define OPENTITAN_SW_DEVICE_SILICON_CREATOR_LIB_SIGVERIFY_MLDSA_VERIFY_H_

#include "sw/device/silicon_creator/lib/drivers/lifecycle.h"
#include "sw/device/silicon_creator/lib/error.h"
#include "sw/device/silicon_creator/lib/sigverify/mldsa_key.h"

#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus

enum {
  /**
   * A non-trivial constant chosen such that `kSigverifyEcdsaSuccess ^
   * kSigverifyMldsaSuccess = kSigverifyFlashExec`.
   */
  kSigverifyMldsaSuccess = 0x8d6c8c17,
  /**
   * A non-trivial constant equal to `kSigverifyMldsaSuccess`.
   *
   * Setting the `CREATOR_SW_CFG_SIGVERIFY_MLDSA_EN` OTP item to this value
   * disables ML-DSA-87 signature verification, any other value enables it.
   */
  kSigverifyMldsaDisabledOtp = kSigverifyMldsaSuccess,
};

/**
 * Get whether ML-DSA-87 signature verification is enabled in OTP.
 *
 * This function returns the value of the `CREATOR_SW_CFG_SIGVERIFY_MLDSA_EN`
 * OTP item unless the lifecycle state of the device is `TEST_UNLOCKED`. For
 * `TEST_UNLOCKED` this function always returns `kSigverifyMldsaDisabledOtp`.
 *
 * @param lc_state Life cycle state of the device.
 * @return Result of the operation.
 */
OT_WARN_UNUSED_RESULT
uint32_t sigverify_mldsa_verify_enabled(lifecycle_state_t lc_state);

/**
 * Computes the SHA3-256 digest of an ML-DSA-87 public key.
 *
 * This uses the KMAC block's dedicated SHA3 hardware mode. Used to validate a
 * full public key (e.g. delivered via a manifest extension) against a
 * `kSigverifyMldsaKeyDigestWords`-sized digest stored in a fixed-size slot
 * too small for the full key.
 
 * @param key An ML-DSA-87 public key.
 * @param[out] digest The resulting digest (`kSigverifyMldsaKeyDigestWords`).
 * @return The result of the operation.
 */
OT_WARN_UNUSED_RESULT
rom_error_t sigverify_mldsa_key_digest(const sigverify_mldsa_key_t *key,
                                       uint32_t *digest);

/**
 * Computes the ML-DSA-87 "mu" message representative (FIPS 204).
 *
 * Per FIPS 204 Algorithm 7 (ML-DSA.Sign_internal) / Algorithm 8
 * (ML-DSA.Verify_internal), non-pre-hashed ("pure") variant:
 *
 *   tr = H(pk, 64)
 *   mu = H(tr || IntegerToBytes(0, 1) || IntegerToBytes(len(ctx), 1) || ctx
 *          || M, 64)
 *
 * where `H` is SHAKE-256, `ctx` is the (possibly empty) context string, and
 * `M` is the message, split here into up to two optional prefixes plus a
 * message buffer purely for the caller's convenience.
 *
 * @param key Signer's ML-DSA-87 public key.
 * @param ctx Context string; must be <= 255 bytes (FIPS 204).
 * @param ctx_len Length of the context string.
 * @param msg_prefix_1 Optional message prefix.
 * @param msg_prefix_1_len Length of the first prefix.
 * @param msg_prefix_2 Optional message prefix.
 * @param msg_prefix_2_len Length of the second prefix.
 * @param msg Start of the message.
 * @param msg_len Length of the message.
 * @param[out] mu The resulting message representative.
 * @return Result of the operation.
 */
OT_WARN_UNUSED_RESULT
rom_error_t sigverify_mldsa_compute_mu(
    const sigverify_mldsa_key_t *key, const void *ctx, size_t ctx_len,
    const void *msg_prefix_1, size_t msg_prefix_1_len,
    const void *msg_prefix_2, size_t msg_prefix_2_len, const void *msg,
    size_t msg_len,
    sigverify_mldsa_mu_t *mu);

/**
 * Verifies an ML-DSA-87 signature.
 *
 * Runs the verification on OTBN (see `otbn_boot_mldsa87_verify_start` /
 * `_finish`). The OTBN boot-services program must already be loaded (see
 * `otbn_boot_app_load`).
 *
 * The  ML-DSA-87 implementation has no separate "pure"/"pre-hash" variants
 * here: the caller is responsible for precomputing `mu`, the FIPS 204
 * message representative, using the message and the public key.
 *
 * @param signature Signature to be verified.
 * @param key Signer's ML-DSA-87 public key.
 * @param lc_state Life cycle state of the device.
 * @param mu Precomputed ML-DSA-87 message representative.
 * @param[out] flash_exec Value to write to the flash_ctrl EXEC register.
 * @return Result of the operation.
 */
OT_WARN_UNUSED_RESULT
rom_error_t sigverify_mldsa_verify(const sigverify_mldsa_signature_t *signature,
                                   const sigverify_mldsa_key_t *key,
                                   lifecycle_state_t lc_state,
                                   const sigverify_mldsa_mu_t *mu,
                                   uint32_t *flash_exec);

/**
 * Transforms `kSigverifyMldsaSuccess` into `kErrorOk`.
 *
 * Callers should transform the result to a suitable error value if it is not
 * `kErrorOk` for ease of debugging.
 *
 * @param v A value.
 * @return `kErrorOk` if `v` is `kSigverifyMldsaSuccess`.
 */
OT_WARN_UNUSED_RESULT
inline uint32_t sigverify_mldsa_success_to_ok(uint32_t v) {
  return (v << 22 ^ v << 8 ^ v << 1) >> 20;
}

#ifdef __cplusplus
}  // extern "C"
#endif  // __cplusplus

#endif  // OPENTITAN_SW_DEVICE_SILICON_CREATOR_LIB_SIGVERIFY_MLDSA_VERIFY_H_
