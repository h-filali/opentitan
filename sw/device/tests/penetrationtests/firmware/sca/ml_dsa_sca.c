// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "sw/device/tests/penetrationtests/firmware/sca/ml_dsa_sca.h"

#include "sw/device/lib/base/memory.h"
#include "sw/device/lib/base/status.h"
#include "sw/device/lib/crypto/drivers/otbn.h"
#include "sw/device/lib/dif/dif_otbn.h"
#include "sw/device/lib/runtime/log.h"
#include "sw/device/lib/testing/test_framework/check.h"
#include "sw/device/lib/testing/test_framework/ottf_test_config.h"
#include "sw/device/lib/testing/test_framework/ujson_ottf.h"
#include "sw/device/lib/ujson/ujson.h"
#include "sw/device/sca/lib/prng.h"
#include "sw/device/tests/penetrationtests/firmware/lib/pentest_lib.h"
#include "sw/device/tests/penetrationtests/json/ml_dsa_sca_commands.h"

#include "hw/top_earlgrey/sw/autogen/top_earlgrey.h"

// NOP macros.
#define NOP1 "addi x0, x0, 0\n"
#define NOP10 NOP1 NOP1 NOP1 NOP1 NOP1 NOP1 NOP1 NOP1 NOP1 NOP1
#define NOP30 NOP10 NOP10 NOP10
#define NOP100 NOP30 NOP30 NOP30 NOP10
#define NOP1000 NOP100 NOP100 NOP100 NOP100 NOP100 NOP100 NOP100 NOP100 NOP100 NOP100
#define NOP5000 NOP1000 NOP1000 NOP1000 NOP1000 NOP1000

enum {
  /**
   * Number of cycles (at `kClockFreqCpuHz`) that Ibex should sleep to minimize
   * noise during OTBN operations. Caution: This number should be chosen to
   * provide enough time. Otherwise, Ibex might wake up while OTBN is still busy
   * and disturb the capture.
   */
  kMlDsaRejectSleepCycles    = 3896,
  kMlDsaDecomposeSleepCycles = 7848,
  kMlDsaVecAddSleepCycles    = 2189,
  kMlDsaVecSubSleepCycles    = 2190,
  kMlDsaVecMulSleepCycles    = 4755,
  kMlDsaVecMacSleepCycles    = 5592,
  kMlDsaNttSleepCycles       = 8791,
  kMlDsaInttSleepCycles      = 9862,
};

// Reject
OTBN_DECLARE_APP_SYMBOLS(ml_dsa_sec_reject);
OTBN_DECLARE_SYMBOL_ADDR(ml_dsa_sec_reject, inp_z_s0);
OTBN_DECLARE_SYMBOL_ADDR(ml_dsa_sec_reject, inp_z_s1);
OTBN_DECLARE_SYMBOL_ADDR(ml_dsa_sec_reject, result);
const otbn_app_t kOtbnAppMlDsaSecReject = OTBN_APP_T_INIT(ml_dsa_sec_reject);
static const otbn_addr_t kOtbnAppMlDsaSecRejectInpZS0 =
    OTBN_ADDR_T_INIT(ml_dsa_sec_reject, inp_z_s0);
static const otbn_addr_t kOtbnAppMlDsaSecRejectInpZS1 =
    OTBN_ADDR_T_INIT(ml_dsa_sec_reject, inp_z_s1);
// static const otbn_addr_t kOtbnAppMlDsaSecRejctResult =
//     OTBN_ADDR_T_INIT(ml_dsa_sec_reject, result);

// Decompose
OTBN_DECLARE_APP_SYMBOLS(ml_dsa_sec_decompose);
OTBN_DECLARE_SYMBOL_ADDR(ml_dsa_sec_decompose, decompose_r_s1);
OTBN_DECLARE_SYMBOL_ADDR(ml_dsa_sec_decompose, decompose_r_s2);
// OTBN_DECLARE_SYMBOL_ADDR(ml_dsa_sec_decompose, decompose_r0_s1);
// OTBN_DECLARE_SYMBOL_ADDR(ml_dsa_sec_decompose, decompose_r0_s2);
// OTBN_DECLARE_SYMBOL_ADDR(ml_dsa_sec_decompose, decompose_r1);
const otbn_app_t kOtbnAppMlDsaDecompose = OTBN_APP_T_INIT(ml_dsa_sec_decompose);
static const otbn_addr_t kOtbnAppMlDsaDecomposeInpRS1 =
    OTBN_ADDR_T_INIT(ml_dsa_sec_decompose, decompose_r_s1);
