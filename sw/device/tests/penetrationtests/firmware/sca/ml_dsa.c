// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "sw/device/tests/penetrationtests/firmware/sca/otbn_sca.h"

#include "ml_dsa.h"
#include "sw/device/lib/arch/boot_stage.h"
#include "sw/device/lib/base/memory.h"
#include "sw/device/lib/base/status.h"
#include "sw/device/lib/dif/dif_otbn.h"
#include "sw/device/lib/runtime/log.h"
#include "sw/device/lib/testing/entropy_testutils.h"
#include "sw/device/lib/testing/test_framework/ottf_test_config.h"
#include "sw/device/lib/testing/test_framework/ujson_ottf.h"
#include "sw/device/lib/ujson/ujson.h"
#include "sw/device/sca/lib/prng.h"
#include "sw/device/sca/lib/sca.h"
#include "sw/device/tests/penetrationtests/firmware/lib/pentest_lib.h"
#include "sw/device/tests/penetrationtests/json/otbn_sca_commands.h"

#include "hw/top_earlgrey/sw/autogen/top_earlgrey.h"
#include "otbn_regs.h"  // Generated.

static dif_otbn_t otbn;

// Data structs for key sideloading test.
OTBN_DECLARE_APP_SYMBOLS(otbn_ml_dsa_reject_sca);
OTBN_DECLARE_SYMBOL_ADDR(otbn_ml_dsa_reject_sca, gamma_1_sub_beta);
OTBN_DECLARE_SYMBOL_ADDR(otbn_ml_dsa_reject_sca, gamma_2_sub_beta);
OTBN_DECLARE_SYMBOL_ADDR(otbn_ml_dsa_reject_sca, inp_vec_z);
OTBN_DECLARE_SYMBOL_ADDR(otbn_ml_dsa_reject_sca, inp_vec_r0);
OTBN_DECLARE_SYMBOL_ADDR(otbn_ml_dsa_reject_sca, result);
const otbn_app_t kOtbnAppMlDsaReject = OTBN_APP_T_INIT(otbn_ml_dsa_reject_sca);
static const otbn_addr_t kOtbnAppMlDsaRejectGamma1SubBeta =
    OTBN_ADDR_T_INIT(otbn_ml_dsa_reject_sca, gamma_1_sub_beta);
static const otbn_addr_t kOtbnAppMlDsaRejectGamma2SubBeta =
    OTBN_ADDR_T_INIT(otbn_ml_dsa_reject_sca, gamma_2_sub_beta);
static const otbn_addr_t kOtbnAppMlDsaRejectInpVecZ =
    OTBN_ADDR_T_INIT(otbn_ml_dsa_reject_sca, inp_vec_z);
static const otbn_addr_t kOtbnAppMlDsaRejectInpVecR0 =
    OTBN_ADDR_T_INIT(otbn_ml_dsa_reject_sca, inp_vec_r0);
static const otbn_addr_t kOtbnAppMlDsaRejectResult =
    OTBN_ADDR_T_INIT(otbn_ml_dsa_reject_sca, result);

status_t ml_dsa_otbn_init(void) {
  // Configure the entropy complex for OTBN. Set the reseed interval to max
  // to avoid a non-constant trigger window.
  TRY(pentest_configure_entropy_source_max_reseed_interval());

  sca_init(kScaTriggerSourceOtbn, kScaPeripheralEntropy | kScaPeripheralIoDiv4 |
                                      kScaPeripheralOtbn | kScaPeripheralCsrng |
                                      kScaPeripheralEdn | kScaPeripheralHmac |
                                      kScaPeripheralKmac);

  // Init the OTBN core.
  TRY(dif_otbn_init(mmio_region_from_addr(TOP_EARLGREY_OTBN_BASE_ADDR), &otbn));

  // Disable the instruction cache and dummy instructions for better SCA
  // measurements.
  pentest_configure_cpu();

  return OK_STATUS();
}

status_t ml_dsa_otbn_run_reject(void) {
  uint32_t result;

  otbn_load_app(kOtbnAppMlDsaReject);

  TRY(dif_otbn_set_ctrl_software_errs_fatal(&otbn, /*enable=*/false));

  sca_set_trigger_high();
  // Give the trigger time to rise.
  asm volatile(NOP30);
  otbn_execute();
  otbn_busy_wait_for_done();
  sca_set_trigger_low();
  asm volatile(NOP30);

  otbn_dmem_read(1, kOtbnAppMlDsaRejectResult, &result);

  // TODO: RETURN RESULT TO HOST??

  return OK_STATUS();
}

bool test_main(void) {
  CHECK_STATUS_OK(ml_dsa_otbn_init());
  return status_ok(ml_dsa_otbn_run_reject());
}
