// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

module otbn_mask_accelerator_sca_wrapper
  import otbn_pkg::*;
#(
  parameter  int Width          = 32,
  localparam int NumShares      = 2,
  localparam int Stages         = $clog2(Width),
  localparam int RandWidth      = 2*(Stages*Width + 1),
  localparam int DoubleWidth    = 2*Width,
  // rand_i carries adder randomness in [RandWidth-1:0] and arithmetic masks in
  // [RandWidth+DoubleWidth-1:RandWidth] (layout: {mask1, mask0, adder_rand})
  localparam int TotalRandWidth = RandWidth + DoubleWidth
) (
  input  logic clk_i,
  input  logic rst_ni,

  input  logic wvalid_i,
  output logic rvalid_o,

  // Randomness: [RandWidth-1:0] = secure adder rand, [TotalRandWidth-1:RandWidth] = {mask1, mask0}
  input  logic [TotalRandWidth-1:0]        rand_i,

  // Modulus (used for SecAddMod, ArithToBool, BoolToArith)
  input  logic [Width-1:0]                 mod_i,

  // Operation mode
  input  mask_op_e                         mask_op_i,

  // One element per cycle: {b_share, a_share}
  input  logic [DoubleWidth-1:0]           share0_i,
  input  logic [DoubleWidth-1:0]           share1_i,

  // Output shares
  output logic [NumShares-1:0][Width-1:0]  result_o,

  // Error signals
  output logic                             mask_fifo_err_o,
  output logic                             ctr_err_o
);

  logic [NumShares-1:0][Width-1:0] in0_shares;
  logic [NumShares-1:0][Width-1:0] in1_shares;
  logic [NumShares-1:0][Width-1:0] remask_rand;

  assign remask_rand[0] = rand_i[RandWidth +: Width];
  assign remask_rand[1] = rand_i[RandWidth + Width +: Width];

  assign in0_shares[0] = share0_i[Width-1:0];
  assign in0_shares[1] = share1_i[Width-1:0];
  assign in1_shares[0] = share0_i[DoubleWidth-1:Width];
  assign in1_shares[1] = share1_i[DoubleWidth-1:Width];

  otbn_mask_accelerator #(
    .Width        (Width),
    .EnRejSampling(1'b0)
  ) u_otbn_mask_accelerator (
    .clk_i,
    .rst_ni,

    .sec_wipe_running_i(1'b0),

    .wvalid_i,
    .wready_o        (),
    .in0_i           (in0_shares),
    .in1_i           (in1_shares),

    .rand_i          (rand_i[RandWidth-1:0]),
    .remask_rand_i   (remask_rand),

    .mod_i,
    .mask_op_i,

    .rvalid_o,
    .rready_i        (1'b1),
    .result_o,

    .mask_fifo_err_o,
    .ctr_err_o
  );

endmodule
