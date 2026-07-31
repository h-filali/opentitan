// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#ifndef OPENTITAN_SW_DEVICE_SILICON_CREATOR_LIB_OWNERSHIP_OWNER_VERIFY_H_
#define OPENTITAN_SW_DEVICE_SILICON_CREATOR_LIB_OWNERSHIP_OWNER_VERIFY_H_

#include "sw/device/silicon_creator/lib/drivers/hmac.h"
#include "sw/device/silicon_creator/lib/error.h"
#include "sw/device/silicon_creator/lib/ownership/datatypes.h"
#include "sw/device/silicon_creator/lib/sigverify/ecdsa_p256_key.h"
#include "sw/device/silicon_creator/lib/sigverify/mldsa_key.h"
#include "sw/device/silicon_creator/lib/sigverify/spx_key.h"

/**
 * Verify data using an owner key or owner application key.
 *
 * @param key_alg The key algorithm (i.e.: ownership_key_alg_t).
 * @param key The public key material.
 * @param ecdsa_sig The ECDSA signature to verify (if relevant to key_alg).
 * @param spx_sig The SPX signature to verify (if relevant to key_alg).
 * @param mldsa_sig The ML-DSA-87 signature to verify (if relevant to
 * key_alg).
 * @param mldsa_full_key The full ML-DSA-87 public key (if relevant to
 * key_alg). `key`'s ML-DSA-87 field only holds a SHA3-256 digest (too
 * large to store in full), so the full key must be supplied separately
 * (e.g. from the image's own manifest extension) and is validated against
 * that digest internally.
 * @param mldsa_full_key_digest The caller-precomputed SHA3-256 digest of
 * `mldsa_full_key` (if relevant to key_alg), e.g. already computed by the
 * caller for a keyring lookup. Passed in rather than recomputed here to
 * avoid hashing the key twice per verification.
 * @param msg_prefix_1 A portion of the SPX+/ML-DSA-87 message to verify (if
 * relevant).
 * @param msg_prefix_1_len The length of msg_prefix_1.
 * @param msg_prefix_2 A portion of the SPX+/ML-DSA-87 message to verify (if
 * relevant).
 * @param msg_prefix_2_len The length of msg_prefix_2.
 * @param msg The SPX+/ML-DSA-87 message to verify (if relevant).
 * @param msg_len The length of the msg.
 * @param digest The SHA256 digest over the data to verify.
 * @param flash_exec[out] The flash_exec password, if the verify succeeds.
 * @return kErrorOk if the verify succeeds, else an error code.
 */
rom_error_t owner_verify(uint32_t key_alg, const owner_keydata_t *key,
                         const ecdsa_p256_signature_t *ecdsa_sig,
                         const sigverify_spx_signature_t *spx_sig,
                         const sigverify_mldsa_signature_t *mldsa_sig,
                         const sigverify_mldsa_key_t *mldsa_full_key,
                         const uint32_t *mldsa_full_key_digest,
                         const void *msg_prefix_1, size_t msg_prefix_1_len,
                         const void *msg_prefix_2, size_t msg_prefix_2_len,
                         const void *msg, size_t msg_len,
                         const hmac_digest_t *digest, uint32_t *flash_exec);

#endif  // OPENTITAN_SW_DEVICE_SILICON_CREATOR_LIB_OWNERSHIP_OWNER_VERIFY_H_
