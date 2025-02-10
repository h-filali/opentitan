// Security gadget for hardening ML-DSA.
// This gadget is a masked implementation of y = a & b.
// This gadget uses one random bit r0 to refresh the output.
// yp0 = (a0 & b0)
// yp1 = (a0 & b1) ^ r0
// yp2 = (a1 & b0) ^ r0
// yp3 = (a1 & b1)
// y0  = yp0 ^ yp1
// y1  = yp2 ^ yp3
module ml_dsa_dom_and (
  input  logic clk_i,
  input  logic rst_ni,
  input  logic a0_i,
  input  logic a1_i,
  input  logic b0_i,
  input  logic b1_i,
  input  logic r0_i,
  output logic y0_o,
  output logic y1_o
);

  timeunit 1ns;
  timeprecision 10ps;

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
    .r1_i(1'b0),
    .y0_o,
    .y1_o
  );
  
endmodule
