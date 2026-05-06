// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

module otbn_sec_add_sca_wrapper #(
  parameter  int Width = 32,
  localparam int NumShares = 2,
  localparam int Stages = $clog2(Width),
  localparam int RandWidth = 2*Stages*Width - 4*Stages + 2,
  localparam int DoubleWidth = 2*Width,
  localparam int Latency = 6
) (
  input clk_i,
  input rst_ni,

  input  logic en_i,
  input  logic [RandWidth-1:0]   rand_i,
  // input  logic [RandWidth-1:0]   rand_i [Latency],
  // share0_i = {b_share0, a_share0}
  input  logic [DoubleWidth-1:0] share0_i,
  // share1_i = {b_share1, a_share1}
  input  logic [DoubleWidth-1:0] share1_i,

  output logic [Width-1:0]       result_o[NumShares],
  // output logic [Width-1:0]       leak_o
);

  // Extract shares for A and B from the combined share inputs
  // We assume: [63:32] is B, [31:0] is A
  logic [Width-1:0] inp1_shares [NumShares];
  logic [Width-1:0] inp2_shares [NumShares];

  assign inp1_shares[0] = share0_i[Width-1:0];
  assign inp1_shares[1] = share1_i[Width-1:0];
  assign inp2_shares[0] = share0_i[DoubleWidth-1:Width];
  assign inp2_shares[1] = share1_i[DoubleWidth-1:Width];


  // logic [Width-1:0] inp1_shares_q [NumShares];
  // logic [Width-1:0] inp2_shares_q [NumShares];
  // logic [RandWidth-1:0] rand_q;
  // logic en_q;

  // prim_flop #(
  //   .Width      (Width),
  //   .ResetValue ('0)
  // ) u_prim_flop_enable_0 (
  //   .clk_i(clk_i),
  //   .rst_ni(rst_ni),
  //   .d_i(inp1_shares[0]),
  //   .q_o(inp1_shares_q[0])
  // );
  // prim_flop #(
  //   .Width      (Width),
  //   .ResetValue ('0)
  // ) u_prim_flop_enable_1 (
  //   .clk_i(clk_i),
  //   .rst_ni(rst_ni),
  //   .d_i(inp1_shares[1]),
  //   .q_o(inp1_shares_q[1])
  // );

  // prim_flop #(
  //   .Width      (Width),
  //   .ResetValue ('0)
  // ) u_prim_flop_enable_2 (
  //   .clk_i(clk_i),
  //   .rst_ni(rst_ni),
  //   .d_i(inp2_shares[0]),
  //   .q_o(inp2_shares_q[0])
  // );
  // prim_flop #(
  //   .Width      (Width),
  //   .ResetValue ('0)
  // ) u_prim_flop_enable_3 (
  //   .clk_i(clk_i),
  //   .rst_ni(rst_ni),
  //   .d_i(inp2_shares[1]),
  //   .q_o(inp2_shares_q[1])
  // );

  // prim_flop #(
  //   .Width      (RandWidth),
  //   .ResetValue ('0)
  // ) u_prim_flop_enable_4 (
  //   .clk_i(clk_i),
  //   .rst_ni(rst_ni),
  //   .d_i(rand_i),
  //   .q_o(rand_q)
  // );

  // prim_flop #(
  //   .Width      (1),
  //   .ResetValue ('0)
  // ) u_prim_flop_enable_5 (
  //   .clk_i(clk_i),
  //   .rst_ni(rst_ni),
  //   .d_i(en_i),
  //   .q_o(en_q)
  // );

  // Instantiate the core logic
  otbn_sec_add u_otbn_sec_add (
    .clk_i,
    .rst_ni,
    .valid_i  (en_i),
    .stall_i  (1'b0),
    .rand_i   (rand_i),
    .inp1_i   (inp1_shares),
    .inp2_i   (inp2_shares),
    .result_o (result_o)
  );

endmodule : otbn_sec_add_sca_wrapper