static const otbn_addr_t kOtbnAppMlDsaDecomposeInpRS2 =
    OTBN_ADDR_T_INIT(ml_dsa_sec_decompose, decompose_r_s2);
// static const otbn_addr_t kOtbnAppMlDsaDecomposeOupR0S1 =
//     OTBN_ADDR_T_INIT(ml_dsa_sec_decompose, decompose_r0_s1);
// static const otbn_addr_t kOtbnAppMlDsaDecomposeOupR0S2 =
//     OTBN_ADDR_T_INIT(ml_dsa_sec_decompose, decompose_r0_s2);
// static const otbn_addr_t kOtbnAppMlDsaDecomposeOupR1 =
//     OTBN_ADDR_T_INIT(ml_dsa_sec_decompose, decompose_r1);

// Vector addition
OTBN_DECLARE_APP_SYMBOLS(ml_dsa_vec_add);
OTBN_DECLARE_SYMBOL_ADDR(ml_dsa_vec_add, vec_add_a);
OTBN_DECLARE_SYMBOL_ADDR(ml_dsa_vec_add, vec_add_b);
const otbn_app_t kOtbnAppMlDsaVecAdd = OTBN_APP_T_INIT(ml_dsa_vec_add);
static const otbn_addr_t kOtbnAppMlDsaVecAddA =
    OTBN_ADDR_T_INIT(ml_dsa_vec_add, vec_add_a);
static const otbn_addr_t kOtbnAppMlDsaVecAddB =
    OTBN_ADDR_T_INIT(ml_dsa_vec_add, vec_add_b);

// Vector subtraction
OTBN_DECLARE_APP_SYMBOLS(ml_dsa_vec_sub);
OTBN_DECLARE_SYMBOL_ADDR(ml_dsa_vec_sub, vec_sub_a);
OTBN_DECLARE_SYMBOL_ADDR(ml_dsa_vec_sub, vec_sub_b);
const otbn_app_t kOtbnAppMlDsaVecSub = OTBN_APP_T_INIT(ml_dsa_vec_sub);
static const otbn_addr_t kOtbnAppMlDsaVecSubA =
    OTBN_ADDR_T_INIT(ml_dsa_vec_sub, vec_sub_a);
static const otbn_addr_t kOtbnAppMlDsaVecSubB =
    OTBN_ADDR_T_INIT(ml_dsa_vec_sub, vec_sub_b);

// Vector coefficient-wise multiplicaiton
OTBN_DECLARE_APP_SYMBOLS(ml_dsa_vec_mul);
OTBN_DECLARE_SYMBOL_ADDR(ml_dsa_vec_mul, vec_mul_a);
OTBN_DECLARE_SYMBOL_ADDR(ml_dsa_vec_mul, vec_mul_b);
const otbn_app_t kOtbnAppMlDsaVecMul = OTBN_APP_T_INIT(ml_dsa_vec_mul);
static const otbn_addr_t kOtbnAppMlDsaVecMulA =
    OTBN_ADDR_T_INIT(ml_dsa_vec_mul, vec_mul_a);
static const otbn_addr_t kOtbnAppMlDsaVecMulB =
    OTBN_ADDR_T_INIT(ml_dsa_vec_mul, vec_mul_b);

// Vector multiply accumulate
OTBN_DECLARE_APP_SYMBOLS(ml_dsa_vec_mac);
OTBN_DECLARE_SYMBOL_ADDR(ml_dsa_vec_mac, vec_mac_a);
OTBN_DECLARE_SYMBOL_ADDR(ml_dsa_vec_mac, vec_mac_b);
// OTBN_DECLARE_SYMBOL_ADDR(ml_dsa_vec_mac, vec_mac_res);
const otbn_app_t kOtbnAppMlDsaVecMac = OTBN_APP_T_INIT(ml_dsa_vec_mac);
static const otbn_addr_t kOtbnAppMlDsaVecMacA =
    OTBN_ADDR_T_INIT(ml_dsa_vec_mac, vec_mac_a);
