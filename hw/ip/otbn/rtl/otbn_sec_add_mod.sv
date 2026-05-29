// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// First-order masked modular adder: computes inp1 + inp2 mod modulus on two Width-bit Boolean
// sharings, producing a Width-bit Boolean sharing result_o.
//
// When enable_mod_i is high the inputs must satisfy:
//   (inp1_i[0] ^ inp1_i[1]) + (inp2_i[0] ^ inp2_i[1]) = inp1 + inp2 + (pow(2, Width) - modulus)
// with inp1 + inp2 < 2*modulus, so that a single pass-2 correction step produces the correct
// result. The (pow(2, Width) - modulus) offset must be pre-subtracted and embedded in the input
// share encodings before the inputs are presented.
//
// When enable_mod_i is low the modular reduction is skipped and the raw pass-1 result is returned
// directly. Hence, no pre-subtraction of the modulus is needed.
//
// Algorithm (enable_mod_i = 1, modulus = q):
//   Input:  inp1_i = (inp1_i[0], inp1_i[1]), inp2_i = (inp2_i[0], inp2_i[1]), where
//           (inp1_i[0] ^ inp1_i[1]) + (inp2_i[0] ^ inp2_i[1]) = inp1 + inp2 + (2^Width - q)
//   Output: result_o where result_o[0] ^ result_o[1] = inp1 + inp2 mod q
//
//   sec_add_result = SecAdd(inp1_i, inp2_i)                  // calculate the sum
//   add_mod[s]     = sec_add_result[s][Width]                // carry-out bit per share
//   mod_correction = (add_mod[0] * q, add_mod[1] * q)        // calculate the mod correction term
//   result_o       = SecAdd(sec_add_result, mod_correction)  // perform the correction
//
// Two-pass implementation:
//   Pass 1: Feed (inp1_i, inp2_i) into otbn_sec_add. The (Width+1)-bit result (data + carry out)
//           is written into a FIFO of depth 2.
//   Pass 2: Once the pass-1 result reaches the FIFO tail, the per-share carry bit (add_mod[s])
//           selects the correction for each share. The otbn_sec_add result and the correction term
//           are re-fed into otbn_sec_add to produce the final modular-reduced output.
//   The correction term is computed as follows:
//     mod_correction[0] = add_mod[0] ? 0         : modulus_i  (share 0: add modulus_i if no carry)
//     mod_correction[1] = add_mod[1] ? modulus_i : 0          (share 1: add modulus_i if carry)
//
// Throughput:
//   enable_mod_i = 0: 1 sample/cycle, latency = 6 cycles.
//   enable_mod_i = 1: 0.5 samples/cycle, VecSize=8 inputs are accepted over 8 cycles,
//                     then pass 2 occupies otbn_sec_add for 8 cycles. Latency = 14 cycles
//                     to the first result of a batch, 21 cycles to the last.
//
// Interface:
//   wvalid_i / wready_o : Input handshake; wready_o deasserted while otbn_sec_add is occupied
//                         during the 8 pass-2 cycles.
//   rvalid_o            : Asserted when a valid result is present at result_o and stall_i is low.
//                         There is no backpressure, the result must be consumed immediately.
//   stall_i             : Freezes the entire datapath (pipeline, counter, and FIFO).
//   enable_mod_i        : When low, bypasses reduction and routes pass-1 directly to output.
//
// For details, see the following paper:
// Algorithm 8 in T. Fritzmann et al., "Masked Accelerators and Instruction Set Extensions for
// Post-Quantum Cryptography", available at:
// https://tches.iacr.org/index.php/TCHES/article/view/9303/8869

module otbn_sec_add_mod
  import otbn_pkg::*;
