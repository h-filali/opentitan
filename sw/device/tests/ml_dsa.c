// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "sw/device/lib/dif/dif_otbn.h"
#include "sw/device/lib/crypto/drivers/otbn.h"
#include "sw/device/lib/runtime/ibex.h"
#include "sw/device/lib/runtime/irq.h"
#include "sw/device/lib/runtime/log.h"
#include "sw/device/lib/testing/entropy_testutils.h"
#include "sw/device/lib/testing/profile.h"
#include "sw/device/lib/testing/rv_plic_testutils.h"
#include "sw/device/lib/testing/test_framework/check.h"
#include "sw/device/lib/testing/test_framework/ottf_main.h"

#include "hw/top_earlgrey/sw/autogen/top_earlgrey.h"

// Enum for constants and selecting sub-function
enum {
  kMlDsaDregSize = 1,
  kMlDsaWregSize = 8,
  kMlDsaVecSize = 256,
  kMlDsaReject,
  kMlDsaDecompose,
  kMlDsaVecAdd,
  kMlDsaVecSub,
  kMlDsaVecMul,
  kMlDsaVecMac,
  kMlDsaNtt,
  kMlDsaIntt,
};

// Reject
OTBN_DECLARE_APP_SYMBOLS(ml_dsa_reject);
OTBN_DECLARE_SYMBOL_ADDR(ml_dsa_reject, inp_vec_z);
OTBN_DECLARE_SYMBOL_ADDR(ml_dsa_reject, inp_vec_r0);
OTBN_DECLARE_SYMBOL_ADDR(ml_dsa_reject, result);
const otbn_app_t kOtbnAppMlDsaReject = OTBN_APP_T_INIT(ml_dsa_reject);
static const otbn_addr_t kOtbnAppMlDsaRejectInpVecZ =
    OTBN_ADDR_T_INIT(ml_dsa_reject, inp_vec_z);
static const otbn_addr_t kOtbnAppMlDsaRejectInpVecR0 =
    OTBN_ADDR_T_INIT(ml_dsa_reject, inp_vec_r0);
static const otbn_addr_t kOtbnAppMlDsaRejectResult =
    OTBN_ADDR_T_INIT(ml_dsa_reject, result);

// Decompose
OTBN_DECLARE_APP_SYMBOLS(ml_dsa_decompose);
OTBN_DECLARE_SYMBOL_ADDR(ml_dsa_decompose, decompose_r);
OTBN_DECLARE_SYMBOL_ADDR(ml_dsa_decompose, decompose_r0);
OTBN_DECLARE_SYMBOL_ADDR(ml_dsa_decompose, decompose_r1);
const otbn_app_t kOtbnAppMlDsaDecompose = OTBN_APP_T_INIT(ml_dsa_decompose);
static const otbn_addr_t kOtbnAppMlDsaDecomposeInpR =
    OTBN_ADDR_T_INIT(ml_dsa_decompose, decompose_r);
static const otbn_addr_t kOtbnAppMlDsaDecomposeOupR0 =
    OTBN_ADDR_T_INIT(ml_dsa_decompose, decompose_r0);
static const otbn_addr_t kOtbnAppMlDsaDecomposeOupR1 =
    OTBN_ADDR_T_INIT(ml_dsa_decompose, decompose_r1);

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
OTBN_DECLARE_SYMBOL_ADDR(ml_dsa_vec_mac, vec_mac_res);
const otbn_app_t kOtbnAppMlDsaVecMac = OTBN_APP_T_INIT(ml_dsa_vec_mac);
static const otbn_addr_t kOtbnAppMlDsaVecMacA =
    OTBN_ADDR_T_INIT(ml_dsa_vec_mac, vec_mac_a);
static const otbn_addr_t kOtbnAppMlDsaVecMacB =
    OTBN_ADDR_T_INIT(ml_dsa_vec_mac, vec_mac_b);
static const otbn_addr_t kOtbnAppMlDsaVecMacRes =
    OTBN_ADDR_T_INIT(ml_dsa_vec_mac, vec_mac_res);

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

OTTF_DEFINE_TEST_CONFIG();

/**
 * The plic dif to access the hardware.
 */
static dif_rv_plic_t plic;

/**
 * The otbn context handler.
 */
static dif_otbn_t otbn;

/**
 * The peripheral which fired the irq to be filled by the irq handler.
 */
static volatile top_earlgrey_plic_peripheral_t plic_peripheral;

/**
 * The irq id to be filled by the irq handler.
 */
static volatile dif_rv_plic_irq_id_t irq_id;

/**
 * The otbn irq to be filled by the irq handler.
 */
static volatile dif_otbn_irq_t irq;


static const uint32_t kMlDsaInpVecA[kMlDsaVecSize] = {
    0x0060FC78, 0x002D0230, 0x002A2114, 0x0025C490,
    0x0025D781, 0x0038F5B2, 0x00475320, 0x004907AA,
    0x00080853, 0x003D7E45, 0x0025C590, 0x0072939A,
    0x004807CC, 0x004A34C0, 0x00057204, 0x007006AF,
    0x003030BB, 0x006DAA68, 0x0075D2A9, 0x005AC31B,
    0x00595FC2, 0x002D0E84, 0x0057A4A4, 0x00471722,
    0x002CBA7B, 0x0013EB7E, 0x001B3277, 0x00533D4E,
    0x00695224, 0x006195DA, 0x004C799A, 0x002E253D,
    0x00015952, 0x000CD7CF, 0x00708758, 0x00285707,
    0x00783E7B, 0x005895F8, 0x0014D14B, 0x0038C0F5,
    0x00566EDC, 0x001027F6, 0x000C631F, 0x00081F8C,
    0x000EA60B, 0x0005ED5E, 0x0035B6B0, 0x005A2A27,
    0x006FEA32, 0x0024A266, 0x005BD287, 0x004ED1FD,
    0x006A1ED8, 0x006906A0, 0x0053133E, 0x0036AB36,
    0x005D0FDF, 0x001E6A3D, 0x00202D00, 0x0014B783,
    0x00356821, 0x005AA9C9, 0x0023B661, 0x00088AE9,
    0x004FC98E, 0x005B2841, 0x004869BA, 0x004BA979,
    0x000634DC, 0x000A10C8, 0x002D8532, 0x000A8611,
    0x00736E04, 0x00194D7C, 0x004FA9E0, 0x00139F4F,
    0x001A4980, 0x00236D28, 0x0053C904, 0x0077E267,
    0x0021D117, 0x0070210B, 0x0021FD42, 0x006388AC,
    0x003A435C, 0x005B3E04, 0x007D94D6, 0x00415584,
    0x00479C7C, 0x00273C82, 0x003A499F, 0x0046D934,
    0x001B043B, 0x0034644C, 0x005E9B3D, 0x007E524B,
    0x004006A1, 0x007D72BC, 0x00255C7B, 0x00774D10,
    0x0035B779, 0x002BEAD2, 0x006EA3D2, 0x0072D1B5,
    0x006B0AD5, 0x002490F9, 0x002C653A, 0x00400209,
    0x0050B408, 0x000147F8, 0x0020CD52, 0x0016F475,
    0x005268A3, 0x00567E8F, 0x003AAADA, 0x003A1B75,
    0x0034D477, 0x000E1CB3, 0x002D25D2, 0x001C40C9,
    0x00774F25, 0x006DE42A, 0x002B4340, 0x0047CC89,
    0x001724F5, 0x0018E549, 0x001AA9F2, 0x00421954,
    0x004777A5, 0x00372DAA, 0x007906B2, 0x00613D41,
    0x000C00EB, 0x00183FFE, 0x005C760A, 0x003F8190,
    0x004BF439, 0x0012AC2D, 0x007CA0E1, 0x0037D0E4,
    0x007A709D, 0x0071D97B, 0x0072DF19, 0x000013DC,
    0x002C16E1, 0x0028D750, 0x00574AB4, 0x000C533D,
    0x00016016, 0x005FC8F0, 0x0036A32E, 0x003F35F9,
    0x000BAAB7, 0x0026A92F, 0x007C6DB5, 0x0074FD65,
    0x006D55BA, 0x002BAF75, 0x001376D4, 0x000F12AA,
    0x0074430E, 0x007BAB9E, 0x007DD540, 0x007E2968,
    0x00555B81, 0x005D2512, 0x00577CCA, 0x001FF1F9,
    0x005ED915, 0x007A3581, 0x00254C08, 0x00738226,
    0x007291E4, 0x00551691, 0x005CC299, 0x006BB1AB,
    0x00220133, 0x005C57B8, 0x0020F375, 0x000BA294,
    0x00182FAE, 0x005CDA7A, 0x004DB334, 0x00559F0F,
    0x001FAF5B, 0x0042BE26, 0x007E9067, 0x006E5028,
    0x000A0E87, 0x0066A710, 0x006E29B7, 0x007A1905,
    0x000ED243, 0x00781DCC, 0x0068EFF1, 0x001990FA,
    0x006072D5, 0x0057554D, 0x001EC93E, 0x004B58AE,
    0x003EF5C4, 0x0028B8CC, 0x002F3631, 0x00595322,
    0x002E52AA, 0x007A6755, 0x00311980, 0x00050A4F,
    0x00328251, 0x00510941, 0x00160714, 0x006D359C,
    0x0013C262, 0x001AE8FD, 0x0026012D, 0x00249BF0,
    0x00242A57, 0x001AEF4E, 0x0002A575, 0x001448A4,
    0x007884BD, 0x00665BAA, 0x0020AAE0, 0x00372ACB,
    0x00300D08, 0x006B2E97, 0x005C8F82, 0x005F7E50,
    0x007FBE01, 0x005AC259, 0x0072CEE2, 0x0010D726,
    0x00138122, 0x00604FF0, 0x001A96C5, 0x003CB96D,
    0x0066A42F, 0x0048166B, 0x0067B4EA, 0x0056A296,
    0x00726E0E, 0x000A7921, 0x00614496, 0x000C8E00,
    0x0072F994, 0x003863F1, 0x003736EE, 0x001FFDEF,
    0x0033FC89, 0x002D6E48, 0x0059DD87, 0x002CC657,
    0x0053C105, 0x002D7B43, 0x00692453, 0x0051FD00,};

