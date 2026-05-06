module otbn_sec_add_safe #(
  parameter  int Width     = 32,
  localparam int NumShares = 2,
  localparam int Stages    = $clog2(Width),
  localparam int RandWidth = 2*(Stages*Width + 1)
) (
  input  logic clk_i,
  input  logic rst_ni,

  input  logic                 valid_i,
  input  logic                 stall_i,
  input  logic [RandWidth-1:0] rand_i,
  input  logic [Width-1:0]     inp1_i[NumShares],
  input  logic [Width-1:0]     inp2_i[NumShares],
  output logic [Width:0]       result_o[NumShares],
  output logic                 valid_o
);

  logic [Width-1:0] g [Stages+1][NumShares];
  logic [Width-1:0] p [Stages+1][NumShares];
  logic [Width-1:0] pre_p [Stages+2][NumShares];
  logic en [Stages+2];
  logic update_en [Stages+2];

  assign en[0] = valid_i;

  always_comb begin
    for (int i = 0; i <= Stages+1; i++) begin
      update_en[i] = en[i] & ~stall_i;
    end
  end

  // Level 0: Pre-processing
  // pre_p[0] = a ^ b;
  for (genvar s = 0; s < NumShares; s++) begin : gen_pre_p
    prim_xor2 #(
      .Width(Width)
    ) u_prim_xor2 (
      .in0_i(inp1_i[s]),
      .in1_i(inp2_i[s]),
      .out_o(pre_p[0][s])
    );
  end

  assign p[0] = pre_p[1];

  for (genvar i = 0; i < Width; i++) begin : pre_processing_g
    prim_hpc3 #(
      .EnW(1'b0)
    ) u_prim_hpc3_and_g (
      .clk_i,
      .rst_ni,
      .en_i (update_en[0]),
      .x_i  ('{inp1_i[0][i], inp1_i[1][i]}),
      .y_i  ('{inp2_i[0][i], inp2_i[1][i]}),
      .w_i  ('{default: '0}),
      .r_i  (rand_i[2*i]),
      .rp_i (rand_i[2*i+1]),
      .z_o  ('{g[0][0][i], g[0][1][i]})
    );
  end

  // Prefix Tree Logic
  for (genvar level = 1; level <= Stages; level++) begin : stage
    localparam int step = 1 << (level - 1);
    localparam int stage_rand_offset = 2*(level*Width - (step - 1));

    for (genvar i = 0; i < Width; i++) begin : bit_logic
      localparam int group = i / (2 * step);
      localparam int remote = group * (2 * step) + step - 1;
      localparam int group_rand_offset = stage_rand_offset + ((group == 0) ? 0 : step * (4 * group - 2));

      // Determine if this bit is occupied by a gadget (x)
      if ((i % (2 * step)) >= step) begin : gen_gadgets
        // Compute G
        prim_hpc3 #(
          .EnW(1'b1)
        ) u_prim_hpc3o_g (
          .clk_i,
          .rst_ni,
          .en_i(update_en[level]),
          .x_i ('{g[level-1][0][remote], g[level-1][1][remote]}),
          .y_i ('{p[level-1][0][i], p[level-1][1][i]}),
          .w_i ('{g[level-1][0][i], g[level-1][1][i]}),
          .r_i  (rand_i[group_rand_offset]),
          .rp_i (rand_i[group_rand_offset+1]),
          .z_o ('{g[level][0][i], g[level][1][i]})
        );

        // Compute P
        if ((2 * step) > i) begin : gen_no_gadget_p
          assign p[level][0][i] = '0;
          assign p[level][1][i] = '0;

        end else begin : gen_gadget_p
          prim_hpc3 #(
            .EnW(1'b0)
          ) u_prim_hpc3_and_p (
            .clk_i,
            .rst_ni,
            .en_i(update_en[level]),
            .x_i ('{p[level-1][0][remote], p[level-1][1][remote]}),
            .y_i ('{p[level-1][0][i], p[level-1][1][i]}),
            .w_i ('{default: '0}),
            .r_i  (rand_i[group_rand_offset+2]),
            .rp_i (rand_i[group_rand_offset+3]),
            .z_o ('{p[level][0][i], p[level][1][i]})
          );
        end

      end else begin : gen_feedthrough
        prim_flop_en #(
          .Width      ( 2),
          .ResetValue ('0)
        ) u_prim_flop_en_g (
          .clk_i(clk_i),
          .rst_ni(rst_ni),
          .en_i(update_en[level]),
          .d_i('{g[level-1][0][i], g[level-1][1][i]}),
          .q_o('{g[level][0][i], g[level][1][i]})
        );

        if ((i >= step) && ((i % (2 * step)) < step)) begin : gen_reg_p
          prim_flop_en #(
            .Width      ( 2),
            .ResetValue ('0)
          ) u_prim_flop_en_p (
            .clk_i(clk_i),
            .rst_ni(rst_ni),
            .en_i(update_en[level]),
            .d_i('{p[level-1][0][i], p[level-1][1][i]}),
            .q_o('{p[level][0][i], p[level][1][i]})
          );
        end else begin : gen_no_reg_p
          assign p[level][0][i] = '0;
          assign p[level][1][i] = '0;
        end
      end
    end
  end

  for (genvar level = 1; level <= Stages+1; level++) begin : feedthrough_stage
    prim_flop_en #(
      .Width      (2*Width),
      .ResetValue ('0)
    ) u_prim_flop_en_pre_p (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .en_i(update_en[level-1]),
      .d_i({pre_p[level-1][0], pre_p[level-1][1]}),
      .q_o({pre_p[level][0], pre_p[level][1]})
    );
    prim_flop_en #(
      .Width      (1),
      .ResetValue ('0)
    ) u_prim_flop_en_enable (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .en_i(~stall_i),
      .d_i(en[level-1]),
      .q_o(en[level])
    );
  end

  // Final Sum Generation
  // result_o[i] = p_initial[i] ^ carry_in[i]
  // carry_in[i] is the 'generate' signal from the previous bit (i-1)
  for (genvar s = 0; s < NumShares; s++) begin : gen_sum_share
    assign result_o[s][0] = pre_p[Stages+1][s][0];
    for (genvar i = 1; i < Width; i++) begin : gen_sum_bit
      prim_xor2 #(
        .Width(1)
      ) u_prim_xor2 (
        .in0_i(pre_p[Stages+1][s][i]),
        .in1_i(g[Stages][s][i-1]),
        .out_o(result_o[s][i])
      );
    end
    assign result_o[s][Width] = g[Stages][s][Width-1];
  end

  // Output valid signal
  assign valid_o = en[Stages+1] && !stall_i;

  // --- Linter Compliance Sink ---
  // A single block to cleanly evaluate arrays and suppress "driven but unused" 
  // warnings for P-nodes, and "unread input" for over-provisioned PRNG routing.
  logic unused_sigs;

  always_comb begin
    unused_sigs = 1'b0;

    // Sink p
    for (int i = 0; i <= Stages; i++) begin
      for (int s = 0; s < NumShares; s++) begin
        unused_sigs ^= ^p[i][s]; // Unary XOR the packed vector, then XOR with accumulator
      end
    end
  end

endmodule
