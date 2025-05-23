// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

class chip_sw_inject_scramble_seed_vseq extends chip_sw_base_vseq;
  `uvm_object_utils(chip_sw_inject_scramble_seed_vseq)

  `uvm_object_new

  virtual task dut_init(string reset_kind = "HARD");
    super.dut_init(reset_kind);

    // make sure it is unlocked and empty to start
    for (int i = 0; i < 4; i++) begin
      cfg.mem_bkdr_util_h[Otp].write64(otp_ctrl_reg_pkg::SramDataKeySeedOffset + i*8,
                                       '0);
    end


    cfg.mem_bkdr_util_h[Otp].write64(otp_ctrl_reg_pkg::Secret1DigestOffset,
                                     '0);


    // make sure we are in prod state
    otp_write_lc_partition_state(cfg.mem_bkdr_util_h[Otp], LcStProd);

    `uvm_fatal(`gfn, "This sequence is currently not functional and needs to be fixed.")

  endtask // dut_init

  virtual task body();
    super.body();

    `DV_SPINWAIT(wait(cfg.sw_logger_vif.printed_log ==
                      "Completed first phase, wait for reset");,
                 "timeout waiting for C side acknowledgement",
                 cfg.sw_test_timeout_ns)

    `uvm_info(`gfn, "Received C side acknowledgement", UVM_LOW)

    // setup triggers to bootstrap during the second run
    cfg.use_spi_load_bootstrap = 1'b1;

    `DV_SPINWAIT(wait(cfg.sw_logger_vif.printed_log ==
                      "Boot strap requested");,
                 "timeout waiting for C side acknowledgement",
                 cfg.sw_test_timeout_ns)

    `uvm_info(`gfn, "Received C side acknowledgement", UVM_LOW)

    spi_device_load_bootstrap({cfg.sw_images[SwTypeTestSlotA], ".64.vmem"});
    cfg.use_spi_load_bootstrap = 1'b0;

    `DV_SPINWAIT(wait(cfg.sw_logger_vif.printed_log == "Hello World");,
             "timeout waiting for Hello World",
             cfg.sw_test_timeout_ns)

  endtask



endclass : chip_sw_inject_scramble_seed_vseq
