module otbn_sec_add_core_253 #(
  parameter  int Width     = 32,
  localparam int NumShares = 2,
  localparam int Stages    = $clog2(Width)
) (
  input clk_i,
  input rst_ni,

  input  logic             valid_i,
  input  logic [Width-1:0] r_i[Stages+1][4],
  input  logic [Width-1:0] a_i[NumShares],
  input  logic [Width-1:0] b_i[NumShares],
  output logic [Width-1:0] sum_o[NumShares],
  output logic             valid_o
);

  logic [Width-2:0] g [Stages+1][NumShares];
  logic [Width-2:0] p [Stages+1][NumShares];
  logic [Width-1:0] pre_p [Stages+1][NumShares];
  logic en [Stages+1];

  assign en[0] = valid_i;

  // Level 0: Pre-processing
  // pre_p[0] = a ^ b;
  prim_sharewise_xor #(
    .Width     (Width),
    .NumShares (NumShares),
    .PipeReg   (1)
  ) u_prim_sharewise_xor (
    .clk_i,
    .rst_ni,
    .en_i(en[0]),
    .x_i (a_i),
    .y_i (b_i),
    .z_o (pre_p[0])
  );

  assign p[0][0] = pre_p[0][0][Width-2:0];
  assign p[0][1] = pre_p[0][1][Width-2:0];

  generate
    for (genvar i = 0; i < Width-1; i++) begin : pre_processing_g
      prim_hpc3_and u_prim_hpc3_and (
        .clk_i,
        .rst_ni,
        .en_i(en[0]),
        .x_i ('{a_i[0][i], a_i[1][i]}),
        .y_i ('{b_i[0][i], b_i[1][i]}),
        .r_i  (r_i[0][0][i]),
        .rp_i (r_i[0][1][i]),
        .z_o ('{g[0][0][i], g[0][1][i]})
      );
    end
  endgenerate

  // Prefix Tree Logic
  generate
    for (genvar level = 1; level <= Stages; level++) begin : stage
      localparam int step = 1 << (level - 1);
      localparam int step_next = 1 << level;

      for (genvar i = 0; i < Width-1; i++) begin : bit_logic
        localparam int remote = (i / (2 * step)) * (2 * step) + step - 1;
        localparam int remote_next = (i / (2 * step_next)) * (2 * step_next) + step_next - 1;
        // Determine if this bit is occupied by a gadget (x)
        // step = 1
        // x o x o x o x o
        // step = 2
        // x x o o x x o o
        // step = 4
        // x x x x o o o o
        if ((i % (2 * step)) >= step) begin : gen_gadget
          
          // Compute G
          if ((2*(i - remote)) <= step) begin : gen_gadget_g_hpc2o
            // step = 1
            // o o o o o o o o
            // step = 2
            // o x o o o x o o
            // step = 4
            // o o x x o o o o
            // Delayed handling for g_next = hpc2o(g, p)
            prim_hpc2o u_prim_hpc2o (
              .clk_i,
              .rst_ni,
              .en1_i(en[level-1]),
              .en2_i(en[level]),
              .x_i ('{g[level-1][0][remote], g[level-1][1][remote]}),
              .y_i ({p[level-2][0][i], p[level-2][1][i]}),
              .w_i ('{g[level-1][0][i], g[level-1][1][i]}),
              .r_i  (r_i[level][0][i]),
              .z_o ('{g[level][0][i], g[level][1][i]})
            );
          end else begin : gen_gadget_g_hpc3o
            // step = 1
            // x o x o x o x o
            // step = 2
            // x o o o x o o o
            // step = 4
            // x x o o o o o o
            // Immediate handling for g_next = hpc3o(g, p)
            prim_hpc3o u_prim_hpc3o (
              .clk_i,
              .rst_ni,
              .en_i(en[level]),
              .x_i ('{g[level-1][0][remote], g[level-1][1][remote]}),
              .y_i ('{p[level-1][0][i], p[level-1][1][i]}),
              .w_i ('{g[level-1][0][i], g[level-1][1][i]}),
              .r_i  (r_i[level][0][i]),
              .rp_i (r_i[level][1][i]),
              .z_o ('{g[level][0][i], g[level][1][i]})
            );
          end

          // Compute P
          if ((2 * step) > i) begin : gen_no_gadget_p
            // step = 1
            // o o o o o o x o
            // step = 2
            // o o o o x x o o
            // step = 4
            // x x x x o o o o
            // P does not need to be computed and p output is unused
            assign p[level][0][i] = '0;
            assign p[level][1][i] = '0;
          end else if ((2*(i - remote)) <= step) begin : gen_gadget_p_hpc2_and
            // step = 1
            // o o o o o o o o
            // step = 2
            // o x o o o o o o
            // step = 4
            // o o o o o o o o
            // Delayed handling for p_next = hpc2(p, p_remote)
            prim_hpc2_and u_prim_hpc2_and (
              .clk_i,
              .rst_ni,
              .en1_i(en[level-1]),
              .en2_i(en[level]),
              .x_i ('{p[level-1][0][remote], p[level-1][1][remote]}),
              .y_i ('{p[level-2][0][i], p[level-2][1][i]}),
              .r_i  (r_i[level][2][i]),
              .z_o ('{p[level][0][i], p[level][1][i]})
            );
          end else begin : gen_gadget_p_hpc3_and
            // step = 1
            // x o x o x o o o
            // step = 2
            // x o o o o o o o
            // step = 4
            // o o o o o o o o
            // Immediate handling for p_next = hpc3(p, p_remote)
            prim_hpc3_and u_prim_hpc3_and (
              .clk_i,
              .rst_ni,
              .en_i(en[level]),
              .x_i ('{p[level-1][0][remote], p[level-1][1][remote]}),
              .y_i ('{p[level-1][0][i], p[level-1][1][i]}),
              .r_i  (r_i[level][2][i]),
              .rp_i (r_i[level][3][i]),
              .z_o ('{p[level][0][i], p[level][1][i]})
            );
          end

        // Pass-through
        // step = 1
        // o x o x o x o x
        // step = 2
        // o o x x o o x x
        // step = 4
        // o o o o x x x x
        end else begin : gen_reg
					prim_flop_en #(
            .Width      ( 2),
            .ResetValue ('0)
          ) u_prim_flop_en_g (
						.clk_i(clk_i),
						.rst_ni(rst_ni),
						.en_i(en[level]),
						.d_i('{g[level-1][0][i], g[level-1][1][i]}),
						.q_o('{g[level][0][i], g[level][1][i]})
					);

          // TODO: double check if i % (2 * step_next) or i % (2 * step)
          if ((i >= step) && ((i % (2 * step)) < step)) begin : gen_reg_p
            // step = 1
            // o o o x o o o o
            // step = 2
            // o o o o o o o o
            // step = 4
            // o o o o o o o o
            // Propagate P
            prim_flop_en #(
              .Width      ( 2),
              .ResetValue ('0)
            ) u_prim_flop_en_g (
              .clk_i(clk_i),
              .rst_ni(rst_ni),
						  .en_i(en[level]),
              .d_i('{p[level-1][0][i], p[level-1][1][i]}),
              .q_o('{p[level][0][i], p[level][1][i]})
            );
          end else begin : gen_no_reg_p
            // step = 1
            // o o o o o o o x
            // step = 2
            // o o o o o o x x
            // step = 4
            // o o o o x x x x
            // OR
            // step = 1
            // o x o o o x o o
            // step = 2
            // o o x x o o o o
            // step = 4
            // o o o o o o o o
            // P is unused
            assign p[level][0][i] = '0;
            assign p[level][1][i] = '0;
          end
        end
      end
    end
  endgenerate

  generate
    for (genvar level = 1; level <= Stages; level++) begin : feedthrough_stage
      prim_flop_en #(
        .Width      (2*Width),
        .ResetValue ('0)
      ) u_prim_flop_en_g (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .en_i(en[level]),
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
  endgenerate

  // Final Sum Generation
  // sum_o[i] = p_initial[i] ^ carry_in[i]
  // carry_in[i] is the 'generate' signal from the previous bit (i-1)
  always_comb begin
    for (int s = 0; s < NumShares; s++) begin
      sum_o[s][0] = pre_p[Stages][s][0];
      for (int i = 1; i < Width; i++) begin
        sum_o[s][i] = pre_p[Stages][s][i] ^ g[Stages][s][i-1];
      end
    end
  end

  // Output valid signal
  prim_flop #(
    .Width      (1),
    .ResetValue ('0)
  ) u_prim_flop_enable (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .d_i(en[Stages]),
    .q_o(valid_o)
  );

  // --- Linter Compliance Sink ---
  // A single block to cleanly evaluate arrays and suppress "driven but unused" 
  // warnings for P-nodes, and "unread input" for over-provisioned PRNG routing.
  logic unused_sigs;

  always_comb begin
    unused_sigs = 1'b0;

    // Sink r_i
    for (int i = 0; i <= Stages; i++) begin
      for (int j = 0; j < Width; j++) begin
        unused_sigs ^= ^r_i[i][j]; // Unary XOR the 4-bit vector, then XOR with accumulator
      end
    end

    // Sink p
    for (int i = 0; i <= Stages; i++) begin
      for (int s = 0; s < NumShares; s++) begin
        unused_sigs ^= ^p[i][s]; // Unary XOR the packed vector, then XOR with accumulator
      end
    end
  end

endmodule
