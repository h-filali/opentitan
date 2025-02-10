// Security gadget for hardening ML-DSA.
// This gadget is a mask conversion from a k-bit boolean
// masking to arithmetic masking modulo 2^(k+1).
// This gadget uses a k-bit random value gamma to
// refresh the output.
// x = x1_i ^ x2_i = z1_o - z2_o
module ml_dsa_sec_b2a_2k #(
  parameter int unsigned ShareWidth = 23
) (
  input  logic                  clk_i,
  input  logic                  rst_ni,
  input  logic [ShareWidth-1:0] x1_i,
  input  logic [ShareWidth-1:0] x2_i,
  input  logic [ShareWidth-1:0] gamma_i,
  output logic [ShareWidth:0]   z1_o,
  output logic [ShareWidth:0]   z2_o
);

  timeunit 1ns;
  timeprecision 10ps;

  // Signals
  logic [ShareWidth-1:0]  a1_q, a2_q, a4_q, a1_d, a2_d, a4_d;
  logic [ShareWidth:0]    a3_q, a3_d;
  logic [ShareWidth:0]    z1_d, z1_q, z2_d, z2_q;

  // XOR AND signals which are at the beginning of each bit calculation.
  logic z1_2_xor_and, z1_3_xor_and, z1_4_xor_and, z1_5_xor_and, z1_6_xor_and, z1_7_xor_and,
        z1_8_xor_and, z1_9_xor_and, z1_10_xor_and, z1_11_xor_and, z1_12_xor_and, z1_13_xor_and,
        z1_14_xor_and, z1_15_xor_and, z1_16_xor_and, z1_17_xor_and, z1_18_xor_and, z1_19_xor_and,
        z1_20_xor_and, z1_21_xor_and, z1_22_xor_and, z1_23_xor_and;

  // And chain signals for bit 2 of z1.
  logic z1_2_and_chain_1;

  // And chain signals for bit 3 of z1.
  logic z1_3_and_chain_1, z1_3_and_chain_2;

  // And chain signals for bit 4 of z1.
  logic z1_4_and_chain_1, z1_4_and_chain_2, z1_4_and_chain_3;

  // And chain signals for bit 5 of z1.
  logic z1_5_and_chain_1, z1_5_and_chain_2, z1_5_and_chain_3, z1_5_and_chain_4;

  // And chain signals for bit 6 of z1.
  logic z1_6_and_chain_1, z1_6_and_chain_2, z1_6_and_chain_3, z1_6_and_chain_4,
        z1_6_and_chain_5;

  // And chain signals for bit 7 of z1.
  logic z1_7_and_chain_1, z1_7_and_chain_2, z1_7_and_chain_3, z1_7_and_chain_4,
        z1_7_and_chain_5, z1_7_and_chain_6;

  // And chain signals for bit 8 of z1.
  logic z1_8_and_chain_1, z1_8_and_chain_2, z1_8_and_chain_3, z1_8_and_chain_4,
        z1_8_and_chain_5, z1_8_and_chain_6, z1_8_and_chain_7;

  // And chain signals for bit 9 of z1.
  logic z1_9_and_chain_1, z1_9_and_chain_2, z1_9_and_chain_3, z1_9_and_chain_4,
        z1_9_and_chain_5, z1_9_and_chain_6, z1_9_and_chain_7, z1_9_and_chain_8;

  // And chain signals for bit 10 of z1.
  logic z1_10_and_chain_1, z1_10_and_chain_2, z1_10_and_chain_3, z1_10_and_chain_4,
        z1_10_and_chain_5, z1_10_and_chain_6, z1_10_and_chain_7, z1_10_and_chain_8,
        z1_10_and_chain_9;

  // And chain signals for bit 11 of z1.
  logic z1_11_and_chain_1, z1_11_and_chain_2, z1_11_and_chain_3, z1_11_and_chain_4,
        z1_11_and_chain_5, z1_11_and_chain_6, z1_11_and_chain_7, z1_11_and_chain_8,
        z1_11_and_chain_9, z1_11_and_chain_10;

  // And chain signals for bit 12 of z1.
  logic z1_12_and_chain_1, z1_12_and_chain_2, z1_12_and_chain_3, z1_12_and_chain_4,
        z1_12_and_chain_5, z1_12_and_chain_6, z1_12_and_chain_7, z1_12_and_chain_8,
        z1_12_and_chain_9, z1_12_and_chain_10, z1_12_and_chain_11;

  // And chain signals for bit 13 of z1.
  logic z1_13_and_chain_1, z1_13_and_chain_2, z1_13_and_chain_3, z1_13_and_chain_4,
        z1_13_and_chain_5, z1_13_and_chain_6, z1_13_and_chain_7, z1_13_and_chain_8,
        z1_13_and_chain_9, z1_13_and_chain_10, z1_13_and_chain_11, z1_13_and_chain_12;

  // And chain signals for bit 14 of z1.
  logic z1_14_and_chain_1, z1_14_and_chain_2, z1_14_and_chain_3, z1_14_and_chain_4,
        z1_14_and_chain_5, z1_14_and_chain_6, z1_14_and_chain_7, z1_14_and_chain_8,
        z1_14_and_chain_9, z1_14_and_chain_10, z1_14_and_chain_11, z1_14_and_chain_12,
        z1_14_and_chain_13;

  // And chain signals for bit 15 of z1.
  logic z1_15_and_chain_1, z1_15_and_chain_2, z1_15_and_chain_3, z1_15_and_chain_4,
        z1_15_and_chain_5, z1_15_and_chain_6, z1_15_and_chain_7, z1_15_and_chain_8,
        z1_15_and_chain_9, z1_15_and_chain_10, z1_15_and_chain_11, z1_15_and_chain_12,
        z1_15_and_chain_13, z1_15_and_chain_14;

  // And chain signals for bit 16 of z1.
  logic z1_16_and_chain_1, z1_16_and_chain_2, z1_16_and_chain_3, z1_16_and_chain_4,
        z1_16_and_chain_5, z1_16_and_chain_6, z1_16_and_chain_7, z1_16_and_chain_8,
        z1_16_and_chain_9, z1_16_and_chain_10, z1_16_and_chain_11, z1_16_and_chain_12,
        z1_16_and_chain_13, z1_16_and_chain_14, z1_16_and_chain_15;

  // And chain signals for bit 17 of z1.
  logic z1_17_and_chain_1, z1_17_and_chain_2, z1_17_and_chain_3, z1_17_and_chain_4,
        z1_17_and_chain_5, z1_17_and_chain_6, z1_17_and_chain_7, z1_17_and_chain_8,
        z1_17_and_chain_9, z1_17_and_chain_10, z1_17_and_chain_11, z1_17_and_chain_12,
        z1_17_and_chain_13, z1_17_and_chain_14, z1_17_and_chain_15, z1_17_and_chain_16;

  // And chain signals for bit 18 of z1.
  logic z1_18_and_chain_1, z1_18_and_chain_2, z1_18_and_chain_3, z1_18_and_chain_4,
        z1_18_and_chain_5, z1_18_and_chain_6, z1_18_and_chain_7, z1_18_and_chain_8,
        z1_18_and_chain_9, z1_18_and_chain_10, z1_18_and_chain_11, z1_18_and_chain_12,
        z1_18_and_chain_13, z1_18_and_chain_14, z1_18_and_chain_15, z1_18_and_chain_16,
        z1_18_and_chain_17;

  // And chain signals for bit 19 of z1.
  logic z1_19_and_chain_1, z1_19_and_chain_2, z1_19_and_chain_3, z1_19_and_chain_4,
        z1_19_and_chain_5, z1_19_and_chain_6, z1_19_and_chain_7, z1_19_and_chain_8,
        z1_19_and_chain_9, z1_19_and_chain_10, z1_19_and_chain_11, z1_19_and_chain_12,
        z1_19_and_chain_13, z1_19_and_chain_14, z1_19_and_chain_15, z1_19_and_chain_16,
        z1_19_and_chain_17, z1_19_and_chain_18;

  // And chain signals for bit 20 of z1.
  logic z1_20_and_chain_1, z1_20_and_chain_2, z1_20_and_chain_3, z1_20_and_chain_4,
        z1_20_and_chain_5, z1_20_and_chain_6, z1_20_and_chain_7, z1_20_and_chain_8,
        z1_20_and_chain_9, z1_20_and_chain_10, z1_20_and_chain_11, z1_20_and_chain_12,
        z1_20_and_chain_13, z1_20_and_chain_14, z1_20_and_chain_15, z1_20_and_chain_16,
        z1_20_and_chain_17, z1_20_and_chain_18, z1_20_and_chain_19;

  // And chain signals for bit 21 of z1.
  logic z1_21_and_chain_1, z1_21_and_chain_2, z1_21_and_chain_3, z1_21_and_chain_4,
        z1_21_and_chain_5, z1_21_and_chain_6, z1_21_and_chain_7, z1_21_and_chain_8,
        z1_21_and_chain_9, z1_21_and_chain_10, z1_21_and_chain_11, z1_21_and_chain_12,
        z1_21_and_chain_13, z1_21_and_chain_14, z1_21_and_chain_15, z1_21_and_chain_16,
        z1_21_and_chain_17, z1_21_and_chain_18, z1_21_and_chain_19, z1_21_and_chain_20;

  // And chain signals for bit 22 of z1.
  logic z1_22_and_chain_1, z1_22_and_chain_2, z1_22_and_chain_3, z1_22_and_chain_4,
        z1_22_and_chain_5, z1_22_and_chain_6, z1_22_and_chain_7, z1_22_and_chain_8,
        z1_22_and_chain_9, z1_22_and_chain_10, z1_22_and_chain_11, z1_22_and_chain_12,
        z1_22_and_chain_13, z1_22_and_chain_14, z1_22_and_chain_15, z1_22_and_chain_16,
        z1_22_and_chain_17, z1_22_and_chain_18, z1_22_and_chain_19, z1_22_and_chain_20,
        z1_22_and_chain_21;

  // And chain signals for bit 23 of z1.
  logic z1_23_and_chain_1, z1_23_and_chain_2, z1_23_and_chain_3, z1_23_and_chain_4,
        z1_23_and_chain_5, z1_23_and_chain_6, z1_23_and_chain_7, z1_23_and_chain_8,
        z1_23_and_chain_9, z1_23_and_chain_10, z1_23_and_chain_11, z1_23_and_chain_12,
        z1_23_and_chain_13, z1_23_and_chain_14, z1_23_and_chain_15, z1_23_and_chain_16,
        z1_23_and_chain_17, z1_23_and_chain_18, z1_23_and_chain_19, z1_23_and_chain_20,
        z1_23_and_chain_21, z1_23_and_chain_22;

  // State registers
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      a1_q <= '0;
      a2_q <= '0;
      a4_q <= '0;
      a3_q <= '0;
      z1_q <= '0;
      z2_q <= '0;
    end else begin
      a1_q <= a1_d;
      a2_q <= a2_d;
      a4_q <= a4_d;
      a3_q <= a3_d;
      z1_q <= z1_d;
      z2_q <= z2_d;
    end
  end

  // Assignments
  // Initial assignments of a1_d-a4_q.
  assign a1_d = x1_i;
  assign a2_d = x1_i ^ gamma_i;
  assign a3_d = x2_i + gamma_i;
  assign a4_d = x2_i ^ gamma_i;

  // Compute the value of z1_d[0].
  assign z1_d[0] = a3_q[0];

  // Compute the value of z1_d[1].
  assign z1_d[1] = a3_q[1] ^ (a1_q[0] & ~a4_q[0]);

  // Compute the value of z1_d[2].
  assign z1_2_xor_and     = a3_q[2] ^ (a1_q[1] & ~a4_q[1]);
  assign z1_2_and_chain_1 = a4_q[1] & a1_q[0] & ~a4_q[0];
  assign z1_d[2] = z1_2_xor_and ^ z1_2_and_chain_1;

  // Compute the value of z1_d[3].
  assign z1_3_xor_and     = a3_q[3] ^ (a1_q[2] & ~a4_q[2]);
  assign z1_3_and_chain_1 = a4_q[2] & a1_q[1] & ~a4_q[1];
  assign z1_3_and_chain_2 = z1_2_and_chain_1 & a4_q[2];
  assign z1_d[3] = z1_3_xor_and ^ z1_3_and_chain_1 ^ z1_3_and_chain_2;

  // Compute the value of z1_d[4].
  assign z1_4_xor_and     = a3_q[4] ^ (a1_q[3] & ~a4_q[3]);
  assign z1_4_and_chain_1 = a4_q[3] & a1_q[2] & ~a4_q[2];
  assign z1_4_and_chain_2 = z1_3_and_chain_1 & a4_q[3];
  assign z1_4_and_chain_3 = z1_3_and_chain_2 & a4_q[3];
  assign z1_d[4] = z1_4_xor_and ^ z1_4_and_chain_1 ^ z1_4_and_chain_2 ^ z1_4_and_chain_3;

  // Compute the value of z1_d[5].
  assign z1_5_xor_and     = a3_q[5] ^ (a1_q[4] & ~a4_q[4]);
  assign z1_5_and_chain_1 = a4_q[4] & a1_q[3] & ~a4_q[3];
  assign z1_5_and_chain_2 = z1_4_and_chain_1 & a4_q[4];
  assign z1_5_and_chain_3 = z1_4_and_chain_2 & a4_q[4];
  assign z1_5_and_chain_4 = z1_4_and_chain_3 & a4_q[4];
  assign z1_d[5] = z1_5_xor_and ^ z1_5_and_chain_1 ^ z1_5_and_chain_2 ^ z1_5_and_chain_3
                   ^ z1_5_and_chain_4;

  // Compute the value of z1_d[6].
  assign z1_6_xor_and     = a3_q[6] ^ (a1_q[5] & ~a4_q[5]);
  assign z1_6_and_chain_1 = a4_q[5] & a1_q[4] & ~a4_q[4];
  assign z1_6_and_chain_2 = z1_5_and_chain_1 & a4_q[5];
  assign z1_6_and_chain_3 = z1_5_and_chain_2 & a4_q[5];
  assign z1_6_and_chain_4 = z1_5_and_chain_3 & a4_q[5];
  assign z1_6_and_chain_5 = z1_5_and_chain_4 & a4_q[5];
  assign z1_d[6] = z1_6_xor_and ^ z1_6_and_chain_1 ^ z1_6_and_chain_2 ^ z1_6_and_chain_3
                   ^ z1_6_and_chain_4 ^ z1_6_and_chain_5;

  // Compute the value of z1_d[7].
  assign z1_7_xor_and     = a3_q[7] ^ (a1_q[6] & ~a4_q[6]);
  assign z1_7_and_chain_1 = a4_q[6] & a1_q[5] & ~a4_q[5];
  assign z1_7_and_chain_2 = z1_6_and_chain_1 & a4_q[6];
  assign z1_7_and_chain_3 = z1_6_and_chain_2 & a4_q[6];
  assign z1_7_and_chain_4 = z1_6_and_chain_3 & a4_q[6];
  assign z1_7_and_chain_5 = z1_6_and_chain_4 & a4_q[6];
  assign z1_7_and_chain_6 = z1_6_and_chain_5 & a4_q[6];
  assign z1_d[7] = z1_7_xor_and ^ z1_7_and_chain_1 ^ z1_7_and_chain_2 ^ z1_7_and_chain_3
                   ^ z1_7_and_chain_4 ^ z1_7_and_chain_5 ^ z1_7_and_chain_6;

  // Compute the value of z1_d[8].
  assign z1_8_xor_and     = a3_q[8] ^ (a1_q[7] & ~a4_q[7]);
  assign z1_8_and_chain_1 = a4_q[7] & a1_q[6] & ~a4_q[6];
  assign z1_8_and_chain_2 = z1_7_and_chain_1 & a4_q[7];
  assign z1_8_and_chain_3 = z1_7_and_chain_2 & a4_q[7];
  assign z1_8_and_chain_4 = z1_7_and_chain_3 & a4_q[7];
  assign z1_8_and_chain_5 = z1_7_and_chain_4 & a4_q[7];
  assign z1_8_and_chain_6 = z1_7_and_chain_5 & a4_q[7];
  assign z1_8_and_chain_7 = z1_7_and_chain_6 & a4_q[7];
  assign z1_d[8] = z1_8_xor_and ^ z1_8_and_chain_1 ^ z1_8_and_chain_2 ^ z1_8_and_chain_3
                   ^ z1_8_and_chain_4 ^ z1_8_and_chain_5 ^ z1_8_and_chain_6 ^ z1_8_and_chain_7;

  // Compute the value of z1_d[9].
  assign z1_9_xor_and     = a3_q[9] ^ (a1_q[8] & ~a4_q[8]);
  assign z1_9_and_chain_1 = a4_q[8] & a1_q[7] & ~a4_q[7];
  assign z1_9_and_chain_2 = z1_8_and_chain_1 & a4_q[8];
  assign z1_9_and_chain_3 = z1_8_and_chain_2 & a4_q[8];
  assign z1_9_and_chain_4 = z1_8_and_chain_3 & a4_q[8];
  assign z1_9_and_chain_5 = z1_8_and_chain_4 & a4_q[8];
  assign z1_9_and_chain_6 = z1_8_and_chain_5 & a4_q[8];
  assign z1_9_and_chain_7 = z1_8_and_chain_6 & a4_q[8];
  assign z1_9_and_chain_8 = z1_8_and_chain_7 & a4_q[8];
  assign z1_d[9] = z1_9_xor_and ^ z1_9_and_chain_1 ^ z1_9_and_chain_2 ^ z1_9_and_chain_3
                    ^ z1_9_and_chain_4 ^ z1_9_and_chain_5 ^ z1_9_and_chain_6 ^ z1_9_and_chain_7
                    ^ z1_9_and_chain_8;

  // Compute the value of z1_d[10].
  assign z1_10_xor_and     = a3_q[10] ^ (a1_q[9] & ~a4_q[9]);
  assign z1_10_and_chain_1 = a4_q[9] & a1_q[8] & ~a4_q[8];
  assign z1_10_and_chain_2 = z1_9_and_chain_1 & a4_q[9];
  assign z1_10_and_chain_3 = z1_9_and_chain_2 & a4_q[9];
  assign z1_10_and_chain_4 = z1_9_and_chain_3 & a4_q[9];
  assign z1_10_and_chain_5 = z1_9_and_chain_4 & a4_q[9];
  assign z1_10_and_chain_6 = z1_9_and_chain_5 & a4_q[9];
  assign z1_10_and_chain_7 = z1_9_and_chain_6 & a4_q[9];
  assign z1_10_and_chain_8 = z1_9_and_chain_7 & a4_q[9];
  assign z1_10_and_chain_9 = z1_9_and_chain_8 & a4_q[9];
  assign z1_d[10] = z1_10_xor_and ^ z1_10_and_chain_1 ^ z1_10_and_chain_2 ^ z1_10_and_chain_3
                    ^ z1_10_and_chain_4 ^ z1_10_and_chain_5 ^ z1_10_and_chain_6 ^ z1_10_and_chain_7
                    ^ z1_10_and_chain_8 ^ z1_10_and_chain_9;

  // Compute the value of z1_d[11].
  assign z1_11_xor_and      = a3_q[11] ^ (a1_q[10] & ~a4_q[10]);
  assign z1_11_and_chain_1  = a4_q[10] & a1_q[9] & ~a4_q[9];
  assign z1_11_and_chain_2  = z1_10_and_chain_1 & a4_q[10];
  assign z1_11_and_chain_3  = z1_10_and_chain_2 & a4_q[10];
  assign z1_11_and_chain_4  = z1_10_and_chain_3 & a4_q[10];
  assign z1_11_and_chain_5  = z1_10_and_chain_4 & a4_q[10];
  assign z1_11_and_chain_6  = z1_10_and_chain_5 & a4_q[10];
  assign z1_11_and_chain_7  = z1_10_and_chain_6 & a4_q[10];
  assign z1_11_and_chain_8  = z1_10_and_chain_7 & a4_q[10];
  assign z1_11_and_chain_9  = z1_10_and_chain_8 & a4_q[10];
  assign z1_11_and_chain_10 = z1_10_and_chain_9 & a4_q[10];
  assign z1_d[11] = z1_11_xor_and ^ z1_11_and_chain_1 ^ z1_11_and_chain_2 ^ z1_11_and_chain_3
                    ^ z1_11_and_chain_4 ^ z1_11_and_chain_5 ^ z1_11_and_chain_6 ^ z1_11_and_chain_7
                    ^ z1_11_and_chain_8 ^ z1_11_and_chain_9 ^ z1_11_and_chain_10;

  // Compute the value of z1_d[12].
  assign z1_12_xor_and      = a3_q[12] ^ (a1_q[11] & ~a4_q[11]);
  assign z1_12_and_chain_1  = a4_q[11] & a1_q[10] & ~a4_q[10];
  assign z1_12_and_chain_2  = z1_11_and_chain_1 & a4_q[11];
  assign z1_12_and_chain_3  = z1_11_and_chain_2 & a4_q[11];
  assign z1_12_and_chain_4  = z1_11_and_chain_3 & a4_q[11];
  assign z1_12_and_chain_5  = z1_11_and_chain_4 & a4_q[11];
  assign z1_12_and_chain_6  = z1_11_and_chain_5 & a4_q[11];
  assign z1_12_and_chain_7  = z1_11_and_chain_6 & a4_q[11];
  assign z1_12_and_chain_8  = z1_11_and_chain_7 & a4_q[11];
  assign z1_12_and_chain_9  = z1_11_and_chain_8 & a4_q[11];
  assign z1_12_and_chain_10 = z1_11_and_chain_9 & a4_q[11];
  assign z1_12_and_chain_11 = z1_11_and_chain_10 & a4_q[11];
  assign z1_d[12] = z1_12_xor_and ^ z1_12_and_chain_1 ^ z1_12_and_chain_2 ^ z1_12_and_chain_3
                    ^ z1_12_and_chain_4 ^ z1_12_and_chain_5 ^ z1_12_and_chain_6 ^ z1_12_and_chain_7
                    ^ z1_12_and_chain_8 ^ z1_12_and_chain_9 ^ z1_12_and_chain_10 ^ z1_12_and_chain_11;

  // Compute the value of z1_d[13].
  assign z1_13_xor_and      = a3_q[13] ^ (a1_q[12] & ~a4_q[12]);
  assign z1_13_and_chain_1  = a4_q[12] & a1_q[11] & ~a4_q[11];
  assign z1_13_and_chain_2  = z1_12_and_chain_1 & a4_q[12];
  assign z1_13_and_chain_3  = z1_12_and_chain_2 & a4_q[12];
  assign z1_13_and_chain_4  = z1_12_and_chain_3 & a4_q[12];
  assign z1_13_and_chain_5  = z1_12_and_chain_4 & a4_q[12];
  assign z1_13_and_chain_6  = z1_12_and_chain_5 & a4_q[12];
  assign z1_13_and_chain_7  = z1_12_and_chain_6 & a4_q[12];
  assign z1_13_and_chain_8  = z1_12_and_chain_7 & a4_q[12];
  assign z1_13_and_chain_9  = z1_12_and_chain_8 & a4_q[12];
  assign z1_13_and_chain_10 = z1_12_and_chain_9 & a4_q[12];
  assign z1_13_and_chain_11 = z1_12_and_chain_10 & a4_q[12];
  assign z1_13_and_chain_12 = z1_12_and_chain_11 & a4_q[12];
  assign z1_d[13] = z1_13_xor_and ^ z1_13_and_chain_1 ^ z1_13_and_chain_2 ^ z1_13_and_chain_3
                    ^ z1_13_and_chain_4 ^ z1_13_and_chain_5 ^ z1_13_and_chain_6 ^ z1_13_and_chain_7
                    ^ z1_13_and_chain_8 ^ z1_13_and_chain_9 ^ z1_13_and_chain_10 ^ z1_13_and_chain_11
                    ^ z1_13_and_chain_12;

  // Compute the value of z1_d[14].
  assign z1_14_xor_and      = a3_q[14] ^ (a1_q[13] & ~a4_q[13]);
  assign z1_14_and_chain_1  = a4_q[13] & a1_q[12] & ~a4_q[12];
  assign z1_14_and_chain_2  = z1_13_and_chain_1 & a4_q[13];
  assign z1_14_and_chain_3  = z1_13_and_chain_2 & a4_q[13];
  assign z1_14_and_chain_4  = z1_13_and_chain_3 & a4_q[13];
  assign z1_14_and_chain_5  = z1_13_and_chain_4 & a4_q[13];
  assign z1_14_and_chain_6  = z1_13_and_chain_5 & a4_q[13];
  assign z1_14_and_chain_7  = z1_13_and_chain_6 & a4_q[13];
  assign z1_14_and_chain_8  = z1_13_and_chain_7 & a4_q[13];
  assign z1_14_and_chain_9  = z1_13_and_chain_8 & a4_q[13];
  assign z1_14_and_chain_10 = z1_13_and_chain_9 & a4_q[13];
  assign z1_14_and_chain_11 = z1_13_and_chain_10 & a4_q[13];
  assign z1_14_and_chain_12 = z1_13_and_chain_11 & a4_q[13];
  assign z1_14_and_chain_13 = z1_13_and_chain_12 & a4_q[13];
  assign z1_d[14] = z1_14_xor_and ^ z1_14_and_chain_1 ^ z1_14_and_chain_2 ^ z1_14_and_chain_3
                    ^ z1_14_and_chain_4 ^ z1_14_and_chain_5 ^ z1_14_and_chain_6 ^ z1_14_and_chain_7
                    ^ z1_14_and_chain_8 ^ z1_14_and_chain_9 ^ z1_14_and_chain_10 ^ z1_14_and_chain_11
                    ^ z1_14_and_chain_12 ^ z1_14_and_chain_13;

  // Compute the value of z1_d[15].
  assign z1_15_xor_and      = a3_q[15] ^ (a1_q[14] & ~a4_q[14]);
  assign z1_15_and_chain_1  = a4_q[14] & a1_q[13] & ~a4_q[13];
  assign z1_15_and_chain_2  = z1_14_and_chain_1 & a4_q[14];
  assign z1_15_and_chain_3  = z1_14_and_chain_2 & a4_q[14];
  assign z1_15_and_chain_4  = z1_14_and_chain_3 & a4_q[14];
  assign z1_15_and_chain_5  = z1_14_and_chain_4 & a4_q[14];
  assign z1_15_and_chain_6  = z1_14_and_chain_5 & a4_q[14];
  assign z1_15_and_chain_7  = z1_14_and_chain_6 & a4_q[14];
  assign z1_15_and_chain_8  = z1_14_and_chain_7 & a4_q[14];
  assign z1_15_and_chain_9  = z1_14_and_chain_8 & a4_q[14];
  assign z1_15_and_chain_10 = z1_14_and_chain_9 & a4_q[14];
  assign z1_15_and_chain_11 = z1_14_and_chain_10 & a4_q[14];
  assign z1_15_and_chain_12 = z1_14_and_chain_11 & a4_q[14];
  assign z1_15_and_chain_13 = z1_14_and_chain_12 & a4_q[14];
  assign z1_15_and_chain_14 = z1_14_and_chain_13 & a4_q[14];
  assign z1_d[15] = z1_15_xor_and ^ z1_15_and_chain_1 ^ z1_15_and_chain_2 ^ z1_15_and_chain_3
                    ^ z1_15_and_chain_4 ^ z1_15_and_chain_5 ^ z1_15_and_chain_6 ^ z1_15_and_chain_7
                    ^ z1_15_and_chain_8 ^ z1_15_and_chain_9 ^ z1_15_and_chain_10 ^ z1_15_and_chain_11
                    ^ z1_15_and_chain_12 ^ z1_15_and_chain_13 ^ z1_15_and_chain_14;

  // Compute the value of z1_d[16].
  assign z1_16_xor_and      = a3_q[16] ^ (a1_q[15] & ~a4_q[15]);
  assign z1_16_and_chain_1  = a4_q[15] & a1_q[14] & ~a4_q[14];
  assign z1_16_and_chain_2  = z1_15_and_chain_1 & a4_q[15];
  assign z1_16_and_chain_3  = z1_15_and_chain_2 & a4_q[15];
  assign z1_16_and_chain_4  = z1_15_and_chain_3 & a4_q[15];
  assign z1_16_and_chain_5  = z1_15_and_chain_4 & a4_q[15];
  assign z1_16_and_chain_6  = z1_15_and_chain_5 & a4_q[15];
  assign z1_16_and_chain_7  = z1_15_and_chain_6 & a4_q[15];
  assign z1_16_and_chain_8  = z1_15_and_chain_7 & a4_q[15];
  assign z1_16_and_chain_9  = z1_15_and_chain_8 & a4_q[15];
  assign z1_16_and_chain_10 = z1_15_and_chain_9 & a4_q[15];
  assign z1_16_and_chain_11 = z1_15_and_chain_10 & a4_q[15];
  assign z1_16_and_chain_12 = z1_15_and_chain_11 & a4_q[15];
  assign z1_16_and_chain_13 = z1_15_and_chain_12 & a4_q[15];
  assign z1_16_and_chain_14 = z1_15_and_chain_13 & a4_q[15];
  assign z1_16_and_chain_15 = z1_15_and_chain_14 & a4_q[15];
  assign z1_d[16] = z1_16_xor_and ^ z1_16_and_chain_1 ^ z1_16_and_chain_2 ^ z1_16_and_chain_3
                    ^ z1_16_and_chain_4 ^ z1_16_and_chain_5 ^ z1_16_and_chain_6 ^ z1_16_and_chain_7
                    ^ z1_16_and_chain_8 ^ z1_16_and_chain_9 ^ z1_16_and_chain_10 ^ z1_16_and_chain_11
                    ^ z1_16_and_chain_12 ^ z1_16_and_chain_13 ^ z1_16_and_chain_14 ^ z1_16_and_chain_15;

  // Compute the value of z1_d[17].
  assign z1_17_xor_and      = a3_q[17] ^ (a1_q[16] & ~a4_q[16]);
  assign z1_17_and_chain_1  = a4_q[16] & a1_q[15] & ~a4_q[15];
  assign z1_17_and_chain_2  = z1_16_and_chain_1 & a4_q[16];
  assign z1_17_and_chain_3  = z1_16_and_chain_2 & a4_q[16];
  assign z1_17_and_chain_4  = z1_16_and_chain_3 & a4_q[16];
  assign z1_17_and_chain_5  = z1_16_and_chain_4 & a4_q[16];
  assign z1_17_and_chain_6  = z1_16_and_chain_5 & a4_q[16];
  assign z1_17_and_chain_7  = z1_16_and_chain_6 & a4_q[16];
  assign z1_17_and_chain_8  = z1_16_and_chain_7 & a4_q[16];
  assign z1_17_and_chain_9  = z1_16_and_chain_8 & a4_q[16];
  assign z1_17_and_chain_10 = z1_16_and_chain_9 & a4_q[16];
  assign z1_17_and_chain_11 = z1_16_and_chain_10 & a4_q[16];
  assign z1_17_and_chain_12 = z1_16_and_chain_11 & a4_q[16];
  assign z1_17_and_chain_13 = z1_16_and_chain_12 & a4_q[16];
  assign z1_17_and_chain_14 = z1_16_and_chain_13 & a4_q[16];
  assign z1_17_and_chain_15 = z1_16_and_chain_14 & a4_q[16];
  assign z1_17_and_chain_16 = z1_16_and_chain_15 & a4_q[16];
  assign z1_d[17] = z1_17_xor_and ^ z1_17_and_chain_1 ^ z1_17_and_chain_2 ^ z1_17_and_chain_3
                    ^ z1_17_and_chain_4 ^ z1_17_and_chain_5 ^ z1_17_and_chain_6 ^ z1_17_and_chain_7
                    ^ z1_17_and_chain_8 ^ z1_17_and_chain_9 ^ z1_17_and_chain_10 ^ z1_17_and_chain_11
                    ^ z1_17_and_chain_12 ^ z1_17_and_chain_13 ^ z1_17_and_chain_14 ^ z1_17_and_chain_15
                    ^ z1_17_and_chain_16;

  // Compute the value of z1_d[18].
  assign z1_18_xor_and      = a3_q[18] ^ (a1_q[17] & ~a4_q[17]);
  assign z1_18_and_chain_1  = a4_q[17] & a1_q[16] & ~a4_q[16];
  assign z1_18_and_chain_2  = z1_17_and_chain_1 & a4_q[17];
  assign z1_18_and_chain_3  = z1_17_and_chain_2 & a4_q[17];
  assign z1_18_and_chain_4  = z1_17_and_chain_3 & a4_q[17];
  assign z1_18_and_chain_5  = z1_17_and_chain_4 & a4_q[17];
  assign z1_18_and_chain_6  = z1_17_and_chain_5 & a4_q[17];
  assign z1_18_and_chain_7  = z1_17_and_chain_6 & a4_q[17];
  assign z1_18_and_chain_8  = z1_17_and_chain_7 & a4_q[17];
  assign z1_18_and_chain_9  = z1_17_and_chain_8 & a4_q[17];
  assign z1_18_and_chain_10 = z1_17_and_chain_9 & a4_q[17];
  assign z1_18_and_chain_11 = z1_17_and_chain_10 & a4_q[17];
  assign z1_18_and_chain_12 = z1_17_and_chain_11 & a4_q[17];
  assign z1_18_and_chain_13 = z1_17_and_chain_12 & a4_q[17];
  assign z1_18_and_chain_14 = z1_17_and_chain_13 & a4_q[17];
  assign z1_18_and_chain_15 = z1_17_and_chain_14 & a4_q[17];
  assign z1_18_and_chain_16 = z1_17_and_chain_15 & a4_q[17];
  assign z1_18_and_chain_17 = z1_17_and_chain_16 & a4_q[17];
  assign z1_d[18] = z1_18_xor_and ^ z1_18_and_chain_1 ^ z1_18_and_chain_2 ^ z1_18_and_chain_3
                    ^ z1_18_and_chain_4 ^ z1_18_and_chain_5 ^ z1_18_and_chain_6 ^ z1_18_and_chain_7
                    ^ z1_18_and_chain_8 ^ z1_18_and_chain_9 ^ z1_18_and_chain_10 ^ z1_18_and_chain_11
                    ^ z1_18_and_chain_12 ^ z1_18_and_chain_13 ^ z1_18_and_chain_14 ^ z1_18_and_chain_15
                    ^ z1_18_and_chain_16 ^ z1_18_and_chain_17;

  // Compute the value of z1_d[19].
  assign z1_19_xor_and      = a3_q[19] ^ (a1_q[18] & ~a4_q[18]);
  assign z1_19_and_chain_1  = a4_q[18] & a1_q[17] & ~a4_q[17];
  assign z1_19_and_chain_2  = z1_18_and_chain_1 & a4_q[18];
  assign z1_19_and_chain_3  = z1_18_and_chain_2 & a4_q[18];
  assign z1_19_and_chain_4  = z1_18_and_chain_3 & a4_q[18];
  assign z1_19_and_chain_5  = z1_18_and_chain_4 & a4_q[18];
  assign z1_19_and_chain_6  = z1_18_and_chain_5 & a4_q[18];
  assign z1_19_and_chain_7  = z1_18_and_chain_6 & a4_q[18];
  assign z1_19_and_chain_8  = z1_18_and_chain_7 & a4_q[18];
  assign z1_19_and_chain_9  = z1_18_and_chain_8 & a4_q[18];
  assign z1_19_and_chain_10 = z1_18_and_chain_9 & a4_q[18];
  assign z1_19_and_chain_11 = z1_18_and_chain_10 & a4_q[18];
  assign z1_19_and_chain_12 = z1_18_and_chain_11 & a4_q[18];
  assign z1_19_and_chain_13 = z1_18_and_chain_12 & a4_q[18];
  assign z1_19_and_chain_14 = z1_18_and_chain_13 & a4_q[18];
  assign z1_19_and_chain_15 = z1_18_and_chain_14 & a4_q[18];
  assign z1_19_and_chain_16 = z1_18_and_chain_15 & a4_q[18];
  assign z1_19_and_chain_17 = z1_18_and_chain_16 & a4_q[18];
  assign z1_19_and_chain_18 = z1_18_and_chain_17 & a4_q[18];
  assign z1_d[19] = z1_19_xor_and ^ z1_19_and_chain_1 ^ z1_19_and_chain_2 ^ z1_19_and_chain_3
                    ^ z1_19_and_chain_4 ^ z1_19_and_chain_5 ^ z1_19_and_chain_6 ^ z1_19_and_chain_7
                    ^ z1_19_and_chain_8 ^ z1_19_and_chain_9 ^ z1_19_and_chain_10 ^ z1_19_and_chain_11
                    ^ z1_19_and_chain_12 ^ z1_19_and_chain_13 ^ z1_19_and_chain_14 ^ z1_19_and_chain_15
                    ^ z1_19_and_chain_16 ^ z1_19_and_chain_17 ^ z1_19_and_chain_18;

  // Compute the value of z1_d[20].
  assign z1_20_xor_and      = a3_q[20] ^ (a1_q[19] & ~a4_q[19]);
  assign z1_20_and_chain_1  = a4_q[19] & a1_q[18] & ~a4_q[18];
  assign z1_20_and_chain_2  = z1_19_and_chain_1 & a4_q[19];
  assign z1_20_and_chain_3  = z1_19_and_chain_2 & a4_q[19];
  assign z1_20_and_chain_4  = z1_19_and_chain_3 & a4_q[19];
  assign z1_20_and_chain_5  = z1_19_and_chain_4 & a4_q[19];
  assign z1_20_and_chain_6  = z1_19_and_chain_5 & a4_q[19];
  assign z1_20_and_chain_7  = z1_19_and_chain_6 & a4_q[19];
  assign z1_20_and_chain_8  = z1_19_and_chain_7 & a4_q[19];
  assign z1_20_and_chain_9  = z1_19_and_chain_8 & a4_q[19];
  assign z1_20_and_chain_10 = z1_19_and_chain_9 & a4_q[19];
  assign z1_20_and_chain_11 = z1_19_and_chain_10 & a4_q[19];
  assign z1_20_and_chain_12 = z1_19_and_chain_11 & a4_q[19];
  assign z1_20_and_chain_13 = z1_19_and_chain_12 & a4_q[19];
  assign z1_20_and_chain_14 = z1_19_and_chain_13 & a4_q[19];
  assign z1_20_and_chain_15 = z1_19_and_chain_14 & a4_q[19];
  assign z1_20_and_chain_16 = z1_19_and_chain_15 & a4_q[19];
  assign z1_20_and_chain_17 = z1_19_and_chain_16 & a4_q[19];
  assign z1_20_and_chain_18 = z1_19_and_chain_17 & a4_q[19];
  assign z1_20_and_chain_19 = z1_19_and_chain_18 & a4_q[19];
  assign z1_d[20] = z1_20_xor_and ^ z1_20_and_chain_1 ^ z1_20_and_chain_2 ^ z1_20_and_chain_3
                    ^ z1_20_and_chain_4 ^ z1_20_and_chain_5 ^ z1_20_and_chain_6 ^ z1_20_and_chain_7
                    ^ z1_20_and_chain_8 ^ z1_20_and_chain_9 ^ z1_20_and_chain_10 ^ z1_20_and_chain_11
                    ^ z1_20_and_chain_12 ^ z1_20_and_chain_13 ^ z1_20_and_chain_14 ^ z1_20_and_chain_15
                    ^ z1_20_and_chain_16 ^ z1_20_and_chain_17 ^ z1_20_and_chain_18 ^ z1_20_and_chain_19;

  // Compute the value of z1_d[21].
  assign z1_21_xor_and      = a3_q[21] ^ (a1_q[20] & ~a4_q[20]);
  assign z1_21_and_chain_1  = a4_q[20] & a1_q[19] & ~a4_q[19];
  assign z1_21_and_chain_2  = z1_20_and_chain_1 & a4_q[20];
  assign z1_21_and_chain_3  = z1_20_and_chain_2 & a4_q[20];
  assign z1_21_and_chain_4  = z1_20_and_chain_3 & a4_q[20];
  assign z1_21_and_chain_5  = z1_20_and_chain_4 & a4_q[20];
  assign z1_21_and_chain_6  = z1_20_and_chain_5 & a4_q[20];
  assign z1_21_and_chain_7  = z1_20_and_chain_6 & a4_q[20];
  assign z1_21_and_chain_8  = z1_20_and_chain_7 & a4_q[20];
  assign z1_21_and_chain_9  = z1_20_and_chain_8 & a4_q[20];
  assign z1_21_and_chain_10 = z1_20_and_chain_9 & a4_q[20];
  assign z1_21_and_chain_11 = z1_20_and_chain_10 & a4_q[20];
  assign z1_21_and_chain_12 = z1_20_and_chain_11 & a4_q[20];
  assign z1_21_and_chain_13 = z1_20_and_chain_12 & a4_q[20];
  assign z1_21_and_chain_14 = z1_20_and_chain_13 & a4_q[20];
  assign z1_21_and_chain_15 = z1_20_and_chain_14 & a4_q[20];
  assign z1_21_and_chain_16 = z1_20_and_chain_15 & a4_q[20];
  assign z1_21_and_chain_17 = z1_20_and_chain_16 & a4_q[20];
  assign z1_21_and_chain_18 = z1_20_and_chain_17 & a4_q[20];
  assign z1_21_and_chain_19 = z1_20_and_chain_18 & a4_q[20];
  assign z1_21_and_chain_20 = z1_20_and_chain_19 & a4_q[20];
  assign z1_d[21] = z1_21_xor_and ^ z1_21_and_chain_1 ^ z1_21_and_chain_2 ^ z1_21_and_chain_3
                    ^ z1_21_and_chain_4 ^ z1_21_and_chain_5 ^ z1_21_and_chain_6 ^ z1_21_and_chain_7
                    ^ z1_21_and_chain_8 ^ z1_21_and_chain_9 ^ z1_21_and_chain_10 ^ z1_21_and_chain_11
                    ^ z1_21_and_chain_12 ^ z1_21_and_chain_13 ^ z1_21_and_chain_14 ^ z1_21_and_chain_15
                    ^ z1_21_and_chain_16 ^ z1_21_and_chain_17 ^ z1_21_and_chain_18 ^ z1_21_and_chain_19
                    ^ z1_21_and_chain_20;

  // Compute the value of z1_d[22].
  assign z1_22_xor_and      = a3_q[22] ^ (a1_q[21] & ~a4_q[21]);
  assign z1_22_and_chain_1  = a4_q[21] & a1_q[20] & ~a4_q[20];
  assign z1_22_and_chain_2  = z1_21_and_chain_1 & a4_q[21];
  assign z1_22_and_chain_3  = z1_21_and_chain_2 & a4_q[21];
  assign z1_22_and_chain_4  = z1_21_and_chain_3 & a4_q[21];
  assign z1_22_and_chain_5  = z1_21_and_chain_4 & a4_q[21];
  assign z1_22_and_chain_6  = z1_21_and_chain_5 & a4_q[21];
  assign z1_22_and_chain_7  = z1_21_and_chain_6 & a4_q[21];
  assign z1_22_and_chain_8  = z1_21_and_chain_7 & a4_q[21];
  assign z1_22_and_chain_9  = z1_21_and_chain_8 & a4_q[21];
  assign z1_22_and_chain_10 = z1_21_and_chain_9 & a4_q[21];
  assign z1_22_and_chain_11 = z1_21_and_chain_10 & a4_q[21];
  assign z1_22_and_chain_12 = z1_21_and_chain_11 & a4_q[21];
  assign z1_22_and_chain_13 = z1_21_and_chain_12 & a4_q[21];
  assign z1_22_and_chain_14 = z1_21_and_chain_13 & a4_q[21];
  assign z1_22_and_chain_15 = z1_21_and_chain_14 & a4_q[21];
  assign z1_22_and_chain_16 = z1_21_and_chain_15 & a4_q[21];
  assign z1_22_and_chain_17 = z1_21_and_chain_16 & a4_q[21];
  assign z1_22_and_chain_18 = z1_21_and_chain_17 & a4_q[21];
  assign z1_22_and_chain_19 = z1_21_and_chain_18 & a4_q[21];
  assign z1_22_and_chain_20 = z1_21_and_chain_19 & a4_q[21];
  assign z1_22_and_chain_21 = z1_21_and_chain_20 & a4_q[21];
  assign z1_d[22] = z1_22_xor_and ^ z1_22_and_chain_1 ^ z1_22_and_chain_2 ^ z1_22_and_chain_3
                    ^ z1_22_and_chain_4 ^ z1_22_and_chain_5 ^ z1_22_and_chain_6 ^ z1_22_and_chain_7
                    ^ z1_22_and_chain_8 ^ z1_22_and_chain_9 ^ z1_22_and_chain_10 ^ z1_22_and_chain_11
                    ^ z1_22_and_chain_12 ^ z1_22_and_chain_13 ^ z1_22_and_chain_14 ^ z1_22_and_chain_15
                    ^ z1_22_and_chain_16 ^ z1_22_and_chain_17 ^ z1_22_and_chain_18 ^ z1_22_and_chain_19
                    ^ z1_22_and_chain_20 ^ z1_22_and_chain_21;

  // Compute the value of z1_d[23].
  assign z1_23_xor_and      = a3_q[23] ^ (a1_q[22] & ~a4_q[22]);
  assign z1_23_and_chain_1  = a4_q[22] & a1_q[21] & ~a4_q[21];
  assign z1_23_and_chain_2  = z1_22_and_chain_1 & a4_q[22];
  assign z1_23_and_chain_3  = z1_22_and_chain_2 & a4_q[22];
  assign z1_23_and_chain_4  = z1_22_and_chain_3 & a4_q[22];
  assign z1_23_and_chain_5  = z1_22_and_chain_4 & a4_q[22];
  assign z1_23_and_chain_6  = z1_22_and_chain_5 & a4_q[22];
  assign z1_23_and_chain_7  = z1_22_and_chain_6 & a4_q[22];
  assign z1_23_and_chain_8  = z1_22_and_chain_7 & a4_q[22];
  assign z1_23_and_chain_9  = z1_22_and_chain_8 & a4_q[22];
  assign z1_23_and_chain_10 = z1_22_and_chain_9 & a4_q[22];
  assign z1_23_and_chain_11 = z1_22_and_chain_10 & a4_q[22];
  assign z1_23_and_chain_12 = z1_22_and_chain_11 & a4_q[22];
  assign z1_23_and_chain_13 = z1_22_and_chain_12 & a4_q[22];
  assign z1_23_and_chain_14 = z1_22_and_chain_13 & a4_q[22];
  assign z1_23_and_chain_15 = z1_22_and_chain_14 & a4_q[22];
  assign z1_23_and_chain_16 = z1_22_and_chain_15 & a4_q[22];
  assign z1_23_and_chain_17 = z1_22_and_chain_16 & a4_q[22];
  assign z1_23_and_chain_18 = z1_22_and_chain_17 & a4_q[22];
  assign z1_23_and_chain_19 = z1_22_and_chain_18 & a4_q[22];
  assign z1_23_and_chain_20 = z1_22_and_chain_19 & a4_q[22];
  assign z1_23_and_chain_21 = z1_22_and_chain_20 & a4_q[22];
  assign z1_23_and_chain_22 = z1_22_and_chain_21 & a4_q[22];
  assign z1_d[23] = z1_23_xor_and ^ z1_23_and_chain_1 ^ z1_23_and_chain_2 ^ z1_23_and_chain_3
                    ^ z1_23_and_chain_4 ^ z1_23_and_chain_5 ^ z1_23_and_chain_6 ^ z1_23_and_chain_7
                    ^ z1_23_and_chain_8 ^ z1_23_and_chain_9 ^ z1_23_and_chain_10 ^ z1_23_and_chain_11
                    ^ z1_23_and_chain_12 ^ z1_23_and_chain_13 ^ z1_23_and_chain_14 ^ z1_23_and_chain_15
                    ^ z1_23_and_chain_16 ^ z1_23_and_chain_17 ^ z1_23_and_chain_18 ^ z1_23_and_chain_19
                    ^ z1_23_and_chain_20 ^ z1_23_and_chain_21 ^ z1_23_and_chain_22;

  assign z2_d = {1'b0, a2_q};

  // Assign outputs
  assign z1_o = z1_q;
  assign z2_o = z2_q;
  
endmodule
