module prim_ml_dsa_sec_b2a_q_tb ();

    timeunit 1ns;
    timeprecision 10ps;

    localparam time CLK_PERIOD         = 50ns;
    localparam time APPL_DELAY         = 10ns;
    localparam time ACQ_DELAY          = 30ns;
    localparam unsigned RST_CLK_CYCLES = 10;
    localparam unsigned TOT_STIMS      = 10000;
    localparam unsigned SHARE_WIDTH    = 23;
    localparam unsigned RAND_WIDTH     = 114;
    localparam unsigned MODULUS        = 8380417;

    integer n_stims,
            n_checks,
            n_errs;

    typedef struct packed {
        logic [ShareWidth-1:0] share0, share1;
    } masked_coeff_t;

    masked_coeff_t  act_resp,
                    acq_resp_queue[$],
                    stim;
    
    logic [ShareWidth-1:0] exp_resp_queue[$];

    logic clk, rst_n,
          inp_valid, inp_ready,
          oup_valid, oup_ready;

    logic[SHARE_WIDTH-1:0] gamma, mask, secret;
    logic[RAND_WIDTH-1:0]  rand_val;

    prim_ml_dsa_clk_rst_gen #(
        .ClkPeriod   (CLK_PERIOD),
        .RstClkCycles(RST_CLK_CYCLES)
    ) i_prim_ml_dsa_clk_rst_gen (
        .clk_o (clk),
        .rst_no(rst_n)
    );

    // Instantiate the DUT.
    prim_ml_dsa_sec_b2a_q dut (
      .clk_i(clk),
      .rst_ni(rst_n),
  
      .valid_i(inp_valid),
      .ready_o(inp_ready),
  
      .valid_o(oup_valid),
      .ready_i(oup_ready),

      .x0_i(stim.share0),
      .x1_i(stim.share1),
      .gamma_i(gamma),
      .r_i(rand_val),

      .z0_o(act_resp.share0),
      .z1_o(act_resp.share1)
    );

    initial begin: application_block
        inp_valid = 0;
        stim = 0;
        gamma = 0;
        rand_val = 0;
        n_stims = 0;
        wait (rst_n);
        while (n_stims < TOT_STIMS) begin
            @(posedge clk);
            #(APPL_DELAY);
            randomize(inp_valid);
            if (inp_valid) begin
                std::randomize(gamma);
                std::randomize(rand_val);
                std::randomize(mask);
                secret = $urandom_range(MODULUS-1);
                stim.share0 = secret ^ mask;
                stim.share1 = mask;
                #(ACQ_DELAY-APPL_DELAY);
                n_stims = n_stims + 1;
                wait (inp_ready);
            end
        end
        @(posedge clk);
        #(APPL_DELAY);
        inp_valid = 0;
        stim = 0;
        gamma = 0;
        rand_val = 0;
    end

    // Acquire response
    initial begin: acquire_block
        wait (rst_n);
        while (1) begin
            @(posedge clk);
            #(ACQ_DELAY);
            if (oup_valid) begin
                acq_resp_queue.push_back(act_resp);
            end
        end
    end

    // Golden Model
    initial begin: golden_block
        logic [ShareWidth-1:0] gold_val;
        while (1) begin
            @(posedge clk);
            #(ACQ_DELAY);
            if (inp_valid && inp_ready) begin
                gold_val = stim.share0 ^ stim.share1;
                exp_resp_queue.push_back(gold_val);
            end
        end
    end

    // Check response
    initial begin: checker_block
        masked_coeff_t acq_resp,
                       exp_resp;

        logic [ShareWidth-1:0] acq_resp_unmasked;

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
                acq_resp_unmasked = (acq_resp.share0 + acq_resp.share1) % MODULUS;
                if (acq_resp_unmasked !== exp_resp) begin
                    n_errs = n_errs + 1;
                    $display("Mismatch occurred at %d: acquired (%2x + %2x) mod q = %2x, expected %2x",
                        $time, acq_resp.share0, acq_resp.share01, acq_resp.b, exp_resp);
                end
            end
        end
        if (n_errs > 0) begin
            $display("Test ***FAILED*** with ", n_errs, " mismatches out of ", n_checks, " checks after ", n_stims, " stimuli!");
        end else begin
            $display("Test ***PASSED*** with ", n_errs, " mismatches out of ", n_checks, " checks after ", n_stims, " stimuli.");
        end
        $stop();
    end

endmodule
