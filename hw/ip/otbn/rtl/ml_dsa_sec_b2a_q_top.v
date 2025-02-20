module ml_dsa_sec_b2a_q_top (
  input wire  CLK100MHZ,
  input wire  ck_rst,

// ready and valid signals
  inout wire [3:0] qspi_dq,

// z
  output wire ck_io0,
  output wire ck_io1,
  output wire ck_io2,
  output wire ck_io3,
  output wire ck_io4,
  output wire ck_io5,
  output wire ck_io6,
  output wire ck_io7,
  output wire ck_io8,
  output wire ck_io9,
  output wire ck_io10,
  output wire ck_io11,
  output wire ck_io12,
  output wire ck_io13,
  output wire ck_io26,
  output wire ck_io27,
  output wire ck_io28,
  output wire ck_io29,
  output wire ck_io30,
  output wire ck_io31,
  output wire ck_io32,
  output wire ck_io33,
  output wire ck_io34,

// x0
  input wire ck_io35,
  input wire ck_io36,
  input wire ck_io37,
  input wire ck_io38,
  input wire ck_io39,
  input wire ck_io40,
  input wire ck_io41,
  inout wire [7:0] ja,
  inout wire [7:0] jb,
  
//  x1
  input wire ck_a0,
  input wire ck_a1,
  input wire ck_a2,
  input wire ck_a3,
  input wire ck_a4,
  input wire ck_a5,
  input wire vaux12_p,
  input wire vaux12_n,
  input wire vaux13_p,
  input wire vaux13_n,
  input wire vaux14_p,
  input wire vaux14_n,
  input wire ck_a6,
  input wire ck_a7,
  input wire ck_a8,
  input wire ck_a9,
  input wire ck_a10,
  input wire ck_a11,
  input wire ck_miso,
  input wire ck_mosi,
  input wire ck_sck,
  input wire ck_ss,
  input wire ck_scl,
  input wire ck_sda,

// gamma
  input wire [7:0] jc,
  input wire [3:0] eth_rxd,
  input wire [3:0] eth_txd,

// r
  input wire [7:0] jd
 );

  localparam ShareWidth = 23;
  localparam RandWidth  = 80;
  localparam Modulus    = 8380417;

  wire [ShareWidth-1:0] z, z0, z1, x0, x1;
  wire [ShareWidth:0] gamma;
  wire [RandWidth-1:0] r;

  assign z = z0 ^ z1;
  assign x1 = {ck_a0, ck_a1, ck_a2, ck_a3, ck_a4, ck_a5,
               vaux12_p, vaux12_n, vaux13_p, vaux13_n, vaux14_p, vaux14_n,
               ck_a6, ck_a7, ck_a8, ck_a9, ck_a10, ck_a11, ck_miso, ck_mosi,
               ck_sck, ck_ss, ck_scl, ck_sda};
  assign x0 = {ck_io35, ck_io36, ck_io37, ck_io38, ck_io39, ck_io40, ck_io41, ja, jb};
  assign gamma = {jc, jc, eth_rxd, eth_txd};
  assign r = {10{jd}};

  ml_dsa_sec_b2a_q #(
    .ShareWidth(ShareWidth),
    .RandWidth(RandWidth),
    .Modulus(Modulus)
  ) i_ml_dsa_sec_b2a_q (
    .clk_i(CLK100MHZ),
    .rst_ni(ck_rst),
    .valid_i(qspi_dq[0]),
    .ready_o(qspi_dq[1]),
    .valid_o(qspi_dq[2]),
    .ready_i(qspi_dq[3]),
    .x0_i(x0),
    .x1_i(x1),
    .gamma_i(gamma[ShareWidth-1:0]),
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