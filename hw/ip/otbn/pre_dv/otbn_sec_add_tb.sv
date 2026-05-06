module otbn_sec_add_tb (
  input logic clk,
  input logic rst_n
);

  timeunit 1ns;
  timeprecision 10ps;

  localparam time     CLK_PERIOD      = 50;
  localparam unsigned RST_CLK_CYCLES  = 10;
  localparam unsigned TOT_STIMS       = 1000000;
  localparam unsigned SHARE_WIDTH     = 32;
  localparam unsigned STAGES          = $clog2(SHARE_WIDTH);
  localparam unsigned RAND_WIDTH      = 2*(STAGES*SHARE_WIDTH + 1);

  integer n_stims, n_checks, n_errs;

  typedef struct packed {
    logic [SHARE_WIDTH-1:0] share0;
    logic [SHARE_WIDTH-1:0] share1;
  } masked_coeff_t;

  typedef struct packed {
    logic [SHARE_WIDTH:0] share0;
    logic [SHARE_WIDTH:0] share1;
  } masked_res_coeff_t;

  typedef struct packed {
    masked_coeff_t         inp1;
    masked_coeff_t         inp2;
    logic                  valid;
    logic [RAND_WIDTH-1:0] rand_data;
  } coeff_op_t;

  coeff_op_t         stim;
  masked_res_coeff_t act_resp;

  logic [SHARE_WIDTH:0] exp_resp_queue[$];

  logic [1:0][SHARE_WIDTH-1:0] dut_inp1_i;
  logic [1:0][SHARE_WIDTH-1:0] dut_inp2_i;
  logic [RAND_WIDTH-1:0]       dut_flat_rand_i;
  logic                        dut_valid_i;
  logic                        dut_valid_o;
  logic [1:0][SHARE_WIDTH:0]   dut_result_o;

  // Pipeline register: presents registered stim to the DUT.
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      dut_inp1_i      <= '0;
      dut_inp2_i      <= '0;
      dut_flat_rand_i <= '0;
      dut_valid_i     <= '0;
    end else begin
      dut_inp1_i[0]   <= stim.inp1.share0;
      dut_inp1_i[1]   <= stim.inp1.share1;
      dut_inp2_i[0]   <= stim.inp2.share0;
      dut_inp2_i[1]   <= stim.inp2.share1;
      dut_flat_rand_i <= stim.rand_data;
      dut_valid_i     <= stim.valid;
    end
  end

  assign act_resp.share0 = dut_result_o[0];
  assign act_resp.share1 = dut_result_o[1];

  otbn_sec_add dut (
    .clk_i  (clk),
    .rst_ni (rst_n),
    .valid_i(dut_valid_i),
    .stall_i(1'b0),
    .rand_i (dut_flat_rand_i),
    .inp1_i (dut_inp1_i),
    .inp2_i (dut_inp2_i),
    .valid_o (dut_valid_o),
    .result_o(dut_result_o)
  );

  // Stimulus + randomness generator.
  always_ff @(posedge clk or negedge rst_n) begin : application_block
    if (!rst_n) begin
      stim    <= '0;
      n_stims <= 0;
    end else if (n_stims < int'(TOT_STIMS)) begin
      stim.rand_data   <= RAND_WIDTH'({
        $urandom(), $urandom(), $urandom(), $urandom(),
        $urandom(), $urandom(), $urandom(), $urandom(),
        $urandom(), $urandom(), $urandom()
      });
      stim.inp1.share0 <= SHARE_WIDTH'($urandom());
      stim.inp1.share1 <= SHARE_WIDTH'($urandom());
      stim.inp2.share0 <= SHARE_WIDTH'($urandom());
      stim.inp2.share1 <= SHARE_WIDTH'($urandom());
      stim.valid       <= 1'b1;
      n_stims          <= n_stims + 1;
    end else begin
      stim <= '0;
    end
  end

  // Golden model: push expected sum for each cycle the DUT processes an input.
  // Uses dut_inp*_i (the already-registered values), which are exactly what
  // the DUT sees on this clock edge, so no latency offset is needed.
  always_ff @(posedge clk or negedge rst_n) begin : golden_block
    if (!rst_n) begin
    end else if (dut_valid_i) begin
      logic [SHARE_WIDTH-1:0] a, b;
      logic [SHARE_WIDTH:0]   gold;
      a    = dut_inp1_i[0] ^ dut_inp1_i[1];
      b    = dut_inp2_i[0] ^ dut_inp2_i[1];
      gold = {1'b0, a} + {1'b0, b};
      exp_resp_queue.push_back(gold);
    end
  end

  // Checker: pop and compare whenever the DUT produces a valid output.
  // dut_valid_o fires exactly LATENCY cycles after dut_valid_i, so
  // exp_resp_queue naturally stays LATENCY entries ahead.
  always_ff @(posedge clk or negedge rst_n) begin : checker_block
    if (!rst_n) begin
    end else if (dut_valid_o) begin
      logic [SHARE_WIDTH-1:0] exp_val, acq_val;
      logic [SHARE_WIDTH:0]   exp_full;
      if (exp_resp_queue.size() > 0) begin
        n_checks  = n_checks + 1;
        exp_full  = exp_resp_queue.pop_front();
        exp_val   = exp_full[SHARE_WIDTH-1:0];
        acq_val   = act_resp.share0[SHARE_WIDTH-1:0] ^ act_resp.share1[SHARE_WIDTH-1:0];
        if (acq_val !== exp_val) begin
          n_errs = n_errs + 1;
          $display("[FAIL] Time: %0t | Expected: %08h | Got: %08h (Shares: %08h ^ %08h)",
            $time, exp_val, acq_val,
            act_resp.share0[SHARE_WIDTH-1:0], act_resp.share1[SHARE_WIDTH-1:0]);
        end
        if (n_checks == int'(TOT_STIMS)) begin
          if (n_errs > 0)
            $display("Test ***FAILED*** with %0d mismatches out of %0d checks after %0d stimuli!",
              n_errs, n_checks, n_stims);
          else
            $display("Test ***PASSED*** with %0d mismatches out of %0d checks after %0d stimuli.",
              n_errs, n_checks, n_stims);
          $finish();
        end
      end
    end
  end

  initial begin : record_traces
    $dumpfile("dump.vcd");
    $dumpvars(0, otbn_sec_add_tb);
  end

endmodule
