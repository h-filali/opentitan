// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#ifndef OPENTITAN_SW_DEVICE_SILICON_CREATOR_LIB_DRIVERS_KMAC_H_
#define OPENTITAN_SW_DEVICE_SILICON_CREATOR_LIB_DRIVERS_KMAC_H_

/**
 * This driver is specialized to meet the needs of SPHINCS+-SHAKE.
 */

#include <stdint.h>

#include "sw/device/lib/base/macros.h"
#include "sw/device/silicon_creator/lib/error.h"

#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus

/**
 * Configure the KMAC block for KEYMGR mode of operation.
 *
 * In this mode, KMAC is configured to support sideload and message masking
 * functionality.
 *
 * @return Error code indicating if the operation succeeded.
 */
rom_error_t kmac_keymgr_configure(void);

/**
 * Configure the KMAC block for KMAC-256 operation with a key loaded by
 * software.
 *
 * @return Error code indicating if the operation succeeded.
 */
rom_error_t kmac_kmac256_sw_configure(void);

/**
 * Configure the KMAC block for KMAC-256 operation with a key sideloaded from
 * the keymgr hardware block.
 *
 * @return Error code indicating if the operation succeeded.
 */
rom_error_t kmac_kmac256_hw_configure(void);

/**
 * Configure the KMAC block at startup.
 *
 * Sets the KMAC block to use software entropy (since we have no secret inputs
 * for SPHINCS+) and sets the mode to SHAKE-256.
 *
 * @return Error code indicating if the operation succeeded.
 */
OT_WARN_UNUSED_RESULT
rom_error_t kmac_shake256_configure(void);

/**
 * Configure the KMAC block for a SHA3-256 hashing operation.
 *
 * This selects the KMAC's dedicated SHA3 mode.
 *
 * @return Error code indicating if the operation succeeded.
 */
OT_WARN_UNUSED_RESULT
rom_error_t kmac_sha3_256_configure(void);

/**
 * Start a SHAKE-256 hashing operation.
 *
 * Must be called after `kmac_shake256_configure()`. Will block until KMAC
 * hardware is idle.
 *
 * This driver supports SHAKE-256 hashing with the following pattern:
 * - Exactly one call to `kmac_shake256_start`
 * - Zero or more calls to `kmac_shake256_absorb`
 * - Exactly one call to `kmac_shake256_squeeze_start`
 * - Exactly one call to `kmac_shake256_squeeze_end`
 *
 * There is no need to append the `1111` padding in the SHAKE-256 specification
 * to the input; this will happen automatically in squeeze_start().
 *
 * @return Error code indicating if the operation succeeded.
 */
OT_WARN_UNUSED_RESULT
rom_error_t kmac_shake256_start(void);

/**
 * Absorb (more) input for a SHAKE-256 hashing operation.
 *
 * The caller is responsible for calling `kmac_shake256_configure()` and
 * `kmac_shake256_start()` first. The implementation depends on specific
 * details of the KMAC configuration (in particular the entropy setup).
 *
 * Blocks until the all input is written.
 *
 * For best performance, `in` should be 32b-aligned, although this function
 * does handle unaligned buffers.
 *
 * @param in Input buffer
 * @param inlen Length of input (bytes)
 * @return Error code indicating if the operation succeeded.
 */
void kmac_shake256_absorb(const uint8_t *in, size_t inlen);

/**
 * Absorb (more) input for a SHAKE-256 hashing operation.
 *
 * Identical to `kmac_shake256_absorb`, but accepts input in the 32b words
 * rather than bytes and is therefore faster because it does not need to
 * perform alignment checks.
 *
 * The caller is responsible for calling `kmac_shake256_configure()` and
 * `kmac_shake256_start()` first. The implementation depends on specific
 * details of the KMAC configuration (in particular the entropy setup).
 *
 * Blocks until the all input is written.
 *
 * @param in Input buffer
 * @param inlen Length of input (words)
 * @return Error code indicating if the operation succeeded.
 */
void kmac_shake256_absorb_words(const uint32_t *in, size_t inlen);

/**
 * Begin the squeezing phase of a SHAKE-256 hashing operation.
 *
 * This function will move from `absorb` to `squeeze` state and append the
 * SHAKE-256 suffix to the message. It will also initialize the internal
 * context object.
 *
 * The caller is responsible for calling `kmac_shake256_configure()` and
 * `kmac_shake256_start()` first. It is not necessary to call
 * `kmac_shake256_absorb()` before calling this; in that case, the resulting
 * digest will simply be the digest of an empty message.
 *
 * @return Error code indicating if the operation succeeded.
 */