static const otbn_addr_t kOtbnAppMlDsaVecMacB =
    OTBN_ADDR_T_INIT(ml_dsa_vec_mac, vec_mac_b);
// static const otbn_addr_t kOtbnAppMlDsaVecMacRes =
//     OTBN_ADDR_T_INIT(ml_dsa_vec_mac, vec_mac_res);

// Vector NTT
OTBN_DECLARE_APP_SYMBOLS(ml_dsa_ntt);
OTBN_DECLARE_SYMBOL_ADDR(ml_dsa_ntt, ntt_w);
const otbn_app_t kOtbnAppMlDsaNtt = OTBN_APP_T_INIT(ml_dsa_ntt);
static const otbn_addr_t kOtbnAppMlDsaNttW =
    OTBN_ADDR_T_INIT(ml_dsa_ntt, ntt_w);

// Vector INTT
OTBN_DECLARE_APP_SYMBOLS(ml_dsa_intt);
OTBN_DECLARE_SYMBOL_ADDR(ml_dsa_intt, ntt_w);
const otbn_app_t kOtbnAppMlDsaIntt = OTBN_APP_T_INIT(ml_dsa_intt);
static const otbn_addr_t kOtbnAppMlDsaInttW =
    OTBN_ADDR_T_INIT(ml_dsa_intt, ntt_w);

/**
 * The otbn context handler.
 */
static dif_otbn_t otbn;

/**
 * Clears the OTBN DMEM and IMEM.
 *
 * @returns OK or error.
 */
static status_t clear_otbn(void) {
  // Clear OTBN memory.
  TRY(otbn_dmem_sec_wipe());
  TRY(otbn_imem_sec_wipe());

  return OK_STATUS();
}

static void otbn_execute_delayed(void) {
  // Wait for the trigger to rise.
  // asm volatile(NOP5000);
  // Call OTBN to perform the operation and wait for it to complete.
  CHECK_STATUS_OK(otbn_execute());
}

// Generate Fixed vs Random (FvsR) array of values. The fixed value is provided
// by the user and the random values are generated by the PRNG provided in the
// SCA library.
// static void generate_fvsr_decompose(size_t num_iterations, uint32_t fixed_data,
//     uint32_t values[kMlDsaMaxBatchSize][kMlDsaNumShares]) {
//   bool sample_fixed = prng_rand_uint32() & 0x1;
//   for (size_t i = 0; i < num_iterations; i++) {
//     if (sample_fixed) {
//       const uint32_t a = pentest_next_lfsr(32, kPentestLfsrMasking);
//       values[i][0] = (fixed_data + a) % kMlDsaModulus;
//       values[i][1] = (kMlDsaModulus - a) % kMlDsaModulus;
//     } else {
//       const uint32_t a = pentest_next_lfsr(32, kPentestLfsrMasking);
//       values[i][0] = (prng_rand_uint32() + a) % kMlDsaModulus;
//       values[i][1] = (kMlDsaModulus - a) % kMlDsaModulus;
//     }
//     sample_fixed = prng_rand_uint32() & 0x1;
//   }
// }

// Generate Fixed vs Random (FvsR) array of values. The fixed value is provided
// by the user and the random values are generated by the PRNG provided in the
// SCA library.
static void generate_vec_fvsr(size_t num_iterations, uint32_t fixed_data[],
                              uint32_t values[kMlDsaMaxBatchSize][kMlDsaVectorSize],
                              uint32_t *result) {
  bool sample_fixed = prng_rand_uint32() & 0x1;
  for (size_t i = 0; i < num_iterations; i++) {
    if (sample_fixed) {
      for (size_t j = 0; j < kMlDsaVectorSize; j++) {
        const uint32_t a = pentest_next_lfsr(32, kPentestLfsrMasking);
        values[i][j] = (fixed_data[j] + a) % kMlDsaModulus;
      }
      *result = fixed_data[kMlDsaVectorSize-1];
    } else {
      for (size_t j = 0; j < kMlDsaVectorSize; j++) {
        const uint32_t a = pentest_next_lfsr(32, kPentestLfsrMasking);
        *result = prng_rand_uint32() % kMlDsaModulus;
        values[i][j] = (*result + a) % kMlDsaModulus;
        // values[i][j] = (prng_rand_uint32() + a) % kMlDsaModulus;
      }
    }
    sample_fixed = prng_rand_uint32() & 0x1;
  }
  // *result = 0;
}

