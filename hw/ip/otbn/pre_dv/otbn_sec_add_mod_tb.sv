module otbn_sec_add_mod_tb ();

  timeunit 1ns;
  timeprecision 10ps;

  localparam otbn_sec_add_pkg::adder_mode_e OpMode = otbn_sec_add_pkg::ModeSecAddMod;

  localparam time CLK_PERIOD         = 50ns;
  localparam time APPL_DELAY         = 10ns;
  localparam time ACQ_DELAY          = 30ns;
  localparam unsigned RST_CLK_CYCLES = 10;
  localparam unsigned VEC_SIZE       = 8;
  // Has to be a multiple of the vector size.
  localparam unsigned TOT_STIMS       = 10000*VEC_SIZE;
  localparam unsigned SHARE_WIDTH     = 32;
  localparam unsigned STAGES          = $clog2(SHARE_WIDTH);
  localparam unsigned RAND_WIDTH      = 2*(STAGES*SHARE_WIDTH + 1);

  integer n_stims,
          n_checks,
          n_errs;

  typedef struct packed {
    logic [SHARE_WIDTH-1:0] share0;
    logic [SHARE_WIDTH-1:0] share1;
  } masked_coeff_t;

  typedef struct packed {
    masked_coeff_t          a;
    masked_coeff_t          b;
    logic [SHARE_WIDTH-1:0] q;
    logic                   enable_mod;
    logic                   valid;
    logic [RAND_WIDTH-1:0]  rand_data;
  } coeff_op_t;

  coeff_op_t stim;
  masked_coeff_t act_resp,
                 acq_resp_queue[$];
  
  logic [SHARE_WIDTH-1:0] exp_resp_queue[$];

  logic clk, rst_n, en;

  clk_rst_gen #(
    .ClkPeriod   (CLK_PERIOD),
    .RstClkCycles(RST_CLK_CYCLES)
  ) i_rst_gen (
    .clk_o (clk),
    .rst_no(rst_n)
  );

  logic [SHARE_WIDTH-1:0] dut_a [2];
  logic [SHARE_WIDTH-1:0] dut_b [2];
  logic [SHARE_WIDTH-1:0] dut_q;
  logic [RAND_WIDTH-1:0]  dut_flat_rand;
  logic                   dut_enable_mod;
  logic                   dut_valid_in;
  logic                   dut_valid_out;
  logic [SHARE_WIDTH-1:0] dut_sum [2];
  logic [SHARE_WIDTH-1:0] unmasked_a;
  logic [SHARE_WIDTH-1:0] unmasked_b;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      dut_a[0]       <= '0;
      dut_a[1]       <= '0;
      dut_b[0]       <= '0;
      dut_b[1]       <= '0;
      dut_q          <= '0;
      dut_flat_rand  <= '0;
      dut_enable_mod <= '0;
      dut_valid_in   <= '0;
    end else begin
      dut_a[0]       <= stim.a.share0;
      dut_a[1]       <= stim.a.share1;
      dut_b[0]       <= stim.b.share0;
      dut_b[1]       <= stim.b.share1;
      dut_q          <= stim.q;
      dut_flat_rand  <= stim.rand_data;
      dut_enable_mod <= stim.enable_mod;
      dut_valid_in   <= stim.valid;
    end
  end

  assign act_resp.share0 = dut_sum[0];
  assign act_resp.share1 = dut_sum[1];

  // Instantiate the DUT.
  otbn_sec_add_mod dut (
    .clk_i(clk),
    .rst_ni(rst_n),

    .enable_mod_i(dut_enable_mod),
    .valid_i(dut_valid_in),
    .stall_i(1'b0),
    .rand_i(dut_flat_rand),
    .a_i(dut_a),
    .b_i(dut_b),
    .q_i(dut_q),

    .sum_o(dut_sum),
    .valid_o(dut_valid_out),
    .fifo_err_o(),
    .ctr_err_o()
  );

  initial begin: config_block
    wait (rst_n);
    stim.q = SHARE_WIDTH'($urandom());
    stim.enable_mod = (OpMode == otbn_sec_add_pkg::ModeSecAdd) ? 1'b0 : 1'b1;
    while (n_checks < TOT_STIMS) begin
      @(posedge clk);
      #(APPL_DELAY);
      stim.rand_data = RAND_WIDTH'({ 
        $urandom(), $urandom(), $urandom(), $urandom(),
        $urandom(), $urandom(), $urandom(), $urandom(),
        $urandom(), $urandom(), $urandom()
      });
    end
  end

  initial begin: application_block
    logic [SHARE_WIDTH-1:0] mask_a;
    logic [SHARE_WIDTH-1:0] mask_b;
    logic [SHARE_WIDTH-1:0] sub_q;
    stim = 0;
    n_stims = 0;
    wait (rst_n);
    while (n_stims < TOT_STIMS) begin
      for (int i = 0; i < VEC_SIZE; i++) begin
        @(posedge clk);
        #(APPL_DELAY);

        mask_a = SHARE_WIDTH'($urandom());
        mask_b = SHARE_WIDTH'($urandom());

        if (OpMode == otbn_sec_add_pkg::ModeSecAdd) begin
          unmasked_a = SHARE_WIDTH'($urandom());
          unmasked_b = SHARE_WIDTH'($urandom());
          stim.a.share0 = unmasked_a ^ mask_a;
        end else begin
          unmasked_a = SHARE_WIDTH'($urandom() % stim.q);
          unmasked_b = SHARE_WIDTH'($urandom() % stim.q);
          sub_q = (1 << (SHARE_WIDTH)) - stim.q;
          stim.a.share0 = (unmasked_a + sub_q) ^ mask_a;
        end

        stim.a.share1 = mask_a;
        stim.b.share0 = unmasked_b ^ mask_b;
        stim.b.share1 = mask_b;

        stim.valid = 1'b1;
        n_stims = n_stims + 1;
      end
      if (OpMode != otbn_sec_add_pkg::ModeSecAdd) begin
        @(posedge clk);
        #(APPL_DELAY);
        stim.valid = 1'b0;
        repeat (VEC_SIZE - 1) @(posedge clk);
      end
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
    while (n_checks < TOT_STIMS) begin
      @(posedge clk);
      #(ACQ_DELAY);
      if (dut_valid_out) begin
        acq_resp_queue.push_back(act_resp);
      end
    end
  end

  // Golden Model
  initial begin: golden_block
    logic [SHARE_WIDTH-1:0] a_unmasked;
    logic [SHARE_WIDTH-1:0] b_unmasked;
    logic [SHARE_WIDTH-1:0] gold_val;
    logic [SHARE_WIDTH-1:0] sub_q;
    logic [SHARE_WIDTH-1:0] real_a;
    logic [SHARE_WIDTH:0]   full_sum;
    
    wait (rst_n);
    while (n_stims < TOT_STIMS) begin
      @(posedge clk);
      #(ACQ_DELAY);
      if (stim.valid) begin
        a_unmasked = stim.a.share0 ^ stim.a.share1;
        b_unmasked = stim.b.share0 ^ stim.b.share1;
        
        if (OpMode == otbn_sec_add_pkg::ModeSecAdd) begin
          gold_val = a_unmasked + b_unmasked;
        end else begin
          sub_q = -stim.q;
          real_a = a_unmasked - sub_q;
          full_sum = 33'(real_a) + 33'(b_unmasked);
          gold_val = full_sum % stim.q;
        end
        exp_resp_queue.push_back(gold_val);
      end
    end
  end

  // Check response
  initial begin: checker_block
    masked_coeff_t acq_resp;
    logic [SHARE_WIDTH-1:0] exp_resp, acq_resp_unmasked;

    n_checks = 0;
    n_errs   = 0;
    wait (rst_n);
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