static const uint32_t kMlDsaInpVecB[kMlDsaVecSize] = {
    0x0029EE21, 0x007326BF, 0x0051D5D5, 0x00237D9B,
    0x00198397, 0x001A6000, 0x000E590E, 0x007A1FA6,
    0x001E80E8, 0x006CF1F2, 0x000E7950, 0x00722B01,
    0x00617DFB, 0x001F0688, 0x0003E062, 0x006722D3,
    0x0041388C, 0x0051DC5C, 0x0058D5DA, 0x0061AEAE,
    0x005FC75C, 0x0012A400, 0x0043049A, 0x002247FB,
    0x0004AC81, 0x0017F702, 0x006BE79C, 0x005C709E,
    0x006B6927, 0x00520D78, 0x003E1C98, 0x005BCA36,
    0x00574AB5, 0x000B4E02, 0x00444BD7, 0x00798282,
    0x0046984C, 0x000CDCB6, 0x0018CCFA, 0x00448025,
    0x0040BDEF, 0x00371D6B, 0x0024989D, 0x00757E7F,
    0x002ED8E9, 0x0066E4E4, 0x006E180C, 0x0047C76D,
    0x0060B1A8, 0x0003C631, 0x0064784B, 0x0040A401,
    0x0011B353, 0x0024503F, 0x004EA083, 0x0075BF3C,
    0x004CF5E1, 0x0031F7D2, 0x002017E8, 0x0064A5E0,
    0x00542EAE, 0x007797AD, 0x001A259E, 0x003C5534,
    0x00342AD0, 0x0064DE4F, 0x006876E9, 0x0005ECD3,
    0x0041C3F1, 0x0034239D, 0x004D0905, 0x00770075,
    0x00035EE4, 0x00767736, 0x000EC42F, 0x006B5700,
    0x00658D58, 0x00009F2C, 0x0066712E, 0x0051D3AA,
    0x00302A56, 0x005FE472, 0x002F2B6C, 0x0052AD49,
    0x0042D848, 0x00008730, 0x000D41DC, 0x006DD035,
    0x00424589, 0x00421D94, 0x00685396, 0x007A8646,
    0x000E35E7, 0x00067E3A, 0x000242BC, 0x0017AB42,
    0x00226F17, 0x0007109A, 0x00348A77, 0x00401BD6,
    0x007A44F7, 0x0012F8D7, 0x005ADCCB, 0x004F3A65,
    0x007E556F, 0x0046AB6E, 0x0049A869, 0x0064F8A3,
    0x001713E7, 0x00337D67, 0x006B9006, 0x006FBA81,
    0x001E7FF9, 0x00092A07, 0x0076543A, 0x0035B5E9,
    0x00244328, 0x004BB78F, 0x0068FBBD, 0x0017D22A,
    0x0005E36A, 0x00531AE9, 0x0066B876, 0x005ECA03,
    0x00692D71, 0x003888DA, 0x004C117A, 0x003BD769,
    0x00617A7E, 0x003CECCD, 0x00621263, 0x00313DC4,
    0x0004A77A, 0x00757939, 0x002B3684, 0x0012B272,
    0x001E2651, 0x006C4414, 0x0012E104, 0x00287072,
    0x00316DBE, 0x0021EECA, 0x0052C0E0, 0x0039F3FB,
    0x006073CB, 0x006BFF98, 0x0025E989, 0x00107E52,
    0x00266241, 0x0058BA3F, 0x0047DC0C, 0x0056F62C,
    0x001B6DFF, 0x007ED5C2, 0x00726932, 0x003F9CDD,
    0x002675ED, 0x007FC304, 0x001273BC, 0x00567813,
    0x00557281, 0x0027344D, 0x004216A7, 0x006F49A0,
    0x00349985, 0x00666B17, 0x0074B16D, 0x00272D0D,
    0x0024C2FC, 0x0042C0F3, 0x00562275, 0x000FE290,
    0x005DC5EC, 0x005D1924, 0x00324D5A, 0x004EE676,
    0x004DA2E8, 0x0034112E, 0x006AC5F6, 0x0024C1D9,
    0x004A941D, 0x0063B8E3, 0x00012B4C, 0x007D8815,
    0x0043C2C3, 0x0025914A, 0x00374DD3, 0x006CAAA7,
    0x00375ADD, 0x004CB811, 0x000D7962, 0x0012E6E9,
    0x0064C506, 0x005A7A25, 0x007F4939, 0x006097BD,
    0x005CA9BB, 0x003B5F70, 0x0002FB17, 0x005B4333,
    0x0060DC8E, 0x00456BFA, 0x00087530, 0x0076AB74,
    0x007F9613, 0x005E3D92, 0x00605FCF, 0x003E28DD,
    0x0019B858, 0x003A3481, 0x00429ACE, 0x004C40DA,
    0x000D54C9, 0x004C2C17, 0x00689324, 0x005EFD74,
    0x004D3030, 0x000463B9, 0x007ABAFC, 0x001E82D5,
    0x0024AA60, 0x00300BD3, 0x006250D6, 0x00467928,
    0x004409A8, 0x0016169A, 0x00318242, 0x00269444,
    0x00187038, 0x00424399, 0x004064B8, 0x005361DD,
    0x002EFBCE, 0x0052934E, 0x00139484, 0x00625DE5,
    0x00097A80, 0x00126217, 0x0044D387, 0x003F24CD,
    0x00609B8A, 0x0033C97C, 0x0071F8B5, 0x005CB2DD,
    0x00687217, 0x001E6A98, 0x0060A45E, 0x006BA1EC,
    0x002FAF6A, 0x00738515, 0x007E82A2, 0x001B2C1F,
    0x007AB449, 0x005B5687, 0x00032596, 0x0038FCC7,};

/**
 * Provides external IRQ handling for otbn tests.
 *
 * This function overrides the default OTTF external ISR.
 *
 * It performs the following:
 * 1. Claims the IRQ fired (finds PLIC IRQ index).
 * 2. Compute the OTBN peripheral.
 * 3. Compute the otbn irq.
 * 4. Clears the IRQ at the peripheral.
 * 5. Completes the IRQ service at PLIC.
 */
void ottf_external_isr(uint32_t *exc_info) {
  CHECK_DIF_OK(dif_rv_plic_irq_claim(&plic, kTopEarlgreyPlicTargetIbex0,
                                     (dif_rv_plic_irq_id_t *)&irq_id));

  plic_peripheral = (top_earlgrey_plic_peripheral_t)
      top_earlgrey_plic_interrupt_for_peripheral[irq_id];

  irq = (dif_otbn_irq_t)(irq_id -
                         (dif_rv_plic_irq_id_t)kTopEarlgreyPlicIrqIdOtbnDone);

  CHECK_DIF_OK(dif_otbn_irq_acknowledge(&otbn, irq));

  // Complete the IRQ by writing the IRQ source to the Ibex specific CC.
  // register.
  CHECK_DIF_OK(
      dif_rv_plic_irq_complete(&plic, kTopEarlgreyPlicTargetIbex0, irq_id));
}

static void otbn_wait_for_done_irq(dif_otbn_t *otbn) {
  // Clear the otbn irq variable: we'll set it in the interrupt handler when
  // we see the Done interrupt fire.
  irq = UINT32_MAX;
  irq_id = UINT32_MAX;
  plic_peripheral = UINT32_MAX;
  // Enable Done interrupt.
  CHECK_DIF_OK(
      dif_otbn_irq_set_enabled(otbn, kDifOtbnIrqDone, kDifToggleEnabled));

  // At this point, OTBN should be running. Wait for an interrupt that says
  // it's done.
  ATOMIC_WAIT_FOR_INTERRUPT(plic_peripheral != UINT32_MAX);

  CHECK(plic_peripheral == kTopEarlgreyPlicPeripheralOtbn,
        "Interrupt from incorrect peripheral: (exp: %d, obs: %s)",
        kTopEarlgreyPlicPeripheralOtbn, plic_peripheral);

  // Check this is the interrupt we expected.
  CHECK(irq_id == kTopEarlgreyPlicIrqIdOtbnDone);

  // Disable Done interrupt.
  CHECK_DIF_OK(
      dif_otbn_irq_set_enabled(otbn, kDifOtbnIrqDone, kDifToggleDisabled));

  // Acknowledge Done interrupt. This clears INTR_STATE.done back to 0.
  CHECK_DIF_OK(dif_otbn_irq_acknowledge(otbn, kDifOtbnIrqDone));
}

