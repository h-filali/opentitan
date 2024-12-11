// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "sw/device/lib/base/status.h"
#include "sw/device/lib/ujson/ujson.h"

enum {
  /**
   * Maximum Batch size.
   */
  kMlDsaMaxBatchSize = 32,
  /**
   * Size of vectors in ML-DSA.
   */
  kMlDsaVectorSize = 256,
  /**
   * Modulus in ML-DSA for modular operations.
   */
  kMlDsaModulus = 8380417,
};

status_t handle_ml_dsa_pentest_init(ujson_t *uj);
status_t handle_ml_dsa_seed_lfsr(ujson_t *uj);
status_t handle_ml_dsa_sca_reject_fvsr(ujson_t *uj);
status_t handle_ml_dsa_sca_decompose_fvsr(ujson_t *uj);
status_t handle_ml_dsa_sca_vec_add_fvsr(ujson_t *uj);
status_t handle_ml_dsa_sca_vec_sub_fvsr(ujson_t *uj);
status_t handle_ml_dsa_sca_vec_mul_fvsr(ujson_t *uj);
status_t handle_ml_dsa_sca_vec_mac_fvsr(ujson_t *uj);
status_t handle_ml_dsa_sca_ntt(ujson_t *uj);
status_t handle_ml_dsa_sca_ntt_fvsr(ujson_t *uj);
status_t handle_ml_dsa_sca_intt(ujson_t *uj);
status_t handle_ml_dsa_sca_intt_fvsr(ujson_t *uj);
status_t handle_ml_dsa_sca(ujson_t *uj);
