// Copyright lowRISC contributors (OpenTitan project).
// Copyright IAIK.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <random>
#include <stdio.h>

#include "Vcircuit.h"
#include "testbench.h"

// Port widths derived from wrapper parameters (Width=32, VecSize=8, Stages=5):
//   TotalRandWidth = RandWidth + DoubleWidth = 322 + 64 = 386 bits -> 13 x
//   32-bit words (rand_i)
//     [321:0]   = randomness for the secure adder  (words 0-10; word[10] uses
//     only bits[1:0]) [353:322] = mask0 (arithmetic mask share 0, for A2B/B2A)
//     [385:354] = mask1 (arithmetic mask share 1, for A2B/B2A)
//   FlatShareWidth = 8 * 64 = 512 bits -> 16 x 32-bit words
//     share{0,1}_i[2k]   = a_share[k]   (bits [31:0]  of element k)
//     share{0,1}_i[2k+1] = b_share[k]   (bits [63:32] of element k)
static constexpr int TOTAL_WORDS = 13;           // ceil(386/32)
static constexpr int SHARE_WORDS = 16;           // 512 / 32
static constexpr uint64_t MAX_VAL = 1ULL << 32;  // 2^32
// static constexpr uint64_t MODULUS        = 8380417;         // ML-DSA-87
// modulus
static constexpr uint64_t MODULUS = MAX_VAL;  // Modulus 2^32 (no reduction)

// Pipeline depth: VecSize=8 dispatch cycles + Latency=6 pipeline stages +
// margin
static constexpr int NUM_CYCLES = 30;

// Valid state_mask_op_e encodings (otbn_pkg.sv)
static constexpr uint8_t MASK_OP_SEC_ADD = 0x10;      // 5'b10000
static constexpr uint8_t MASK_OP_SEC_ADD_MOD = 0x07;  // 5'b00111
static constexpr uint8_t MASK_OP_ARITH2BOOL = 0x1B;   // 5'b11011
static constexpr uint8_t MASK_OP_BOOL2ARITH = 0x0C;   // 5'b01100

int main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);
  Testbench<Vcircuit> tb;
  tb.opentrace("tmp.vcd");

  std::random_device rd;
  std::mt19937 gen(rd());
  std::uniform_int_distribution<uint32_t> dis(0, 0xFFFFFFFFu);

  // Refresh all rand_i words each cycle.
  // mask0 must be < q_i in B2A mode (hardware stalls otherwise); mask1 is
  // unconstrained. Mask bits straddle word boundaries (start at bit 322):
  //   rand_i[10][31:2] = mask0[29:0],  rand_i[10][1:0] = adder rand
  //   rand_i[11]       = {mask1[29:0], mask0[31:30]}
  //   rand_i[12][1:0]  = mask1[31:30]
  auto refresh_rand = [&]() {
    for (int w = 0; w < 10; w++)
      tb.m_core.rand_i[w] = dis(gen);

    uint32_t mask0;
    if (tb.m_core.mask_op_i == MASK_OP_BOOL2ARITH) {
      mask0 = dis(gen) % MODULUS;
    } else {
      mask0 = dis(gen);
    }
    uint32_t mask1 = dis(gen);

    tb.m_core.rand_i[10] = (dis(gen) & 0x3u) | ((mask0 & 0x3FFFFFFFu) << 2);
    tb.m_core.rand_i[11] = (mask0 >> 30) | ((mask1 & 0x3FFFFFFFu) << 2);
    tb.m_core.rand_i[12] = mask1 >> 30;
  };

  tb.reset();

  // --- Static configuration ---
  tb.m_core.q_i = MODULUS % MAX_VAL;
  tb.m_core.mask_op_i = MASK_OP_ARITH2BOOL;
  tb.m_core.wvalid_i = 0;

  // Build boolean-shared input vectors: share0 = val ^ mask, share1 = mask
  // Invariant: share0_i[k] XOR share1_i[k] = secret[k] for each element k.
  for (int k = 0; k < 8 /*VecSize*/; k++) {
    uint32_t a_val = dis(gen), b_val = dis(gen);
    uint32_t a_mask = dis(gen), b_mask = dis(gen);

    if (tb.m_core.mask_op_i == MASK_OP_ARITH2BOOL) {
      tb.m_core.share0_i[2 * k] = a_val - a_mask;      // a_share0[k]
      tb.m_core.share0_i[2 * k + 1] = b_val - b_mask;  // b_share0[k]
    } else {
      tb.m_core.share0_i[2 * k] = a_val ^ a_mask;      // a_share0[k]
      tb.m_core.share0_i[2 * k + 1] = b_val ^ b_mask;  // b_share0[k]
    }

    tb.m_core.share1_i[2 * k] = a_mask;      // a_share1[k]
    tb.m_core.share1_i[2 * k + 1] = b_mask;  // b_share1[k]
  }

  refresh_rand();
  tb.tick();

  // Wait for wready_o before presenting the share vector (immediate after
  // reset)
  while (!tb.m_core.wready_o) {
    refresh_rand();
    tb.tick();
  }

  // Assert wvalid for exactly one cycle to latch the share vector into the
  // wrapper
  tb.m_core.wvalid_i = 1;
  refresh_rand();
  tb.tick();
  tb.m_core.wvalid_i = 0;

  // Run enough cycles for the wrapper to dispatch all 8 elements through
  // the pipeline (8 dispatch cycles + Latency=6 + margin = NUM_CYCLES)
  for (int i = 0; i < NUM_CYCLES; i++) {
    refresh_rand();
    tb.tick();
  }

  tb.closetrace();
  return 0;
}
