module ml_dsa_clk_rst_gen #(
    parameter time     ClkPeriod,
    parameter unsigned RstClkCycles
) (
    output logic clk_o,
    output logic rst_no
);

  timeunit 1ns;
  timeprecision 10ps;

  logic clk;

  // Clock Generation
  initial begin
    clk = 1'b0;
  end
  always begin
    #(ClkPeriod/2);
    clk = ~clk;
  end
  assign clk_o = clk;

  // Reset Generation
  ml_dsa_rst_gen #(
    .RstClkCycles(RstClkCycles)
  ) i_ml_dsa_rst_gen (
    .clk_i (clk),
    .rst_ni(1'b1),
    .rst_o (),
    .rst_no(rst_no)
  );

endmodule
