module ml_dsa_dom_and_tb ();

    timeunit 1ns;
    timeprecision 10ps;

    localparam time CLK_PERIOD         = 50ns;
    localparam time APPL_DELAY         = 10ns;
    localparam time ACQ_DELAY          = 30ns;
    localparam unsigned RST_CLK_CYCLES = 10;
    localparam unsigned TOT_STIMS      = 100;

    integer n_stims,
            n_checks,
            n_errs;

    typedef struct packed {
        logic a0, a1, b0, b1, r0;
    } and_xor_inputs_t;

    typedef struct packed {
        logic y0, y1;
    } and_xor_outputs_t;

    and_xor_outputs_t act_resp,
                      acq_resp_queue[$],
                      exp_resp_queue[$];

    and_xor_inputs_t stim;

    logic clk, rst_n;

    ml_dsa_clk_rst_gen #(
        .ClkPeriod   (CLK_PERIOD),
        .RstClkCycles(RST_CLK_CYCLES)
    ) i_ml_dsa_clk_rst_gen (
        .clk_o (clk),
        .rst_no(rst_n)
    );

    // Instantiate the DUT.
    ml_dsa_dom_and dut (
        .clk_i(clk),
        .rst_ni(rst_n),

        .a0_i(stim.a0),
        .a1_i(stim.a1),
        .b0_i(stim.b0),
        .b1_i(stim.b1),
        .r0_i(stim.r0),

        .y0_o(act_resp.y0),
        .y1_o(act_resp.y1)
    );

    initial begin: application_block
        stim = 0;
        n_stims = 0;
        wait (rst_n);
        while (n_stims < TOT_STIMS) begin
            @(posedge clk);
            #(APPL_DELAY);
            stim = 5'($urandom());
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
        @(posedge clk);
        while (1) begin
            @(posedge clk);
            #(ACQ_DELAY);
            acq_resp_queue.push_back(act_resp);
        end
    end

    // Golden Model
    initial begin: golden_block
        and_xor_outputs_t gold_val;
        logic y0p, y1p, y2p, y3p;
        wait (rst_n);
        while (1) begin
            @(posedge clk);
            #(ACQ_DELAY);
            y0p = (stim.a0 & stim.b0);
            y1p = (stim.a0 & stim.b1) ^ stim.r0;
            y2p = (stim.a1 & stim.b0) ^ stim.r0;
            y3p = (stim.a1 & stim.b1);
            gold_val.y0 = y0p ^ y1p;
            gold_val.y1 = y2p ^ y3p;
            exp_resp_queue.push_back(gold_val);
        end
    end

    // Check response
    initial begin: checker_block
        and_xor_outputs_t acq_resp, exp_resp;

        n_checks = 0;
        n_errs   = 0;
        wait (rst_n);
        @(posedge clk);
        while (n_checks < TOT_STIMS) begin
            @(posedge clk);
            #(ACQ_DELAY);
            if (acq_resp_queue.size() > 0 && exp_resp_queue.size() > 0) begin
                n_checks += 1;
                acq_resp = acq_resp_queue.pop_front();
                exp_resp = exp_resp_queue.pop_front();
                if (acq_resp !== exp_resp) begin
                    n_errs = n_errs + 1;
                    $display("Mismatch occurred at %d: acquired y0=%x, y1=%x, expected y0=%x, y1=%x",
                        $time, acq_resp.y0, acq_resp.y1, exp_resp.y0, exp_resp.y1);
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
