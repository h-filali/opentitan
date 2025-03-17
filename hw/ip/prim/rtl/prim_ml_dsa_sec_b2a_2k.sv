// Security gadget for hardening ML-DSA.
// This gadget is a mask conversion from a k-bit boolean
// masking to arithmetic masking modulo 2^(k+1).
// This gadget uses a k-bit random value gamma to
// refresh the output.
// x = x1_i ^ x2_i = z1_o - z2_o
module prim_ml_dsa_sec_b2a_2k #(
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

  // Signals
  logic [ShareWidth-1:0]  a1, a2, a4;
  logic [ShareWidth:0]    a3;
  logic [ShareWidth:0]    z1;

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

  // Assignments
  // Initial assignments of a1-a4.
  assign a1 = x1_i;
  assign a2 = x1_i ^ gamma_i;
  assign a3 = x2_i + gamma_i;
  assign a4 = x2_i ^ gamma_i;

  // Compute the value of z1[0].
  assign z1[0] = a3[0];

  // Compute the value of z1[1].
  assign z1[1] = a3[1] ^ (a1[0] & ~a4[0]);

  // Compute the value of z1[2].
  assign z1_2_xor_and     = a3[2] ^ (a1[1] & ~a4[1]);
  assign z1_2_and_chain_1 = a4[1] & a1[0] & ~a4[0];
  assign z1[2] = z1_2_xor_and ^ z1_2_and_chain_1;

  // Compute the value of z1[3].
  assign z1_3_xor_and     = a3[3] ^ (a1[2] & ~a4[2]);
  assign z1_3_and_chain_1 = a4[2] & a1[1] & ~a4[1];
  assign z1_3_and_chain_2 = z1_2_and_chain_1 & a4[2];
  assign z1[3] = z1_3_xor_and ^ z1_3_and_chain_1 ^ z1_3_and_chain_2;

  // Compute the value of z1[4].
  assign z1_4_xor_and     = a3[4] ^ (a1[3] & ~a4[3]);
  assign z1_4_and_chain_1 = a4[3] & a1[2] & ~a4[2];
  assign z1_4_and_chain_2 = z1_3_and_chain_1 & a4[3];
  assign z1_4_and_chain_3 = z1_3_and_chain_2 & a4[3];
  assign z1[4] = z1_4_xor_and ^ z1_4_and_chain_1 ^ z1_4_and_chain_2 ^ z1_4_and_chain_3;

  // Compute the value of z1[5].
  assign z1_5_xor_and     = a3[5] ^ (a1[4] & ~a4[4]);
  assign z1_5_and_chain_1 = a4[4] & a1[3] & ~a4[3];
  assign z1_5_and_chain_2 = z1_4_and_chain_1 & a4[4];
  assign z1_5_and_chain_3 = z1_4_and_chain_2 & a4[4];
  assign z1_5_and_chain_4 = z1_4_and_chain_3 & a4[4];
  assign z1[5] = z1_5_xor_and ^ z1_5_and_chain_1 ^ z1_5_and_chain_2 ^ z1_5_and_chain_3
                 ^ z1_5_and_chain_4;

  // Compute the value of z1[6].
  assign z1_6_xor_and     = a3[6] ^ (a1[5] & ~a4[5]);
  assign z1_6_and_chain_1 = a4[5] & a1[4] & ~a4[4];
  assign z1_6_and_chain_2 = z1_5_and_chain_1 & a4[5];
  assign z1_6_and_chain_3 = z1_5_and_chain_2 & a4[5];
  assign z1_6_and_chain_4 = z1_5_and_chain_3 & a4[5];
  assign z1_6_and_chain_5 = z1_5_and_chain_4 & a4[5];
  assign z1[6] = z1_6_xor_and ^ z1_6_and_chain_1 ^ z1_6_and_chain_2 ^ z1_6_and_chain_3
                 ^ z1_6_and_chain_4 ^ z1_6_and_chain_5;

  // Compute the value of z1[7].
  assign z1_7_xor_and     = a3[7] ^ (a1[6] & ~a4[6]);
  assign z1_7_and_chain_1 = a4[6] & a1[5] & ~a4[5];
  assign z1_7_and_chain_2 = z1_6_and_chain_1 & a4[6];
  assign z1_7_and_chain_3 = z1_6_and_chain_2 & a4[6];
  assign z1_7_and_chain_4 = z1_6_and_chain_3 & a4[6];
  assign z1_7_and_chain_5 = z1_6_and_chain_4 & a4[6];
  assign z1_7_and_chain_6 = z1_6_and_chain_5 & a4[6];
  assign z1[7] = z1_7_xor_and ^ z1_7_and_chain_1 ^ z1_7_and_chain_2 ^ z1_7_and_chain_3
                 ^ z1_7_and_chain_4 ^ z1_7_and_chain_5 ^ z1_7_and_chain_6;

  // Compute the value of z1[8].
  assign z1_8_xor_and     = a3[8] ^ (a1[7] & ~a4[7]);
  assign z1_8_and_chain_1 = a4[7] & a1[6] & ~a4[6];
  assign z1_8_and_chain_2 = z1_7_and_chain_1 & a4[7];
  assign z1_8_and_chain_3 = z1_7_and_chain_2 & a4[7];
  assign z1_8_and_chain_4 = z1_7_and_chain_3 & a4[7];
  assign z1_8_and_chain_5 = z1_7_and_chain_4 & a4[7];
  assign z1_8_and_chain_6 = z1_7_and_chain_5 & a4[7];
  assign z1_8_and_chain_7 = z1_7_and_chain_6 & a4[7];
  assign z1[8] = z1_8_xor_and ^ z1_8_and_chain_1 ^ z1_8_and_chain_2 ^ z1_8_and_chain_3
                 ^ z1_8_and_chain_4 ^ z1_8_and_chain_5 ^ z1_8_and_chain_6 ^ z1_8_and_chain_7;

  // Compute the value of z1[9].
  assign z1_9_xor_and     = a3[9] ^ (a1[8] & ~a4[8]);
  assign z1_9_and_chain_1 = a4[8] & a1[7] & ~a4[7];
  assign z1_9_and_chain_2 = z1_8_and_chain_1 & a4[8];
  assign z1_9_and_chain_3 = z1_8_and_chain_2 & a4[8];
  assign z1_9_and_chain_4 = z1_8_and_chain_3 & a4[8];
  assign z1_9_and_chain_5 = z1_8_and_chain_4 & a4[8];
  assign z1_9_and_chain_6 = z1_8_and_chain_5 & a4[8];
  assign z1_9_and_chain_7 = z1_8_and_chain_6 & a4[8];
  assign z1_9_and_chain_8 = z1_8_and_chain_7 & a4[8];
  assign z1[9] = z1_9_xor_and ^ z1_9_and_chain_1 ^ z1_9_and_chain_2 ^ z1_9_and_chain_3
                 ^ z1_9_and_chain_4 ^ z1_9_and_chain_5 ^ z1_9_and_chain_6 ^ z1_9_and_chain_7
                 ^ z1_9_and_chain_8;

  // Compute the value of z1[10].
  assign z1_10_xor_and     = a3[10] ^ (a1[9] & ~a4[9]);
  assign z1_10_and_chain_1 = a4[9] & a1[8] & ~a4[8];
  assign z1_10_and_chain_2 = z1_9_and_chain_1 & a4[9];
  assign z1_10_and_chain_3 = z1_9_and_chain_2 & a4[9];
  assign z1_10_and_chain_4 = z1_9_and_chain_3 & a4[9];
  assign z1_10_and_chain_5 = z1_9_and_chain_4 & a4[9];
  assign z1_10_and_chain_6 = z1_9_and_chain_5 & a4[9];
  assign z1_10_and_chain_7 = z1_9_and_chain_6 & a4[9];
  assign z1_10_and_chain_8 = z1_9_and_chain_7 & a4[9];
  assign z1_10_and_chain_9 = z1_9_and_chain_8 & a4[9];
  assign z1[10] = z1_10_xor_and ^ z1_10_and_chain_1 ^ z1_10_and_chain_2 ^ z1_10_and_chain_3
                 ^ z1_10_and_chain_4 ^ z1_10_and_chain_5 ^ z1_10_and_chain_6 ^ z1_10_and_chain_7
                 ^ z1_10_and_chain_8 ^ z1_10_and_chain_9;

  // Compute the value of z1[11].
  assign z1_11_xor_and      = a3[11] ^ (a1[10] & ~a4[10]);
  assign z1_11_and_chain_1  = a4[10] & a1[9] & ~a4[9];
  assign z1_11_and_chain_2  = z1_10_and_chain_1 & a4[10];
  assign z1_11_and_chain_3  = z1_10_and_chain_2 & a4[10];
  assign z1_11_and_chain_4  = z1_10_and_chain_3 & a4[10];
  assign z1_11_and_chain_5  = z1_10_and_chain_4 & a4[10];
  assign z1_11_and_chain_6  = z1_10_and_chain_5 & a4[10];
  assign z1_11_and_chain_7  = z1_10_and_chain_6 & a4[10];
  assign z1_11_and_chain_8  = z1_10_and_chain_7 & a4[10];
  assign z1_11_and_chain_9  = z1_10_and_chain_8 & a4[10];
  assign z1_11_and_chain_10 = z1_10_and_chain_9 & a4[10];
  assign z1[11] = z1_11_xor_and ^ z1_11_and_chain_1 ^ z1_11_and_chain_2 ^ z1_11_and_chain_3
                 ^ z1_11_and_chain_4 ^ z1_11_and_chain_5 ^ z1_11_and_chain_6 ^ z1_11_and_chain_7
                 ^ z1_11_and_chain_8 ^ z1_11_and_chain_9 ^ z1_11_and_chain_10;

  // Compute the value of z1[12].
  assign z1_12_xor_and      = a3[12] ^ (a1[11] & ~a4[11]);
  assign z1_12_and_chain_1  = a4[11] & a1[10] & ~a4[10];
  assign z1_12_and_chain_2  = z1_11_and_chain_1 & a4[11];
  assign z1_12_and_chain_3  = z1_11_and_chain_2 & a4[11];
  assign z1_12_and_chain_4  = z1_11_and_chain_3 & a4[11];
  assign z1_12_and_chain_5  = z1_11_and_chain_4 & a4[11];
  assign z1_12_and_chain_6  = z1_11_and_chain_5 & a4[11];
  assign z1_12_and_chain_7  = z1_11_and_chain_6 & a4[11];
  assign z1_12_and_chain_8  = z1_11_and_chain_7 & a4[11];
  assign z1_12_and_chain_9  = z1_11_and_chain_8 & a4[11];
  assign z1_12_and_chain_10 = z1_11_and_chain_9 & a4[11];
  assign z1_12_and_chain_11 = z1_11_and_chain_10 & a4[11];
  assign z1[12] = z1_12_xor_and ^ z1_12_and_chain_1 ^ z1_12_and_chain_2 ^ z1_12_and_chain_3
                 ^ z1_12_and_chain_4 ^ z1_12_and_chain_5 ^ z1_12_and_chain_6 ^ z1_12_and_chain_7
                 ^ z1_12_and_chain_8 ^ z1_12_and_chain_9 ^ z1_12_and_chain_10 ^ z1_12_and_chain_11;

  // Compute the value of z1[13].
  assign z1_13_xor_and      = a3[13] ^ (a1[12] & ~a4[12]);
  assign z1_13_and_chain_1  = a4[12] & a1[11] & ~a4[11];
  assign z1_13_and_chain_2  = z1_12_and_chain_1 & a4[12];
  assign z1_13_and_chain_3  = z1_12_and_chain_2 & a4[12];
  assign z1_13_and_chain_4  = z1_12_and_chain_3 & a4[12];
  assign z1_13_and_chain_5  = z1_12_and_chain_4 & a4[12];
  assign z1_13_and_chain_6  = z1_12_and_chain_5 & a4[12];
  assign z1_13_and_chain_7  = z1_12_and_chain_6 & a4[12];
  assign z1_13_and_chain_8  = z1_12_and_chain_7 & a4[12];
  assign z1_13_and_chain_9  = z1_12_and_chain_8 & a4[12];
  assign z1_13_and_chain_10 = z1_12_and_chain_9 & a4[12];
  assign z1_13_and_chain_11 = z1_12_and_chain_10 & a4[12];
  assign z1_13_and_chain_12 = z1_12_and_chain_11 & a4[12];
  assign z1[13] = z1_13_xor_and ^ z1_13_and_chain_1 ^ z1_13_and_chain_2 ^ z1_13_and_chain_3
                 ^ z1_13_and_chain_4 ^ z1_13_and_chain_5 ^ z1_13_and_chain_6 ^ z1_13_and_chain_7
                 ^ z1_13_and_chain_8 ^ z1_13_and_chain_9 ^ z1_13_and_chain_10 ^ z1_13_and_chain_11
                 ^ z1_13_and_chain_12;

  // Compute the value of z1[14].
  assign z1_14_xor_and      = a3[14] ^ (a1[13] & ~a4[13]);
  assign z1_14_and_chain_1  = a4[13] & a1[12] & ~a4[12];
  assign z1_14_and_chain_2  = z1_13_and_chain_1 & a4[13];
  assign z1_14_and_chain_3  = z1_13_and_chain_2 & a4[13];
  assign z1_14_and_chain_4  = z1_13_and_chain_3 & a4[13];
  assign z1_14_and_chain_5  = z1_13_and_chain_4 & a4[13];
  assign z1_14_and_chain_6  = z1_13_and_chain_5 & a4[13];
  assign z1_14_and_chain_7  = z1_13_and_chain_6 & a4[13];
  assign z1_14_and_chain_8  = z1_13_and_chain_7 & a4[13];
  assign z1_14_and_chain_9  = z1_13_and_chain_8 & a4[13];
  assign z1_14_and_chain_10 = z1_13_and_chain_9 & a4[13];
  assign z1_14_and_chain_11 = z1_13_and_chain_10 & a4[13];
  assign z1_14_and_chain_12 = z1_13_and_chain_11 & a4[13];
  assign z1_14_and_chain_13 = z1_13_and_chain_12 & a4[13];
  assign z1[14] = z1_14_xor_and ^ z1_14_and_chain_1 ^ z1_14_and_chain_2 ^ z1_14_and_chain_3
                 ^ z1_14_and_chain_4 ^ z1_14_and_chain_5 ^ z1_14_and_chain_6 ^ z1_14_and_chain_7
                 ^ z1_14_and_chain_8 ^ z1_14_and_chain_9 ^ z1_14_and_chain_10 ^ z1_14_and_chain_11
                 ^ z1_14_and_chain_12 ^ z1_14_and_chain_13;

  // Compute the value of z1[15].
  assign z1_15_xor_and      = a3[15] ^ (a1[14] & ~a4[14]);
  assign z1_15_and_chain_1  = a4[14] & a1[13] & ~a4[13];
  assign z1_15_and_chain_2  = z1_14_and_chain_1 & a4[14];
  assign z1_15_and_chain_3  = z1_14_and_chain_2 & a4[14];
  assign z1_15_and_chain_4  = z1_14_and_chain_3 & a4[14];
  assign z1_15_and_chain_5  = z1_14_and_chain_4 & a4[14];
  assign z1_15_and_chain_6  = z1_14_and_chain_5 & a4[14];
  assign z1_15_and_chain_7  = z1_14_and_chain_6 & a4[14];
  assign z1_15_and_chain_8  = z1_14_and_chain_7 & a4[14];
  assign z1_15_and_chain_9  = z1_14_and_chain_8 & a4[14];
  assign z1_15_and_chain_10 = z1_14_and_chain_9 & a4[14];
  assign z1_15_and_chain_11 = z1_14_and_chain_10 & a4[14];
  assign z1_15_and_chain_12 = z1_14_and_chain_11 & a4[14];
  assign z1_15_and_chain_13 = z1_14_and_chain_12 & a4[14];
  assign z1_15_and_chain_14 = z1_14_and_chain_13 & a4[14];
  assign z1[15] = z1_15_xor_and ^ z1_15_and_chain_1 ^ z1_15_and_chain_2 ^ z1_15_and_chain_3
                 ^ z1_15_and_chain_4 ^ z1_15_and_chain_5 ^ z1_15_and_chain_6 ^ z1_15_and_chain_7
                 ^ z1_15_and_chain_8 ^ z1_15_and_chain_9 ^ z1_15_and_chain_10 ^ z1_15_and_chain_11
                 ^ z1_15_and_chain_12 ^ z1_15_and_chain_13 ^ z1_15_and_chain_14;

  // Compute the value of z1[16].
  assign z1_16_xor_and      = a3[16] ^ (a1[15] & ~a4[15]);
  assign z1_16_and_chain_1  = a4[15] & a1[14] & ~a4[14];
  assign z1_16_and_chain_2  = z1_15_and_chain_1 & a4[15];
  assign z1_16_and_chain_3  = z1_15_and_chain_2 & a4[15];
  assign z1_16_and_chain_4  = z1_15_and_chain_3 & a4[15];
  assign z1_16_and_chain_5  = z1_15_and_chain_4 & a4[15];
  assign z1_16_and_chain_6  = z1_15_and_chain_5 & a4[15];
  assign z1_16_and_chain_7  = z1_15_and_chain_6 & a4[15];
  assign z1_16_and_chain_8  = z1_15_and_chain_7 & a4[15];
  assign z1_16_and_chain_9  = z1_15_and_chain_8 & a4[15];
  assign z1_16_and_chain_10 = z1_15_and_chain_9 & a4[15];
  assign z1_16_and_chain_11 = z1_15_and_chain_10 & a4[15];
  assign z1_16_and_chain_12 = z1_15_and_chain_11 & a4[15];
  assign z1_16_and_chain_13 = z1_15_and_chain_12 & a4[15];
  assign z1_16_and_chain_14 = z1_15_and_chain_13 & a4[15];
  assign z1_16_and_chain_15 = z1_15_and_chain_14 & a4[15];
  assign z1[16] = z1_16_xor_and ^ z1_16_and_chain_1 ^ z1_16_and_chain_2 ^ z1_16_and_chain_3
                 ^ z1_16_and_chain_4 ^ z1_16_and_chain_5 ^ z1_16_and_chain_6 ^ z1_16_and_chain_7
                 ^ z1_16_and_chain_8 ^ z1_16_and_chain_9 ^ z1_16_and_chain_10 ^ z1_16_and_chain_11
                 ^ z1_16_and_chain_12 ^ z1_16_and_chain_13 ^ z1_16_and_chain_14 ^ z1_16_and_chain_15;

  // Compute the value of z1[17].
  assign z1_17_xor_and      = a3[17] ^ (a1[16] & ~a4[16]);
  assign z1_17_and_chain_1  = a4[16] & a1[15] & ~a4[15];
  assign z1_17_and_chain_2  = z1_16_and_chain_1 & a4[16];
  assign z1_17_and_chain_3  = z1_16_and_chain_2 & a4[16];
  assign z1_17_and_chain_4  = z1_16_and_chain_3 & a4[16];
  assign z1_17_and_chain_5  = z1_16_and_chain_4 & a4[16];
  assign z1_17_and_chain_6  = z1_16_and_chain_5 & a4[16];
  assign z1_17_and_chain_7  = z1_16_and_chain_6 & a4[16];
  assign z1_17_and_chain_8  = z1_16_and_chain_7 & a4[16];
  assign z1_17_and_chain_9  = z1_16_and_chain_8 & a4[16];
  assign z1_17_and_chain_10 = z1_16_and_chain_9 & a4[16];
  assign z1_17_and_chain_11 = z1_16_and_chain_10 & a4[16];
  assign z1_17_and_chain_12 = z1_16_and_chain_11 & a4[16];
  assign z1_17_and_chain_13 = z1_16_and_chain_12 & a4[16];
  assign z1_17_and_chain_14 = z1_16_and_chain_13 & a4[16];
  assign z1_17_and_chain_15 = z1_16_and_chain_14 & a4[16];
  assign z1_17_and_chain_16 = z1_16_and_chain_15 & a4[16];
  assign z1[17] = z1_17_xor_and ^ z1_17_and_chain_1 ^ z1_17_and_chain_2 ^ z1_17_and_chain_3
                 ^ z1_17_and_chain_4 ^ z1_17_and_chain_5 ^ z1_17_and_chain_6 ^ z1_17_and_chain_7
                 ^ z1_17_and_chain_8 ^ z1_17_and_chain_9 ^ z1_17_and_chain_10 ^ z1_17_and_chain_11
                 ^ z1_17_and_chain_12 ^ z1_17_and_chain_13 ^ z1_17_and_chain_14 ^ z1_17_and_chain_15
                 ^ z1_17_and_chain_16;

  // Compute the value of z1[18].
  assign z1_18_xor_and      = a3[18] ^ (a1[17] & ~a4[17]);
  assign z1_18_and_chain_1  = a4[17] & a1[16] & ~a4[16];
  assign z1_18_and_chain_2  = z1_17_and_chain_1 & a4[17];
  assign z1_18_and_chain_3  = z1_17_and_chain_2 & a4[17];
  assign z1_18_and_chain_4  = z1_17_and_chain_3 & a4[17];
  assign z1_18_and_chain_5  = z1_17_and_chain_4 & a4[17];
  assign z1_18_and_chain_6  = z1_17_and_chain_5 & a4[17];
  assign z1_18_and_chain_7  = z1_17_and_chain_6 & a4[17];
  assign z1_18_and_chain_8  = z1_17_and_chain_7 & a4[17];
  assign z1_18_and_chain_9  = z1_17_and_chain_8 & a4[17];
  assign z1_18_and_chain_10 = z1_17_and_chain_9 & a4[17];
  assign z1_18_and_chain_11 = z1_17_and_chain_10 & a4[17];
  assign z1_18_and_chain_12 = z1_17_and_chain_11 & a4[17];
  assign z1_18_and_chain_13 = z1_17_and_chain_12 & a4[17];
  assign z1_18_and_chain_14 = z1_17_and_chain_13 & a4[17];
  assign z1_18_and_chain_15 = z1_17_and_chain_14 & a4[17];
  assign z1_18_and_chain_16 = z1_17_and_chain_15 & a4[17];
  assign z1_18_and_chain_17 = z1_17_and_chain_16 & a4[17];
  assign z1[18] = z1_18_xor_and ^ z1_18_and_chain_1 ^ z1_18_and_chain_2 ^ z1_18_and_chain_3
                 ^ z1_18_and_chain_4 ^ z1_18_and_chain_5 ^ z1_18_and_chain_6 ^ z1_18_and_chain_7
                 ^ z1_18_and_chain_8 ^ z1_18_and_chain_9 ^ z1_18_and_chain_10 ^ z1_18_and_chain_11
                 ^ z1_18_and_chain_12 ^ z1_18_and_chain_13 ^ z1_18_and_chain_14 ^ z1_18_and_chain_15
                 ^ z1_18_and_chain_16 ^ z1_18_and_chain_17;

  // Compute the value of z1[19].
  assign z1_19_xor_and      = a3[19] ^ (a1[18] & ~a4[18]);
  assign z1_19_and_chain_1  = a4[18] & a1[17] & ~a4[17];
  assign z1_19_and_chain_2  = z1_18_and_chain_1 & a4[18];
  assign z1_19_and_chain_3  = z1_18_and_chain_2 & a4[18];
  assign z1_19_and_chain_4  = z1_18_and_chain_3 & a4[18];
  assign z1_19_and_chain_5  = z1_18_and_chain_4 & a4[18];
  assign z1_19_and_chain_6  = z1_18_and_chain_5 & a4[18];
  assign z1_19_and_chain_7  = z1_18_and_chain_6 & a4[18];
  assign z1_19_and_chain_8  = z1_18_and_chain_7 & a4[18];
  assign z1_19_and_chain_9  = z1_18_and_chain_8 & a4[18];
  assign z1_19_and_chain_10 = z1_18_and_chain_9 & a4[18];
  assign z1_19_and_chain_11 = z1_18_and_chain_10 & a4[18];
  assign z1_19_and_chain_12 = z1_18_and_chain_11 & a4[18];
  assign z1_19_and_chain_13 = z1_18_and_chain_12 & a4[18];
  assign z1_19_and_chain_14 = z1_18_and_chain_13 & a4[18];
  assign z1_19_and_chain_15 = z1_18_and_chain_14 & a4[18];
  assign z1_19_and_chain_16 = z1_18_and_chain_15 & a4[18];
  assign z1_19_and_chain_17 = z1_18_and_chain_16 & a4[18];
  assign z1_19_and_chain_18 = z1_18_and_chain_17 & a4[18];
  assign z1[19] = z1_19_xor_and ^ z1_19_and_chain_1 ^ z1_19_and_chain_2 ^ z1_19_and_chain_3
                 ^ z1_19_and_chain_4 ^ z1_19_and_chain_5 ^ z1_19_and_chain_6 ^ z1_19_and_chain_7
                 ^ z1_19_and_chain_8 ^ z1_19_and_chain_9 ^ z1_19_and_chain_10 ^ z1_19_and_chain_11
                 ^ z1_19_and_chain_12 ^ z1_19_and_chain_13 ^ z1_19_and_chain_14 ^ z1_19_and_chain_15
                 ^ z1_19_and_chain_16 ^ z1_19_and_chain_17 ^ z1_19_and_chain_18;

  // Compute the value of z1[20].
  assign z1_20_xor_and      = a3[20] ^ (a1[19] & ~a4[19]);
  assign z1_20_and_chain_1  = a4[19] & a1[18] & ~a4[18];
  assign z1_20_and_chain_2  = z1_19_and_chain_1 & a4[19];
  assign z1_20_and_chain_3  = z1_19_and_chain_2 & a4[19];
  assign z1_20_and_chain_4  = z1_19_and_chain_3 & a4[19];
  assign z1_20_and_chain_5  = z1_19_and_chain_4 & a4[19];
  assign z1_20_and_chain_6  = z1_19_and_chain_5 & a4[19];
  assign z1_20_and_chain_7  = z1_19_and_chain_6 & a4[19];
  assign z1_20_and_chain_8  = z1_19_and_chain_7 & a4[19];
  assign z1_20_and_chain_9  = z1_19_and_chain_8 & a4[19];
  assign z1_20_and_chain_10 = z1_19_and_chain_9 & a4[19];
  assign z1_20_and_chain_11 = z1_19_and_chain_10 & a4[19];
  assign z1_20_and_chain_12 = z1_19_and_chain_11 & a4[19];
  assign z1_20_and_chain_13 = z1_19_and_chain_12 & a4[19];
  assign z1_20_and_chain_14 = z1_19_and_chain_13 & a4[19];
  assign z1_20_and_chain_15 = z1_19_and_chain_14 & a4[19];
  assign z1_20_and_chain_16 = z1_19_and_chain_15 & a4[19];
  assign z1_20_and_chain_17 = z1_19_and_chain_16 & a4[19];
  assign z1_20_and_chain_18 = z1_19_and_chain_17 & a4[19];
  assign z1_20_and_chain_19 = z1_19_and_chain_18 & a4[19];
  assign z1[20] = z1_20_xor_and ^ z1_20_and_chain_1 ^ z1_20_and_chain_2 ^ z1_20_and_chain_3
                 ^ z1_20_and_chain_4 ^ z1_20_and_chain_5 ^ z1_20_and_chain_6 ^ z1_20_and_chain_7
                 ^ z1_20_and_chain_8 ^ z1_20_and_chain_9 ^ z1_20_and_chain_10 ^ z1_20_and_chain_11
                 ^ z1_20_and_chain_12 ^ z1_20_and_chain_13 ^ z1_20_and_chain_14 ^ z1_20_and_chain_15
                 ^ z1_20_and_chain_16 ^ z1_20_and_chain_17 ^ z1_20_and_chain_18 ^ z1_20_and_chain_19;

  // Compute the value of z1[21].
  assign z1_21_xor_and      = a3[21] ^ (a1[20] & ~a4[20]);
  assign z1_21_and_chain_1  = a4[20] & a1[19] & ~a4[19];
  assign z1_21_and_chain_2  = z1_20_and_chain_1 & a4[20];
  assign z1_21_and_chain_3  = z1_20_and_chain_2 & a4[20];
  assign z1_21_and_chain_4  = z1_20_and_chain_3 & a4[20];
  assign z1_21_and_chain_5  = z1_20_and_chain_4 & a4[20];
  assign z1_21_and_chain_6  = z1_20_and_chain_5 & a4[20];
  assign z1_21_and_chain_7  = z1_20_and_chain_6 & a4[20];
  assign z1_21_and_chain_8  = z1_20_and_chain_7 & a4[20];
  assign z1_21_and_chain_9  = z1_20_and_chain_8 & a4[20];
  assign z1_21_and_chain_10 = z1_20_and_chain_9 & a4[20];
  assign z1_21_and_chain_11 = z1_20_and_chain_10 & a4[20];
  assign z1_21_and_chain_12 = z1_20_and_chain_11 & a4[20];
  assign z1_21_and_chain_13 = z1_20_and_chain_12 & a4[20];
  assign z1_21_and_chain_14 = z1_20_and_chain_13 & a4[20];
  assign z1_21_and_chain_15 = z1_20_and_chain_14 & a4[20];
  assign z1_21_and_chain_16 = z1_20_and_chain_15 & a4[20];
  assign z1_21_and_chain_17 = z1_20_and_chain_16 & a4[20];
  assign z1_21_and_chain_18 = z1_20_and_chain_17 & a4[20];
  assign z1_21_and_chain_19 = z1_20_and_chain_18 & a4[20];
  assign z1_21_and_chain_20 = z1_20_and_chain_19 & a4[20];
  assign z1[21] = z1_21_xor_and ^ z1_21_and_chain_1 ^ z1_21_and_chain_2 ^ z1_21_and_chain_3
                 ^ z1_21_and_chain_4 ^ z1_21_and_chain_5 ^ z1_21_and_chain_6 ^ z1_21_and_chain_7
                 ^ z1_21_and_chain_8 ^ z1_21_and_chain_9 ^ z1_21_and_chain_10 ^ z1_21_and_chain_11
                 ^ z1_21_and_chain_12 ^ z1_21_and_chain_13 ^ z1_21_and_chain_14 ^ z1_21_and_chain_15
                 ^ z1_21_and_chain_16 ^ z1_21_and_chain_17 ^ z1_21_and_chain_18 ^ z1_21_and_chain_19
                 ^ z1_21_and_chain_20;

  // Compute the value of z1[22].
  assign z1_22_xor_and      = a3[22] ^ (a1[21] & ~a4[21]);
  assign z1_22_and_chain_1  = a4[21] & a1[20] & ~a4[20];
  assign z1_22_and_chain_2  = z1_21_and_chain_1 & a4[21];
  assign z1_22_and_chain_3  = z1_21_and_chain_2 & a4[21];
  assign z1_22_and_chain_4  = z1_21_and_chain_3 & a4[21];
  assign z1_22_and_chain_5  = z1_21_and_chain_4 & a4[21];
  assign z1_22_and_chain_6  = z1_21_and_chain_5 & a4[21];
  assign z1_22_and_chain_7  = z1_21_and_chain_6 & a4[21];
  assign z1_22_and_chain_8  = z1_21_and_chain_7 & a4[21];
  assign z1_22_and_chain_9  = z1_21_and_chain_8 & a4[21];
  assign z1_22_and_chain_10 = z1_21_and_chain_9 & a4[21];
  assign z1_22_and_chain_11 = z1_21_and_chain_10 & a4[21];
  assign z1_22_and_chain_12 = z1_21_and_chain_11 & a4[21];
  assign z1_22_and_chain_13 = z1_21_and_chain_12 & a4[21];
  assign z1_22_and_chain_14 = z1_21_and_chain_13 & a4[21];
  assign z1_22_and_chain_15 = z1_21_and_chain_14 & a4[21];
  assign z1_22_and_chain_16 = z1_21_and_chain_15 & a4[21];
  assign z1_22_and_chain_17 = z1_21_and_chain_16 & a4[21];
  assign z1_22_and_chain_18 = z1_21_and_chain_17 & a4[21];
  assign z1_22_and_chain_19 = z1_21_and_chain_18 & a4[21];
  assign z1_22_and_chain_20 = z1_21_and_chain_19 & a4[21];
  assign z1_22_and_chain_21 = z1_21_and_chain_20 & a4[21];
  assign z1[22] = z1_22_xor_and ^ z1_22_and_chain_1 ^ z1_22_and_chain_2 ^ z1_22_and_chain_3
                 ^ z1_22_and_chain_4 ^ z1_22_and_chain_5 ^ z1_22_and_chain_6 ^ z1_22_and_chain_7
                 ^ z1_22_and_chain_8 ^ z1_22_and_chain_9 ^ z1_22_and_chain_10 ^ z1_22_and_chain_11
                 ^ z1_22_and_chain_12 ^ z1_22_and_chain_13 ^ z1_22_and_chain_14 ^ z1_22_and_chain_15
                 ^ z1_22_and_chain_16 ^ z1_22_and_chain_17 ^ z1_22_and_chain_18 ^ z1_22_and_chain_19
                 ^ z1_22_and_chain_20 ^ z1_22_and_chain_21;

  // Compute the value of z1[23].
  assign z1_23_xor_and      = a3[23] ^ (a1[22] & ~a4[22]);
  assign z1_23_and_chain_1  = a4[22] & a1[21] & ~a4[21];
  assign z1_23_and_chain_2  = z1_22_and_chain_1 & a4[22];
  assign z1_23_and_chain_3  = z1_22_and_chain_2 & a4[22];
  assign z1_23_and_chain_4  = z1_22_and_chain_3 & a4[22];
  assign z1_23_and_chain_5  = z1_22_and_chain_4 & a4[22];
  assign z1_23_and_chain_6  = z1_22_and_chain_5 & a4[22];
  assign z1_23_and_chain_7  = z1_22_and_chain_6 & a4[22];
  assign z1_23_and_chain_8  = z1_22_and_chain_7 & a4[22];
  assign z1_23_and_chain_9  = z1_22_and_chain_8 & a4[22];
  assign z1_23_and_chain_10 = z1_22_and_chain_9 & a4[22];
  assign z1_23_and_chain_11 = z1_22_and_chain_10 & a4[22];
  assign z1_23_and_chain_12 = z1_22_and_chain_11 & a4[22];
  assign z1_23_and_chain_13 = z1_22_and_chain_12 & a4[22];
  assign z1_23_and_chain_14 = z1_22_and_chain_13 & a4[22];
  assign z1_23_and_chain_15 = z1_22_and_chain_14 & a4[22];
  assign z1_23_and_chain_16 = z1_22_and_chain_15 & a4[22];
  assign z1_23_and_chain_17 = z1_22_and_chain_16 & a4[22];
  assign z1_23_and_chain_18 = z1_22_and_chain_17 & a4[22];
  assign z1_23_and_chain_19 = z1_22_and_chain_18 & a4[22];
  assign z1_23_and_chain_20 = z1_22_and_chain_19 & a4[22];
  assign z1_23_and_chain_21 = z1_22_and_chain_20 & a4[22];
  assign z1_23_and_chain_22 = z1_22_and_chain_21 & a4[22];
  assign z1[23] = z1_23_xor_and ^ z1_23_and_chain_1 ^ z1_23_and_chain_2 ^ z1_23_and_chain_3
                 ^ z1_23_and_chain_4 ^ z1_23_and_chain_5 ^ z1_23_and_chain_6 ^ z1_23_and_chain_7
                 ^ z1_23_and_chain_8 ^ z1_23_and_chain_9 ^ z1_23_and_chain_10 ^ z1_23_and_chain_11
                 ^ z1_23_and_chain_12 ^ z1_23_and_chain_13 ^ z1_23_and_chain_14 ^ z1_23_and_chain_15
                 ^ z1_23_and_chain_16 ^ z1_23_and_chain_17 ^ z1_23_and_chain_18 ^ z1_23_and_chain_19
                 ^ z1_23_and_chain_20 ^ z1_23_and_chain_21 ^ z1_23_and_chain_22;

  // Assign outputs
  assign z1_o = z1;
  assign z2_o = {1'b0, a2};
  
endmodule