static void otbn_init_irq(void) {
  mmio_region_t plic_base_addr =
      mmio_region_from_addr(TOP_EARLGREY_RV_PLIC_BASE_ADDR);
  // Initialize PLIC and configure OTBN interrupt.
  CHECK_DIF_OK(dif_rv_plic_init(plic_base_addr, &plic));

  // Set interrupt priority to be positive.
  dif_rv_plic_irq_id_t irq_id = kTopEarlgreyPlicIrqIdOtbnDone;
  CHECK_DIF_OK(dif_rv_plic_irq_set_priority(&plic, irq_id, 0x1));

  CHECK_DIF_OK(dif_rv_plic_irq_set_enabled(
      &plic, irq_id, kTopEarlgreyPlicTargetIbex0, kDifToggleEnabled));

  // Set the threshold for Ibex to 0.
  CHECK_DIF_OK(dif_rv_plic_target_set_threshold(
      &plic, kTopEarlgreyPlicTargetIbex0, 0x0));

  // Enable the external IRQ (so that we see the interrupt from the PLIC).
  irq_global_ctrl(true);
  irq_external_ctrl(true);
}

static void ml_dsa_reject(void) {
  static const uint32_t kMlDsaRejectPassing[kMlDsaVecSize] = {
      0x00016883, 0x00018972, 0x000341C7, 0x0001E4F4,
      0x00027CE2, 0x0000F6B0, 0x00008C58, 0x00033409,
      0x000003E8, 0x0002881E, 0x0002CDA4, 0x0001DBAB,
      0x0000B322, 0x000255FF, 0x00008464, 0x00019CDA,
      0x0002D748, 0x00034838, 0x00030F89, 0x0003CFC3,
      0x00032119, 0x0003D890, 0x00037CD6, 0x0003C02B,
      0x00039FA9, 0x0000190E, 0x00019488, 0x000060F9,
      0x000052C5, 0x0000AB57, 0x00007FB9, 0x00035770,
      0x00001E8C, 0x00027E41, 0x0003BCB6, 0x00000F8B,
      0x00033697, 0x00014E17, 0x0003441E, 0x00001CAC,
      0x000368E9, 0x0001CFA3, 0x0002D56C, 0x000318FB,
      0x0001492F, 0x0001914D, 0x0003D3FB, 0x0003F76F,
      0x0003BD30, 0x0003200D, 0x00008DB8, 0x000146E5,
      0x00001ED8, 0x000123ED, 0x0001AAAB, 0x0001D3AF,
      0x00010CAE, 0x0003C26C, 0x0001DFDD, 0x00004B99,
      0x0000EC2D, 0x0001F356, 0x00021DD0, 0x00031CD3,
      0x00037A4E, 0x0003F4F0, 0x0001F650, 0x0003309F,
      0x00006B0C, 0x0003680F, 0x00031B80, 0x00003C7E,
      0x00036D13, 0x0001FB79, 0x0003596D, 0x00017132,
      0x0003995A, 0x0003C1CC, 0x000382A2, 0x0003DC44,
      0x000254B7, 0x0002094A, 0x0003F910, 0x00029374,
      0x0001A707, 0x0000EC1D, 0x0003692F, 0x0001EA67,
      0x0000296A, 0x00036884, 0x0000AF4E, 0x0002C528,
      0x00015A10, 0x0002ED6D, 0x00034C52, 0x00014359,
      0x000214F9, 0x00001957, 0x00027B9E, 0x0001E902,
      0x0001BE77, 0x00030F28, 0x000312F5, 0x000186B7,
      0x0003F4F0, 0x0001BCE0, 0x0003317B, 0x000218EA,
      0x0002F213, 0x00008CCD, 0x0001D617, 0x00010D35,
      0x0002190B, 0x0001D088, 0x0000BAD4, 0x0002A646,
      0x00038DE5, 0x00007A17, 0x0003EF16, 0x0003A7D3,
      0x00017CE9, 0x0002219D, 0x00030787, 0x000193AD,
      0x0001CAA9, 0x0001E4B9, 0x00025304, 0x0000A32E,
      0x000084CA, 0x000256B1, 0x00017A9C, 0x00019CF0,
      0x00010E97, 0x0003F1F4, 0x0000B51E, 0x00036F61,
      0x0003D37C, 0x0002964C, 0x000393F3, 0x0000F0EA,
      0x0002A721, 0x0003A04C, 0x0002257F, 0x000109FF,
      0x0002A63E, 0x00026698, 0x0001EE28, 0x0002C4E2,
      0x00020A92, 0x0002454C, 0x0002F5DA, 0x00004146,
      0x0003E865, 0x00030C5D, 0x000036C0, 0x0000E4A2,
      0x00003058, 0x000242E7, 0x0002FCEF, 0x0003BE05,
      0x0001AE1E, 0x00021DE7, 0x000354DC, 0x0002CC80,
      0x000211D0, 0x00011F3E, 0x00021EE3, 0x000073F6,
      0x00028316, 0x0003CAEF, 0x0000EE2C, 0x0000747E,
      0x0001D9E4, 0x0002442F, 0x0000D660, 0x0000A3CB,
      0x0002814D, 0x00034472, 0x00039C9D, 0x0001A8D3,
      0x00021913, 0x0002BB11, 0x000160D1, 0x0003F690,
      0x00016E14, 0x000300B9, 0x00012441, 0x00019E33,
      0x00032CF2, 0x0003DABA, 0x0001C371, 0x0002FA47,
      0x0003C397, 0x00014F78, 0x0002C3C0, 0x00037C89,
      0x00035D6B, 0x0000F4A7, 0x0000B16C, 0x0001DF8A,
      0x00014B88, 0x000223D7, 0x00018DE9, 0x0003445B,
      0x000301AD, 0x0001B3CA, 0x00037A2A, 0x00006140,
      0x00019D13, 0x0003134E, 0x000349F8, 0x00028581,
      0x00037434, 0x00035A0E, 0x0003C373, 0x000352C9,
      0x0000F0AC, 0x00017789, 0x00014783, 0x0000D6F3,
      0x00004194, 0x0000EC3B, 0x0001DE72, 0x00001115,
      0x0000B31F, 0x0001D96A, 0x0000F6B5, 0x00002CB1,
      0x00028C0A, 0x0003C0B9, 0x00029DB7, 0x00027347,
      0x00039A36, 0x00015BDF, 0x0003EF85, 0x0000A05E,
      0x000073DA, 0x0003F087, 0x00027018, 0x00020AD6,
      0x00026762, 0x000236E5, 0x00028D8D, 0x0001D097,
      0x000379C8, 0x00003776, 0x00004FAC, 0x00000F2D,
      0x00039ACE, 0x0002E341, 0x0002D8BC, 0x00011F44,
      0x0000F41E, 0x0000C811, 0x0000D64C, 0x0003DE2C,};

  static const uint32_t kMlDsaRejectFailing[kMlDsaVecSize] = {
      0x0078A0FF, 0x004C2B27, 0x0031DDB6, 0x006B6139,
      0x000D4B13, 0x007790D1, 0x0010DCD4, 0x000F5DD2,
      0x005FF7E2, 0x00245E0B, 0x007BF1C8, 0x000225AC,
      0x0061C332, 0x000D98F3, 0x00488B9D, 0x00462C85,
      0x0067FD5E, 0x001E207B, 0x005EB930, 0x0043F5A8,
      0x00196B2D, 0x0049B0DE, 0x0006F238, 0x0043A67A,
      0x0022AA41, 0x0067CFBA, 0x00057796, 0x0021071E,
      0x003207CD, 0x00375555, 0x00651F14, 0x002BBC15,
      0x00417C6A, 0x00467852, 0x004B6B3B, 0x004D37E8,
      0x0025CFEF, 0x0059D398, 0x00509560, 0x000AB50E,
      0x0001677B, 0x00164003, 0x00662512, 0x002DFA9D,
      0x000EC13B, 0x0061B25F, 0x00716FDA, 0x00311456,
      0x00107D91, 0x0057FEEF, 0x0033770C, 0x00304AE9,
      0x000FE48B, 0x006378BE, 0x0072CC59, 0x0049AF9A,
      0x0047883D, 0x0045FF6F, 0x00046FA6, 0x00633314,
      0x00491420, 0x00767563, 0x0061FD3E, 0x0014E8D5,
      0x001B5A28, 0x001F638B, 0x001EC86A, 0x00397970,
      0x000CB882, 0x003C0174, 0x002D65B9, 0x006E5176,
      0x00488D60, 0x006C64F6, 0x007FDBD6, 0x0025FF4A,
      0x00284D6A, 0x0052AD16, 0x00519107, 0x0057529E,
      0x005A6036, 0x006AE873, 0x002E1FD1, 0x003B596E,
      0x00102084, 0x00589EC4, 0x004CFDE4, 0x00438288,
      0x006A5ED9, 0x0053BB01, 0x007EC096, 0x00525BFB,
      0x004918B1, 0x00691B39, 0x00261D6C, 0x0054B93C,
      0x005D6B91, 0x002760C1, 0x00700276, 0x0018F787,
      0x0003DDF3, 0x00705BC2, 0x003116AB, 0x0025B8B9,
      0x00579255, 0x0032DFCA, 0x00271D74, 0x0020A8B4,
      0x0026A6F2, 0x0063B09C, 0x007E39BC, 0x000210A1,
      0x00515620, 0x00374B26, 0x000CEB72, 0x000C17B4,
      0x003180B5, 0x005A82F7, 0x006A1EC1, 0x0079997D,
      0x006F7F2D, 0x00281A83, 0x001817FF, 0x003F673C,
      0x00079E51, 0x00280216, 0x003FEAD9, 0x0001E3A2,
      0x00116B30, 0x004E94EC, 0x006147AC, 0x0018A2D5,
      0x002D5B62, 0x006F0518, 0x000C0FB1, 0x0005A497,
      0x000592E0, 0x007B5A0A, 0x007A21D1, 0x001F877A,
      0x0010FE99, 0x007BDDD2, 0x0025E759, 0x006EB9A9,
      0x0026699C, 0x00535334, 0x0028E93E, 0x004B3197,
      0x003FAECA, 0x005133FA, 0x00280BBF, 0x003CCFC6,
      0x001081C8, 0x0053B395, 0x00170443, 0x002F7A80,
      0x0028D559, 0x003A49FA, 0x00437AB2, 0x003BD37A,
      0x006967F0, 0x005D55FD, 0x00002129, 0x001E9A87,
      0x004FD292, 0x000BA24E, 0x002B6C1B, 0x004C032A,
      0x006AD50D, 0x005EEA11, 0x0068A377, 0x0077B503,
      0x0073008D, 0x002BB8F2, 0x002619AD, 0x004E5533,
      0x002BE0A6, 0x006E6862, 0x0036668F, 0x0044FDB2,
      0x007D14F2, 0x002F7241, 0x000DFF35, 0x000BBAF6,
      0x0075D5AD, 0x007D874E, 0x00360A40, 0x00559B03,
      0x00663404, 0x006C8BED, 0x003545EF, 0x005B1EC8,
      0x00710EBA, 0x006A3E98, 0x0024FE97, 0x00691B06,
      0x001C8376, 0x002619B3, 0x001B9310, 0x00453370,
      0x002D77E0, 0x005D92A6, 0x004B0B8F, 0x003EBA8B,
      0x0018C99D, 0x005FD08B, 0x00392C31, 0x006210C9,
      0x005C3E2F, 0x005B75DD, 0x0034B366, 0x0026697E,
      0x00609FD8, 0x0039F442, 0x0079952C, 0x001F1318,
      0x00107B80, 0x0012C81B, 0x00644500, 0x004005F8,
      0x00361911, 0x00479796, 0x007F598C, 0x00785689,
      0x003D58D6, 0x007068D2, 0x007328A7, 0x00464B42,
      0x006429D0, 0x000621DF, 0x0057B213, 0x004A1035,
      0x002100E2, 0x00267C87, 0x001BBE21, 0x00409EA2,
      0x00291C21, 0x00794455, 0x0018EC05, 0x0002D839,
      0x005F3830, 0x00332D97, 0x006FAAE8, 0x00536FDF,
      0x00112A4E, 0x000C619A, 0x0008C6B4, 0x00269C5D,
      0x002C3B6A, 0x0027B5DE, 0x000A144E, 0x006A8AD3,
      0x004041D7, 0x00000393, 0x001457E3, 0x0003FE88,};

  bool fail = false;
  uint32_t response = 0;
  uint32_t response_exp;

  // Initialize
  CHECK_DIF_OK(
      dif_otbn_init(mmio_region_from_addr(TOP_EARLGREY_OTBN_BASE_ADDR), &otbn));
  otbn_init_irq();
  CHECK_STATUS_OK(otbn_load_app(kOtbnAppMlDsaReject));

  LOG_INFO("Rejection Loop sampling");

  // Write input arguments.
  if (fail) {
    response_exp = 0;
    CHECK_STATUS_OK(
      otbn_dmem_write(/*num_words=*/kMlDsaVecSize, kMlDsaRejectFailing, kOtbnAppMlDsaRejectInpVecZ));
    CHECK_STATUS_OK(
      otbn_dmem_write(/*num_words=*/kMlDsaVecSize, kMlDsaRejectFailing, kOtbnAppMlDsaRejectInpVecR0));

  } else {
    response_exp = 1;
    CHECK_STATUS_OK(
      otbn_dmem_write(/*num_words=*/kMlDsaVecSize, kMlDsaRejectPassing, kOtbnAppMlDsaRejectInpVecZ));
    CHECK_STATUS_OK(
      otbn_dmem_write(/*num_words=*/kMlDsaVecSize, kMlDsaRejectPassing, kOtbnAppMlDsaRejectInpVecR0));
  }

  // Call OTBN to perform operation, and wait for it to complete.
  uint64_t start_cycles = ibex_mcycle_read();
  CHECK_STATUS_OK(otbn_execute());
  otbn_busy_wait_for_done();
  uint64_t end_cycles = ibex_mcycle_read();
  CHECK(end_cycles - start_cycles <= UINT32_MAX);
  uint32_t cycles = (uint32_t)(end_cycles - start_cycles);
  LOG_INFO("took %u cycles", cycles);

  // Read back results.
  CHECK_STATUS_OK(
      otbn_dmem_read(/*num_words=*/kMlDsaDregSize, kOtbnAppMlDsaRejectResult, &response));

  CHECK(response == response_exp);

}

