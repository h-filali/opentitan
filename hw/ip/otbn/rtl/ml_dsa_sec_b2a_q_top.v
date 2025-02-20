module ml_dsa_sec_b2a_q_top (
  input wire  CLK100MHZ,
  input wire  ck_rst,

  inout wire [3:0] qspi_dq,

  inout wire [3:0] eth_rxd,
  inout wire [3:0] eth_txd,

  input wire ck_io0,
  input wire ck_io1,
  input wire ck_io2,
  input wire ck_io3,
  input wire ck_io4,
  input wire ck_io5,
  input wire ck_io6,
  input wire ck_io7,
  input wire ck_io8,
  input wire ck_io9,
  input wire ck_io10,
  input wire ck_io11,
  input wire ck_io12,
  input wire ck_io13,

  input wire ck_io26,
  input wire ck_io27,
  input wire ck_io28,
  input wire ck_io29,
  input wire ck_io30,
  input wire ck_io31,
  input wire ck_io32,
  input wire ck_io33,
  input wire ck_io34,
  input wire ck_io35,
  input wire ck_io36,
  input wire ck_io37,
  input wire ck_io38,
  input wire ck_io39,
  input wire ck_io40,
  input wire ck_io41,

  inout wire [7:0] ja,
  inout wire [7:0] jb,
  inout wire [7:0] jc,
  inout wire [7:0] jd
 );

  localparam ShareWidth = 23;
  localparam RandWidth  = 80;
  localparam Modulus    = 8380417;
  localparam Mask       = 23'h12C001;

  wire [ShareWidth-1:0] z, z0, z1, x0, x1, gamma;
  wire [RandWidth-1:0] r;

  assign z = z0 ^ z1;
  assign x1 = x0 ^ Mask;
  assign x0 = {ck_io35, ck_io36, ck_io37, ck_io38, ck_io39, ck_io40, ck_io41, ja, jb};
  assign gamma = {jc[6:0], 2{jc}};
  assign r = {10{jd}};

  ml_dsa_sec_b2a_q #(
    .ShareWidth,
    .RandWidth,
    .Modulus
  ) i_ml_dsa_sec_b2a_q (
    .clk_i(CLK100MHZ),
    .rst_ni(ck_rst),
    .valid_i(qspi_dq[0]),
    .ready_o(qspi_dq[1]),
    .valid_o(qspi_dq[2]),
    .ready_i(qspi_dq[3]),
    .x0_i(x0),
    .x1_i(x1),
    .gamma_i(gamma),
    .r_i(r),
    .z0_o(z0),
    .z1_o(z1)
  );

  // Assign outputs.
  assign ck_io0 = z[0];
  assign ck_io1 = z[1];
  assign ck_io2 = z[2];
  assign ck_io3 = z[3];
  assign ck_io4 = z[4];
  assign ck_io5 = z[5];
  assign ck_io6 = z[6];
  assign ck_io7 = z[7];
  assign ck_io8 = z[8];
  assign ck_io9 = z[9];
  assign ck_io10 = z[10];
  assign ck_io11 = z[11];
  assign ck_io12 = z[12];
  assign ck_io13 = z[13];
  assign ck_io26 = z[14];
  assign ck_io27 = z[15];
  assign ck_io28 = z[16];
  assign ck_io29 = z[17];
  assign ck_io30 = z[18];
  assign ck_io31 = z[19];
  assign ck_io32 = z[20];
  assign ck_io33 = z[21];
  assign ck_io34 = z[22];

endmodule