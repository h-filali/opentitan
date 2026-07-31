// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#ifndef OPENTITAN_SW_DEVICE_SILICON_CREATOR_LIB_SIGVERIFY_MLDSA_KEY_H_
#define OPENTITAN_SW_DEVICE_SILICON_CREATOR_LIB_SIGVERIFY_MLDSA_KEY_H_

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus

enum {
  /**
   * Size of the `rho` component of an ML-DSA-87 public key in bytes.
   */
  kSigverifyMldsaPkRhoBytes = 32,
  /**
   * Size of the `t1` component of an ML-DSA-87 public key in bytes.
   */
  kSigverifyMldsaPkT1Bytes = 2560,
  /**
   * Size of the `c_tilde` component of an ML-DSA-87 signature in bytes.
   */
  kSigverifyMldsaSigCTildeBytes = 64,
  /**
   * Size of the `z` component of an ML-DSA-87 signature in bytes.
   */
  kSigverifyMldsaSigZBytes = 4480,
  /**
   * Size of the `h` (hint) component of an ML-DSA-87 signature in bytes.
   */
  kSigverifyMldsaSigHBytes = 83,
  /**
   * Size of the ML-DSA-87 "mu" message representative in bytes.
   */
  kSigverifyMldsaMuBytes = 64,
  /**
   * Size of the ML-DSA-87 "mu" message representative in words.
   */
  kSigverifyMldsaMuNumWords = kSigverifyMldsaMuBytes / sizeof(uint32_t),
  /**
   * Size of an ML-DSA-87 public key digest in words.
   *
   * ML-DSA-87 public keys (2592 bytes) are too large to store directly in
   * some fixed-size, OTP- or flash-resident key slots. In those places, a
   * SHA3-256 digest of the key is stored instead, and the full key is
   * delivered separately and validated against the digest before use.
   */
  kSigverifyMldsaKeyDigestWords = 8,
};

/**
 * An ML-DSA-87 public key.
 */
typedef struct sigverify_mldsa_key {
  /**
   * `rho`, the seed for the public matrix A. Little-endian.
   */
  uint32_t rho[kSigverifyMldsaPkRhoBytes / sizeof(uint32_t)];
  /**
   * `t1`, the high-order bits of the public key vector t. Little-endian.
   */
  uint32_t t1[kSigverifyMldsaPkT1Bytes / sizeof(uint32_t)];
} sigverify_mldsa_key_t;

/**
 * An ML-DSA-87 signature.
 */
typedef struct sigverify_mldsa_signature {
  /**
   * `c_tilde`, the commitment hash. Little-endian.
   */
  uint32_t c_tilde[kSigverifyMldsaSigCTildeBytes / sizeof(uint32_t)];
  /**
   * `z`, the signer's response vector. Little-endian.
   */
  uint32_t z[kSigverifyMldsaSigZBytes / sizeof(uint32_t)];
  /**
   * `h`, the hint bit-vector, byte-packed per FIPS 204.
   */
  uint8_t h[kSigverifyMldsaSigHBytes];
} sigverify_mldsa_signature_t;

/**
 * The ML-DSA-87 "mu" message representative.
 *
 * Precomputed by the caller from the public key and message.
 */
typedef struct sigverify_mldsa_mu {
  uint32_t data[kSigverifyMldsaMuNumWords];
} sigverify_mldsa_mu_t;

#ifdef __cplusplus
}  // extern "C"
#endif  // __cplusplus

#endif  // OPENTITAN_SW_DEVICE_SILICON_CREATOR_LIB_SIGVERIFY_MLDSA_KEY_H_