void kmac_shake256_squeeze_start(void);

/**
 * Squeeze output from a SHAKE-256 hashing operation, and end the operation.
 *
 * The caller is responsible for calling `kmac_shake256_configure` and
 * `kmac_shake256_squeeze_start()` first.
 *
 * Blocks until all output is written.  After ending the operation, this
 * function does not block until KMAC is idle; errors may appear in the next
 * call to `kmac_shake256_start`.
 *
 * @param out Output buffer
 * @param outlen Desired length of output (in words)
 * @return Error code indicating if the operation succeeded.
 */
OT_WARN_UNUSED_RESULT
rom_error_t kmac_shake256_squeeze_end(uint32_t *out, size_t outlen);

enum {
  /**
   * Size of a SHA3-256 digest in words.
   *
   * SHA3-256 always produces a fixed-size, 256-bit digest.
   */
  kKmacSha3256DigestWords = 256 / 32,
};

/**
 * Start a SHA3-256 hashing operation.
 *
 * Must be called after `kmac_sha3_256_configure()`. Identical in mechanics to
 * `kmac_shake256_start()`.
 *
 * @return Error code indicating if the operation succeeded.
 */
OT_WARN_UNUSED_RESULT
inline rom_error_t kmac_sha3_256_start(void) { return kmac_shake256_start(); }

/**
 * Absorb (more) input for a SHA3-256 hashing operation.
 *
 * @param in Input buffer.
 * @param inlen Length of input (bytes).
 */
inline void kmac_sha3_256_absorb(const void *in, size_t inlen) {
  kmac_shake256_absorb((const uint8_t *)in, inlen);
}

/**
 * Absorb (more) word-aligned input for a SHA3-256 hashing operation.
 *
 * @param in Input buffer.
 * @param inlen Length of input (words).
 */
inline void kmac_sha3_256_absorb_words(const uint32_t *in, size_t inlen) {
  kmac_shake256_absorb_words(in, inlen);
}

/**
 * Begin the squeezing phase of a SHA3-256 hashing operation.
 */
inline void kmac_sha3_256_squeeze_start(void) { kmac_shake256_squeeze_start(); }

/**
 * Squeeze the (fixed-size) digest from a SHA3-256 hashing operation, and end
 * the operation.
 *
 * @param[out] out Output buffer, exactly `kKmacSha3256DigestWords` long.
 * @return Error code indicating if the operation succeeded.
 */
OT_WARN_UNUSED_RESULT
inline rom_error_t kmac_sha3_256_squeeze_end(uint32_t *out) {
  return kmac_shake256_squeeze_end(out, kKmacSha3256DigestWords);
}

/**
 * Load an unmasked software key into KMAC.
 *
 * @param key The key material.
 * @param len The length of the key material in words.
 * @return Error code indicating if the operation succeeded.
 */
OT_WARN_UNUSED_RESULT
rom_error_t kmac_kmac256_sw_key(const uint32_t *key, size_t len);

/**
 * Set the KMAC prefix value.
 *
 * Sets the prefix to the given prefix value.  The prefix
 * must be 31 bytes or fewer.
 *
 * @param prefix The prefix value encoded as words.
 * @param len The length of the prefix in bytes.
 */
void kmac_kmac256_set_prefix(const void *prefix, size_t len);

/**
 * Start a KMAC-256 operation.
 *
 * @return Error code indicating if the operation succeeded.
 */
OT_WARN_UNUSED_RESULT
inline rom_error_t kmac_kmac256_start(void) { return kmac_shake256_start(); }

/**
 * Absorb data into a KMAC-256.
 *
 * @param data Data to absorb into the sponge.
 * @param len Length of the data.
 */
inline void kmac_kmac256_absorb(const void *data, size_t len) {
  kmac_shake256_absorb((const uint8_t *)data, len);
}

/**
 * Finalize the KMAC-256 operation.
 *
 * @param result Buffer to hold the result of the KMAC operation.
 * @param rlen Length of the result buffer in words.
 * @return Error code indicating if the operation succeeded.
 */
OT_WARN_UNUSED_RESULT
rom_error_t kmac_kmac256_final(uint32_t *result, size_t rlen);

#ifdef __cplusplus
}  // extern "C"
#endif  // __cplusplus

#endif  // OPENTITAN_SW_DEVICE_SILICON_CREATOR_LIB_DRIVERS_KMAC_H_
