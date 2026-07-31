// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#ifndef OPENTITAN_SW_DEVICE_SILICON_CREATOR_ROM_SIGVERIFY_KEYS_MLDSA_H_
#define OPENTITAN_SW_DEVICE_SILICON_CREATOR_ROM_SIGVERIFY_KEYS_MLDSA_H_

#include <stdint.h>

#include "sw/device/silicon_creator/lib/drivers/lifecycle.h"
#include "sw/device/silicon_creator/lib/error.h"
#include "sw/device/silicon_creator/lib/sigverify/mldsa_key.h"
#include "sw/device/silicon_creator/rom/sigverify_key_types.h"
#include "sw/device/silicon_creator/rom/sigverify_otp_keys.h"

#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus

/**
 * Number of ML-DSA-87 key digests.
 */
extern const size_t kSigverifyMldsaKeysCnt;

/**
 * Step size to use when checking ML-DSA-87 key digests.
 *
 * This must be coprime with and less than `kSigverifyMldsaKeysCnt`.
 * Note: Step size is not applicable when `kSigverifyMldsaKeysCnt` is 1.
 */
extern const size_t kSigverifyMldsaKeysStep;

/**
 * ML-DSA-87 key digests for signature verification.
 */
extern const sigverify_rom_mldsa_key_t kSigverifyMldsaKeys[];

/**
 * Validates an ML-DSA-87 public key against the digests stored in OTP.
 *
 * OTP does not hold a usable copy of the key itself, ML-DSA-87 public keys
 * are too large to store directly in OTP. Instead, OTP holds a SHA3-256 digest
 * of each provisioned key, and the full key must be delivered by the caller
 * (e.g. extracted from the manifest). This function computes the digest of
 * `key` and checks it against OTP. The caller must not trust `key` for
 * signature verification unless this function returns `kErrorOk`.
 *
 * This function returns success only if the computed digest matches an OTP
 * entry that is `Provisioned` and usable in the given life cycle state. OTP
 * checks are performed only if the device is in a non-test operational state
 * (PROD, PROD_END, DEV, RMA).
 *
 * @param sigverify_ctx OTP keys context.
 * @param key Full ML-DSA-87 public key to validate, e.g. from the manifest.
 * @param lc_state Life cycle state of the device.
 * @return Result of the operation.
 */
OT_WARN_UNUSED_RESULT
rom_error_t sigverify_mldsa_key_get(
    const sigverify_otp_key_ctx_t *sigverify_ctx,
    const sigverify_mldsa_key_t *key, lifecycle_state_t lc_state);

#ifdef __cplusplus
}  // extern "C"
#endif  // __cplusplus

#endif  // OPENTITAN_SW_DEVICE_SILICON_CREATOR_ROM_SIGVERIFY_KEYS_MLDSA_H_
