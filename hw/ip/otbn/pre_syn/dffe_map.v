// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// Techmap rules applied BEFORE the standard techmap pass to prevent Yosys
// from emitting $_SDFFE_*_ / $_SDFF_*_ primitives that MaskVerif does not
// support.  Behavioral $sdff / $sdffe / $dffe / $adffe cells are lowered here
// to plain $dff / $adff + combinational ($mux), which the standard techmap
// then maps to $_DFF_P_ / $_DFF_PP0_ / $_DFF_PN0_ + $_MUX_, and abc -g AND
// further reduces the combinational part to $_AND_ + $_NOT_.

// -------------------------------------------------------------------------
// $dffe  – DFF with synchronous enable, no reset
// -------------------------------------------------------------------------
module $dffe (CLK, EN, D, Q);
  parameter WIDTH = 1;
  parameter CLK_POLARITY = 1;
  parameter EN_POLARITY  = 1;

  input CLK;
  input EN;
  input  [WIDTH-1:0] D;
  output [WIDTH-1:0] Q;

  wire [WIDTH-1:0] d_in;

  generate
    if (EN_POLARITY == 1)
      assign d_in = EN ? D : Q;   // capture D when EN=1
    else
      assign d_in = EN ? Q : D;   // capture D when EN=0 (active-low)
  endgenerate

  $dff #(.WIDTH(WIDTH), .CLK_POLARITY(CLK_POLARITY)) ff (.CLK(CLK), .D(d_in), .Q(Q));
endmodule

// -------------------------------------------------------------------------
// $sdff  – DFF with synchronous reset, no enable
// -------------------------------------------------------------------------
module $sdff (CLK, SRST, D, Q);
  parameter WIDTH = 1;
  parameter CLK_POLARITY  = 1;
  parameter SRST_POLARITY = 1;
  parameter [WIDTH-1:0] SRST_VALUE = {WIDTH{1'b0}};

  input CLK;
  input SRST;
  input  [WIDTH-1:0] D;
  output [WIDTH-1:0] Q;

  wire [WIDTH-1:0] d_in;

  generate
    if (SRST_POLARITY == 1)
      assign d_in = SRST ? SRST_VALUE : D;
    else
      assign d_in = SRST ? D : SRST_VALUE;
  endgenerate

  $dff #(.WIDTH(WIDTH), .CLK_POLARITY(CLK_POLARITY)) ff (.CLK(CLK), .D(d_in), .Q(Q));
endmodule

// -------------------------------------------------------------------------
// $sdffe  – DFF with synchronous reset AND synchronous enable
// -------------------------------------------------------------------------
module $sdffe (CLK, EN, SRST, D, Q);
  parameter WIDTH = 1;
  parameter CLK_POLARITY  = 1;
  parameter EN_POLARITY   = 1;
  parameter SRST_POLARITY = 1;
  parameter [WIDTH-1:0] SRST_VALUE = {WIDTH{1'b0}};

  input CLK;
  input EN;
  input SRST;
  input  [WIDTH-1:0] D;
  output [WIDTH-1:0] Q;

  wire [WIDTH-1:0] d_en, d_in;

  // Enable mux: select D or hold Q
  generate
    if (EN_POLARITY == 1)
      assign d_en = EN ? D : Q;
    else
      assign d_en = EN ? Q : D;
  endgenerate

  // Reset mux: override with SRST_VALUE when reset asserted (reset has priority)
  generate
    if (SRST_POLARITY == 1)
      assign d_in = SRST ? SRST_VALUE : d_en;
    else
      assign d_in = SRST ? d_en : SRST_VALUE;
  endgenerate

  $dff #(.WIDTH(WIDTH), .CLK_POLARITY(CLK_POLARITY)) ff (.CLK(CLK), .D(d_in), .Q(Q));
endmodule

// -------------------------------------------------------------------------
// $adffe  – DFF with async reset AND synchronous enable
// -------------------------------------------------------------------------
module $adffe (CLK, ARST, EN, D, Q);
  parameter WIDTH = 1;
  parameter CLK_POLARITY  = 1;
  parameter EN_POLARITY   = 1;
  parameter ARST_POLARITY = 1;
  parameter [WIDTH-1:0] ARST_VALUE = {WIDTH{1'b0}};

  input CLK;
  input ARST;
  input EN;
  input  [WIDTH-1:0] D;
  output [WIDTH-1:0] Q;

  wire [WIDTH-1:0] d_in;

  generate
    if (EN_POLARITY == 1)
      assign d_in = EN ? D : Q;
    else
      assign d_in = EN ? Q : D;
  endgenerate

  $adff #(
    .WIDTH(WIDTH), .CLK_POLARITY(CLK_POLARITY),
    .ARST_POLARITY(ARST_POLARITY), .ARST_VALUE(ARST_VALUE)
  ) ff (.CLK(CLK), .ARST(ARST), .D(d_in), .Q(Q));
endmodule