status_t handle_ml_dsa_sca_init(ujson_t *uj) {
  // Setup trigger and enable peripherals needed for the test.
  pentest_select_trigger_type(kPentestTriggerTypeSw);

  // Configure the entropy complex for OTBN. Set the reseed interval to max
  // to avoid a non-constant trigger window.
  TRY(pentest_configure_entropy_source_max_reseed_interval());

  // Initialize everything potentially needed for pentesting
  // (eg. uart, gpio, timer, csrng, edn).
  pentest_init(kPentestTriggerSourceOtbn,
               kPentestPeripheralEntropy | kPentestPeripheralIoDiv4 |
                   kPentestPeripheralOtbn | kPentestPeripheralCsrng |
                   kPentestPeripheralEdn | kPentestPeripheralHmac |
                   kPentestPeripheralKmac);

  // Initialize OTBN.
  CHECK_DIF_OK(
      dif_otbn_init(mmio_region_from_addr(TOP_EARLGREY_OTBN_BASE_ADDR), &otbn));
  
  // Disable the instruction cache and dummy instructions for better SCA
  // measurements.
  pentest_configure_cpu();

  // Read device ID and return to host.
  penetrationtest_device_id_t uj_output;
  TRY(pentest_read_device_id(uj_output.device_id));
  RESP_OK(ujson_serialize_penetrationtest_device_id_t, uj, &uj_output);

  return OK_STATUS();
}

status_t handle_ml_dsa_seed_lfsr(ujson_t *uj) {
  ml_dsa_sca_lfsr_t uj_lfsr_data;
  TRY(ujson_deserialize_ml_dsa_sca_lfsr_t(uj, &uj_lfsr_data));

  uint32_t seed_local = read_32(uj_lfsr_data.seed);
  pentest_seed_lfsr(seed_local, kPentestLfsrMasking);

  return OK_STATUS();
}

static status_t handle_ml_dsa_sca_vec_fvsr(ujson_t *uj, otbn_app_t otbn_app,
    ml_dsa_sca_fvsr_data_t uj_data, otbn_addr_t dmem_addr, uint32_t sleep_cycles) {

  // Result that is sent back to the host.
  uint32_t result;

  // Copy uj_data.data to our fixed input vector.
  uint32_t fixed_data[kMlDsaVectorSize];
  memcpy(fixed_data, uj_data.data, uj_data.data_length);

  // Generate FvsR values.
  uint32_t values[kMlDsaMaxBatchSize][kMlDsaVectorSize];
  generate_vec_fvsr(uj_data.iterations, fixed_data, values, &result);

  // Set the initial value determining whether we execute
  // with random or fixed inputs.
  for (size_t it = 0; it < uj_data.iterations; it++) {
    // Load the OTBN app.
    CHECK_STATUS_OK(otbn_load_app(otbn_app));
    // Write the input vector to OTBN.
    CHECK_STATUS_OK(
        otbn_dmem_write(/*num_words=*/kMlDsaVectorSize, values[it], dmem_addr));
    // Put Ibex to sleep and then wait for OTBN to finish executing its app.
    // This function also sets the trigger for capturing traces.
    pentest_call_and_sleep(otbn_execute_delayed, sleep_cycles + 5100, true, true);
    // Clear the IMEM and DMEM of OTBN.
    CHECK_STATUS_OK(clear_otbn());
  }

  // Write back last vector value to validate generated data.
  ml_dsa_sca_result_t uj_output;
  uj_output.result = result;
  RESP_OK(ujson_serialize_ml_dsa_sca_result_t, uj, &uj_output);

  return OK_STATUS();
}

