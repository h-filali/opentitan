module otbn_mask_accelerator_tb ();
  import otbn_pkg::*;

  timeunit 1ns;
  timeprecision 10ps;

  localparam otbn_pkg::state_mask_op_e OpMode = otbn_pkg::SecAddMod;

  localparam time CLK_PERIOD         = 50ns;
  localparam time APPL_DELAY         = 10ns;
  localparam time ACQ_DELAY          = 30ns;
  localparam unsigned RST_CLK_CYCLES = 10;
  localparam unsigned VEC_SIZE       = 8;
  // Has to be a multiple of the vector size.
  localparam unsigned TOT_STIMS       = 10*VEC_SIZE;
  localparam unsigned SHARE_WIDTH     = 32;
  localparam unsigned STAGES          = $clog2(SHARE_WIDTH);
  localparam unsigned RAND_WIDTH      = 2*(STAGES*SHARE_WIDTH + 1);

  int n_stims  = 0,
      n_checks = 0,
      n_errs   = 0;

  typedef struct packed {
    logic [SHARE_WIDTH-1:0] share0;
    logic [SHARE_WIDTH-1:0] share1;
  } masked_coeff_t;

  typedef struct packed {
    masked_coeff_t          a;
    masked_coeff_t          b;
    logic [SHARE_WIDTH-1:0] q;
    logic                   wvalid;
    state_mask_op_e         mask_op;
    logic [RAND_WIDTH-1:0]  rand_data;
    masked_coeff_t          masks;
  } coeff_op_t;

  coeff_op_t stim;
  masked_coeff_t act_resp,
                 acq_resp_queue[$];

  logic [SHARE_WIDTH-1:0] exp_resp_queue[$];

  logic clk, rst_n;

  clk_rst_gen #(
    .ClkPeriod   (CLK_PERIOD),
    .RstClkCycles(RST_CLK_CYCLES)
  ) i_rst_gen (
    .clk_o (clk),
    .rst_no(rst_n)
  );

  logic [SHARE_WIDTH-1:0] dut_a [2];
  logic [SHARE_WIDTH-1:0] dut_b [2];
  logic [SHARE_WIDTH-1:0] dut_masks [2];
  logic [SHARE_WIDTH-1:0] dut_q;
  logic [RAND_WIDTH-1:0]  dut_rand;
  state_mask_op_e         dut_mask_op;
  logic                   dut_wready;
  logic                   dut_wvalid;
  logic                   dut_rvalid;
  logic [SHARE_WIDTH-1:0] dut_sum [2];

  assign dut_a[0]     = stim.a.share0;
  assign dut_a[1]     = stim.a.share1;
  assign dut_b[0]     = stim.b.share0;
  assign dut_b[1]     = stim.b.share1;
  assign dut_masks[0] = stim.masks.share0;
  assign dut_masks[1] = stim.masks.share1;
  assign dut_q        = stim.q;
  assign dut_rand     = stim.rand_data;
  assign dut_mask_op  = stim.mask_op;
  assign dut_wvalid   = stim.wvalid;

  assign act_resp.share0 = dut_sum[0];
  assign act_resp.share1 = dut_sum[1];

  // Instantiate the DUT.
  otbn_mask_accelerator dut (
    .clk_i(clk),
    .rst_ni(rst_n),

    .wvalid_i(dut_wvalid),
    .wready_o(dut_wready),
    .a_i(dut_a),
    .b_i(dut_b),

    .rand_i(dut_rand),
    .masks_i(dut_masks),

    .q_i(dut_q),
    .mask_op_i(dut_mask_op),

    .rvalid_o(dut_rvalid),
    .rready_i(1'b1),
    .sum_o(dut_sum),

    .mask_fifo_err_o(),
    .ctr_err_o()
  );

  // Refresh rand_data and masks with fresh randomness. Must be called every cycle
  // so the DUT never reuses the same randomness across pipeline stages.
  task automatic refresh_rand;
    dut_rand = RAND_WIDTH'({
      $urandom(), $urandom(), $urandom(), $urandom(),
      $urandom(), $urandom(), $urandom(), $urandom(),
      $urandom(), $urandom(), $urandom()
    });
    stim.masks.share0 = $urandom();
    stim.masks.share1 = $urandom();
  endtask

  initial begin: application_block
    logic [SHARE_WIDTH-1:0] mask_a, mask_b;
    logic [SHARE_WIDTH-1:0] unmasked_a, unmasked_b;
    logic [SHARE_WIDTH-1:0] sub_q;
    int q_bits;
    logic [SHARE_WIDTH-1:0] q_mask;
    stim = 0;
    stim.q = SHARE_WIDTH'($urandom());
    q_bits = $clog2(stim.q + 1);
    q_mask = (SHARE_WIDTH'(1) << q_bits) - 1;

    stim.mask_op = OpMode;
    wait (rst_n);
    while (n_stims < TOT_STIMS) begin
      for (int i = 0; i < VEC_SIZE; i++) begin
        @(posedge clk);
        #(APPL_DELAY);
        refresh_rand();

        if (OpMode == otbn_pkg::BoolToArith) begin
          // Retry until the registered mask satisfies mask_mod < q (wready).
          // refresh_rand() must come BEFORE @(posedge clk) so that the mask
          // that caused wready=1 is the same one still in stim.masks when the
          // valid transaction is presented on the next cycle.
          while ((stim.masks.share0 & q_mask) >= stim.q) begin
            @(posedge clk);
            #(APPL_DELAY);
            refresh_rand();
          end
        end

        mask_a = SHARE_WIDTH'($urandom());
        mask_b = SHARE_WIDTH'($urandom());

        if (OpMode == otbn_pkg::SecAddMod) begin
          // Modulus operations can't be stored directly into structs.
          // Otherwise the result might be incorrect due to word offsets inside the struct.
          unmasked_a = {$urandom()} % stim.q;
          unmasked_b = {$urandom()} % stim.q;
          sub_q = -stim.q;  // 2's-complement negation; avoids 32-bit shift overflow
          stim.a.share0 = (unmasked_a + sub_q) ^ mask_a;
          stim.a.share1 = mask_a;
          stim.b.share0 = unmasked_b ^ mask_b;
          stim.b.share1 = mask_b;
        end else if (OpMode == otbn_pkg::ArithToBool) begin
          // Modulus operations can't be stored directly into structs.
          // Otherwise the result might be incorrect due to word offsets inside the struct.
          unmasked_a = {$urandom()} % stim.q;
          unmasked_b = {$urandom()} % stim.q;
          stim.a.share0 = unmasked_a;
          stim.a.share1 = unmasked_b;

          stim.b.share0 = '0;
          stim.b.share1 = '0;
        end else if (OpMode == otbn_pkg::BoolToArith) begin
          // Modulus operations can't be stored directly into structs.
          // Otherwise the result might be incorrect due to word offsets inside the struct.
          unmasked_a = {$urandom()} % stim.q;
          stim.a.share0 = unmasked_a ^ mask_a;
          stim.a.share1 = mask_a;
          stim.b.share0 = '0;
          stim.b.share1 = '0;
        end else begin
          unmasked_a = SHARE_WIDTH'($urandom());
          unmasked_b = SHARE_WIDTH'($urandom());
          stim.a.share0 = unmasked_a ^ mask_a;
          stim.a.share1 = mask_a;
          stim.b.share0 = unmasked_b ^ mask_b;
          stim.b.share1 = mask_b;
        end

        stim.wvalid = 1'b1;
        n_stims = n_stims + 1;
      end
      if (OpMode != otbn_pkg::SecAdd) begin
        // Deassert valid and keep refreshing rand for the rest of the pipeline flush.
        int num_iters = (OpMode == otbn_pkg::ArithToBool) ? VEC_SIZE + 1 : VEC_SIZE;
        for (int i = 0; i < num_iters; i++) begin
          @(posedge clk);
          #(APPL_DELAY);
          refresh_rand();
          stim.wvalid = 1'b0;
          stim.a = '0;
          stim.b = '0;
        end
      end
    end
    @(posedge clk);
    #(APPL_DELAY);
    stim.wvalid = 1'b0;
    stim.a = '0;
    stim.b = '0;
  end

  // Acquire response
  initial begin: acquire_block
    wait (rst_n);
    while (n_checks < TOT_STIMS) begin
      @(posedge clk);
      #(ACQ_DELAY);
      if (dut_rvalid) begin
        acq_resp_queue.push_back(act_resp);
      end
    end
  end

  // Golden Model
  // Samples dut_* signals (the registered DUT inputs) so the timing matches what the DUT sees.
  //
  // A2B timing note: the DUT has a one-cycle register stage on a/b before the adder.
  // That flop latches the combinational a/b at the posedge AFTER inp_valid fires.
  // By then, APPL_DELAY has already updated dut_a/dut_masks to the next element's values.
  // So the DUT effectively computes with the next cycle's dut_a.  To match, the A2B golden
  // value is deferred: when wvalid&&wready fires we set a flag, then push the gold at the
  // NEXT ACQ_DELAY (when dut_a already reflects the values the register stage will capture).
  initial begin: golden_block
    logic [SHARE_WIDTH-1:0] gold_val;
    logic [SHARE_WIDTH-1:0] a_unmasked;
    logic [SHARE_WIDTH:0]   full_sum;

    wait (rst_n);
    // Loop one cycle beyond n_stims == TOT_STIMS: dut_wvalid is registered, so the last
    // stimulus only appears on dut_wvalid one cycle after application_block sets stim.wvalid.
    while (n_stims <= TOT_STIMS) begin
      @(posedge clk);
      #(ACQ_DELAY);

      // dut_wvalid/dut_wready reflect the registered inputs the DUT actually processes.
      if (dut_wvalid && dut_wready) begin
        unique case (dut_mask_op)
          otbn_pkg::SecAddMod: begin
            // a_xor = unmasked_a - q (32-bit wrap). Add q back in a 32-bit variable so
            // the 2^32 wrap cancels before zero-extending to 33-bit for the final sum.
            a_unmasked = (dut_a[0] ^ dut_a[1]) + dut_q;
            full_sum   = 33'(a_unmasked) + 33'(dut_b[0] ^ dut_b[1]);
            gold_val   = full_sum % dut_q;
          end
          otbn_pkg::ArithToBool: begin
            gold_val = (dut_a[0] + dut_a[1]) % dut_q;
          end
          otbn_pkg::BoolToArith: begin
            // a carries XOR shares of the input; b is unused (driven to 0).
            gold_val = dut_a[0] ^ dut_a[1];
          end
          default: begin  // SecAdd
            gold_val = (dut_a[0] ^ dut_a[1]) + (dut_b[0] ^ dut_b[1]);
          end
        endcase
        exp_resp_queue.push_back(gold_val);
      end
    end
  end

  // Check response
  initial begin: checker_block
    masked_coeff_t acq_resp;
    logic [SHARE_WIDTH-1:0] exp_resp, acq_resp_unmasked;

    wait (rst_n);
    while (n_checks < TOT_STIMS) begin
      @(posedge clk);
      #(ACQ_DELAY);
      if (acq_resp_queue.size() > 0 && exp_resp_queue.size() > 0) begin
        n_checks += 1;
        acq_resp = acq_resp_queue.pop_front();
        exp_resp = exp_resp_queue.pop_front();
        // BoolToArith outputs arithmetic shares (sum mod q); all other modes output XOR shares.
        if (dut_mask_op == otbn_pkg::BoolToArith) begin
          acq_resp_unmasked = (acq_resp.share0 + acq_resp.share1) % dut_q;
          if (acq_resp_unmasked !== exp_resp)
            $display("[FAIL] Time: %0t | Expected: %08h | Got: %08h (Shares: %08h + %08h)",
              $time, exp_resp, acq_resp_unmasked, acq_resp.share0, acq_resp.share1);
        end else begin
          acq_resp_unmasked = acq_resp.share0 ^ acq_resp.share1;
          if (acq_resp_unmasked !== exp_resp)
            $display("[FAIL] Time: %0t | Expected: %08h | Got: %08h (Shares: %08h ^ %08h)",
              $time, exp_resp, acq_resp_unmasked, acq_resp.share0, acq_resp.share1);
        end
        if (acq_resp_unmasked !== exp_resp) n_errs = n_errs + 1;
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
    $dumpvars(0, otbn_mask_accelerator_tb);
  end

endmodule