#(
  parameter  int Width       = 32,
  localparam int Stages      = $clog2(Width),           // derived parameter
  localparam int VecSize     = 8,                       // inputs per batch
  localparam int CtrWidth    = $clog2(VecSize),         // derived parameter
  localparam int Latency     = Stages + 1,              // derived parameter
  localparam int BufferWidth = NumShares*(Width + 1),   // derived parameter
  localparam int BufferDepth = VecSize - Latency,       // derived parameter
  localparam int RandWidth   = 2*(Stages*Width + 1)     // derived parameter
) (
  input  logic clk_i,
  input  logic rst_ni,

  // Input handshake.
  input  logic wvalid_i,
  output logic wready_o,

  // Input signals.
  input  logic                            enable_mod_i,
  input  logic                            stall_i,
  input  logic [RandWidth-1:0]            rand_i,
  input  logic [NumShares-1:0][Width-1:0] inp1_i,
  input  logic [NumShares-1:0][Width-1:0] inp2_i,
  input  logic [Width-1:0]                modulus_i,

  // Output signals.
  output logic [NumShares-1:0][Width-1:0] result_o,
  output logic                            rvalid_o,
  output logic                            ctr_err_o
);

  // Shift register tracking which adder cycles are part of pass-2.
  // Bit 0 indicates if the current input is part of pass-2.
  // Bit Latency indicates when a pass-2 result is exiting the pipeline.
  logic [Latency:0] mux_state_d, mux_state_q;
  logic mux_state_next;

  // Secure adder interface signals.
  logic sec_add_inp_valid;
  logic sec_add_stall;
  logic sec_add_oup_valid;

  logic [NumShares-1:0][Width-1:0] sec_add_inp1;
  logic [NumShares-1:0][Width-1:0] sec_add_inp2;
  logic [NumShares-1:0][Width:0]   sec_add_result;

  // Signals to count adder input transactions to detect when a full batch of VecSize inputs has
  // been fed into otbn_sec_add.
  logic [CtrWidth-1:0] add_oup_cnt;
  logic add_inp_cnt_incr_en;
  logic vector_inserted_pulse;
  logic add_inp_cnt_clr;
  logic add_inp_ctr_max;

  // Pass-1 result FIFO:
  // buffer_data[0] is the blanked adder output
  // buffer_data[BufferDepth] is the FIFO tail read by pass-2.
  logic [BufferDepth:0][BufferWidth-1:0] buffer_data;
  // buffer_advance shifts the FIFO data forward on pass-1 output or pass-2 start.
  logic buffer_advance;
  // Decide whether the otbn_sec_add output should be routed to the module output.
  logic route_sec_add_result_out;

  // Per-share carry bits extracted from the FIFO tail, and the derived modulus corrections.
  logic [NumShares-1:0]            add_mod;
  logic [NumShares-1:0][Width-1:0] mod_correction;

  // Toggle pass-2 flag at the start of each new batch. Set to 0 when modular reduction is off.
  assign mux_state_next = enable_mod_i ? mux_state_q[0] ^ vector_inserted_pulse : 1'b0;

  // Shift register tracking which adder cycles are part of pass-2.
  assign mux_state_d    = (mux_state_q << 1) | {Latency'(0), mux_state_next};
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      mux_state_q <= '0;
    end else if (sec_add_inp_valid) begin
      mux_state_q <= mux_state_d;
    end
  end

  // Determine the otbn_sec_add input valid and stall signals.
  // During pass-2 there are no stalls and the values are automatically fed back in.
  assign sec_add_inp_valid = mux_state_q[0] ? 1'b1 : wvalid_i && !stall_i;
  assign sec_add_stall     = mux_state_q[0] ? 1'b0 : stall_i;

  // Multiplex inputs into the secure adder.
  // On the 2nd pass (mux_state_q[0]=1), feed back the buffered intermediate
  // result and the modulus correction to complete the modular reduction.
  assign sec_add_inp1[0] = mux_state_q[0] ? buffer_data[BufferDepth][Width-1:0] : inp1_i[0];
  assign sec_add_inp1[1] = mux_state_q[0] ? buffer_data[BufferDepth][BufferWidth-2:Width+1]
                                          : inp1_i[1];

  assign sec_add_inp2 = mux_state_q[0] ? mod_correction : inp2_i;

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

  // Input batch counter: increments each cycle a new input enters the adder.
  // Fires vector_inserted_pulse when the last element of a batch of VecSize is accepted,
  // which triggers the pass-2 flag toggle in mux_state_next.
  assign add_inp_ctr_max       = (add_oup_cnt == CtrWidth'(VecSize-1));
  assign add_inp_cnt_incr_en   = sec_add_inp_valid && enable_mod_i;
  assign vector_inserted_pulse = add_inp_ctr_max && add_inp_cnt_incr_en;
  assign add_inp_cnt_clr       = vector_inserted_pulse || !enable_mod_i;

  prim_count #(
    .Width(CtrWidth),
    .PossibleActions(prim_count_pkg::Clr | prim_count_pkg::Incr)
  ) u_prim_count_add_inp (
    .clk_i,
    .rst_ni,

    .clr_i    (add_inp_cnt_clr),
    .set_i    (1'b0),
    .set_cnt_i('0),

    .incr_en_i(add_inp_cnt_incr_en),
    .decr_en_i(1'b0),
    .step_i   (CtrWidth'(1)),
    .commit_i (1'b1),

    .cnt_o             (add_oup_cnt),
    .cnt_after_commit_o(),
    .err_o             (ctr_err_o)
  );

  // Route pass-1 outputs to the FIFO and pass-2 outputs to result_o.
  // When enable_mod_i is low, all outputs are routed out directly.
  assign route_sec_add_result_out = enable_mod_i ? mux_state_q[Latency] : 1'b1;

  // Advance the FIFO when a pass-1 result arrives, or at the start of a pass-2 cycle
  // so the FIFO tail is ready for the mux before the pass-2 transaction completes.
  assign buffer_advance = (sec_add_oup_valid && !route_sec_add_result_out) || mux_state_q[0];

  // Blank the input to the buffer.
  prim_blanker #(
    .Width(BufferWidth)
  ) u_prim_blanker (
    .in_i  ({sec_add_result[1], sec_add_result[0]}),
    .en_i  (!route_sec_add_result_out),
    .out_o (buffer_data[0])
  );

  // Instantiate the buffer flops.
  for (genvar d = 0; d < BufferDepth; d++) begin : gen_buffer
    prim_flop_en #(
      .Width      (BufferWidth),
      .ResetValue ('0)
    ) u_prim_flop_en (
      .clk_i,
      .rst_ni,
      .en_i(buffer_advance),
      .d_i(buffer_data[d]),
      .q_o(buffer_data[d+1])
    );
  end

  // Get the per-share carry bit which is used to set the modular correction term.
  assign add_mod[0] = buffer_data[BufferDepth][Width];
  assign add_mod[1] = buffer_data[BufferDepth][BufferWidth-1];

  // The correction is only performed if the unmasked carry out bit is 1.
  assign mod_correction[0] = add_mod[0] ? '0        : modulus_i;
  assign mod_correction[1] = add_mod[1] ? modulus_i : '0;

  // Set the handshake signals.
  assign rvalid_o = route_sec_add_result_out && sec_add_oup_valid;
  assign wready_o = !mux_state_q[0];

  // Blank the otbn_sec_add_mod sum output.
  prim_blanker #(
    .Width(NumShares * Width)
  ) u_prim_blanker_result (
    .in_i  ({sec_add_result[1][Width-1:0], sec_add_result[0][Width-1:0]}),
    .en_i  (rvalid_o),
    .out_o (result_o)
  );

endmodule
