(* DONT_TOUCH = "yes" *)
module prim_hpc3 #(
  parameter  bit EnW = 1'b0,
  localparam int NumShares = 2
) (
  input clk_i,
  input rst_ni,

  input  logic en_i,
  input  logic x_i[NumShares],
  input  logic y_i[NumShares],
  input  logic w_i[NumShares],
  input  logic r_i,
  input  logic rp_i,
  output logic z_o[NumShares]
);

  logic x[NumShares];
  prim_buf #(
    .Width(2)
  ) u_prim_buf_x (
    .in_i ('{x_i[0], x_i[1]}),
    .out_o('{x[0], x[1]})
  );

  logic y[NumShares];
  prim_buf #(
    .Width(2)
  ) u_prim_buf_y (
    .in_i ('{y_i[0], y_i[1]}),
    .out_o('{y[0], y[1]})
  );

  logic w[NumShares];
  prim_buf #(
    .Width(2)
  ) u_prim_buf_w (
    .in_i ('{w_i[0], w_i[1]}),
    .out_o('{w[0], w[1]})
  );

  logic r;
  prim_buf #(
    .Width(1)
  ) u_prim_buf_r (
    .in_i (r_i),
    .out_o(r)
  );

  logic rp;
  prim_buf #(
    .Width(1)
  ) u_prim_buf_rp (
    .in_i (rp_i),
    .out_o(rp)
  );

  logic p_inner_and[NumShares];
  logic p_inner_xor_w[NumShares];
  logic p_inner_d[NumShares];
  logic p_inner_q[NumShares];
  logic p_cross[NumShares];
  logic x_q[NumShares];
  logic y_masked_d[NumShares];
  logic y_masked_q[NumShares];

  // always_comb begin
  //   for (int i = 0; i < NumShares; i++) begin
  //     int j = (i == 0) ? 1 : 0;
  //     y_masked_d[i] = y[i] ^ r;
  //     p_inner_d[i] = w[i] ^ (x[i] & y_masked_d[i]) ^ rp;
  //     p_cross[i] = x_q[i] & y_masked_q[j];
  //     z[i] = p_inner_q[i] ^ p_cross[i];
  //   end
  // end

  // y_masked_d[i] = y[i] ^ r;
  for (genvar i = 0; i < NumShares; i++) begin : gen_y_masked
    prim_xor2 #(
      .Width(1)
    ) u_prim_xor2 (
      .in0_i(y[i]),
      .in1_i(r),
      .out_o(y_masked_d[i])
    );
  end

  prim_flop_en #(
    .Width      ( 2),
    .ResetValue ('0)
  ) u_prim_flop_en_y_masked (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .en_i(en_i),
    .d_i('{y_masked_d[0], y_masked_d[1]}),
    .q_o('{y_masked_q[0], y_masked_q[1]})
  );

  // p_inner_d[i] = w[i] ^ (x[i] & y_masked_d[i]) ^ rp;
  for (genvar i = 0; i < NumShares; i++) begin : gen_p_inner_and
    prim_and2 #(
      .Width(1)
    ) u_prim_and2 (
      .in0_i(x[i]),
      .in1_i(y_masked_d[i]),
      .out_o(p_inner_and[i])
    );
  end

  if (EnW) begin : gen_xor_w
    for (genvar i = 0; i < NumShares; i++) begin : gen_p_inner
      prim_xor2 #(
        .Width(1)
      ) u_prim_xor2_w (
        .in0_i(p_inner_and[i]),
        .in1_i(w[i]),
        .out_o(p_inner_xor_w[i])
      );

      prim_xor2 #(
        .Width(1)
      ) u_prim_xor2_d (
        .in0_i(p_inner_xor_w[i]),
        .in1_i(rp),
        .out_o(p_inner_d[i])
      );
    end
  end else begin : gen_no_xor_w
    for (genvar i = 0; i < NumShares; i++) begin : gen_p_inner
      prim_xor2 #(
        .Width(1)
      ) u_prim_xor2_x_masked (
        .in0_i(p_inner_and[i]),
        .in1_i(rp),
        .out_o(p_inner_d[i])
      );
    end
  end

  prim_flop_en #(
    .Width      ( 2),
    .ResetValue ('0)
  ) u_prim_flop_en_p_inner (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .en_i(en_i),
    .d_i('{p_inner_d[0], p_inner_d[1]}),
    .q_o('{p_inner_q[0], p_inner_q[1]})
  );

  // p_cross[i] = x_q[i] & y_masked_q[j];
  prim_flop_en #(
    .Width      ( 2),
    .ResetValue ('0)
  ) u_prim_flop_en_x (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .en_i(en_i),
    .d_i('{x[0], x[1]}),
    .q_o('{x_q[0], x_q[1]})
  );

  for (genvar i = 0; i < NumShares; i++) begin : gen_p_cross
    int j = (i == 0) ? 1 : 0;

    prim_and2 #(
      .Width(1)
    ) u_prim_and2 (
      .in0_i(x_q[i]),
      .in1_i(y_masked_q[j]),
      .out_o(p_cross[i])
    );
  end

  // z_o[i] = p_inner_q[i] ^ p_cross[i];
  for (genvar i = 0; i < NumShares; i++) begin : gen_z
    prim_xor2 #(
      .Width(1)
    ) u_prim_xor2 (
      .in0_i(p_inner_q[i]),
      .in1_i(p_cross[i]),
      .out_o(z_o[i])
    );
  end

  if (EnW == 1'b0) begin
    logic unused_w;
    always_comb begin
      unused_w = 1'b0;
      for (int i = 0; i < NumShares; i++) begin : gen_unused_w
        unused_w ^= w[i];
        unused_w ^= p_inner_xor_w[i];
      end
    end
  end

endmodule // prim_hpc3
