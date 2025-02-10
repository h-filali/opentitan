// Security gadget for hardening ML-DSA.
// This gadget is a masked implementation of y = (a & b) ^ c.
// This gadget uses two random bits (r0, r1) to refresh the output.
// yp0 = (a0 & b0) ^ c0 ^ r1
// yp1 = (a0 & b1) ^ r0
// yp2 = (a1 & b0) ^ r0
// yp3 = (a1 & b1) ^ c1 ^ r1
// y0  = yp0 ^ yp1
// y1  = yp2 ^ yp3
module ml_dsa_dom_and_xor_refresh (
  input  logic clk_i,
  input  logic rst_ni,
  input  logic a0_i,
  input  logic a1_i,
  input  logic b0_i,
  input  logic b1_i,
  input  logic c0_i,
  input  logic c1_i,
  input  logic r0_i,
  input  logic r1_i,
  output logic y0_o,
  output logic y1_o
);

  timeunit 1ns;
  timeprecision 10ps;

  // Signals
  logic yp0_d, yp1_d, yp2_d, yp3_d,
        yp0_q, yp1_q, yp2_q, yp3_q;

  // State registers
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      yp0_q <= 1'b0;
      yp1_q <= 1'b0;
      yp2_q <= 1'b0;
      yp3_q <= 1'b0;
    end else begin
      yp0_q <= yp0_d;
      yp1_q <= yp1_d;
      yp2_q <= yp2_d;
      yp3_q <= yp3_d;
    end
  end

  // Assignments
  assign yp0_d = (a0_i & b0_i) ^ c0_i ^ r1_i;
  assign yp1_d = (a0_i & b1_i) ^ r0_i;
  assign yp2_d = (a1_i & b0_i) ^ r0_i;
  assign yp3_d = (a1_i & b1_i) ^ c1_i ^ r1_i;

  assign y0_o = yp0_q ^ yp1_q;
  assign y1_o = yp2_q ^ yp3_q;
  
endmodule
