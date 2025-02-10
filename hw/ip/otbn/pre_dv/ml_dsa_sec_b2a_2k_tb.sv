module ml_dsa_sec_b2a_2k_tb ();

    timeunit 1ns;
    timeprecision 10ps;

    localparam time CLK_PERIOD         = 50ns;
    localparam time APPL_DELAY         = 10ns;
    localparam time ACQ_DELAY          = 30ns;
    localparam unsigned RST_CLK_CYCLES = 10;
    localparam unsigned TOT_STIMS      = 1000;
    localparam unsigned SHARE_WIDTH    = 23;
    localparam unsigned MODULUS        = 8380417;

    integer n_stims,
            n_checks,
            n_errs;

    typedef struct packed {
        logic [SHARE_WIDTH-1:0] x1, x2, gamma;
    } masked_coeff_inp_t;

    typedef struct packed {
        logic [SHARE_WIDTH:0] z1, z2;
    } masked_coeff_oup_t;

    masked_coeff_oup_t  act_resp,
                        acq_resp_queue[$];

    masked_coeff_inp_t  stim;
    
    logic [SHARE_WIDTH:0] exp_resp_queue[$];

    logic clk, rst_n;

    ml_dsa_clk_rst_gen #(
        .ClkPeriod   (CLK_PERIOD),
        .RstClkCycles(RST_CLK_CYCLES)
    ) i_ml_dsa_clk_rst_gen (
        .clk_o (clk),
        .rst_no(rst_n)
    );

    // Instantiate the DUT.
    ml_dsa_sec_b2a_2k dut (
        .clk_i(clk),
        .rst_ni(rst_n),

        .x1_i(stim.x1),
        .x2_i(stim.x2),
        .gamma_i(stim.gamma),

        .z1_o(act_resp.z1),
        .z2_o(act_resp.z2)
    );

    initial begin: application_block
        logic [SHARE_WIDTH-1:0] temp, mask;
        stim = 0;
        n_stims = 0;
        wait (rst_n);
        while (n_stims < TOT_STIMS) begin
            @(posedge clk);
            #(APPL_DELAY);
            temp = SHARE_WIDTH'($urandom_range(MODULUS-1, 0));
            mask = SHARE_WIDTH'($urandom());
            stim.x1 = temp ^ mask;
            stim.x2 = mask;
            stim.gamma = SHARE_WIDTH'($urandom());
            n_stims = n_stims + 1;
            #(ACQ_DELAY-APPL_DELAY);
        end
        @(posedge clk);
        #(APPL_DELAY);
        stim = 0;
    end

    // Acquire response
    initial begin: acquire_block
        wait (rst_n);
        while (1) begin
            @(posedge clk);
            #(ACQ_DELAY);
            acq_resp_queue.push_back(act_resp);
        end
    end

    // Golden Model
    initial begin: golden_block
        logic [SHARE_WIDTH:0] gold_val;
        wait (rst_n);
        while (1) begin
            @(posedge clk);
            #(ACQ_DELAY);
            gold_val = {1'b0, stim.x1 ^ stim.x2};
            exp_resp_queue.push_back(gold_val);
        end
    end

    // Check response
    initial begin: checker_block
        masked_coeff_oup_t acq_resp;
        logic [SHARE_WIDTH:0] exp_resp, acq_resp_unmasked;

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
                acq_resp_unmasked = (acq_resp.z1 - acq_resp.z2) % MODULUS;
                if (acq_resp_unmasked !== exp_resp) begin
                    n_errs = n_errs + 1;
                    $display("Mismatch occurred at %d: acquired (%2x + %2x) mod q = %2x, expected %2x",
                        $time, acq_resp.z1, acq_resp.z2,
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
