// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#ifndef OPENTITAN_SW_DEVICE_TESTS_PENETRATIONTESTS_JSON_ML_DSA_SCA_COMMANDS_H_
#define OPENTITAN_SW_DEVICE_TESTS_PENETRATIONTESTS_JSON_ML_DSA_SCA_COMMANDS_H_
#include "sw/device/lib/ujson/ujson_derive.h"
#ifdef __cplusplus
extern "C" {
#endif

#define ML_DSA_SCA_CMD_MAX_DATA_BYTES 4*256
#define ML_DSA_SCA_CMD_MAX_SEED_BYTES 4
#define ML_DSA_SCA_CMD_MAX_LFSR_BYTES 4

// clang-format off

// ML-DSA SCA arguments

#define ML_DSA_SCA_SUBCOMMAND(_, value) \
    value(_, Init) \
    value(_, SeedLfsr) \
    value(_, RejectFvsr) \
    value(_, DecomposeFvsr) \
    value(_, VecAddFvsr) \
    value(_, VecSubFvsr) \
    value(_, VecMulFvsr) \
    value(_, VecMacFvsr) \
    value(_, NttFvsr) \
    value(_, Ntt) \
    value(_, InttFvsr) \
    value(_, Intt)
UJSON_SERDE_ENUM(MlDsaScaSubcommand, ml_dsa_sca_subcommand_t, ML_DSA_SCA_SUBCOMMAND);

#define ML_DSA_SCA_DATA(field, string) \
    field(data, uint32_t, ML_DSA_SCA_CMD_MAX_DATA_BYTES) \
    field(data_length, size_t)
UJSON_SERDE_STRUCT(MlDsaScaData, ml_dsa_sca_data_t, ML_DSA_SCA_DATA);

#define ML_DSA_SCA_FVSR_DATA(field, string) \
    field(data, uint32_t, ML_DSA_SCA_CMD_MAX_DATA_BYTES) \
    field(data_length, size_t) \
    field(iterations, uint32_t) \
    field(var_select, uint32_t)
UJSON_SERDE_STRUCT(MlDsaScaFvsrData, ml_dsa_sca_fvsr_data_t, ML_DSA_SCA_FVSR_DATA);

#define ML_DSA_SCA_RESULT(field, string) \
    field(result, uint32_t)
UJSON_SERDE_STRUCT(MlDsaScaResult, ml_dsa_sca_result_t, ML_DSA_SCA_RESULT);

#define ML_DSA_SCA_SEED(field, string) \
    field(seed, uint8_t, ML_DSA_SCA_CMD_MAX_SEED_BYTES)
UJSON_SERDE_STRUCT(MlDsaScaSeed, ml_dsa_sca_seed_t, ML_DSA_SCA_SEED);

#define ML_DSA_SCA_LFSR(field, string) \
    field(seed, uint8_t, ML_DSA_SCA_CMD_MAX_LFSR_BYTES)
UJSON_SERDE_STRUCT(MlDsaScaLfsr, ml_dsa_sca_lfsr_t, ML_DSA_SCA_LFSR);
// clang-format on

#ifdef __cplusplus
}
#endif
#endif  // OPENTITAN_SW_DEVICE_TESTS_PENETRATIONTESTS_JSON_AES_SCA_COMMANDS_H_
