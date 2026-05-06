// Copyright lowRISC contributors (OpenTitan project).
// Copyright IAIK.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <random>
#include <stdio.h>

#include "Vcircuit.h"
#include "testbench.h"

int main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);
  Testbench<Vcircuit> tb;
  tb.opentrace("tmp.vcd");

  // RNG Setup for high-quality entropy
  std::random_device rd;
  std::mt19937 gen(rd());
  std::uniform_int_distribution<uint32_t> dis(0, 0xFFFFFFFF);

  tb.reset();

  // Mask for the randomness
  const uint32_t WORD_MASK = 0x1;

  // Initialize the first cycle of randomness
  tb.m_core.rand_i = dis(gen) & WORD_MASK;

  // Drive Combined Shares (A and B)
  tb.m_core.share0_i = 0x1;
  tb.m_core.share1_i = 0x1;

  tb.tick();

  // Simulation Run
  for (int i = 0; i < 7; i++) {
    tb.tick();
  }

  tb.closetrace();
  return 0;
}