static void ml_dsa_decompose(void) {

  static const uint32_t decompose_r[kMlDsaWregSize] = {
      0x006141C6, 0x00000000, 0x00000000, 0x00000000,
      0x00000000, 0x00000000, 0x00000000, 0x00000000,};

  static const uint32_t decompose_r0_exp[kMlDsaWregSize] = {
      0x000159C6, 0x00000000, 0x00000000, 0x00000000,
      0x00000000, 0x00000000, 0x00000000, 0x00000000,};

  static const uint32_t decompose_r1_exp[kMlDsaWregSize] = {
      0x0000000C, 0x00000000, 0x00000000, 0x00000000,
      0x00000000, 0x00000000, 0x00000000, 0x00000000,};

  uint32_t decompose_r0_act[kMlDsaWregSize] = {
      0x00000000, 0x00000000, 0x00000000, 0x00000000,
      0x00000000, 0x00000000, 0x00000000, 0x00000000,};

  uint32_t decompose_r1_act[kMlDsaWregSize] = {
      0x00000000, 0x00000000, 0x00000000, 0x00000000,
      0x00000000, 0x00000000, 0x00000000, 0x00000000,};

  // Initialize
  CHECK_DIF_OK(
      dif_otbn_init(mmio_region_from_addr(TOP_EARLGREY_OTBN_BASE_ADDR), &otbn));
  otbn_init_irq();
  CHECK_STATUS_OK(otbn_load_app(kOtbnAppMlDsaDecompose));

  LOG_INFO("Decompose");

  // Write input arguments.
  CHECK_STATUS_OK(
    otbn_dmem_write(/*num_words=*/kMlDsaWregSize, decompose_r, kOtbnAppMlDsaDecomposeInpR));

  // Call OTBN to perform operation, and wait for it to complete.
  uint64_t start_cycles = ibex_mcycle_read();
  CHECK_STATUS_OK(otbn_execute());
  otbn_busy_wait_for_done();
  uint64_t end_cycles = ibex_mcycle_read();
  CHECK(end_cycles - start_cycles <= UINT32_MAX);
  uint32_t cycles = (uint32_t)(end_cycles - start_cycles);
  LOG_INFO("took %u cycles", cycles);

  // Read back results.
  CHECK_STATUS_OK(
      otbn_dmem_read(/*num_words=*/kMlDsaWregSize, kOtbnAppMlDsaDecomposeOupR0, decompose_r0_act));
  CHECK_STATUS_OK(
      otbn_dmem_read(/*num_words=*/kMlDsaWregSize, kOtbnAppMlDsaDecomposeOupR1, decompose_r1_act));

  CHECK_ARRAYS_EQ(decompose_r0_act, decompose_r0_exp, kMlDsaWregSize);
  CHECK_ARRAYS_EQ(decompose_r1_act, decompose_r1_exp, kMlDsaWregSize);

}