status_t handle_ml_dsa_sca_reject_fvsr(ujson_t *uj) {
  ml_dsa_sca_data_t uj_data;
  uint32_t masked_data[2];
  uint32_t result;
  TRY(ujson_deserialize_ml_dsa_sca_data_t(uj, &uj_data));
  result = uj_data.data[0];

  // Load the application to OTBN.
  CHECK_STATUS_OK(otbn_load_app(kOtbnAppMlDsaSecReject));

  const uint32_t a = pentest_next_lfsr(32, kPentestLfsrMasking) % kMlDsaModulus;
  masked_data[0] = (uj_data.data[0] + a) % kMlDsaModulus;
  masked_data[1] = kMlDsaModulus - a;

  // Write the input vector to OTBN.
  CHECK_STATUS_OK(
      otbn_dmem_write(/*num_words=*/1, masked_data, kOtbnAppMlDsaSecRejectInpZS0));
  CHECK_STATUS_OK(
      otbn_dmem_write(/*num_words=*/1, &masked_data[1], kOtbnAppMlDsaSecRejectInpZS1));
  // Put Ibex to sleep and then wait for OTBN to finish executing its app.
  // This function also sets the trigger for capturing traces.
  pentest_call_and_sleep(otbn_execute_delayed, kMlDsaInttSleepCycles + 5100, true, true);
  // Clear the IMEM and DMEM of OTBN.
  CHECK_STATUS_OK(clear_otbn());

  // Write back the last word of the input vector to validate the data transfer.
  ml_dsa_sca_result_t uj_output;
  uj_output.result = result;
  RESP_OK(ujson_serialize_ml_dsa_sca_result_t, uj, &uj_output);

  return OK_STATUS();
}

status_t handle_ml_dsa_sca_decompose_fvsr(ujson_t *uj) {
  ml_dsa_sca_data_t uj_data;
  uint32_t masked_data[2];
  uint32_t result;
  TRY(ujson_deserialize_ml_dsa_sca_data_t(uj, &uj_data));
  result = uj_data.data[0];

  // Load the OTBN app.
  CHECK_STATUS_OK(otbn_load_app(kOtbnAppMlDsaDecompose));

  const uint32_t a = pentest_next_lfsr(32, kPentestLfsrMasking) % kMlDsaModulus;
  masked_data[0] = (uj_data.data[0] + a) % kMlDsaModulus;
  masked_data[1] = kMlDsaModulus - a;

  // Write the input vector to OTBN.
  CHECK_STATUS_OK(
      otbn_dmem_write(/*num_words=*/1, masked_data, kOtbnAppMlDsaDecomposeInpRS1));
  CHECK_STATUS_OK(
      otbn_dmem_write(/*num_words=*/1, &masked_data[1], kOtbnAppMlDsaDecomposeInpRS2));
  // Put Ibex to sleep and then wait for OTBN to finish executing its app.
  // This function also sets the trigger for capturing traces.
  pentest_call_and_sleep(otbn_execute_delayed, kMlDsaDecomposeSleepCycles + 5500, true, true);
  // Clear the IMEM and DMEM of OTBN.
  CHECK_STATUS_OK(clear_otbn());

  // Write back last vector value to validate generated data.
  ml_dsa_sca_result_t uj_output;
  uj_output.result = result;
  RESP_OK(ujson_serialize_ml_dsa_sca_result_t, uj, &uj_output);

  return OK_STATUS();
}

status_t handle_ml_dsa_sca_vec_add_fvsr(ujson_t *uj) {
  ml_dsa_sca_fvsr_data_t uj_data;
  TRY(ujson_deserialize_ml_dsa_sca_fvsr_data_t(uj, &uj_data));

  // Select the variable we want to do the fvsr testing on.
  otbn_addr_t dmem_addr = (otbn_addr_t) uj_data.var_select ? kOtbnAppMlDsaVecAddB :
                                                             kOtbnAppMlDsaVecAddA;

  // Execute the FVSR routine.
  CHECK_STATUS_OK(handle_ml_dsa_sca_vec_fvsr(uj, kOtbnAppMlDsaVecAdd,
      uj_data, dmem_addr, kMlDsaVecAddSleepCycles));

  return OK_STATUS();
}

