// Security gadget for hardening ML-DSA.
// This gadget is a masked implementation of
// y = (b_j & a_j & a_i) ^ (b_i & a_i) ^ (a_j & b_j & b_i)
// This gadget uses two random bits (r0, r1) to refresh it's inputs.
// The bits from b come from a constant and thus are not masked.
// The bits from a come from a secret sharing and the operations
// where different shares are mixed need to be refreshed.
// Such as a_j & a_i.
module ml_dsa_dom_and_u (
  input  logic clk_i,
  input  logic rst_ni,
  input  logic a0_i,
  input  logic a1_i,
  input  logic b0_i,
  input  logic b1_i,
  input  logic ui_i,
  input  logic uim1_i,
  input  logic r0_i,
  input  logic r1_i,
  output logic y0_o,
  output logic y1_o
);

  timeunit 1ns;
  timeprecision 10ps;

  // Signals
  logic m0, m1, l0, l1, k0, k1, sec_and_0, sec_and_1;
  logic uim1_q, u_q, a0_q, a1_q, b0_q, b1_q;

  // State registers
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      uim1_q <= 1'b0;
      u_q    <= 1'b0;
      a0_q   <= 1'b0;
      a1_q   <= 1'b0;
      b0_q   <= 1'b0;
      b1_q   <= 1'b0;
    end else begin
      uim1_q <= uim1_i;
      u_q    <= ui_i;
      a0_q   <= a0_i;
      a1_q   <= a1_i;
      b0_q   <= b0_i;
      b1_q   <= b1_i;
    end
  end

  ml_dsa_dom_and_xor_refresh u_ml_dsa_dom_and_xor_refresh (
    .clk_i,
    .rst_ni,
    .a0_i,
    .a1_i,
    .b0_i,
    .b1_i,
    .c0_i(1'b0),
    .c1_i(1'b0),
    .r0_i,
    .r1_i,
    .y0_o(sec_and_0),
    .y1_o(sec_and_1)
  );

  // Assign Signals.
  assign m0 = sec_and_0 & uim1_q;
  assign m1 = sec_and_1 & uim1_q;

  assign l0 = a0_q & u_q;
  assign l1 = a1_q & u_q;

  assign k0 = b0_q & u_q & uim1_q;
  assign k1 = b1_q & u_q & uim1_q;

  // Assign Outputs.
  assign y0_o = m0 ^ l0 ^ k0;
  assign y1_o = m1 ^ l1 ^ k1;

endmodule
