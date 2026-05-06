// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

module otbn_mask_accelerator_sca_wrapper
  import otbn_pkg::*;
#(
  parameter  int Width          = 32,
  localparam int NumShares      = 2,
  localparam int VecSize        = 8,
  localparam int Stages         = $clog2(Width),
  localparam int RandWidth      = 2*(Stages*Width + 1),
  localparam int DoubleWidth    = 2*Width,
  // rand_i carries adder randomness in [RandWidth-1:0] and arithmetic masks in
  // [RandWidth+DoubleWidth-1:RandWidth] (layout: {mask1, mask0, adder_rand})
  localparam int TotalRandWidth = RandWidth + DoubleWidth,
  // Flat share bus width: VecSize elements of DoubleWidth bits each
  localparam int FlatShareWidth  = VecSize * DoubleWidth
) (
  input  logic clk_i,
  input  logic rst_ni,

  // Handshake
  input  logic wvalid_i,
  output logic wready_o,
  output logic rvalid_o,

  // Randomness: [RandWidth-1:0] = secure adder rand, [TotalRandWidth-1:RandWidth] = {mask1, mask0}
  input  logic [TotalRandWidth-1:0] rand_i,

  // Modulus (used for SecAddMod, ArithToBool, BoolToArith)
  input  logic [Width-1:0]       q_i,

  // Operation mode
  input  state_mask_op_e         mask_op_i,

  // Flat operand share buses: element k at [k*DoubleWidth +: DoubleWidth]
  //   each element = {b_share[k], a_share[k]}
  input  logic [FlatShareWidth-1:0] share0_i,
  input  logic [FlatShareWidth-1:0] share1_i,

  // Output shares
  output logic [Width-1:0]       sum_o[NumShares],

  // Error signals
  output logic                   mask_fifo_err_o,
  output logic                   ctr_err_o
);

  // ---------------------------------------------------------------------------
  // Internal signals
  // ---------------------------------------------------------------------------

  // Registered input buffers
  logic [DoubleWidth-1:0] share0_q[VecSize];
  logic [DoubleWidth-1:0] share1_q[VecSize];

  // FSM / counter state
  logic        shares_received_d, shares_received_q;
  logic [3:0]  ctr_d, ctr_q;   // counts 0..VecSize (needs ceil(log2(VecSize+1)) bits)

  // Signals toward the accelerator
  logic        accel_wvalid;
  logic        accel_wready;
  logic [Width-1:0] a_shares[NumShares];
  logic [Width-1:0] b_shares[NumShares];

  // Unpack arithmetic masks from the upper bits of rand_i
  logic [Width-1:0] masks[NumShares];
  assign masks[0] = rand_i[RandWidth +: Width];
  assign masks[1] = rand_i[RandWidth + Width +: Width];

  // ---------------------------------------------------------------------------
  // Next-state combinational logic
  // ---------------------------------------------------------------------------
  always_comb begin
    if (shares_received_q) begin
      // Done when all VecSize elements have been dispatched
      shares_received_d = (ctr_q == 4'(VecSize)) ? 1'b0 : 1'b1;
      // Advance counter only while within bounds and accelerator is ready
      ctr_d = (accel_wready && (ctr_q < 4'(VecSize))) ? ctr_q + 4'h1 : ctr_q;
    end else begin
      shares_received_d = wvalid_i;
      ctr_d             = '0;
    end
  end

  // ---------------------------------------------------------------------------
  // State registers
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      shares_received_q <= 1'b0;
      ctr_q             <= '0;
      share0_q          <= '{default: '0};
      share1_q          <= '{default: '0};
    end else begin
      shares_received_q <= shares_received_d;
      ctr_q             <= ctr_d;
      // Capture input vector on the handshake cycle, unpacking flat bus
      if (!shares_received_q && wvalid_i) begin
        for (int k = 0; k < VecSize; k++) begin
          share0_q[k] <= share0_i[k*DoubleWidth +: DoubleWidth];
          share1_q[k] <= share1_i[k*DoubleWidth +: DoubleWidth];
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Handshake outputs
  // ---------------------------------------------------------------------------

  // Ready for new input only when not currently dispatching
  assign wready_o = !shares_received_q;

  // Drive accelerator valid only while there are elements left to send
  assign accel_wvalid = shares_received_q && (ctr_q < 4'(VecSize));

  // ---------------------------------------------------------------------------
  // Operand unpacking: lower half = A share, upper half = B share
  // ---------------------------------------------------------------------------
  assign a_shares[0] = share0_q[ctr_q][Width-1:0];
  assign a_shares[1] = share1_q[ctr_q][Width-1:0];
  assign b_shares[0] = share0_q[ctr_q][DoubleWidth-1:Width];
  assign b_shares[1] = share1_q[ctr_q][DoubleWidth-1:Width];

  // ---------------------------------------------------------------------------
  // Accelerator instantiation
  // ---------------------------------------------------------------------------
  otbn_mask_accelerator #(
    .Width        (Width),
    .EnRejSampling(1'b0)
  ) u_otbn_mask_accelerator (
    .clk_i,
    .rst_ni,

    .wvalid_i      (accel_wvalid),
    .wready_o      (accel_wready),
    .a_i           (a_shares),
    .b_i           (b_shares),

    .rand_i        (rand_i[RandWidth-1:0]),
    .masks_i       (masks),

    .q_i,
    .mask_op_i,

    .rvalid_o,
    .rready_i      (1'b1),
    .sum_o,

    .mask_fifo_err_o,
    .ctr_err_o
  );

endmodule : otbn_mask_accelerator_sca_wrapper
