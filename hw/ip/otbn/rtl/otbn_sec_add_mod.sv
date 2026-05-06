module otbn_sec_add_mod #(
  parameter  int Width = 32,
  localparam int Stages = $clog2(Width),
  localparam int VecSize = 8,
  localparam int CtrWidth = $clog2(VecSize),
  localparam int Latency = 6,
  localparam int BufferWidth = 2*(Width + 1),
  localparam int BufferDepth = VecSize - Latency,
  localparam int NumShares = 2,
  localparam int RandWidth = 2*(Stages*Width + 1)
) (
  input  logic clk_i,
  input  logic rst_ni,

  // Input handshake.
  input  logic wvalid_i,
  output logic wready_o,

  input  logic                            enable_mod_i,
  input  logic                            stall_i,
  input  logic [RandWidth-1:0]            rand_i,
  input  logic [NumShares-1:0][Width-1:0] inp1_i,
  input  logic [NumShares-1:0][Width-1:0] inp2_i,
  input  logic [Width-1:0]                modulus_i,

  output logic [NumShares-1:0][Width-1:0] result_o,
  output logic                            rvalid_o,
  output logic                            ctr_err_o
);

  // Secure Add signals
  logic [Latency:0] mux_state_d, mux_state_q;
  logic mux_state_next;
  logic sec_add_inp_valid;
  logic sec_add_stall;
  logic sec_add_oup_valid;

  logic [NumShares-1:0][Width-1:0] sec_add_inp1;
  logic [NumShares-1:0][Width-1:0] sec_add_inp2;
  logic [NumShares-1:0][Width:0]   sec_add_result;

  // Counter signals
  logic [CtrWidth-1:0] add_oup_cnt;
  logic add_inp_cnt_incr_en;
  logic vector_inserted_pulse;
  logic add_inp_cnt_clr;
  logic add_inp_ctr_max;

  // Buffer signals
  logic route_sec_add_result_out;
  logic buffer_advance;
  logic [BufferDepth:0][BufferWidth-1:0] buffer_data;

  // Intermediate results.
  logic [NumShares-1:0]            add_mod;
  logic [NumShares-1:0][Width-1:0] mod_correction;

  // Set the secure add signals.
  assign mux_state_next = enable_mod_i ? mux_state_q[0] ^ vector_inserted_pulse : 1'b0;
  assign mux_state_d = (mux_state_q << 1) | mux_state_next;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if(!rst_ni) begin
      mux_state_q <= '0;
    end else if (sec_add_inp_valid) begin
      mux_state_q <= mux_state_d;
    end else begin
      mux_state_q <= mux_state_q;
    end
  end

  assign sec_add_inp_valid = mux_state_q[0] ? 1'b1 : wvalid_i && !stall_i;
  assign sec_add_stall = mux_state_q[0] ? 1'b0 : stall_i;
  // Multiplex inputs into the secure adder. 
  // If absorbing from Buffer (2nd pass), sec_add_inp1 gets the intermediate sec_add_result, 
  // and sec_add_inp2 gets the modulo correction.
  assign sec_add_inp1[0] = mux_state_q[0] ? buffer_data[BufferDepth][Width-1:0] : inp1_i[0];
  assign sec_add_inp1[1] = mux_state_q[0] ? buffer_data[BufferDepth][BufferWidth-2:Width+1] : inp1_i[1];

  assign sec_add_inp2[0] = mux_state_q[0] ? mod_correction[0] : inp2_i[0];
  assign sec_add_inp2[1] = mux_state_q[0] ? mod_correction[1] : inp2_i[1];

  // Instantiate the secure adder.
  otbn_sec_add #(
    .Width(Width)
  ) u_otbn_sec_add_core (
    .clk_i,
    .rst_ni,
    .valid_i (sec_add_inp_valid),
    .stall_i (sec_add_stall),
    .rand_i,
    .inp1_i  (sec_add_inp1),
    .inp2_i  (sec_add_inp2),
    .result_o(sec_add_result),
    .valid_o (sec_add_oup_valid)
  );

  // Assign add output counter related signals.
  assign add_inp_ctr_max = (add_oup_cnt == CtrWidth'(VecSize-1));
  assign add_inp_cnt_incr_en = sec_add_inp_valid && enable_mod_i;
  assign vector_inserted_pulse = add_inp_ctr_max && add_inp_cnt_incr_en;
  assign add_inp_cnt_clr = vector_inserted_pulse || !enable_mod_i;

  // Instantiate secure add valid output counter.
  prim_count #(
    .Width(CtrWidth),
    .PossibleActions(prim_count_pkg::Clr | prim_count_pkg::Incr)
  ) u_prim_count_add_inp (
    .clk_i,
    .rst_ni,

    .clr_i    (add_inp_cnt_clr),
    .set_i    (1'b0),
    .set_cnt_i(CtrWidth'(0)),

    .incr_en_i(add_inp_cnt_incr_en),
    .decr_en_i(1'b0),
    .step_i   (CtrWidth'(1)),
    .commit_i (1'b1),

    .cnt_o             (add_oup_cnt),
    .cnt_after_commit_o(),
    .err_o             (ctr_err_o)
  );

  // Assign buffer related signals.
  assign route_sec_add_result_out = enable_mod_i ? mux_state_q[Latency] : 1'b1;

  assign buffer_advance = (sec_add_oup_valid && !route_sec_add_result_out) || mux_state_q[0];

  prim_blanker #(
    .Width(BufferWidth)
  ) u_prim_blanker (
    .in_i  ({sec_add_result[1], sec_add_result[0]}),
    .en_i  (!route_sec_add_result_out),
    .out_o (buffer_data[0])
  );

  for (genvar d = 0; d < BufferDepth; d++) begin : gen_buffer
    prim_flop_en #(
      .Width      (BufferWidth),
      .ResetValue ('0)
    ) u_prim_flop_en (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .en_i(buffer_advance),
      .d_i(buffer_data[d]),
      .q_o(buffer_data[d+1])
    );
  end

  // Assign intermediate signals.
  assign add_mod[0] = buffer_data[BufferDepth][Width];
  assign add_mod[1] = buffer_data[BufferDepth][BufferWidth-1];
  assign mod_correction[0] = add_mod[0] ? '0 : modulus_i;
  assign mod_correction[1] = add_mod[1] ? modulus_i : '0;

  // Assign the output signals.
  assign rvalid_o = route_sec_add_result_out && sec_add_oup_valid;
  assign wready_o = !mux_state_q[0];

  always_comb begin
    for (int s = 0; s < NumShares; s++) begin
      result_o[s] = rvalid_o ? sec_add_result[s][Width-1:0] : '0;
    end
  end

endmodule
