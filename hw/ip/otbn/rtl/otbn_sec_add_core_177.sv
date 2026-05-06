module otbn_sec_add_core_177 #(
  parameter  int Width     = 32,
  localparam int NumShares = 2,
  localparam int Stages    = $clog2(Width)
) (
  input  logic clk_i,
  input  logic rst_ni,

  input  logic             valid_i,
  input  logic [Width-1:0] r_i[Stages+1][4],
  input  logic [Width-1:0] a_i[NumShares],
  input  logic [Width-1:0] b_i[NumShares],
  output logic [Width-1:0] sum_o[NumShares],
  output logic             valid_o
);

  logic [Width-1:0] a_q[NumShares];
  logic [Width-2:0] g [Stages+1][NumShares];
  logic [Width-2:0] g_feed_forward [NumShares];
  logic [Width-2:0] g_feed_forward_temp [NumShares];
  logic [Width-2:0] p [Stages+1][NumShares];
  logic [Width-1:0] pre_p [Stages+2][NumShares];
  logic en [Stages+2];

  assign en[0] = valid_i;

  // Level 0: Pre-processing
  // pre_p[0] = a ^ b;
  for (genvar s = 0; s < NumShares; s++) begin : gen_pre_p
    prim_xor2 #(
      .Width(Width)
    ) u_prim_xor2 (
      .in0_i(a_i[s]),
      .in1_i(b_i[s]),
      .out_o(pre_p[0][s])
    );
  end

  assign p[0][0] = pre_p[1][0][Width-2:0];
  assign p[0][1] = pre_p[1][1][Width-2:0];

  for (genvar s = 0; s < NumShares; s++) begin : flop_a
    prim_flop_en #(
      .Width      ( Width),
      .ResetValue ('0)
    ) u_prim_flop_en_g (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .en_i(en[0]),
      .d_i(a_i[s]),
      .q_o(a_q[s])
    );
  end

  // Handle bit 0.
  prim_hpc3 #(
    .EnW(1'b0)
  ) u_prim_hpc3_and_pre_g_lsb (
    .clk_i,
    .rst_ni,
    .en_i(en[0]),
    .x_i ('{a_i[0][0], a_i[1][0]}),
    .y_i ('{b_i[0][0], b_i[1][0]}),
    .w_i ('{default: '0}),
    .r_i  (r_i[0][0][0]),
    .rp_i (r_i[0][1][0]),
    .z_o ('{g_feed_forward[0][0], g_feed_forward[1][0]})
  );

  for (genvar s = 0; s < NumShares; s++) begin : flop_g_feed_forward
    prim_flop_en #(
      .Width      ( 1),
      .ResetValue ('0)
    ) u_prim_flop_en_g_ff (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .en_i(en[1]),
      .d_i(g_feed_forward[s][0]),
      .q_o(g[0][s][0])
    );
  end

  // Handle all the other bits.
  for (genvar i = 1; i < Width-1; i++) begin : pre_processing_g
    prim_hpc2 #(
      .EnW(1'b0)
    ) u_prim_hpc2_and_pre_g (
      .clk_i,
      .rst_ni,
      .en1_i(en[0]),
      .en2_i(en[1]),
      .x_i ('{a_q[0][i], a_q[1][i]}),
      .y_i ('{b_i[0][i], b_i[1][i]}),
      .w_i ('{default: '0}),
      .r_i  (r_i[0][0][i]),
      .z_o ('{g[0][0][i], g[0][1][i]})
    );
  end

  // Prefix Tree Logic
  for (genvar level = 1; level < Stages; level++) begin : stage_p
    localparam int step = 1 << level;

    for (genvar i = 0; i < Width-1; i++) begin : bit_logic
      localparam int group_pos = i % step;
      localparam int remote = i - group_pos + step/2 - 1;

      if ((group_pos >= step/2) && (i >= step)) begin : hpc_gadget_logic

        if (level == 1) begin : gen_p_stage_one
          prim_hpc2 #(
            .EnW(1'b0)
          ) u_prim_hpc2_and (
            .clk_i,
            .rst_ni,
            .en1_i(en[level-1]),
            .en2_i(en[level]),
            .x_i ('{pre_p[1][0][remote], pre_p[1][1][remote]}),
            .y_i ('{pre_p[0][0][i], pre_p[0][1][i]}),
            .w_i ('{default: '0}),
            .r_i  (r_i[level][2][i]),
            .z_o ('{p[1][0][i], p[1][1][i]})
          );

        end else if (group_pos < step*3/4) begin : gen_p_hpc2
          prim_hpc2 #(
            .EnW(1'b0)
          ) u_prim_hpc2_and (
            .clk_i,
            .rst_ni,
            .en1_i(en[level-1]),
            .en2_i(en[level]),
            .x_i ('{p[level-1][0][remote], p[level-1][1][remote]}),
            .y_i ('{p[level-2][0][i], p[level-2][1][i]}),
            .w_i ('{default: '0}),
            .r_i  (r_i[level][2][i]),
            .z_o ('{p[level][0][i], p[level][1][i]})
          );

        end else begin : gen_p_hpc3
          prim_hpc3 #(
            .EnW(1'b0)
          ) u_prim_hpc3_and (
            .clk_i,
            .rst_ni,
            .en_i(en[level]),
            .x_i ('{p[level-1][0][remote], p[level-1][1][remote]}),
            .y_i ('{p[level-1][0][i], p[level-1][1][i]}),
            .w_i ('{default: '0}),
            .r_i  (r_i[level][2][i]),
            .rp_i (r_i[level][3][i]),
            .z_o ('{p[level][0][i], p[level][1][i]})
          );
        end

      end else if ((i < step) || (level == (Stages-1))) begin : unused_logic
        assign p[level][0][i] = 1'b0;
        assign p[level][1][i] = 1'b0;

      end else if (level == 1) begin : feed_through_direct
        assign p[1][0][i] = pre_p[2][0][i];
        assign p[1][1][i] = pre_p[2][1][i];

      end else begin : feed_through_ff
        prim_flop_en #(
          .Width      ( NumShares),
          .ResetValue ('0)
        ) u_prim_flop_en_p (
          .clk_i(clk_i),
          .rst_ni(rst_ni),
          .en_i(en[level]),
          .d_i({p[level-1][0][i], p[level-1][1][i]}),
          .q_o({p[level][0][i], p[level][1][i]})
        );
      end
    end
  end

  for (genvar level = 1; level < Stages; level++) begin : stage_g
    localparam int step = 1 << level;

    for (genvar i = 0; i < Width-1; i++) begin : bit_logic
      localparam int group_pos = i % step;
      localparam int remote = i - group_pos + step/2 - 1;

      if ((i == (step - 1)) || ((level == Stages) && (i >= (Width-step/4)))) begin : gen_feed_forward_g
        prim_hpc3 #(
          .EnW(1'b0)
        ) u_prim_hpc3_and (
          .clk_i,
          .rst_ni,
          .en_i(en[level]),
          .x_i ('{g_feed_forward[0][remote], g_feed_forward[1][remote]}),
          .y_i ('{p[level-1][0][i], p[level-1][1][i]}),
          .w_i ('{default: '0}),
          .r_i  (r_i[level][0][i]),
          .rp_i (r_i[level][1][i]),
          .z_o ('{g_feed_forward_temp[0][i], g_feed_forward_temp[1][i]})
        );
        // XOR
        prim_xor2 #(
          .Width(NumShares)
        ) u_prim_xor2 (
          .in0_i({g_feed_forward_temp[0][i], g_feed_forward_temp[1][i]}),
          .in1_i({g[level-1][0][i], g[level-1][1][i]}),
          .out_o({g_feed_forward[0][i], g_feed_forward[1][i]})
        );
        // FLOP
        prim_flop_en #(
          .Width      ( NumShares),
          .ResetValue ('0)
        ) u_prim_flop_en_g (
          .clk_i(clk_i),
          .rst_ni(rst_ni),
          .en_i(en[level+1]),
          .d_i({g_feed_forward[0][i], g_feed_forward[1][i]}),
          .q_o({g[level][0][i], g[level][1][i]})
        );

      end else if ((group_pos >= step/2)) begin : gen_default_g
        prim_hpc2 #(
          .EnW(1'b1)
        ) u_prim_hpc2o (
          .clk_i,
          .rst_ni,
          .en1_i(en[level]),
          .en2_i(en[level+1]),
          .x_i ('{g[level-1][0][remote], g[level-1][1][remote]}),
          .y_i ('{p[level-1][0][i], p[level-1][1][i]}),
          .w_i ('{g[level-1][0][i], g[level-1][1][i]}),
          .r_i  (r_i[level][0][i]),
          .z_o ('{g[level][0][i], g[level][1][i]})
        );

      end else if ((level == (Stages-1)) && (i >= step)) begin : feed_through_direct
          assign g[level][0][i] = g[level-1][0][i];
          assign g[level][1][i] = g[level-1][1][i];

      end else begin : feed_through_ff
        prim_flop_en #(
          .Width      ( NumShares),
          .ResetValue ('0)
        ) u_prim_flop_en_g (
          .clk_i(clk_i),
          .rst_ni(rst_ni),
          .en_i(en[level+1]),
          .d_i({g[level-1][0][i], g[level-1][1][i]}),
          .q_o({g[level][0][i], g[level][1][i]})
        );
      end
    end
  end

  // Last stage.
  for (genvar i = 0; i < Width-1; i++) begin : last_stage_g
    localparam int remote = (Width/2) - 1;
    if (i < Width/2) begin : gen_feed_through
      assign g[Stages][0][i] = g[Stages-1][0][i];
      assign g[Stages][1][i] = g[Stages-1][1][i];

    end else if(i < Width*3/4) begin : gen_hpc2
      prim_hpc2 #(
        .EnW(1'b1)
      ) u_prim_hpc2o (
        .clk_i,
        .rst_ni,
        .en1_i(en[Stages-1]),
        .en2_i(en[Stages]),
        .x_i ('{g_feed_forward[0][remote], g_feed_forward[1][remote]}),
        .y_i ('{p[Stages-2][0][i], p[Stages-2][1][i]}),
        .w_i ('{g[Stages-1][0][i], g[Stages-1][1][i]}),
        .r_i  (r_i[Stages][0][i]),
        .z_o ('{g[Stages][0][i], g[Stages][1][i]})
      );

    end else begin : gen_hpc3
      prim_hpc3 #(
        .EnW(1'b0)
      ) u_prim_hpc3_and (
        .clk_i,
        .rst_ni,
        .en_i(en[Stages]),
        .x_i ('{g_feed_forward[0][remote], g_feed_forward[1][remote]}),
        .y_i ('{p[Stages-1][0][i], p[Stages-1][1][i]}),
        .w_i ('{default: '0}),
        .r_i  (r_i[Stages][0][i]),
        .rp_i (r_i[Stages][1][i]),
        .z_o ('{g_feed_forward_temp[0][i], g_feed_forward_temp[1][i]})
      );
      // XOR
      prim_xor2 #(
        .Width(NumShares)
      ) u_prim_xor2 (
        .in0_i({g_feed_forward_temp[0][i], g_feed_forward_temp[1][i]}),
        .in1_i({g[Stages-1][0][i], g[Stages-1][1][i]}),
        .out_o({g[Stages][0][i], g[Stages][1][i]})
      );
    end
  end

  for (genvar level = 1; level <= Stages+1; level++) begin : feedthrough_stage
    prim_flop_en #(
      .Width      (2*Width),
      .ResetValue ('0)
    ) u_prim_flop_en_g (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .en_i(en[level-1]),
      .d_i({pre_p[level-1][0], pre_p[level-1][1]}),
      .q_o({pre_p[level][0], pre_p[level][1]})
    );
    prim_flop #(
      .Width      (1),
      .ResetValue ('0)
    ) u_prim_flop_enable (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .d_i(en[level-1]),
      .q_o(en[level])
    );
  end

  // Final Sum Generation
  // sum_o[i] = p_initial[i] ^ carry_in[i]
  // carry_in[i] is the 'generate' signal from the previous bit (i-1)
  for (genvar s = 0; s < NumShares; s++) begin : gen_sum_share
    assign sum_o[s][0] = pre_p[Stages+1][s][0];
    for (genvar i = 1; i < Width; i++) begin : gen_sum_bit
      prim_xor2 #(
        .Width(1)
      ) u_prim_xor2 (
        .in0_i(pre_p[Stages+1][s][i]),
        .in1_i(g[Stages][s][i-1]),
        .out_o(sum_o[s][i])
      );
    end
  end

  // Output valid signal
  assign valid_o = en[Stages+1];

  // --- Linter Compliance Sink ---
  // A single block to cleanly evaluate arrays and suppress "driven but unused" 
  // warnings for P-nodes, and "unread input" for over-provisioned PRNG routing.
  logic [NumShares-1:0] unused_sigs;

  always_comb begin
    unused_sigs = '{default: '0};

    // Sink r_i (Randomness is safe to XOR together into a dummy)
    for (int i = 0; i <= Stages; i++) begin
      for (int j = 0; j < 4; j++) begin 
        unused_sigs[0] ^= ^r_i[i][j]; 
      end
    end

    // Sink p (MUST keep shares separated!)
    for (int i = 0; i <= Stages; i++) begin
      for (int s = 0; s < NumShares; s++) begin
        unused_sigs[s] ^= ^p[i][s]; // Share 0 only XORs with Share 0
      end
    end
  end

endmodule