static void ml_dsa_vec_add(void) {
  static const uint32_t kOupVecExp[kMlDsaVecSize] = {
      0x000B0A98, 0x002048EE, 0x007BF6E9, 0x0049422B,
      0x003F5B18, 0x005355B2, 0x0055AC2E, 0x0043474F,
      0x0026893B, 0x002A9036, 0x00343EE0, 0x0064DE9A,
      0x0029A5C6, 0x00693B48, 0x00095266, 0x00574981,
      0x00716947, 0x003FA6C3, 0x004EC882, 0x003C91C8,
      0x0039471D, 0x003FB284, 0x001AC93D, 0x00695F1D,
      0x003166FC, 0x002BE280, 0x00073A12, 0x002FCDEB,
      0x0054DB4A, 0x0033C351, 0x000AB631, 0x000A0F72,
      0x0058A407, 0x001825D1, 0x0034F32E, 0x0021F988,
      0x003EF6C6, 0x006572AE, 0x002D9E45, 0x007D411A,
      0x00174CCA, 0x00474561, 0x0030FBBC, 0x007D9E0B,
      0x003D7EF4, 0x006CD242, 0x0023EEBB, 0x00221193,
      0x0050BBD9, 0x00286897, 0x00406AD1, 0x000F95FD,
      0x007BD22B, 0x000D76DE, 0x0021D3C0, 0x002C8A71,
      0x002A25BF, 0x0050620F, 0x004044E8, 0x00795D63,
      0x0009B6CE, 0x00526175, 0x003DDBFF, 0x0044E01D,
      0x0004145D, 0x0040268F, 0x003100A2, 0x0051964C,
      0x0047F8CD, 0x003E3465, 0x007A8E37, 0x0001A685,
      0x0076CCE8, 0x000FE4B1, 0x005E6E0F, 0x007EF64F,
      0x007FD6D8, 0x00240C54, 0x003A5A31, 0x0049D610,
      0x0051FB6D, 0x0050257C, 0x005128AE, 0x003655F4,
      0x007D1BA4, 0x005BC534, 0x000AF6B1, 0x002F45B8,
      0x000A0204, 0x00695A16, 0x0022BD34, 0x00417F79,
      0x00293A22, 0x003AE286, 0x0060DDF9, 0x00161D8C,
      0x006275B8, 0x0004A355, 0x0059E6F2, 0x003788E5,
      0x00301C6F, 0x003EE3A9, 0x0049A09C, 0x00422C19,
      0x00698043, 0x006B3C67, 0x00760DA3, 0x00251AAB,
      0x0067C7EF, 0x0034C55F, 0x000C7D57, 0x0006CEF5,
      0x0070E89C, 0x005FA896, 0x00311F13, 0x006FD15E,
      0x0059179F, 0x0059D442, 0x0016418E, 0x003412F3,
      0x007D328F, 0x00411F12, 0x00121BB5, 0x0026B68B,
      0x00007265, 0x00516E23, 0x0066BB6C, 0x007DF0BD,
      0x00291222, 0x00741A77, 0x005B3914, 0x00129B04,
      0x0010A865, 0x000DD936, 0x0007CC8D, 0x00523402,
      0x006A1A8A, 0x007EF041, 0x000FA1E4, 0x00604156,
      0x002BFE5A, 0x0013E844, 0x0045BFF8, 0x003A07D7,
      0x000CAAAB, 0x0014F6E7, 0x007D343D, 0x001CD18F,
      0x0027C257, 0x0038A32E, 0x007E7F3A, 0x00164C24,
      0x002718B6, 0x00259EF0, 0x006EF6E6, 0x0034BA41,
      0x0013EBA6, 0x002B9278, 0x0025EA90, 0x00658ABD,
      0x0049D58E, 0x0022FFEA, 0x00400BE6, 0x006D9307,
      0x000A1505, 0x0043B028, 0x004C4E36, 0x00471F06,
      0x0003BC10, 0x003D1673, 0x007B6E7D, 0x000384B5,
      0x005077CF, 0x00324FB4, 0x000F2FF2, 0x003AB820,
      0x006FA41B, 0x001088E5, 0x000BD96A, 0x0030646D,
      0x0062C3CB, 0x0040B35C, 0x004EDE80, 0x00534723,
      0x0063721E, 0x00684F70, 0x0035FE39, 0x005B1ACE,
      0x00416964, 0x00337F20, 0x007BA319, 0x000D1FED,
      0x00739749, 0x0052B7F0, 0x00685929, 0x007A28B7,
      0x003D3C8F, 0x0012D4BC, 0x0021C455, 0x0026BBE0,
      0x001FF251, 0x006E24C6, 0x0037AB61, 0x00501E95,
      0x002E08BC, 0x0058C4E6, 0x0011994E, 0x0043332C,
      0x004C3AA9, 0x000B5DC1, 0x0058A1E2, 0x00399675,
      0x0021172B, 0x00671514, 0x000EB450, 0x0003B963,
      0x00715A87, 0x001F5307, 0x007D6071, 0x0032CB79,
      0x001D4F1C, 0x0016877C, 0x00031BB5, 0x007DA3F3,
      0x007416B0, 0x00016530, 0x000E31C3, 0x00063293,
      0x00184E38, 0x001D25F1, 0x00335399, 0x00643903,
      0x00427CF0, 0x0033033D, 0x002E2B49, 0x001F3751,
      0x00701EAF, 0x005A7882, 0x002CA870, 0x0015E762,
      0x00532997, 0x003E429D, 0x00535D4A, 0x006940DD,
      0x005B8BAA, 0x0056CE89, 0x0017FB4B, 0x000BBFDA,
      0x0063ABF3, 0x0021135C, 0x00588028, 0x0047F276,
      0x004E954D, 0x0008F1C9, 0x006C49E9, 0x000B19C6,};

  uint32_t kOupVecAct[kMlDsaVecSize] = {0};

  // Initialize
  CHECK_DIF_OK(
      dif_otbn_init(mmio_region_from_addr(TOP_EARLGREY_OTBN_BASE_ADDR), &otbn));
  otbn_init_irq();
  CHECK_STATUS_OK(otbn_load_app(kOtbnAppMlDsaVecAdd));

  LOG_INFO("Vector Addition");

  // Write input arguments.
  CHECK_STATUS_OK(
    otbn_dmem_write(/*num_words=*/kMlDsaVecSize, kMlDsaInpVecA, kOtbnAppMlDsaVecAddA));
  CHECK_STATUS_OK(
    otbn_dmem_write(/*num_words=*/kMlDsaVecSize, kMlDsaInpVecB, kOtbnAppMlDsaVecAddB));

  // Call OTBN to perform operation, and wait for it to complete.
  uint64_t start_cycles = ibex_mcycle_read();
  CHECK_STATUS_OK(otbn_execute());
  otbn_busy_wait_for_done();
  uint64_t end_cycles = ibex_mcycle_read();
  CHECK(end_cycles - start_cycles <= UINT32_MAX);
  uint32_t cycles = (uint32_t)(end_cycles - start_cycles);
  LOG_INFO("took %u cycles", cycles);

  // Read back results.
  CHECK_STATUS_OK(
      otbn_dmem_read(/*num_words=*/kMlDsaVecSize, kOtbnAppMlDsaVecAddA, kOupVecAct));

  CHECK_ARRAYS_EQ(kOupVecAct, kOupVecExp, kMlDsaVecSize);

}