status_t handle_ml_dsa_sca_vec_sub_fvsr(ujson_t *uj) {
  ml_dsa_sca_fvsr_data_t uj_data;
  TRY(ujson_deserialize_ml_dsa_sca_fvsr_data_t(uj, &uj_data));

  // Select the variable we want to do the fvsr testing on.
  otbn_addr_t dmem_addr = (otbn_addr_t) uj_data.var_select ? kOtbnAppMlDsaVecSubB :
                                                             kOtbnAppMlDsaVecSubA;

  // Execute the FVSR routine.
  CHECK_STATUS_OK(handle_ml_dsa_sca_vec_fvsr(uj, kOtbnAppMlDsaVecSub,
      uj_data, dmem_addr, kMlDsaVecSubSleepCycles));

  return OK_STATUS();
}

status_t handle_ml_dsa_sca_vec_mul_fvsr(ujson_t *uj) {
  ml_dsa_sca_fvsr_data_t uj_data;
  TRY(ujson_deserialize_ml_dsa_sca_fvsr_data_t(uj, &uj_data));

  // Select the variable we want to do the fvsr testing on.
  otbn_addr_t dmem_addr = (otbn_addr_t) uj_data.var_select ? kOtbnAppMlDsaVecMulB :
                                                             kOtbnAppMlDsaVecMulA;

  // Execute the FVSR routine.
  CHECK_STATUS_OK(handle_ml_dsa_sca_vec_fvsr(uj, kOtbnAppMlDsaVecMul,
      uj_data, dmem_addr, kMlDsaVecMulSleepCycles));

  return OK_STATUS();
}

status_t handle_ml_dsa_sca_vec_mac_fvsr(ujson_t *uj) {
  ml_dsa_sca_fvsr_data_t uj_data;
  TRY(ujson_deserialize_ml_dsa_sca_fvsr_data_t(uj, &uj_data));

  // Select the variable we want to do the fvsr testing on.
  otbn_addr_t dmem_addr = (otbn_addr_t) uj_data.var_select ? kOtbnAppMlDsaVecMacB :
                                                             kOtbnAppMlDsaVecMacA;

  // Execute the FVSR routine.
  CHECK_STATUS_OK(handle_ml_dsa_sca_vec_fvsr(uj, kOtbnAppMlDsaVecMac,
      uj_data, dmem_addr, kMlDsaVecMacSleepCycles));

  return OK_STATUS();
}

status_t handle_ml_dsa_sca_ntt(ujson_t *uj) {
  ml_dsa_sca_data_t uj_data;
  uint32_t result;
  TRY(ujson_deserialize_ml_dsa_sca_data_t(uj, &uj_data));
  result = uj_data.data[kMlDsaVectorSize-1];

  // Load the application to OTBN.
  CHECK_STATUS_OK(otbn_load_app(kOtbnAppMlDsaNtt));
  // Mask data (masking can be disabled by setting the LFSR seed to 0).
  for (size_t j = 0; j < kMlDsaVectorSize; j++) {
    const uint32_t a = pentest_next_lfsr(32, kPentestLfsrMasking);
    uj_data.data[j] = (uj_data.data[j] + a) % kMlDsaModulus;
  }
  // Write the input vector to OTBN.
  CHECK_STATUS_OK(
      otbn_dmem_write(/*num_words=*/kMlDsaVectorSize, uj_data.data, kOtbnAppMlDsaNttW));
  // Put Ibex to sleep and then wait for OTBN to finish executing its app.
  // This function also sets the trigger for capturing traces.
  pentest_call_and_sleep(otbn_execute_delayed, kMlDsaNttSleepCycles, true, true);
  // Clear the IMEM and DMEM of OTBN.
  CHECK_STATUS_OK(clear_otbn());

  // Write back the last word of the input vector to validate the data transfer.
  ml_dsa_sca_result_t uj_output;
  uj_output.result = result;
  RESP_OK(ujson_serialize_ml_dsa_sca_result_t, uj, &uj_output);
  return OK_STATUS();
}

status_t handle_ml_dsa_sca_ntt_fvsr(ujson_t *uj) {
  ml_dsa_sca_fvsr_data_t uj_data;
  TRY(ujson_deserialize_ml_dsa_sca_fvsr_data_t(uj, &uj_data));

  // Execute the FVSR routine.
  CHECK_STATUS_OK(handle_ml_dsa_sca_vec_fvsr(uj, kOtbnAppMlDsaNtt,
      uj_data, kOtbnAppMlDsaNttW, kMlDsaNttSleepCycles));

  // Copy uj_data.data to our fixed input vector.
  uint32_t fixed_data[kMlDsaVectorSize];
  memcpy(fixed_data, uj_data.data, uj_data.data_length);

  return OK_STATUS();
}

