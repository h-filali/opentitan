module prim_sharewise_xor #(
  parameter int Width     = 32,
  parameter bit PipeReg   = 1,
  parameter int NumShares = 2
) (
  input clk_i,
  input rst_ni,

  input  logic en_i,
  input  logic [Width-1:0] x_i[NumShares],
  input  logic [Width-1:0] y_i[NumShares],
  output logic [Width-1:0] z_o[NumShares]
);

  logic [Width-1:0] z_d[NumShares];

  always_comb begin
    for (int s = 0; s < NumShares; s++) begin
      z_d[s] = x_i[s] ^ y_i[s];
    end
  end

  if (PipeReg) begin : gen_pipe_reg
    for (genvar s = 0; s < NumShares; s++) begin: gen_flop_shares
      prim_flop_en #(
        .Width      (Width),
        .ResetValue ('0)
      ) u_prim_flop_en_x (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .en_i(en_i),
        .d_i(z_d[s]),
        .q_o(z_o[s])
      );
    end
  end else begin : gen_no_pipe
    assign z_o = z_d;
  end

endmodule // prim_sharewise_xor
