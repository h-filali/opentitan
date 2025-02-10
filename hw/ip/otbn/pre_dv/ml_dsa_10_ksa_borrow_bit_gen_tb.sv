module ml_dsa_10_ksa_borrow_bit_gen_tb ();

    timeunit 1ns;
    timeprecision 10ps;

    localparam time CLK_PERIOD         = 50ns;
    localparam time APPL_DELAY         = 10ns;
    localparam time ACQ_DELAY          = 30ns;
    localparam time LATENCY            = 5*CLK_PERIOD;
    localparam unsigned RST_CLK_CYCLES = 10;
    localparam unsigned TOT_STIMS      = 1000;
    localparam unsigned SHARE_WIDTH    = 24;
    localparam unsigned RAND_WIDTH     = 80;
    localparam unsigned MODULUS        = 8380417;

    integer n_stims,
            n_checks,
            n_errs;

    typedef struct packed {
        logic [SHARE_WIDTH-1:0] x0, x1;
        logic [RAND_WIDTH-1:0] r;
    } masked_coeff_inp_t;

    typedef struct packed {
        logic b0, b1;
    } masked_bit_oup_t;

    masked_bit_oup_t  act_resp,
                      acq_resp_queue[$];

    masked_coeff_inp_t stim;

    logic clk, rst_n, exp_resp_queue[$];

    ml_dsa_clk_rst_gen #(
        .ClkPeriod   (CLK_PERIOD),
        .RstClkCycles(RST_CLK_CYCLES)
    ) i_ml_dsa_clk_rst_gen (
        .clk_o (clk),
        .rst_no(rst_n)
    );

    // Instantiate the DUT.
    ml_dsa_10_ksa_borrow_bit_gen dut (
        .clk_i(clk),
        .rst_ni(rst_n),

        .x0_i(stim.x0),
        .x1_i(stim.x1),
        .r_i(stim.r),

        .b0_o(act_resp.b0),
        .b1_o(act_resp.b1)
    );

    initial begin: application_block
        stim = 0;
        n_stims = 0;
        wait (rst_n);
        while (n_stims < TOT_STIMS) begin
            @(posedge clk);
            #(APPL_DELAY);
            stim.x0 = {1'b0, (SHARE_WIDTH-1)'($urandom())};
            stim.x1 = {1'b0, (SHARE_WIDTH-1)'($urandom())};
            stim.r = RAND_WIDTH'($urandom());
            #(ACQ_DELAY-APPL_DELAY);
            n_stims = n_stims + 1;
        end
        @(posedge clk);
        #(APPL_DELAY);
        stim = 0;
    end

    // Acquire response
    initial begin: acquire_block
        wait (rst_n);
        #(LATENCY);
        while (1) begin
            @(posedge clk);
            #(ACQ_DELAY);
            acq_resp_queue.push_back(act_resp);
        end
    end

    // Golden Model
    initial begin: golden_block
        logic [SHARE_WIDTH-1:0] x_unmasked;
        logic gold_val;
        wait (rst_n);
        while (1) begin
            @(posedge clk);
            #(ACQ_DELAY);
            x_unmasked = stim.x0 ^ stim.x1;
            gold_val = (x_unmasked < MODULUS) ? 1'b0 : 1'b1;
            $display("x %x, gold %d, x0 %x, x1 %x, comp %d", x_unmasked, gold_val, stim.x0, stim.x1, x_unmasked < MODULUS);
            exp_resp_queue.push_back(gold_val);
        end
    end

    // Check response
    initial begin: checker_block
        masked_bit_oup_t acq_resp;
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
                acq_resp_unmasked = acq_resp.b0 + acq_resp.b1;
                if (acq_resp_unmasked !== exp_resp) begin
                    n_errs = n_errs + 1;
                    $display("Mismatch occurred at %d: acquired %2x ^ %2x = %2x, expected %2x",
                        $time, acq_resp.b0, acq_resp.b1,
                        acq_resp_unmasked, exp_resp);
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
        $dumpvars();
    end

endmodule
