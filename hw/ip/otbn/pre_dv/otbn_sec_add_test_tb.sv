module otbn_sec_add_test_tb ();

  timeunit 1ns;
  timeprecision 10ps;

  localparam time CLK_PERIOD         = 50ns;
  localparam time APPL_DELAY         = 10ns;
  localparam time ACQ_DELAY          = 30ns;
  localparam time LATENCY            = (3 + 1)*CLK_PERIOD;
  localparam unsigned RST_CLK_CYCLES = 10;
  localparam unsigned TOT_STIMS      = 1;
  localparam unsigned SHARE_WIDTH    = 2;
  localparam unsigned STAGES         = $clog2(SHARE_WIDTH);
  localparam unsigned RAND_WIDTH     = 3;

  integer n_stims,
      n_checks,
      n_errs;

  typedef struct packed {
    logic [SHARE_WIDTH-1:0] share0;
    logic [SHARE_WIDTH-1:0] share1;
  } masked_coeff_t;

  typedef struct packed {
    logic share0;
    logic share1;
  } masked_coeff_resp_t;

  typedef struct packed {
    masked_coeff_t         a;
    masked_coeff_t         b;
    logic                  valid;
    logic [RAND_WIDTH-1:0] rand_data;
  } coeff_op_t;

  coeff_op_t stim;
  masked_coeff_resp_t act_resp,
                      acq_resp_queue[$];
  
  logic [SHARE_WIDTH-1:0] exp_resp_queue[$];

  logic clk, rst_n, valid;

  clk_rst_gen #(
    .ClkPeriod   (CLK_PERIOD),
    .RstClkCycles(RST_CLK_CYCLES)
  ) i_rst_gen (
    .clk_o (clk),
    .rst_no(rst_n)
  );

  logic [SHARE_WIDTH-1:0] dut_a_i [2];
  logic [SHARE_WIDTH-1:0] dut_b_i [2];
  logic [RAND_WIDTH-1:0]  dut_flat_rand_i;
  logic                   dut_valid_i;
  logic                   dut_sum_o [2];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      dut_a_i[0]      <= '0;
      dut_a_i[1]      <= '0;
      dut_b_i[0]      <= '0;
      dut_b_i[1]      <= '0;
      dut_flat_rand_i <= '0;
      dut_valid_i     <= '0;
    end else begin
      dut_a_i[0]      <= stim.a.share0;
      dut_a_i[1]      <= stim.a.share1;
      dut_b_i[0]      <= stim.b.share0;
      dut_b_i[1]      <= stim.b.share1;
      dut_flat_rand_i <= stim.rand_data;
      dut_valid_i     <= stim.valid;
    end
  end

  assign act_resp.share0 = dut_sum_o[0];
  assign act_resp.share1 = dut_sum_o[1];

  // Instantiate the DUT.
  otbn_sec_add_sca_test_wrapper dut (
    .clk_i(clk),
    .rst_ni(rst_n),

    .en_i(dut_valid_i),
    .rand_i(dut_flat_rand_i),
    .share0_i({dut_b_i[0], dut_a_i[0]}),
    .share1_i({dut_b_i[1], dut_a_i[1]}),

    .sum_o('{dut_sum_o[1], dut_sum_o[0]})
  );

  initial begin: rand_application_block
    stim.rand_data = 0;
    wait (rst_n);
    while (n_checks < TOT_STIMS) begin
      @(posedge clk);
      #(APPL_DELAY);
      stim.rand_data = 3'b111;
    end
    stim.rand_data = 0;
  end

  initial begin: application_block
    stim.a = 0;
    stim.b = 0;
    stim.valid = 0;
    n_stims = 0;
    wait (rst_n);
    while (n_stims < TOT_STIMS) begin
      @(posedge clk);
      #(APPL_DELAY);
      stim.a.share0 = SHARE_WIDTH'($urandom());
      stim.a.share1 = SHARE_WIDTH'($urandom());
      stim.b.share0 = SHARE_WIDTH'($urandom());
      stim.b.share1 = SHARE_WIDTH'($urandom());
      stim.a.share0 = 2'h1;
      stim.a.share1 = 2'h2;
      stim.b.share0 = 2'h2;
      stim.b.share1 = 2'h3;
      // $display("INPUT A0: %08h", stim.a.share0);
      // $display("INPUT A1: %08h", stim.a.share1);
      // $display("INPUT B0: %08h", stim.b.share0);
      // $display("INPUT B1: %08h", stim.b.share1);
      // $display("INPUT A: %08h", (stim.a.share0 ^ stim.a.share1));
      // $display("INPUT B: %08h", (stim.b.share0 ^ stim.b.share1));
      stim.valid = 1'b1;
      n_stims = n_stims + 1;
    end
    @(posedge clk);
    #(APPL_DELAY);
    stim.a = 0;
    stim.b = 0;
    stim.valid = 0;
  end

  // Acquire response
  initial begin: acquire_block
    wait (rst_n);
    #(LATENCY);
    while (n_checks < TOT_STIMS) begin
      @(posedge clk);
      #(ACQ_DELAY);
      acq_resp_queue.push_back(act_resp);
    end
  end

  // Golden Model
  initial begin: golden_block
    logic [SHARE_WIDTH-1:0] a_unmasked;
    logic [SHARE_WIDTH-1:0] b_unmasked;
    logic [SHARE_WIDTH-1:0] pre_p;
    logic [SHARE_WIDTH-1:0] pre_g;
    logic [SHARE_WIDTH-1:0] gold_val;
    wait (rst_n);
    while (n_stims < TOT_STIMS) begin
      @(posedge clk);
      #(ACQ_DELAY);
      a_unmasked = stim.a.share0 ^ stim.a.share1;
      b_unmasked = stim.b.share0 ^ stim.b.share1;
      pre_p = a_unmasked ^ b_unmasked;
      pre_g = a_unmasked & b_unmasked;
      gold_val = pre_g[1] ^ (pre_p[1] &pre_g[0]);
      exp_resp_queue.push_back(gold_val);
    end
  end

  // Check response
  initial begin: checker_block
    masked_coeff_resp_t acq_resp;
    logic exp_resp, acq_resp_unmasked;

    n_checks = 0;
    n_errs   = 0;
    wait (rst_n);
    #(LATENCY);
    while (n_checks < TOT_STIMS) begin
      @(posedge clk);
      #(ACQ_DELAY);
      if (acq_resp_queue.size() > 0 && exp_resp_queue.size() > 0) begin
        n_checks += 1;
        acq_resp = acq_resp_queue.pop_front();
        exp_resp = exp_resp_queue.pop_front();
        acq_resp_unmasked = acq_resp.share0 ^ acq_resp.share1;
        if (acq_resp_unmasked !== exp_resp) begin
          n_errs = n_errs + 1;
          $display("[FAIL] Time: %0t | Expected: %08h | Acquired: %08h (Shares: %08h ^ %08h)",
            $time, exp_resp, acq_resp_unmasked, acq_resp.share0, acq_resp.share1);
        end
      end
    end
    if (n_errs > 0) begin
      $display("Test ***FAILED*** with ", n_errs, " mismatches out of ", n_checks, " checks after ", n_stims, " stimuli!");
    end else begin
      $display("Test ***PASSED*** with ", n_errs, " mismatches out of ", n_checks, " checks after ", n_stims, " stimuli.");
    end
    $finish();
  end

  initial begin: record_traces
    $dumpfile("dump.vcd");
    $dumpvars(0, otbn_sec_add_tb);
  end

endmodule
