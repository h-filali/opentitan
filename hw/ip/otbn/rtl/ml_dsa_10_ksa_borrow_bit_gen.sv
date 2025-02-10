// Security gadget for hardening ML-DSA.
// This gadget calculates the borrow bit b = (b0, b1) generated
// during the subtraction x-q, where x is masked using two
// arithmetic shares (x0, x1) modulo 2^k.
// q is the modulus used in ML-DSA.
// The borrow bit calculation is done in 5 stages where each stage
// has a latency of one cycle.
module ml_dsa_10_ksa_borrow_bit_gen #(
  parameter int unsigned ShareWidth = 24,
  parameter int unsigned RandWidth = 80,
  localparam int unsigned Modulus = 8380417,
  localparam int unsigned ShareWidthDiv2 = ShareWidth/2,
  localparam int unsigned ShareWidthDiv4 = ShareWidth/4,
  localparam int unsigned ShareWidthDiv8 = ShareWidth/8,
  localparam int unsigned SubModulus = (1 << (ShareWidth+1)) - Modulus
) (
  input  logic                  clk_i,
  input  logic                  rst_ni,
  input  logic [ShareWidth-1:0] x0_i,
  input  logic [ShareWidth-1:0] x1_i,
  input  logic [RandWidth-1:0]  r_i,
  output logic                  b0_o,
  output logic                  b1_o
);

  timeunit 1ns;
  timeprecision 10ps;

  // Signals
  logic [ShareWidth-1:0] a0, a1;
  logic [ShareWidth-1:0] u, a0_xor_u;

  logic [ShareWidthDiv2-1:0] p0_s1, p1_s1, g0_s1, g1_s1;
  logic [ShareWidthDiv4-1:0] p0_s2, p1_s2, g0_s2, g1_s2;
  logic [ShareWidthDiv8-1:0] p0_s3, p1_s3, g0_s3, g1_s3;
  logic                      p0_s3_0_q, p1_s3_0_q, g0_s3_0_q, g1_s3_0_q;
  logic [1:0]                p0_s4, p1_s4, g0_s4, g1_s4;

  // State registers
  // Since the propagate and generate bits for bits 0-7 are already
  // computed in stage 3 they need to be delayed by one cycle.
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      p0_s3_0_q <= 1'b0;
      p1_s3_0_q <= 1'b0;
      g0_s3_0_q <= 1'b0;
      g1_s3_0_q <= 1'b0;
    end else begin
      p0_s3_0_q <= p0_s3[0];
      p1_s3_0_q <= p1_s3[0];
      g0_s3_0_q <= g0_s3[0];
      g1_s3_0_q <= g1_s3[0];
    end
  end

  // Refresh the even bits of the sharing.
  for (genvar ii = 0; ii < (ShareWidth - 1); ii=ii+2) begin : gen_refresh_even_input
    integer rand_index = ii>>1;
    assign a0[ii] = x0_i[ii] ^ r_i[rand_index];
    assign a1[ii] = x1_i[ii] ^ r_i[rand_index];
  end

  // Assign the odd bits of the sharing without refreshing.
  for (genvar ii = 1; ii < ShareWidth; ii=ii+2) begin : gen_copy_odd_input
    assign a0[ii] = x0_i[ii];
    assign a1[ii] = x1_i[ii];
  end

  // Assign u to 2^k - q.
  assign u = ShareWidth'(SubModulus);

  // Stage 1 of the Kogge-Stone adder.
  for (genvar ii = 1; ii < ShareWidth; ii=ii+2) begin : gen_ks_stage_1
    integer jj = ii/2;
    // Offset is 12 and each iteration uses 3 bits of randomness.
    integer rand_index = 12 + 3*ii;

    assign a0_xor_u[ii] = a0[ii] ^ u[ii];
    assign a0_xor_u[ii-1] = a0[ii-1] ^ u[ii-1];

    ml_dsa_dom_and u_ml_dsa_dom_and_s1 (
      .clk_i,
      .rst_ni,
      .a0_i(a0_xor_u[ii]),
      .a1_i(a1[ii]),
      .b0_i(a0_xor_u[ii-1]),
      .b1_i(a1[ii-1]),
      .r0_i(r_i[rand_index]),
      .y0_o(p0_s1[jj]),
      .y1_o(p1_s1[jj])
    );

    ml_dsa_dom_and_u u_ml_dsa_dom_and_u_s1 (
      .clk_i,
      .rst_ni,
      .a0_i(a0[ii]),
      .a1_i(a1[ii]),
      .b0_i(a0[ii-1]),
      .b1_i(a1[ii-1]),
      .ui_i(u[ii]),
      .uim1_i(u[ii-1]),
      .r0_i(r_i[rand_index + 1]),
      .r1_i(r_i[rand_index + 2]),
      .y0_o(g0_s1[jj]),
      .y1_o(g1_s1[jj])
    );

  end

  // Stage 2 of the Kogge-Stone adder.
  for (genvar ii = 1; ii <= ShareWidthDiv4; ii++) begin : gen_ks_stage_2
    integer mm = 2*ii - 1;
    integer ll = mm - 1;
    // Offset is 48 and each iteration uses 3 bits of randomness.
    integer rand_index = 48 + 3*ii;

    ml_dsa_dom_and u_ml_dsa_dom_and_s2 (
      .clk_i,
      .rst_ni,
      .a0_i(p0_s1[mm]),
      .a1_i(p1_s1[mm]),
      .b0_i(p0_s1[ll]),
      .b1_i(p1_s1[ll]),
      .r0_i(r_i[rand_index]),
      .y0_o(p0_s2[ii-1]),
      .y1_o(p1_s2[ii-1])
    );

    ml_dsa_dom_and_xor_refresh u_ml_dsa_dom_and_xor_refresh_s2 (
      .clk_i,
      .rst_ni,
      .a0_i(p0_s1[mm]),
      .a1_i(p1_s1[mm]),
      .b0_i(g0_s1[ll]),
      .b1_i(g1_s1[ll]),
      .c0_i(g0_s1[mm]),
      .c1_i(g1_s1[mm]),
      .r0_i(r_i[rand_index + 1]),
      .r1_i(r_i[rand_index + 2]),
      .y0_o(g0_s2[ii-1]),
      .y1_o(g1_s2[ii-1])
    );
  end

  // Stage 3 of the Kogge-Stone adder.
  for (genvar ii = 1; ii <= ShareWidthDiv8; ii++) begin : gen_ks_stage_3
    integer mm = 2*ii - 1;
    integer ll = mm - 1;
    // Offset is 66 and each iteration uses 3 bits of randomness.
    integer rand_index = 66 + 3*ii;

    ml_dsa_dom_and u_ml_dsa_dom_and_s3 (
      .clk_i,
      .rst_ni,
      .a0_i(p0_s2[mm]),
      .a1_i(p1_s2[mm]),
      .b0_i(p0_s2[ll]),
      .b1_i(p1_s2[ll]),
      .r0_i(r_i[rand_index]),
      .y0_o(p0_s3[ii-1]),
      .y1_o(p1_s3[ii-1])
    );

    ml_dsa_dom_and_xor_refresh u_ml_dsa_dom_and_xor_refresh_s3 (
      .clk_i,
      .rst_ni,
      .a0_i(p0_s2[mm]),
      .a1_i(p1_s2[mm]),
      .b0_i(g0_s2[ll]),
      .b1_i(g1_s2[ll]),
      .c0_i(g0_s2[mm]),
      .c1_i(g1_s2[mm]),
      .r0_i(r_i[rand_index + 1]),
      .r1_i(r_i[rand_index + 2]),
      .y0_o(g0_s3[ii-1]),
      .y1_o(g1_s3[ii-1])
    );
  end

  // Stage 4 of the Kogge-Stone adder.
  ml_dsa_dom_and u_ml_dsa_dom_and_s4 (
    .clk_i,
    .rst_ni,
    .a0_i(p0_s3[ShareWidthDiv8-1]),
    .a1_i(p1_s3[ShareWidthDiv8-1]),
    .b0_i(p0_s3[ShareWidthDiv8-2]),
    .b1_i(p1_s3[ShareWidthDiv8-2]),
    .r0_i(r_i[75]),
    .y0_o(p0_s4[1]),
    .y1_o(p1_s4[1])
  );

  ml_dsa_dom_and_xor_refresh u_ml_dsa_dom_and_xor_refresh_s4 (
    .clk_i,
    .rst_ni,
    .a0_i(p0_s3[ShareWidthDiv8-1]),
    .a1_i(p1_s3[ShareWidthDiv8-1]),
    .b0_i(g0_s3[ShareWidthDiv8-2]),
    .b1_i(g1_s3[ShareWidthDiv8-2]),
    .c0_i(g0_s3[ShareWidthDiv8-1]),
    .c1_i(g1_s3[ShareWidthDiv8-1]),
    .r0_i(r_i[76]),
    .r1_i(r_i[77]),
    .y0_o(g0_s4[1]),
    .y1_o(g1_s4[1])
  );

  // Add one cycle of delay to the values that skip this stage.
  assign p0_s4[0] = p0_s3_0_q;
  assign p1_s4[0] = p1_s3_0_q;
  assign g0_s4[0] = g0_s3_0_q;
  assign g1_s4[0] = g1_s3_0_q;

  // Stage 5 of the Kogge-Stone adder.
  ml_dsa_dom_and_xor_refresh u_ml_dsa_dom_and_xor_refresh_s5 (
    .clk_i,
    .rst_ni,
    .a0_i(p0_s4[1]),
    .a1_i(p1_s4[1]),
    .b0_i(g0_s4[0]),
    .b1_i(g1_s4[0]),
    .c0_i(g0_s4[1]),
    .c1_i(g1_s4[1]),
    .r0_i(r_i[78]),
    .r1_i(r_i[79]),
    .y0_o(b0_o),
    .y1_o(b1_o)
  );

endmodule
