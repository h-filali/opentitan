// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

class aes_reseed_test extends aes_base_test;
  `uvm_component_utils(aes_reseed_test)
  `uvm_component_new

   virtual function void build_phase(uvm_phase phase);
     super.build_phase(phase);
     configure_env();
  endfunction

  virtual function void configure_env();
    // should the read vs write be unbalanced.
    cfg.unbalanced               = 1;
    cfg.read_prob                = 60;
    cfg.write_prob               = 80;
    cfg.error_types              = 0;
    cfg.num_messages_min         = 1;
    cfg.num_messages_max         = 50;
    // message related knobs
    cfg.ecb_weight               = 10;
    cfg.cbc_weight               = 10;
    cfg.ctr_weight               = 10;
    cfg.ofb_weight               = 10;
    cfg.cfb_weight               = 10;

    cfg.message_len_min          = 7;   // bytes
    cfg.message_len_max          = 1023; // bytes

    cfg.fixed_data_en            = 0;
    cfg.fixed_key_en             = 0;

    cfg.fixed_operation_en       = 0;
    cfg.fixed_operation          = aes_pkg::AES_ENC;

    cfg.fixed_keylen_en          = 0;
    cfg.fixed_keylen             = 3'b010;

    cfg.fixed_iv_en              = 0;

    cfg.random_data_key_iv_order = 1;
    cfg.read_prob                = 65;
    cfg.write_prob               = 80;
    cfg.manual_operation_pct     = 30;
    cfg.sideload_pct             = 30;
  endfunction // configure_env
endclass : aes_reseed_test
