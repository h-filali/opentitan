// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "sw/device/silicon_creator/rom/sigverify_keys_mldsa.h"

#include "sw/device/silicon_creator/lib/sigverify/mldsa_verify.h"
#include "sw/device/silicon_creator/rom/sigverify_otp_keys.h"

#include "hw/top/otp_ctrl_regs.h"

rom_error_t sigverify_mldsa_key_get(
    const sigverify_otp_key_ctx_t *sigverify_ctx,
    const sigverify_mldsa_key_t *key, lifecycle_state_t lc_state) {
  uint32_t mldsa_en = sigverify_mldsa_verify_enabled(lc_state);
  rom_error_t error = kErrorSigverifyBadMldsaKey;

  if (launder32(mldsa_en) != kSigverifyMldsaDisabledOtp) {
    uint32_t digest[kSigverifyMldsaKeyDigestWords];
    HARDENED_RETURN_IF_ERROR(sigverify_mldsa_key_digest(key, digest));

    const sigverify_rom_key_header_t *rom_key = NULL;
    error = sigverify_otp_keys_get(
        (sigverify_otp_keys_get_params_t){
            .key_id = digest[0],
            .lc_state = lc_state,
            .key_array = (const sigverify_rom_key_header_t *)(
                sigverify_ctx->keys.mldsa),
            .key_cnt = kSigVerifyOtpKeysMldsaCount,
            .key_size = sizeof(sigverify_rom_mldsa_key_t),
            .key_states = (uint32_t *)&sigverify_ctx->states.mldsa[0],
        },
        &rom_key);
    if (error == kErrorOk) {
      // `sigverify_otp_keys_get()` only matched on `digest[0]` (aliased as
      // `key_id`, per the common initial sequence convention). Verify the
      // remaining words of the digest too, to rule out a collision on that
      // single word being mistaken for a full match.
      const sigverify_rom_mldsa_key_entry_t *matched =
          &((const sigverify_rom_mldsa_key_t *)rom_key)->entry;
      uint32_t diff = 0;
      size_t i = 0;
      for (; launder32(i) < kSigverifyMldsaKeyDigestWords; ++i) {
        diff |= digest[i] ^ matched->digest[i];
      }
      HARDENED_CHECK_EQ(i, kSigverifyMldsaKeyDigestWords);
      if (launder32(diff) != 0) {
        return kErrorSigverifyBadMldsaKey;
      }
      HARDENED_CHECK_EQ(diff, 0);
    }
  } else {
    HARDENED_CHECK_EQ(mldsa_en, kSigverifyMldsaDisabledOtp);
    error = sigverify_mldsa_success_to_ok(mldsa_en);
  }

  if (error != kErrorOk) {
    return kErrorSigverifyBadMldsaKey;
  }
  return error;
}
