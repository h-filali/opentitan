module otbn_mask_accelerator
  import otbn_pkg::*;
#(
  parameter  int   Width         = 32,
  localparam int   VecSize       = 8,
  localparam int   NumShares     = 2,
  localparam int   Stages        = $clog2(Width),
  localparam int   RandWidth     = 2*(Stages*Width + 1),
  parameter  bit   EnRejSampling = 1
) (
  input  logic clk_i,
  input  logic rst_ni,

  // Write port
  input  logic                 wvalid_i,
  output logic                 wready_o,
  input  logic [Width-1:0]     a_i[NumShares],
  input  logic [Width-1:0]     b_i[NumShares],

  // Randomness
  input  logic [RandWidth-1:0] rand_i,
  input  logic [Width-1:0]     masks_i[NumShares],

  // Config
  input  logic [Width-1:0]     q_i,
  input  state_mask_op_e       mask_op_i,

  // Read port
  output logic                 rvalid_o,
  input  logic                 rready_i,
  output logic [Width-1:0]     sum_o[NumShares],

  // Errors
  output logic                 mask_fifo_err_o,
  output logic                 ctr_err_o
);

  logic [Width-1:0] a[NumShares];
  logic [Width-1:0] b[NumShares];
  logic [Width-1:0] sum[NumShares];
  logic [Width-1:0] sum_b2a_d[NumShares];
  logic [Width-1:0] sum_b2a_q[NumShares];

  logic [Width-1:0] q_smear_mask;
  logic [Width-1:0] q_neg;
  logic [Width-1:0] mask_mod;

  logic enable_mod;
  logic inp_ready;
  logic inp_valid;
  logic stall;

  // A2B pipeline register: breaks the (a_i[1] + q_neg) critical path.
  logic [Width-1:0] a_q[NumShares];
  logic [Width-1:0] b_q[NumShares];
  logic             inp_valid_q;

  logic [Width-1:0] adder_a[NumShares];
  logic [Width-1:0] adder_b[NumShares];
  logic             adder_wready;
  logic             adder_wvalid;
  logic             adder_rready;
  logic             adder_rready_q;

  logic [Width-1:0] fifo_rdata;
  logic             fifo_wready;
  logic [Width-1:0] sum_share0_gated;

  state_mask_op_e mask_op_q;

  assign q_neg = (1 << Width) - q_i;

  always_comb begin
    q_smear_mask = q_i;

    // Parameterized Smear: Shift by 1, 2, 4, 8, 16... up to WIDTH
    for (int i = 1; i < Width; i = i * 2) begin
      q_smear_mask = q_smear_mask | (q_smear_mask >> i);
    end
  end

  // Extract the lowest bits of r using the generated q_smear_mask and compare
  assign mask_mod = masks_i[0] & q_smear_mask;

  if (EnRejSampling) begin : gen_rej_sampling
    assign wready_o = (mask_op_q == BoolToArith) ? (mask_mod < q_i) && inp_ready : inp_ready;
    assign stall = inp_ready && !wready_o;
  end else begin : gen_no_rej_sampling
    assign wready_o = inp_ready;
    assign stall = 1'b0;
  end

  // Calculate inputs based on operation type
  always_comb begin
    // Defaults
    a          = a_i;
    b          = b_i;
    enable_mod = 1'b0;

    unique case (mask_op_q)
      SecAdd: ; // use defaults
      SecAddMod: begin
        enable_mod = 1'b1;
      end
      ArithToBool: begin
        a[0]       = a_i[0] ^ masks_i[0];
        a[1]       = masks_i[0];
        b[0]       = (a_i[1] + q_neg) ^ masks_i[1];
        b[1]       = masks_i[1];
        enable_mod = 1'b1;
      end
      BoolToArith: begin
        // -mask_mod mod 2^Width, re-masked with masks_i[1]
        b[0]       = (~mask_mod + 1'b1) ^ masks_i[1];
        b[1]       = masks_i[1];
        enable_mod = 1'b1;
      end
      default: ; // use defaults
    endcase
  end

  assign inp_valid = wvalid_i && wready_o;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      a_q         <= '{default: '0};
      b_q         <= '{default: '0};
      inp_valid_q <= 1'b0;
    end else begin
      if (inp_valid) begin
        a_q <= a;
        b_q <= b;
      end
      inp_valid_q <= inp_valid && (mask_op_q == ArithToBool);
    end
  end

  // Use the registered path for A2B (extra cycle to settle the adder), direct path elsewhere.
  always_comb begin
    if (mask_op_q == ArithToBool) begin
      adder_a      = a_q;
      adder_b      = b_q;
      adder_wvalid = inp_valid_q;
    end else begin
      adder_a      = a;
      adder_b      = b;
      adder_wvalid = inp_valid;
    end
  end

  prim_flop #(
    .Width(StateMaskOpWidth),
    .ResetValue('0)
  ) u_prim_flop_mask_op (
    .clk_i (clk_i),
    .rst_ni(rst_ni),
    .d_i   (mask_op_i),
    .q_o   (mask_op_q)
  );

  otbn_sec_add_mod #(
    .Width(Width)
  ) u_otbn_sec_add_mod (
    .clk_i,
    .rst_ni,

    .rand_i,
    .modulus_i    (q_i),
    .enable_mod_i (enable_mod),
    .wready_o     (adder_wready),
    .wvalid_i     (adder_wvalid),
    .stall_i      (stall),
    .inp1_i       (adder_a),
    .inp2_i       (adder_b),

    .result_o     (sum),
    .rvalid_o     (adder_rready),
    .ctr_err_o
  );

  // Calculate output for B2A
  prim_fifo_sync #(
    .Width(Width),
    .Depth(VecSize)
  ) u_prim_fifo_sync_mask (
    .clk_i,
    .rst_ni,
    .clr_i    (1'b0),
    // write port
    .wvalid_i (inp_valid),
    .wready_o (fifo_wready),
    .wdata_i  (mask_mod),
    // read port
    .rvalid_o (),
    .rready_i (adder_rready_q),
    .rdata_o  (fifo_rdata),
    // occupancy
    .full_o   (),
    .depth_o  (),
    .err_o    (mask_fifo_err_o)
  );

  prim_blanker #(
    .Width(NumShares*Width)
  ) u_prim_blanker (
    .in_i ({sum[0], sum[1]}),
    .en_i (mask_op_q == BoolToArith),
    .out_o({sum_b2a_d[0], sum_b2a_d[1]})
  );

  prim_flop #(
    .Width(NumShares*Width),
    .ResetValue('0)
  ) u_prim_flop_sum (
    .clk_i (clk_i),
    .rst_ni(rst_ni),
    .d_i   ({sum_b2a_d[0], sum_b2a_d[1]}),
    .q_o   ({sum_b2a_q[0], sum_b2a_q[1]})
  );

  prim_flop #(
    .Width(1),
    .ResetValue('0)
  ) u_prim_flop_adder_rready (
    .clk_i (clk_i),
    .rst_ni(rst_ni),
    .d_i   (adder_rready),
    .q_o   (adder_rready_q)
  );

  always_comb begin
    if (mask_op_q == BoolToArith) begin
      inp_ready = fifo_wready && adder_wready;
      sum_o[0] = fifo_rdata;
      sum_o[1] = sum_b2a_q[0] ^ sum_b2a_q[1];
      rvalid_o = adder_rready_q;
    end else begin
      inp_ready = adder_wready;
      sum_o[0] = sum[0];
      sum_o[1] = sum[1];
      rvalid_o = adder_rready;
    end
  end

endmodule