static void ml_dsa_vec_sub(void) {
  static const uint32_t kOupVecExp[kMlDsaVecSize] = {
      0x00370E57, 0x0039BB72, 0x00582B40, 0x000246F5,
      0x000C53EA, 0x001E95B2, 0x0038FA12, 0x004EC805,
      0x0069676C, 0x00506C54, 0x00174C40, 0x00006899,
      0x006669D2, 0x002B2E38, 0x000191A2, 0x0008E3DC,
      0x006ED830, 0x001BCE0C, 0x001CFCCF, 0x0078F46E,
      0x00797867, 0x001A6A84, 0x0014A00A, 0x0024CF27,
      0x00280DFA, 0x007BD47D, 0x002F2ADC, 0x0076ACB1,
      0x007DC8FE, 0x000F8862, 0x000E5D02, 0x00523B08,
      0x0029EE9E, 0x000189CD, 0x002C3B81, 0x002EB486,
      0x0031A62F, 0x004BB942, 0x007BE452, 0x007420D1,
      0x0015B0ED, 0x0058EA8C, 0x0067AA83, 0x0012810E,
      0x005FAD23, 0x001EE87B, 0x00477EA5, 0x001262BA,
      0x000F388A, 0x0020DC35, 0x00773A3D, 0x000E2DFC,
      0x00586B85, 0x0044B661, 0x000472BB, 0x0040CBFB,
      0x001019FE, 0x006C526C, 0x00001518, 0x002FF1A4,
      0x00611974, 0x0062F21D, 0x000990C3, 0x004C15B6,
      0x001B9EBE, 0x007629F3, 0x005FD2D2, 0x0045BCA6,
      0x004450EC, 0x0055CD2C, 0x00605C2E, 0x0013659D,
      0x00700F20, 0x0022B647, 0x0040E5B1, 0x00282850,
      0x00349C29, 0x0022CDFC, 0x006D37D7, 0x00260EBD,
      0x007186C2, 0x00103C99, 0x0072B1D7, 0x0010DB63,
      0x00774B15, 0x005AB6D4, 0x007052FA, 0x00536550,
      0x000556F3, 0x0064FEEF, 0x0051D60A, 0x004C32EF,
      0x000CCE54, 0x002DE612, 0x005C5881, 0x0066A709,
      0x001D978A, 0x00766222, 0x0070B205, 0x0037313A,
      0x003B5283, 0x0018F1FB, 0x0013C707, 0x00239750,
      0x006C9567, 0x005DC58C, 0x00629CD2, 0x005AE967,
      0x0039A021, 0x004DAA92, 0x00351D4D, 0x002719F5,
      0x0033E8AA, 0x004D5488, 0x004436A1, 0x0004658C,
      0x0010914F, 0x00424525, 0x00440A16, 0x00046E9F,
      0x00716BBB, 0x001AC941, 0x00446ACB, 0x0068E287,
      0x002DD785, 0x00603C70, 0x004E7879, 0x000641EB,
      0x0065DD28, 0x007A20DE, 0x0016F44F, 0x002FFF7D,
      0x00075971, 0x0022A6C6, 0x00313F86, 0x002CCF1E,
      0x002DCDE8, 0x0026481A, 0x0069BFDD, 0x000F6072,
      0x004902DF, 0x004FEAB1, 0x00201E39, 0x0045FFE2,
      0x004B8317, 0x003CB7B9, 0x0031612B, 0x007BB4EC,
      0x005ADDD6, 0x00070EB1, 0x006EA723, 0x00681FCE,
      0x00701CB9, 0x0027B36E, 0x000A0483, 0x00356088,
      0x0046DFCD, 0x002BCC72, 0x00010318, 0x00387A98,
      0x001ED08D, 0x00547751, 0x003BBE99, 0x000EDFC8,
      0x0020C1FC, 0x007699FC, 0x0062AB5E, 0x0078A4ED,
      0x003A1619, 0x0037748E, 0x004F0994, 0x00639F96,
      0x0014CBF8, 0x0077DD6E, 0x002A753F, 0x001CCB35,
      0x00543E4C, 0x0028468A, 0x00360D80, 0x0066C0BC,
      0x004D7B92, 0x00790198, 0x004C87E8, 0x0057F6FB,
      0x005BCC99, 0x001D2CDC, 0x00474294, 0x0001A581,
      0x005293AB, 0x0019EEFF, 0x0060B055, 0x0067321C,
      0x0029ED3E, 0x001DA3A7, 0x006986B9, 0x0038D93E,
      0x0003C91A, 0x001BF5DD, 0x001BCE27, 0x006FF57C,
      0x005DF937, 0x00632CD3, 0x0026C101, 0x006287AF,
      0x002E9C98, 0x001C29C3, 0x005099B2, 0x0046C173,
      0x0018C9F9, 0x0016D4C0, 0x00534C47, 0x0020F4C2,
      0x00066D99, 0x004E9CE7, 0x003D4E0A, 0x00457E7D,
      0x0056DA28, 0x00168B95, 0x0007CA7A, 0x0075A5D0,
      0x0053DA5D, 0x00364FD7, 0x003E3A0B, 0x007091A4,
      0x006BE361, 0x005517FD, 0x002B0D40, 0x0038EA0C,
      0x00674DC9, 0x00187EC0, 0x00326A2A, 0x003D554A,
      0x00646555, 0x000DBCA2, 0x00070241, 0x005A3B89,
      0x005D29AF, 0x0035B454, 0x0022E163, 0x00177DC9,
      0x0011D284, 0x00568FA6, 0x006F2BE2, 0x002FBB24,
      0x000A877D, 0x0019F959, 0x00567291, 0x00343C04,
      0x00044D1F, 0x0039C934, 0x005B3AE6, 0x00119A38,
      0x0058ECBD, 0x005204BD, 0x0065FEBD, 0x00190039,};

  uint32_t kOupVecAct[kMlDsaVecSize] = {0};

  // Initialize
  CHECK_DIF_OK(
      dif_otbn_init(mmio_region_from_addr(TOP_EARLGREY_OTBN_BASE_ADDR), &otbn));
  otbn_init_irq();
  CHECK_STATUS_OK(otbn_load_app(kOtbnAppMlDsaVecSub));

  LOG_INFO("Vector Subtraction");

  // Write input arguments.
  CHECK_STATUS_OK(
    otbn_dmem_write(/*num_words=*/kMlDsaVecSize, kMlDsaInpVecA, kOtbnAppMlDsaVecSubA));
  CHECK_STATUS_OK(
    otbn_dmem_write(/*num_words=*/kMlDsaVecSize, kMlDsaInpVecB, kOtbnAppMlDsaVecSubB));

  // Call OTBN to perform operation, and wait for it to complete.
  uint64_t start_cycles = ibex_mcycle_read();
  CHECK_STATUS_OK(otbn_execute());
  otbn_busy_wait_for_done();
  uint64_t end_cycles = ibex_mcycle_read();
  CHECK(end_cycles - start_cycles <= UINT32_MAX);
  uint32_t cycles = (uint32_t)(end_cycles - start_cycles);
  LOG_INFO("took %u cycles", cycles);

  // Read back results.
  CHECK_STATUS_OK(
      otbn_dmem_read(/*num_words=*/kMlDsaVecSize, kOtbnAppMlDsaVecSubA, kOupVecAct));

  CHECK_ARRAYS_EQ(kOupVecAct, kOupVecExp, kMlDsaVecSize);

}

static void ml_dsa_vec_mul(void) {
  static const uint32_t kOupVecExp[kMlDsaVecSize] = {
      0x00782E39, 0x00463A18, 0x000DD397, 0x006B77C3,
      0x0046B336, 0x001D0070, 0x001B8B09, 0x00602F71,
      0x0079A0B4, 0x0063AE5C, 0x0059A687, 0x005BC615,
      0x0054367D, 0x007864F1, 0x002D3B46, 0x001585CC,
      0x006B9A17, 0x00022932, 0x002686C7, 0x0064014F,
      0x006946B8, 0x003B1E97, 0x00638BD9, 0x006B4D74,
      0x000F7977, 0x0022AD4C, 0x00266E62, 0x0008A9CD,
      0x00595030, 0x002D1245, 0x0004862B, 0x0020BD37,
      0x001A2F40, 0x00139EF6, 0x007F5950, 0x0075AA94,
      0x0065B2B0, 0x0013F547, 0x0052DDA8, 0x00019C7C,
      0x003208C5, 0x006E7B33, 0x003CA67B, 0x005A57BA,
      0x001DCA2D, 0x003C7AC7, 0x006B719B, 0x0056E719,
      0x004DC2AF, 0x006864BA, 0x002370C0, 0x006B2E0C,
      0x00505798, 0x0031EE37, 0x004FE40F, 0x006133E7,
      0x003D5BCF, 0x0065DE84, 0x001494B9, 0x004CF356,
      0x0046ABD5, 0x0053A15C, 0x0064E781, 0x006D4C86,
      0x003302AC, 0x001DA251, 0x00776E55, 0x0021393F,
      0x0018A5F8, 0x00680804, 0x0006EFCA, 0x00107AA5,
      0x001988A7, 0x0006EB4D, 0x0045BD26, 0x002C6060,
      0x007783C3, 0x00656EC8, 0x007F23AD, 0x005786B6,
      0x000626F3, 0x00528D3D, 0x00276430, 0x00623AA9,
      0x006B5D16, 0x005DFC4B, 0x0026B8EC, 0x00619936,
      0x006EAD7F, 0x00242BD2, 0x0026A266, 0x005E99E9,
      0x000AE7A6, 0x00227830, 0x007D4EA2, 0x00636EB2,
      0x002589D4, 0x0008B6D1, 0x005F315B, 0x000CEBF3,
      0x001BAD18, 0x001C0257, 0x003FA1D7, 0x00567AD2,
      0x00000AD0, 0x003828B0, 0x00650242, 0x005D392D,
      0x00699AAF, 0x001168B9, 0x005B587C, 0x00238282,
      0x00117BB7, 0x007CB911, 0x005593B7, 0x006ECE71,
      0x00703C61, 0x003321D9, 0x002DE141, 0x003C3FA2,
      0x001615E2, 0x00646353, 0x00381EE1, 0x006E86C9,
      0x004997DB, 0x0024C67C, 0x005672D2, 0x007380D0,
      0x0055AA89, 0x0047BF14, 0x00440920, 0x000E5109,
      0x00782D27, 0x0005E687, 0x007C9A51, 0x0016E90D,
      0x00733396, 0x0002985C, 0x0061BE35, 0x00243ECF,
      0x002D599C, 0x00031F0B, 0x00609F48, 0x000943B4,
      0x00275610, 0x004B2957, 0x00494D01, 0x0017F893,
      0x001B47E7, 0x00127CEF, 0x00721A0B, 0x0047F039,
      0x002E96A0, 0x0021F7EE, 0x0070B68F, 0x005D598F,
      0x002E3CCC, 0x0065D747, 0x0071F0AE, 0x00172164,
      0x0048B61B, 0x00444C3A, 0x0037F445, 0x00501D15,
      0x0023E6B2, 0x00020080, 0x000A15B1, 0x003A853B,
      0x00439652, 0x001BDDB2, 0x00289041, 0x0033A816,
      0x0067CE09, 0x006D42CD, 0x00081199, 0x0073D40C,
      0x007AB710, 0x005301A3, 0x0047D7FB, 0x0040CB46,
      0x006E43A3, 0x006940FC, 0x0019B994, 0x0030B6DD,
      0x000BFE1F, 0x005CC15D, 0x00400337, 0x00775BF6,
      0x0015A613, 0x002D81DC, 0x00163B73, 0x006C7743,
      0x0006CE92, 0x000CA9AB, 0x00763175, 0x000BEEB4,
      0x00055AB1, 0x0005981E, 0x000606DB, 0x001DCE9F,
      0x000871FD, 0x00575FBA, 0x000FEECC, 0x007A9C67,
      0x0003C6BC, 0x0073DA2B, 0x00291D60, 0x007C8AFD,
      0x007D3B1D, 0x0020DB1A, 0x003D40F0, 0x00638768,
      0x002EB79A, 0x0075E31F, 0x003B0CEB, 0x007146F3,
      0x005EABC6, 0x004F4CAD, 0x0057B6F9, 0x0055C17D,
      0x00151A7D, 0x003585AD, 0x00133984, 0x00233B80,
      0x00224450, 0x00545D47, 0x003DED6E, 0x0010FDF0,
      0x00489680, 0x005B0A4C, 0x00228A35, 0x003A46AD,
      0x003534CB, 0x0013F988, 0x00426F55, 0x007FA152,
      0x002581D3, 0x002A1CA1, 0x006B93F5, 0x0070627F,
      0x0021BA59, 0x0076172E, 0x003CDCD8, 0x00459C1F,
      0x0051EB90, 0x0045375C, 0x005DC8DD, 0x002A99DB,
      0x0015F4E9, 0x0006C955, 0x0075D56E, 0x001B34E3,
      0x006BF067, 0x0024E5D6, 0x001D9143, 0x005A8145,};

  uint32_t kOupVecAct[kMlDsaVecSize] = {0};

  // Initialize
  CHECK_DIF_OK(
      dif_otbn_init(mmio_region_from_addr(TOP_EARLGREY_OTBN_BASE_ADDR), &otbn));
  otbn_init_irq();
  CHECK_STATUS_OK(otbn_load_app(kOtbnAppMlDsaVecMul));

  LOG_INFO("Vector Coefficient-Wise Multiplication");

  // Write input arguments.
  CHECK_STATUS_OK(
    otbn_dmem_write(/*num_words=*/kMlDsaVecSize, kMlDsaInpVecA, kOtbnAppMlDsaVecMulA));
  CHECK_STATUS_OK(
    otbn_dmem_write(/*num_words=*/kMlDsaVecSize, kMlDsaInpVecB, kOtbnAppMlDsaVecMulB));

  // Call OTBN to perform operation, and wait for it to complete.
  uint64_t start_cycles = ibex_mcycle_read();
  CHECK_STATUS_OK(otbn_execute());
  otbn_busy_wait_for_done();
  uint64_t end_cycles = ibex_mcycle_read();
  CHECK(end_cycles - start_cycles <= UINT32_MAX);
  uint32_t cycles = (uint32_t)(end_cycles - start_cycles);
  LOG_INFO("took %u cycles", cycles);

  // Read back results.
  CHECK_STATUS_OK(
      otbn_dmem_read(/*num_words=*/kMlDsaVecSize, kOtbnAppMlDsaVecMulA, kOupVecAct));

  CHECK_ARRAYS_EQ(kOupVecAct, kOupVecExp, kMlDsaVecSize);

}

