(* DONT_TOUCH = "yes" *)
module prim_hpc2 #(
  parameter  bit EnW = 1'b0,
  localparam int NumShares = 2
) (
  input clk_i,
  input rst_ni,

  input  logic en1_i,
  input  logic en2_i,
  input  logic x_i[NumShares],
  input  logic y_i[NumShares],
  input  logic w_i[NumShares],
  input  logic r_i,
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

  logic x_inv[NumShares];
  logic p_inner_x_masked_d[NumShares];
  logic p_inner_x_masked_q[NumShares];
  logic p_inner_and_d[NumShares];
  logic p_inner_and_q[NumShares];
  logic p_inner_xor_w[NumShares];
  logic p_inner_d[NumShares];
  logic p_inner_q[NumShares];
  logic p_cross_d[NumShares];
  logic p_cross_q[NumShares];
  logic r_q;
  logic y_q[NumShares];
  logic y_masked_d[NumShares];
  logic y_masked_q[NumShares];

  // always_comb begin
  //   for (genvar i = 0; i < NumShares; i++) begin
  //     int j = (i == 0) ? 1 : 0;
  //     y_masked_d[i] = y[i] ^ r;
  //     p_inner_d[i] = (x[i] & y_q[i]) ^ (~x[i] & r_q);
  //     p_cross_d[i] = x[i] & y_masked_q[j];
  //     z[i] = p_inner_q[i] ^ p_cross_q[i];
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
    .en_i(en1_i),
    .d_i('{y_masked_d[0], y_masked_d[1]}),
    .q_o('{y_masked_q[0], y_masked_q[1]})
  );

  // p_inner_d[i] = w[i] ^ (x[i] & y_q[i]) ^ (~x[i] & r_q);
  prim_flop_en #(
    .Width      ( 1),
    .ResetValue ('0)
  ) u_prim_flop_en_r (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .en_i(en1_i),
    .d_i(r),
    .q_o(r_q)
  );

  prim_flop_en #(
    .Width      ( 2),
    .ResetValue ('0)
  ) u_prim_flop_en_y (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .en_i(en1_i),
    .d_i('{y[0], y[1]}),
    .q_o('{y_q[0], y_q[1]})
  );

  for (genvar i = 0; i < NumShares; i++) begin : gen_p_inner_and
    prim_and2 #(
      .Width(1)
    ) u_prim_and2 (
      .in0_i(x[i]),
      .in1_i(y_q[i]),
      .out_o(p_inner_and_d[i])
    );

    prim_inv #(
      .Width(1)
    ) prim_inv_x (
      .in_i(x[i]),
      .out_o(x_inv[i])
    );

    prim_and2 #(
      .Width(1)
    ) u_prim_and2_x_masked (
      .in0_i(x_inv[i]),
      .in1_i(r_q),
      .out_o(p_inner_x_masked_d[i])
    );
  end

  if (EnW) begin : gen_xor_w
    for (genvar i = 0; i < NumShares; i++) begin : gen_p_inner
      prim_xor2 #(
        .Width(1)
      ) u_prim_xor2_w (
        .in0_i(p_inner_and_d[i]),
        .in1_i(w[i]),
        .out_o(p_inner_xor_w[i])
      );

      prim_xor2 #(
        .Width(1)
      ) u_prim_xor2_d (
        .in0_i(p_inner_xor_w[i]),
        .in1_i(p_inner_x_masked_d[i]),
        .out_o(p_inner_d[i])
      );
    end

    prim_flop_en #(
      .Width      ( 2),
      .ResetValue ('0)
    ) u_prim_flop_en_p_inner (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .en_i(en2_i),
      .d_i('{p_inner_d[0], p_inner_d[1]}),
      .q_o('{p_inner_q[0], p_inner_q[1]})
    );
  end else begin : gen_no_xor_w
    prim_flop_en #(
      .Width      ( 2),
      .ResetValue ('0)
    ) u_prim_flop_en_p_inner_and (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .en_i(en2_i),
      .d_i('{p_inner_and_d[0], p_inner_and_d[1]}),
      .q_o('{p_inner_and_q[0], p_inner_and_q[1]})
    );

    prim_flop_en #(
      .Width      ( 2),
      .ResetValue ('0)
    ) u_prim_flop_en_p_inner_x_masked (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .en_i(en2_i),
      .d_i('{p_inner_x_masked_d[0], p_inner_x_masked_d[1]}),
      .q_o('{p_inner_x_masked_q[0], p_inner_x_masked_q[1]})
    );

    for (genvar i = 0; i < NumShares; i++) begin : gen_p_inner
      prim_xor2 #(
        .Width(1)
      ) u_prim_xor2_d (
        .in0_i(p_inner_x_masked_q[i]),
        .in1_i(p_inner_and_q[i]),
        .out_o(p_inner_q[i])
      );
    end
  end

  // p_cross_d[i] = x[i] & y_masked_q[j];
  for (genvar i = 0; i < NumShares; i++) begin : gen_p_cross
    localparam int j = (i == 0) ? 1 : 0;

    prim_and2 #(
      .Width(1)
    ) u_prim_and2 (
      .in0_i(x[i]),
      .in1_i(y_masked_q[j]),
      .out_o(p_cross_d[i])
    );
  end

  prim_flop_en #(
    .Width      ( 2),
    .ResetValue ('0)
  ) u_prim_flop_en_p_cross (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .en_i(en2_i),
    .d_i('{p_cross_d[0], p_cross_d[1]}),
    .q_o('{p_cross_q[0], p_cross_q[1]})
  );

  // z_o[i] = p_inner[i] ^ p_cross_q[i];
  for (genvar i = 0; i < NumShares; i++) begin : gen_z
    prim_xor2 #(
      .Width(1)
    ) u_prim_xor2 (
      .in0_i(p_inner_q[i]),
      .in1_i(p_cross_q[i]),
      .out_o(z_o[i])
    );
  end

  if (EnW == 1'b0) begin : gen_unused_w_tieoff
    logic unused_w;
    always_comb begin
      unused_w = 1'b0;
      for (int i = 0; i < NumShares; i++) begin : gen_unused_w
        unused_w ^= w[i];
        unused_w ^= p_inner_xor_w[i];
      end
    end
  end

endmodule // prim_hpc2
