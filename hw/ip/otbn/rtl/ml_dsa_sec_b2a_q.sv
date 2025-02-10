// Security gadget for hardening ML-DSA.
// This gadget is a mask conversion from a k-bit boolean masking
// to an arithmetic masking modulo q.
// This gadget uses gamma_i as randomness for the initial mask
// conversion step and r_i as randomness for the borrow bit
// calculation.
// x0_i ^ x1_i = z0_o + z1_o % q
module ml_dsa_sec_b2a_q #(
  parameter int unsigned ShareWidth = 23,
  parameter int unsigned RandWidth = 80,
  parameter int unsigned Modulus = 8380417
) (
  input  logic                  clk_i,
  input  logic                  rst_ni,
  
  input  logic                  valid_i,
  output logic                  ready_o,
  
  output logic                  valid_o,
  input  logic                  ready_i,

  input  logic [ShareWidth-1:0] x0_i,
  input  logic [ShareWidth-1:0] x1_i,
  input  logic [ShareWidth-1:0] gamma_i,
  input  logic [RandWidth-1:0]  r_i,
  output logic [ShareWidth-1:0] z0_o,
  output logic [ShareWidth-1:0] z1_o
);

  timeunit 1ns;
  timeprecision 10ps;

  // Signals
  logic [ShareWidth:0] t1_d, t1_q, t1_q2, t1_q3,
                       t2_d, t2_q, t2_q2, t2_q3,
                       u_d, u_q, u_q2, u_q3;

  logic b0, b1;

  logic [ShareWidth:0] w1, w2, w, z0, z1;

  logic data_valid_d, data_valid_q, data_valid_q2, data_valid_q3,
        data_valid_q4, data_valid_q5;

  // State registers
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      t1_q          <= '0;
      t1_q2         <= '0;
      t1_q3         <= '0;
      t2_q          <= '0;
      t2_q2         <= '0;
      t2_q3         <= '0;
      u_q           <= '0;
      u_q2          <= '0;
      u_q3          <= '0;
      data_valid_q  <= 1'b0;
      data_valid_q2 <= 1'b0;
      data_valid_q3 <= 1'b0;
      data_valid_q4 <= 1'b0;
      data_valid_q5 <= 1'b0;
    end else begin
      t1_q          <= t1_d;
      t1_q2         <= t1_q;
      t1_q3         <= t1_q2;
      t2_q          <= t2_d;
      t2_q2         <= t2_q;
      t2_q3         <= t2_q2;
      u_q           <= u_d;
      u_q2          <= u_q;
      u_q3          <= u_q2;
      data_valid_q  <= data_valid_d;
      data_valid_q2 <= data_valid_q;
      data_valid_q3 <= data_valid_q2;
      data_valid_q4 <= data_valid_q3;
      data_valid_q5 <= data_valid_q4;
    end
  end

  ml_dsa_sec_b2a_2k u_ml_dsa_sec_b2a_2k (
    .clk_i,
    .rst_ni,
    .x1_i(x0_i),
    .x2_i(x1_i),
    .gamma_i,
    .z1_o(t1_d),
    .z2_o(t2_d)
  );

  ml_dsa_10_ksa_borrow_bit_gen #(
    .ShareWidth(24),
    .RandWidth(80)
  ) u_ml_dsa_10_ksa_borrow_bit_gen (
    .clk_i,
    .rst_ni,
    .x0_i({1'b0, x0_i}),
    .x1_i({1'b0, x1_i}),
    .r_i,
    .b0_o(b0),
    .b1_o(b1)
  );

  // Assignments
  assign u_d = t2_d + (ShareWidth+1)'(Modulus);
  assign w1 = ({(ShareWidth+1){b0}} & (t2_q3 ^ u_q3)) ^ t2_q3;
  assign w2 = ({(ShareWidth+1){b0}} & (t2_q3 ^ u_q3));
  assign w = w1 ^ w2;

  // Get t1 into the right range z0 = t1 - n*q.
  assign z0 = (t1_q3 >= (ShareWidth+1)'(2*Modulus)) ? t1_q3 - (ShareWidth+1)'(2*Modulus) :
      (t1_q3 >= (ShareWidth+1)'(Modulus)) ? t1_q3 - (ShareWidth+1)'(Modulus) : t1_q3;
  // Get w into the right range z1 = w - n*q.
  // And transform the result from z = z0 - z1 % q to z = z0 + z1 % q.
  // Both steps together result in z1 = (n+1)*q - w.
  assign z1 = (w >= (ShareWidth+1)'(2*Modulus)) ? (ShareWidth+1)'(3*Modulus) - w :
      w >= (ShareWidth+1)'(Modulus) ? (ShareWidth+1)'(2*Modulus) - w : (ShareWidth+1)'(Modulus) - w;

  // Set the input handshake signal.
  assign data_valid_d = valid_i && ready_o;

  // Assign outputs
  assign ready_o = 1'b1;
  assign valid_o = data_valid_q5;

  assign z0_o = z0[ShareWidth-1:0];
  assign z1_o = z1[ShareWidth-1:0];
  
endmodule