status_t handle_ml_dsa_sca_intt(ujson_t *uj) {
  ml_dsa_sca_data_t uj_data;
  uint32_t result;
  TRY(ujson_deserialize_ml_dsa_sca_data_t(uj, &uj_data));
  result = uj_data.data[kMlDsaVectorSize-1];

  // Load the application to OTBN.
  CHECK_STATUS_OK(otbn_load_app(kOtbnAppMlDsaIntt));
  // Mask data (masking can be disabled by setting the LFSR seed to 0).
  for (size_t j = 0; j < kMlDsaVectorSize; j++) {
    const uint32_t a = pentest_next_lfsr(32, kPentestLfsrMasking);
    uj_data.data[j] = (uj_data.data[j] + a) % kMlDsaModulus;
  }
  // Write the input vector to OTBN.
  CHECK_STATUS_OK(
      otbn_dmem_write(/*num_words=*/kMlDsaVectorSize, uj_data.data, kOtbnAppMlDsaInttW));
  // Put Ibex to sleep and then wait for OTBN to finish executing its app.
  // This function also sets the trigger for capturing traces.
  pentest_call_and_sleep(otbn_execute_delayed, kMlDsaInttSleepCycles, true, true);
  // Clear the IMEM and DMEM of OTBN.
  CHECK_STATUS_OK(clear_otbn());

  // Write back the last word of the input vector to validate the data transfer.
  ml_dsa_sca_result_t uj_output;
  uj_output.result = result;
  RESP_OK(ujson_serialize_ml_dsa_sca_result_t, uj, &uj_output);
  return OK_STATUS();
}

status_t handle_ml_dsa_sca_intt_fvsr(ujson_t *uj) {
  ml_dsa_sca_fvsr_data_t uj_data;
  TRY(ujson_deserialize_ml_dsa_sca_fvsr_data_t(uj, &uj_data));

  // Execute the FVSR routine.
  CHECK_STATUS_OK(handle_ml_dsa_sca_vec_fvsr(uj, kOtbnAppMlDsaIntt,
      uj_data, kOtbnAppMlDsaInttW, kMlDsaInttSleepCycles));

  return OK_STATUS();
}

status_t handle_ml_dsa_sca(ujson_t *uj) {
  ml_dsa_sca_subcommand_t cmd;
  TRY(ujson_deserialize_ml_dsa_sca_subcommand_t(uj, &cmd));
  switch (cmd) {
    case kMlDsaScaSubcommandInit:
      return handle_ml_dsa_sca_init(uj);
    case kMlDsaScaSubcommandSeedLfsr:
      return handle_ml_dsa_seed_lfsr(uj);
    case kMlDsaScaSubcommandRejectFvsr:
      return handle_ml_dsa_sca_reject_fvsr(uj);
    case kMlDsaScaSubcommandDecomposeFvsr:
      return handle_ml_dsa_sca_decompose_fvsr(uj);
    case kMlDsaScaSubcommandVecAddFvsr:
      return handle_ml_dsa_sca_vec_add_fvsr(uj);
    case kMlDsaScaSubcommandVecSubFvsr:
      return handle_ml_dsa_sca_vec_sub_fvsr(uj);
    case kMlDsaScaSubcommandVecMulFvsr:
      return handle_ml_dsa_sca_vec_mul_fvsr(uj);
    case kMlDsaScaSubcommandVecMacFvsr:
      return handle_ml_dsa_sca_vec_mac_fvsr(uj);
    case kMlDsaScaSubcommandNtt:
      return handle_ml_dsa_sca_ntt(uj);
    case kMlDsaScaSubcommandNttFvsr:
      return handle_ml_dsa_sca_ntt_fvsr(uj);
    case kMlDsaScaSubcommandIntt:
      return handle_ml_dsa_sca_intt(uj);
    case kMlDsaScaSubcommandInttFvsr:
      return handle_ml_dsa_sca_intt_fvsr(uj);
    default:
      LOG_ERROR("Unrecognized ML-DSA SCA subcommand: %d", cmd);
      return INVALID_ARGUMENT();
  }
  return OK_STATUS();
}