static void ml_dsa_vec_mac(void) {
  static const uint32_t kOupVecExp[kMlDsaWregSize] = {
      0x0046F033, 0x00000000, 0x00000000, 0x00000000,
      0x00000000, 0x00000000, 0x00000000, 0x00000000,};

  uint32_t kOupVecAct[kMlDsaWregSize] = {0};

  // Initialize
  CHECK_DIF_OK(
      dif_otbn_init(mmio_region_from_addr(TOP_EARLGREY_OTBN_BASE_ADDR), &otbn));
  otbn_init_irq();
  CHECK_STATUS_OK(otbn_load_app(kOtbnAppMlDsaVecMac));

  LOG_INFO("Vector Multiply and Accumulate");

  // Write input arguments.
  CHECK_STATUS_OK(
    otbn_dmem_write(/*num_words=*/kMlDsaVecSize, kMlDsaInpVecA, kOtbnAppMlDsaVecMacA));
  CHECK_STATUS_OK(
    otbn_dmem_write(/*num_words=*/kMlDsaVecSize, kMlDsaInpVecB, kOtbnAppMlDsaVecMacB));

  // Call OTBN to perform operation, and wait for it to complete.
  uint64_t start_cycles = ibex_mcycle_read();
  CHECK_STATUS_OK(otbn_execute());
  otbn_busy_wait_for_done();
  uint64_t end_cycles = ibex_mcycle_read();
  CHECK(end_cycles - start_cycles <= UINT32_MAX);
  uint32_t cycles = (uint32_t)(end_cycles - start_cycles);
  LOG_INFO("took %u cycles", cycles);

  // Read back results.
  CHECK_STATUS_OK(
      otbn_dmem_read(/*num_words=*/kMlDsaWregSize, kOtbnAppMlDsaVecMacRes, kOupVecAct));

  CHECK_ARRAYS_EQ(kOupVecAct, kOupVecExp, kMlDsaWregSize);

}

static void ml_dsa_ntt(void) {
  static const uint32_t kOupVecExp[kMlDsaVecSize] = {
      0x00765D33, 0x00543658, 0x002D3D65, 0x0043DFED,
      0x00468B4A, 0x0079764B, 0x00292230, 0x002984B3,
      0x003CEE5C, 0x0035142F, 0x004564D5, 0x006D9E12,
      0x00405B4C, 0x0007B381, 0x00627C0C, 0x005C7F41,
      0x004FAFCD, 0x000453E4, 0x0055B502, 0x004C3A94,
      0x00409541, 0x00687538, 0x0005623E, 0x0041924B,
      0x002BBF24, 0x000311F8, 0x000D0358, 0x00589759,
      0x0001BFE8, 0x002BAA4A, 0x007F3DF3, 0x0029EEBF,
      0x005B9DED, 0x001C0C32, 0x006CCC70, 0x00023A4F,
      0x005F5853, 0x0015ED71, 0x0018E35D, 0x003F75C2,
      0x004B5640, 0x000653C0, 0x0067096C, 0x003E66A3,
      0x00191443, 0x007EDC27, 0x000B275B, 0x001B7505,
      0x007734E4, 0x007C2306, 0x0034820B, 0x003E8738,
      0x0013564C, 0x00489BE8, 0x0028EA39, 0x005187AA,
      0x004099A7, 0x0075F948, 0x007E750B, 0x0077A38C,
      0x0027AE0A, 0x00250CC3, 0x00362542, 0x000EF842,
      0x001FA7D7, 0x0038366D, 0x000521E5, 0x0063B05B,
      0x0061EE2B, 0x00767720, 0x00588C48, 0x0076356B,
      0x000D1649, 0x00671925, 0x0008D3DB, 0x00786D2C,
      0x004CA5D5, 0x003B0366, 0x0007293D, 0x007BBBDC,
      0x0011F1B2, 0x00403C30, 0x003C1284, 0x00198A0C,
      0x006870CA, 0x0005C101, 0x004A1C32, 0x004F3B9B,
      0x00656B93, 0x007EBDAD, 0x004EAC01, 0x00218CB4,
      0x000CB8BC, 0x0035EF80, 0x005B4FC4, 0x005B562E,
      0x003E2A17, 0x0041892F, 0x00242F13, 0x004AAE10,
      0x007B7AC9, 0x003DCABA, 0x00563609, 0x003C2903,
      0x00235B32, 0x001E0028, 0x00631B1E, 0x002341F6,
      0x00105A7E, 0x00113689, 0x0025EC39, 0x00147372,
      0x0026C8C0, 0x0005B84D, 0x00094136, 0x0053C42C,
      0x002F2310, 0x0018EF41, 0x0001EDCE, 0x004DE1AA,
      0x004E2608, 0x002B24F7, 0x0032ACFE, 0x00055E64,
      0x0020CB2F, 0x003CEE0E, 0x005B58A1, 0x0055DDC4,
      0x0028FAE2, 0x007BB6F8, 0x002F91DC, 0x00140CDF,
      0x002427EA, 0x007AB26E, 0x0019B679, 0x0020F271,
      0x006A3B4F, 0x00121AB4, 0x006F283F, 0x0067ABCC,
      0x006949CB, 0x0015521A, 0x004CE49A, 0x000EEDA6,
      0x0034BAC3, 0x003F46B3, 0x000044A0, 0x0073DF82,
      0x00742195, 0x006EC134, 0x0053E2D3, 0x001DF365,
      0x005CB0EF, 0x000175E5, 0x0075468F, 0x005525AF,
      0x004DF40E, 0x0043CC6A, 0x0074330D, 0x0050ABC1,
      0x005CED2F, 0x007F2AB1, 0x0043499E, 0x0023E8A0,
      0x00322717, 0x00499729, 0x004BC836, 0x001A2363,
      0x00290BA5, 0x005AF332, 0x0048D99B, 0x003CACE7,
      0x001FA81D, 0x00191473, 0x001618E4, 0x00143F4B,
      0x0027F4C9, 0x004D1C6C, 0x0043F44A, 0x00583D92,
      0x00526A65, 0x000955AC, 0x000FC119, 0x003303EB,
      0x0014C9C3, 0x004DE39D, 0x006C9F50, 0x0023C1F2,
      0x00616950, 0x00289BF1, 0x00283AD4, 0x001E80A5,
      0x00004D9D, 0x002D440F, 0x0078C5B0, 0x005FB899,
      0x007C8FB0, 0x0063B6B0, 0x00458DFF, 0x007F8B83,
      0x00017A98, 0x0066C9C1, 0x0074A680, 0x00386A2A,
      0x0021A0DD, 0x00443D4C, 0x006FD9B2, 0x000D736F,
      0x00508B8A, 0x00286E0E, 0x002234BB, 0x0052F9B5,
      0x0024E07E, 0x000A8C3D, 0x00748534, 0x000AEA44,
      0x00014406, 0x00328861, 0x0073C60A, 0x0034E56C,
      0x00491CA1, 0x002B9623, 0x00462625, 0x0047ACF5,
      0x007128C0, 0x0017F2F5, 0x002FF9C5, 0x002404E2,
      0x0060C662, 0x00789D8F, 0x003AC947, 0x002726F2,
      0x003783EF, 0x0022AC74, 0x00086E7D, 0x00670D70,
      0x003F663F, 0x005E80D8, 0x000F5F7F, 0x005E8650,
      0x0051A4DA, 0x0071AE4B, 0x0027FCE3, 0x006385D2,
      0x00617B8F, 0x0055766F, 0x00598A5D, 0x000B68D5,
      0x002A9CA9, 0x00529AF9, 0x006B7C92, 0x00197770,
      0x0048110B, 0x003F74A7, 0x005C69CD, 0x0020C0D1,};

  uint32_t kOupVecAct[kMlDsaVecSize] = {0};

  // Initialize
  CHECK_DIF_OK(
      dif_otbn_init(mmio_region_from_addr(TOP_EARLGREY_OTBN_BASE_ADDR), &otbn));
  otbn_init_irq();
  CHECK_STATUS_OK(otbn_load_app(kOtbnAppMlDsaNtt));

  LOG_INFO("Vector Number Theretic Transform");

  // Write input arguments.
  CHECK_STATUS_OK(
        otbn_dmem_write(/*num_words=*/kMlDsaVecSize, kMlDsaInpVecA, kOtbnAppMlDsaNttW));

  // Call OTBN to perform operation, and wait for it to complete.
  uint64_t start_cycles = ibex_mcycle_read();
  CHECK_STATUS_OK(otbn_execute());
  otbn_busy_wait_for_done();
  uint64_t end_cycles = ibex_mcycle_read();
  CHECK(end_cycles - start_cycles <= UINT32_MAX);
  uint32_t cycles = (uint32_t)(end_cycles - start_cycles);
  LOG_INFO("took %u cycles", cycles);

  // Read back results.
  CHECK_STATUS_OK(
      otbn_dmem_read(/*num_words=*/kMlDsaVecSize, kOtbnAppMlDsaNttW, kOupVecAct));

  CHECK_ARRAYS_EQ(kOupVecAct, kOupVecExp, kMlDsaVecSize);

}

