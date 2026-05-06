// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

module otbn_sec_add_sca_test_wrapper #(
  parameter  int Width       = 1,
  localparam int NumShares   = 2,
  localparam int RandWidth   = 1,
  localparam int Stages      = 1,
  localparam int DoubleWidth = 2 * Width
) (
  input clk_i,
  input rst_ni,

  input  logic [RandWidth-1:0] rand_i,
  input  logic [Width-1:0]     share0_i,
  input  logic [Width-1:0]     share1_i,

  output logic sum_o,
);

  logic [Width-1:0] a_masked;
  logic [Width-1:0] b_masked;
  logic [Width-1:0] a_masked_q;
  logic [Width-1:0] b_masked_q;
  logic [Width-1:0] rand_inv;

  prim_inv u_prim_inv (
    .in_i (rand_i),
    .out_o(rand_inv)
  );

  prim_and2 #(
    .Width(Width)
  ) prim_and2_mask_a (
    .in0_i(share0_i),
    .in1_i(rand_i),
    .out_o(a_masked)
  );

  prim_and2 #(
    .Width(Width)
  ) prim_and2_mask_b (
    .in0_i(share1_i),
    .in1_i(rand_inv),
    .out_o(b_masked)
  );

  prim_flop #(
    .Width(Width),
    .ResetValue('0)
  ) prim_flop_a (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .d_i(a_masked),
    .q_o(a_masked_q)
  );

  prim_flop #(
    .Width(Width),
    .ResetValue('0)
  ) prim_flop_b (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .d_i(b_masked),
    .q_o(b_masked_q)
  );

  prim_xor2 #(
    .Width(Width)
  ) u_prim_xor2_sum (
    .in0_i(a_masked_q),
    .in1_i(b_masked_q),
    .out_o(sum_o)
  );

endmodule : otbn_sec_add_sca_test_wrapper
