module ml_dsa_dom_and_u_tb ();

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
        logic a0, a1, b0, b1, ui, uim1, r0, r1;
    } and_u_inputs_t;

    typedef struct packed {
        logic x0, x1;
    } shares_t;

    shares_t act_resp,
             acq_resp_queue[$],
             exp_resp_queue[$];

    and_u_inputs_t stim;

    logic clk, rst_n;

    ml_dsa_clk_rst_gen #(
        .ClkPeriod   (CLK_PERIOD),
        .RstClkCycles(RST_CLK_CYCLES)
    ) i_ml_dsa_clk_rst_gen (
        .clk_o (clk),
        .rst_no(rst_n)
    );

    // Instantiate the DUT.
    ml_dsa_dom_and_u dut (
        .clk_i(clk),
        .rst_ni(rst_n),

        .a0_i   (stim.a0),
        .a1_i   (stim.a1),
        .b0_i   (stim.b0),
        .b1_i   (stim.b1),
        .ui_i   (stim.ui),
        .uim1_i (stim.uim1),
        .r0_i   (stim.r0),
        .r1_i   (stim.r1),

        .y0_o   (act_resp.x0),
        .y1_o   (act_resp.x1)
    );

    initial begin: application_block
        stim = 0;
        n_stims = 0;
        wait (rst_n);
        while (n_stims < TOT_STIMS) begin
            @(posedge clk);
            #(APPL_DELAY);
            stim = 8'($urandom());
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
        shares_t gold_val;
        logic y0p, y1p, y2p, y3p, y0, y1, m0, m1, l0, l1, k0, k1;
        wait (rst_n);
        while (1) begin
            @(posedge clk);
            #(ACQ_DELAY);
            y0p = (stim.a0 & stim.b0) ^ stim.r1;
            y1p = (stim.a0 & stim.b1) ^ stim.r0;
            y2p = (stim.a1 & stim.b0) ^ stim.r0;
            y3p = (stim.a1 & stim.b1) ^ stim.r1;
            y0 = y0p ^ y1p;
            y1 = y2p ^ y3p;
            m0 = y0 & stim.uim1;
            m1 = y1 & stim.uim1;
            l0 = stim.a0 & stim.ui;
            l1 = stim.a1 & stim.ui;
            k0 = stim.b0 & stim.ui & stim.uim1;
            k1 = stim.b1 & stim.ui & stim.uim1;
            gold_val.x0 = m0 ^ l0 ^ k0;
            gold_val.x1 = m1 ^ l1 ^ k1;

            exp_resp_queue.push_back(gold_val);
        end
    end

    // Check response
    initial begin: checker_block
        shares_t acq_resp, exp_resp;

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
                        $time, acq_resp.x0, acq_resp.x1, exp_resp.x0, exp_resp.x1);
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