static void ml_dsa_intt(void) {
  static const uint32_t kOupVecExp[kMlDsaVecSize] = {
      0x0029EDD7, 0x004BA08A, 0x00777D16, 0x0013E86D,
      0x00372F90, 0x003FA613, 0x0037BC64, 0x002F2B97,
      0x000A4A93, 0x00676856, 0x00300062, 0x001E8D5B,
      0x006707FC, 0x002E0CA5, 0x004CD145, 0x00387890,
      0x00675771, 0x00391D5F, 0x00581AF7, 0x0009A230,
      0x0069CB1A, 0x0066F8DA, 0x0033E923, 0x00697A9D,
      0x001C6682, 0x0047C847, 0x0046C864, 0x0009D310,
      0x007A0C7C, 0x00544ADB, 0x002E971E, 0x005135FA,
      0x00173C19, 0x0065AC5D, 0x0011775E, 0x004E862F,
      0x0006ECFD, 0x00017DFE, 0x0057AC80, 0x0002749E,
      0x0042227E, 0x007FC3B7, 0x0043590E, 0x007D60EF,
      0x0035F94D, 0x004081D0, 0x0022159F, 0x004FB1F0,
      0x003DEB0F, 0x00619366, 0x00367E64, 0x0000474C,
      0x0079F05B, 0x0078AD21, 0x00352606, 0x0046ADBD,
      0x003C2127, 0x0076B893, 0x000AD436, 0x00785236,
      0x00031B0D, 0x001E19EC, 0x00362054, 0x0062A99A,
      0x001E4E19, 0x0044DCF8, 0x0005D103, 0x002FF28E,
      0x00138225, 0x0009B38D, 0x003165BF, 0x001C0429,
      0x001D9D9F, 0x002FB4A0, 0x001CCD17, 0x0050AAED,
      0x0061D1E7, 0x0070287A, 0x004EE39B, 0x006273C0,
      0x005E3A32, 0x006331E7, 0x003196B0, 0x00583A19,
      0x00615141, 0x0046BA6D, 0x007A3915, 0x003A26EB,
      0x0012BB8F, 0x0072DF22, 0x000D7A31, 0x0035AB9C,
      0x007AD724, 0x001B188A, 0x0013329C, 0x0018DD20,
      0x0056326C, 0x007156F0, 0x00206706, 0x006F30F6,
      0x0061C278, 0x003C6F2A, 0x0006945B, 0x000B6BF8,
      0x0006D923, 0x0002E637, 0x0042D358, 0x00059D0B,
      0x00121035, 0x0045F68D, 0x005F960F, 0x007580B7,
      0x001F4111, 0x000A5C77, 0x00113465, 0x0019F389,
      0x00191DE1, 0x000E2064, 0x007426FC, 0x0043AF12,
      0x004C5274, 0x003CC41C, 0x0077B481, 0x0063FC68,
      0x0049EF1E, 0x002FFED9, 0x0028141A, 0x001C44D6,
      0x003B3B14, 0x0037992A, 0x0009BC82, 0x003DF6B8,
      0x006DB82A, 0x001E29C0, 0x0051C986, 0x0053D9BE,
      0x0021C6BF, 0x00486753, 0x002B2482, 0x00112C08,
      0x007D2A4E, 0x005ADB4B, 0x0002386D, 0x00334C2D,
      0x001899F7, 0x00770B0E, 0x007569D0, 0x00526EF2,
      0x001B6E9D, 0x000AC250, 0x0011352A, 0x0026D906,
      0x0021BD2A, 0x007CD70A, 0x001867CD, 0x0049E611,
      0x005DD779, 0x00228F1C, 0x00586162, 0x00693A66,
      0x00693F6C, 0x00368A37, 0x005F5844, 0x004325FA,
      0x00379593, 0x004C4296, 0x00412D74, 0x00422DB8,
      0x002D77E3, 0x002D3FCB, 0x003BF795, 0x0047B614,
      0x005B0A32, 0x0052D6E0, 0x0056212D, 0x004D490A,
      0x00323169, 0x00536AE6, 0x000560B3, 0x0043E8B2,
      0x0063B37F, 0x00712CD3, 0x0059BD70, 0x002004A4,
      0x000F006C, 0x00633880, 0x00074ACE, 0x002AB9BB,
      0x00228810, 0x00049909, 0x00130973, 0x0038FA13,
      0x0062F374, 0x00383256, 0x00360C27, 0x004940EB,
      0x0012C3FF, 0x003B6AC3, 0x0037B21B, 0x002FB301,
      0x0034058F, 0x00400F2E, 0x0034549B, 0x00430B77,
      0x0022CAC9, 0x0032DE4F, 0x0079DFC1, 0x000C464D,
      0x00425B53, 0x00493356, 0x00490271, 0x005BDE16,
      0x0018CF6C, 0x001111AE, 0x00275A3B, 0x0021AD32,
      0x005309CB, 0x001D0502, 0x005B0B57, 0x00089B7A,
      0x0043BA0A, 0x00257D1C, 0x0058831E, 0x003A261E,
      0x00614E8E, 0x005EE609, 0x00547E9F, 0x00402C26,
      0x00790EC6, 0x00072C73, 0x00543FED, 0x006B72CF,
      0x00357F1C, 0x00733C99, 0x00655926, 0x0042BD3E,
      0x0029E8AC, 0x001A3529, 0x0079F5B3, 0x001B3ECA,
      0x000A8ADF, 0x001327ED, 0x005EF991, 0x0079F9A8,
      0x002D5225, 0x000161AE, 0x000595CE, 0x007097C1,
      0x0058A7BF, 0x0062F6E2, 0x0020D4CE, 0x0011600D,
      0x0002CC4F, 0x00339689, 0x00344903, 0x000B6D9D,};

  uint32_t kOupVecAct[kMlDsaVecSize] = {0};

  // Initialize
  CHECK_DIF_OK(
      dif_otbn_init(mmio_region_from_addr(TOP_EARLGREY_OTBN_BASE_ADDR), &otbn));
  otbn_init_irq();
  CHECK_STATUS_OK(otbn_load_app(kOtbnAppMlDsaIntt));

  LOG_INFO("Vector Inverse Number Theretic Transform");

  // Write input arguments.
  CHECK_STATUS_OK(
        otbn_dmem_write(/*num_words=*/kMlDsaVecSize, kMlDsaInpVecA, kOtbnAppMlDsaInttW));

  // Call OTBN to perform operation, and wait for it to complete.
  uint64_t start_cycles = ibex_mcycle_read();
  CHECK_STATUS_OK(otbn_execute());
  otbn_busy_wait_for_done();
  uint64_t end_cycles = ibex_mcycle_read();
  CHECK(end_cycles - start_cycles <= UINT32_MAX);
  uint32_t cycles = (uint32_t)(end_cycles - start_cycles);
  LOG_INFO("took %u cycles", cycles);

  // Read back results.
  CHECK_STATUS_OK(
      otbn_dmem_read(/*num_words=*/kMlDsaVecSize, kOtbnAppMlDsaInttW, kOupVecAct));

  CHECK_ARRAYS_EQ(kOupVecAct, kOupVecExp, kMlDsaVecSize);

}

bool test_main(void) {
  CHECK_STATUS_OK(entropy_testutils_auto_mode_init());

  switch (kMlDsaNtt) {
    case kMlDsaReject: ml_dsa_reject();
            break;
    case kMlDsaDecompose: ml_dsa_decompose();
            break;
    case kMlDsaVecAdd: ml_dsa_vec_add();
            break;
    case kMlDsaVecSub: ml_dsa_vec_sub();
            break;
    case kMlDsaVecMul: ml_dsa_vec_mul();
            break;
    case kMlDsaVecMac: ml_dsa_vec_mac();
            break;
    case kMlDsaNtt: ml_dsa_ntt();
            break;
    case kMlDsaIntt: ml_dsa_intt();
            break;
    default: ml_dsa_reject();
  }

  return true;
}
