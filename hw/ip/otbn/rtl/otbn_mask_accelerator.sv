module otbn_mask_accelerator
  import otbn_pkg::*;
#(
  parameter  int   Width         = 32,
  localparam int   VecSize       = 8,
  localparam int   Stages        = $clog2(Width),
  localparam int   RandWidth     = 2*(Stages*Width + 1),
  parameter  bit   EnRejSampling = 1
) (
  input  logic clk_i,
  input  logic rst_ni,

  // Wipe
  input  logic sec_wipe_running_i,

  // Write port
  input  logic                            wvalid_i,
  output logic                            wready_o,
  input  logic [NumShares-1:0][Width-1:0] in0_i,
  input  logic [NumShares-1:0][Width-1:0] in1_i,

  // Randomness
  input  logic [RandWidth-1:0]            rand_i,
  input  logic [NumShares-1:0][Width-1:0] remask_rand_i,

  // Config
  input  logic [Width-1:0] mod_i,
  input  mask_op_e         mask_op_i,

  // Read port
  output logic                            rvalid_o,
  input  logic                            rready_i,
  output logic [NumShares-1:0][Width-1:0] result_o,

  // Errors
  output logic mask_fifo_err_o,
  output logic ctr_err_o
);

  logic [NumShares-1:0][Width-1:0] result;
  logic [NumShares-1:0][Width-1:0] result_b2a;

  logic [Width-1:0] q_smear_mask;
  logic [Width-1:0] q_neg;
  logic [Width-1:0] mask_mod;

  logic enable_mod;
  logic inp_ready;
  logic adder_stall;
  logic inp_valid;
  logic stall;
  logic a2b_b2a;

  // Per-mode pre-blanking inputs. Each set is computed combinationally from
  // the current inputs and blanked to 0 when that mode is not active, so no
  // secret data leaks into the unused register path.
  logic [NumShares-1:0][Width-1:0] a2b_inp1_pre, a2b_inp2_pre;
  logic [NumShares-1:0][Width-1:0] b2a_inp1_pre, b2a_inp2_pre;

  // Registered outputs of the A2B and B2A pipeline register stages.
  // The register boundary prevents synthesis from collapsing the masked MUX
  // into an always-zero OAI22 that would kill the rand_i masking.
  logic [NumShares-1:0][Width-1:0] a2b_inp1_q,   a2b_inp2_q;
  logic [NumShares-1:0][Width-1:0] b2a_inp1_q,   b2a_inp2_q;
  logic                            inp_valid_q;
  logic                            stall_q;

  logic [NumShares-1:0][Width-1:0] adder_inp1;
  logic [NumShares-1:0][Width-1:0] adder_inp2;
  logic                            adder_wready;
  logic                            adder_wvalid;
  logic                            adder_rready;
  logic                            adder_batch_complete;

  logic [Width-1:0] fifo_rdata;
  logic             fifo_wready;

  mask_op_e mask_op_q;

  assign q_neg = (1 << Width) - mod_i;

  always_comb begin
    q_smear_mask = mod_i;
    // Smear all set bits rightward: after k iterations all bits below the highest set bit are 1.
    for (int i = 1; i < Width; i = i * 2) begin
      q_smear_mask = q_smear_mask | (q_smear_mask >> i);
    end
  end

  // Mask remask_rand_i[0] to the bit-width of mod_i for rejection sampling.
  assign mask_mod = remask_rand_i[0] & q_smear_mask;

  if (EnRejSampling) begin : gen_rej_sampling
    assign wready_o = (mask_op_q == BoolToArith) ? (mask_mod < mod_i) && inp_ready : inp_ready;
    assign stall    = inp_ready && !wready_o;
  end else begin : gen_no_rej_sampling
    assign wready_o = inp_ready;
    assign stall    = 1'b0;
  end

  always_comb begin
    enable_mod = 1'b0;
    unique case (mask_op_q)
      SecAdd:      ;
      SecAddMod:   enable_mod = 1'b1;
      ArithToBool: enable_mod = 1'b1;
      BoolToArith: enable_mod = 1'b1;
      default:     ;
    endcase
  end

  assign a2b_b2a = (mask_op_q == ArithToBool) || (mask_op_q == BoolToArith);

  // ArithToBool input encoding.
  assign a2b_inp1_pre[0] = in0_i[0] ^ remask_rand_i[0];
  assign a2b_inp1_pre[1] = remask_rand_i[0];
  assign a2b_inp2_pre[0] = (in0_i[1] + q_neg) ^ remask_rand_i[1];
  assign a2b_inp2_pre[1] = remask_rand_i[1];

  // BoolToArith input encoding: inp1 passes in0_i through, inp2 carries -mask_mod.
  assign b2a_inp1_pre[0] = in0_i[0];
  assign b2a_inp1_pre[1] = in0_i[1];
  assign b2a_inp2_pre[0] = (~mask_mod + 1'b1) ^ remask_rand_i[1];
  assign b2a_inp2_pre[1] = remask_rand_i[1];

  // Blank A2B inputs to 0 outside ArithToBool mode.
  logic [NumShares-1:0][Width-1:0] a2b_inp1_blanked, a2b_inp2_blanked;
  prim_blanker #(
    .Width(2*NumShares*Width)
  ) u_prim_blanker_a2b (
    .in_i ({a2b_inp1_pre[0], a2b_inp1_pre[1], a2b_inp2_pre[0], a2b_inp2_pre[1]}),
    .en_i (mask_op_q == ArithToBool),
    .out_o({a2b_inp1_blanked[0], a2b_inp1_blanked[1], a2b_inp2_blanked[0], a2b_inp2_blanked[1]})
  );

  // Blank B2A inputs to 0 outside BoolToArith mode.
  logic [NumShares-1:0][Width-1:0] b2a_inp1_blanked, b2a_inp2_blanked;
  prim_blanker #(
    .Width(2*NumShares*Width)
  ) u_prim_blanker_b2a (
    .in_i ({b2a_inp1_pre[0], b2a_inp1_pre[1], b2a_inp2_pre[0], b2a_inp2_pre[1]}),
    .en_i (mask_op_q == BoolToArith),
    .out_o({b2a_inp1_blanked[0], b2a_inp1_blanked[1], b2a_inp2_blanked[0], b2a_inp2_blanked[1]})
  );

  assign inp_valid = wvalid_i && wready_o;

  for (genvar s = 0; s < NumShares; s++) begin : gen_a2b_input_regs
    prim_flop_en #(.Width(Width), .ResetValue('0)) u_prim_flop_en_a2b_inp1 (
      .clk_i, .rst_ni, .en_i(inp_valid), .d_i(a2b_inp1_blanked[s]), .q_o(a2b_inp1_q[s]));
    prim_flop_en #(.Width(Width), .ResetValue('0)) u_prim_flop_en_a2b_inp2 (
      .clk_i, .rst_ni, .en_i(inp_valid), .d_i(a2b_inp2_blanked[s]), .q_o(a2b_inp2_q[s]));
  end

  for (genvar s = 0; s < NumShares; s++) begin : gen_b2a_input_regs
    prim_flop_en #(.Width(Width), .ResetValue('0)) u_prim_flop_en_b2a_inp1 (
      .clk_i, .rst_ni, .en_i(inp_valid), .d_i(b2a_inp1_blanked[s]), .q_o(b2a_inp1_q[s]));
    prim_flop_en #(.Width(Width), .ResetValue('0)) u_prim_flop_en_b2a_inp2 (
      .clk_i, .rst_ni, .en_i(inp_valid), .d_i(b2a_inp2_blanked[s]), .q_o(b2a_inp2_q[s]));
  end

  prim_flop #(.Width(1), .ResetValue('0)) u_prim_flop_inp_valid_q (
    .clk_i, .rst_ni, .d_i(inp_valid), .q_o(inp_valid_q));

  prim_flop #(.Width(1), .ResetValue('0)) u_prim_flop_stall_q (
    .clk_i, .rst_ni, .d_i(stall), .q_o(stall_q));

  // A2B/B2A: OR the two registered paths (only one is non-zero) and delay valid/stall.
  // SecAdd/SecAddMod: bypass registers, use in0_i/in1_i directly.
  assign adder_inp1 = a2b_b2a ? (a2b_inp1_q | b2a_inp1_q) : in0_i;
  assign adder_inp2 = a2b_b2a ? (a2b_inp2_q | b2a_inp2_q) : in1_i;

  assign adder_stall  = a2b_b2a ? stall_q     : stall;
  assign adder_wvalid = a2b_b2a ? inp_valid_q : inp_valid;

  prim_flop #(
    .Width(MaskOpWidth),
    .ResetValue('0)
  ) u_prim_flop_mask_op (
    .clk_i,
    .rst_ni,
    .d_i(mask_op_i),
    .q_o(mask_op_q)
  );

  otbn_sec_add_mod #(
    .Width(Width)
  ) u_otbn_sec_add_mod (
    .clk_i,
    .rst_ni,
    .rand_i,
    .modulus_i   (mod_i),
    .enable_mod_i(enable_mod),
    .wready_o    (adder_wready),
    .wvalid_i    (adder_wvalid),
    .stall_i     (adder_stall),
    .inp1_i      (adder_inp1),
    .inp2_i      (adder_inp2),
    .result_o         (result),
    .rvalid_o         (adder_rready),
    .batch_complete_o (adder_batch_complete),
    .ctr_err_o
  );

  // Mask FIFO: stores mask_mod values pushed during pass-1 of BoolToArith
  // batches; popped when the pass-2 adder result arrives.
  // Pass=0: passthrough is disabled so the FIFO depth counter is only driven
  //         by genuine write/read handshakes.
  prim_fifo_sync #(
    .Width(Width),
    .Pass (1'b0),
    .Depth(VecSize)
  ) u_prim_fifo_sync_mask (
    .clk_i,
    .rst_ni,
    .clr_i    (1'b0),
    .wvalid_i (inp_valid && (mask_op_q == BoolToArith)),
    .wready_o (fifo_wready),
    .wdata_i  (mask_mod),
    .rvalid_o (),
    .rready_i (adder_rready),
    .rdata_o  (fifo_rdata),
    .full_o   (),
    .depth_o  (),
    .err_o    (mask_fifo_err_o)
  );

  // Gate the adder result to 0 outside of BoolToArith mode.
  prim_blanker #(
    .Width(NumShares*Width)
  ) u_prim_blanker_result (
    .in_i ({result[0], result[1]}),
    .en_i (mask_op_q == BoolToArith),
    .out_o({result_b2a[0], result_b2a[1]})
  );

  always_comb begin
    if (mask_op_q == BoolToArith) begin
      // Gate on batch_complete: in B2A/A2B the input register stage delays
      // adder_wready by one cycle, so block inp_ready on the cycle that
      // batch_complete fires to prevent a spurious 9th acceptance.
      inp_ready    = fifo_wready && adder_wready && !adder_batch_complete;
      result_o[0]  = fifo_rdata;
      result_o[1]  = result_b2a[0] ^ result_b2a[1];
      rvalid_o     = adder_rready;
    end else if (mask_op_q == ArithToBool) begin
      inp_ready    = adder_wready && !adder_batch_complete;
      result_o     = result;
      rvalid_o     = adder_rready;
    end else begin
      inp_ready    = adder_wready;
      result_o     = result;
      rvalid_o     = adder_rready;
    end
  end

endmodule
