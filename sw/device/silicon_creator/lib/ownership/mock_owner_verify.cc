// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "sw/device/silicon_creator/lib/ownership/mock_owner_verify.h"

namespace rom_test {
extern "C" {

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
  return MockOwnerVerify::Instance().verify(
      key_alg, key, ecdsa_sig, spx_sig, mldsa_sig, mldsa_full_key,
      mldsa_full_key_digest, msg_prefix_1, msg_prefix_1_len, msg_prefix_2,
      msg_prefix_2_len, msg, msg_len, digest, flash_exec);
}

}  // extern "C"
}  // namespace rom_test
