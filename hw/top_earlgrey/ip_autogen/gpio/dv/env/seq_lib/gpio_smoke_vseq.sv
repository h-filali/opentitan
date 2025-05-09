// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// class : gpio_smoke_vseq
// This is a smoke test sequence for gpio.
// This sequence does following:
// (i) drives random gpio input data with gpio outputs disabled
// (ii) programs random values of gpio output data and output enable
class gpio_smoke_vseq extends gpio_base_vseq;
  `uvm_object_utils(gpio_smoke_vseq)

  // gpio input to drive
  rand bit [NUM_GPIOS-1:0] gpio_i;
  // gpio output to program in register
  rand bit [NUM_GPIOS-1:0] gpio_o;
  // gpio output enable to program in register
  rand bit [NUM_GPIOS-1:0] gpio_oe;

  `uvm_object_new

  virtual task dut_init(string reset_kind = "HARD");
    // Continue using randomized value by default, unless plusarg
    // no_pullup_pulldown is passed to have no pullup/pulldown
    set_gpio_pulls(.pu(cfg.pullup_en), .pd(cfg.pulldown_en));
    super.dut_init(reset_kind);
  endtask: dut_init

  task body();
    // test gpio inputs
    `DV_CHECK_MEMBER_RANDOMIZE_FATAL(num_trans)
    `uvm_info(`gfn, $sformatf("No. of transactions (gpio_i) = %0d", num_trans), UVM_HIGH)
    for (uint tr_num = 0; tr_num < num_trans; tr_num++) begin
      bit [TL_DW-1:0] csr_rd_val;
      string msg_id = {`gfn, $sformatf(" Transaction-%0d: ", tr_num)};
      `DV_CHECK_MEMBER_RANDOMIZE_FATAL(gpio_i)
      cfg.gpio_vif.drive(gpio_i);
`ifdef GPIO_ASYNC_ON
      // If the CDC synchronizer prims are instantiated, it takes 2-3 cycles longer for inputs
      // to propagate to the register (2 for the sync flops and 0-1 for CDC randomization).
      `DV_CHECK_MEMBER_RANDOMIZE_WITH_FATAL(delay, delay >= 1 + 3;)
`else
      // Wait at least one clock cycle
      `DV_CHECK_MEMBER_RANDOMIZE_WITH_FATAL(delay, delay >= 1;)
`endif

      cfg.clk_rst_vif.wait_clks_or_rst(delay);
      // Skip if a reset is ongoing...
      if (!cfg.clk_rst_vif.rst_n) return;

      // Reading data_in will trigger a check inside scoreboard
      csr_rd(.ptr(ral.data_in), .value(csr_rd_val));
      `uvm_info(msg_id, {$sformatf("reading data_in after %0d clock cycles ", delay),
                         $sformatf("csr_rd_val = %0h", csr_rd_val)}, UVM_HIGH)
    end

    // test gpio outputs
    cfg.gpio_vif.drive_en('0);
    `DV_CHECK_MEMBER_RANDOMIZE_FATAL(num_trans)
    `uvm_info(`gfn, $sformatf("No. of transactions (gpio_o) = %0d", num_trans), UVM_HIGH)
    for (uint tr_num = 0; tr_num < num_trans; tr_num++) begin
      logic [NUM_GPIOS-1:0] exp_gpio_o;
      logic [NUM_GPIOS-1:0] obs_gpio_o;
      string msg_id = {`gfn, $sformatf(" Transaction-%0d: ", tr_num)};

      `DV_CHECK_MEMBER_RANDOMIZE_FATAL(gpio_o)
      `DV_CHECK_MEMBER_RANDOMIZE_FATAL(gpio_oe)
      `uvm_info(msg_id, $sformatf("writing direct_out = 0x%0h [%0b] direct_oe = 0x%0h [%0b]",
                                  gpio_o, gpio_o, gpio_oe, gpio_oe), UVM_HIGH)
      ral.direct_out.set(gpio_o);
      ral.direct_oe.set(gpio_oe);
      csr_update(.csr(ral.direct_out));
      csr_update(.csr(ral.direct_oe));
      // Wait at least one clock cycle
      `DV_CHECK_MEMBER_RANDOMIZE_WITH_FATAL(delay, delay >= 1;)
      `uvm_info(msg_id, $sformatf("waiting for %0d clock cycles", delay), UVM_HIGH)
      cfg.clk_rst_vif.wait_clks_or_rst(delay);
    end
  endtask : body

endclass : gpio_smoke_vseq
