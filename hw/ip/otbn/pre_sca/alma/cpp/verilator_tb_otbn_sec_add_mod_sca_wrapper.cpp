// Copyright lowRISC contributors (OpenTitan project).
// Copyright IAIK.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <random>
#include <stdio.h>

#include "Vcircuit.h"
#include "testbench.h"

// Port widths derived from wrapper parameters (Width=32, VecSize=8, Stages=5):
//   RandWidth  = 2*(5*32+1) = 322 bits -> 11 x 32-bit words (rand_i)
//     [321:0]  = randomness for the secure adder
//   DoubleWidth = 2*32 = 64 bits -> 2 x 32-bit words (masks_i)
//     [31:0]   = mask0, [63:32] = mask1  (arithmetic masks for A2B/B2A)
//   FlatShareWidth = 8 * 64 = 512 bits -> 16 x 32-bit words
//     share{0,1}_i[2k]   = a_share[k]   (bits [31:0]  of element k)
//     share{0,1}_i[2k+1] = b_share[k]   (bits [63:32] of element k)
static constexpr int RAND_WORDS = 11;
static constexpr uint32_t RAND_LAST_MASK =
    (1u << 2) - 1;                      // 322 mod 32 = 2 active bits
static constexpr int SHARE_WORDS = 16;  // 512 / 32

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

  // Refresh the SEC_ADD randomness port with fresh entropy
  auto refresh_rand = [&]() {
    for (int w = 0; w < RAND_WORDS - 1; w++)
      tb.m_core.rand_i[w] = dis(gen);
    tb.m_core.rand_i[RAND_WORDS - 1] = dis(gen) & RAND_LAST_MASK;
  };

  tb.reset();

  // --- Static configuration ---
  tb.m_core.q_i = 8380417;  // ML-DSA-87 modulus
  tb.m_core.mask_op_i = MASK_OP_SEC_ADD;
  tb.m_core.wvalid_i = 0;
  // Arithmetic masks: static values < q, used only for A2B/B2A (not SEC_ADD)
  // masks_i[31:0] = mask0, masks_i[63:32] = mask1
  tb.m_core.masks_i = 1234567ull | (2345678ull << 32);

  // Build boolean-shared input vectors: share0 = val ^ mask, share1 = mask
  // Invariant: share0_i[k] XOR share1_i[k] = secret[k] for each element k.
  for (int k = 0; k < 8 /*VecSize*/; k++) {
    uint32_t a_val = dis(gen), b_val = dis(gen);
    uint32_t a_mask = dis(gen), b_mask = dis(gen);
    tb.m_core.share0_i[2 * k] = a_val ^ a_mask;      // a_share0[k]
    tb.m_core.share0_i[2 * k + 1] = b_val ^ b_mask;  // b_share0[k]
    tb.m_core.share1_i[2 * k] = a_mask;              // a_share1[k]
    tb.m_core.share1_i[2 * k + 1] = b_mask;          // b_share1[k]
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
