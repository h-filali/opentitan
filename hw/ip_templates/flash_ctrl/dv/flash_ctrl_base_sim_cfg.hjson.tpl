// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
{
  // Name of the sim cfg - typically same as the name of the DUT.
  name: flash_ctrl

  // Top level dut name (sv module).
  dut: flash_ctrl

  // Top level testbench name (sv module).
  tb: tb

  // Fusesoc core file used for building the file list.
  fusesoc_core: ${instance_vlnv("lowrisc:dv:flash_ctrl_sim:0.1")}

  // Testplan hjson file.
  testplan: "{self_dir}/../data/flash_ctrl_testplan.hjson"

  // Import additional common sim cfg files.
  import_cfgs: [// Project wide common sim cfg file
                "{proj_root}/hw/dv/tools/dvsim/common_sim_cfg.hjson",
                // Config files to get the correct flags for crypto_dpi_prince
                "{proj_root}/hw/ip/prim/dv/prim_prince/crypto_dpi_prince/crypto_dpi_prince_sim_opts.hjson",
                // Common CIP test lists
                "{proj_root}/hw/dv/tools/dvsim/tests/csr_tests.hjson",
                "{proj_root}/hw/dv/tools/dvsim/tests/mem_tests.hjson",
                "{proj_root}/hw/dv/tools/dvsim/tests/alert_test.hjson",
                "{proj_root}/hw/dv/tools/dvsim/tests/intr_test.hjson",
                "{proj_root}/hw/dv/tools/dvsim/tests/shadow_reg_errors_tests.hjson",
                "{proj_root}/hw/dv/tools/dvsim/tests/tl_access_tests.hjson",
                "{proj_root}/hw/dv/tools/dvsim/tests/sec_cm_tests.hjson",
                "{proj_root}/hw/dv/tools/dvsim/tests/stress_all_test.hjson"],

  en_build_modes: ["{tool}_crypto_dpi_prince_build_opts"]
  // Flash references pwrmgr directly, need to reference the top version
  overrides: [
    {
      name: "timescale"
      value: "1ns/100ps"
    }
  ]

// Add additional tops for simulation.
  sim_tops: ["flash_ctrl_bind","flash_ctrl_cov_bind", "sec_cm_prim_onehot_check_bind",
             "sec_cm_prim_count_bind", "sec_cm_prim_sparse_fsm_flop_bind"]

  // Default iterations for all tests - each test entry can override this.
  reseed: 50


  run_modes: [
    {
      name: csr_tests_mode
      run_opts: ["+csr_test_mode=1"]
    }
  ]

  // Add default run opt
  run_opts: ["+flash_rand_delay_en=1"]

  // Default UVM test and seq class name.
  uvm_test: flash_ctrl_base_test
  uvm_test_seq: flash_ctrl_base_vseq

  // Enable cdc instrumentation.
  run_opts: ["+cdc_instrumentation_enabled=1"]

  // List of test specifications.
  tests: [
    {
      name: flash_ctrl_smoke
      uvm_test_seq: flash_ctrl_smoke_vseq
      reseed: 50
    }
    {
      name: flash_ctrl_smoke_hw
      uvm_test_seq: flash_ctrl_smoke_hw_vseq
      reseed: 5
    }
    {
      name: flash_ctrl_rand_ops
      uvm_test_seq: flash_ctrl_rand_ops_vseq
      reseed: 20
    }
    {
      name: flash_ctrl_sw_op
      uvm_test_seq: flash_ctrl_sw_op_vseq
      reseed: 5
    }
    {
      name: flash_ctrl_host_dir_rd
      uvm_test_seq: flash_ctrl_host_dir_rd_vseq
      run_opts: ["+zero_delays=1"]
      reseed: 5
    }
    {
      name: flash_ctrl_rd_buff_evict
      uvm_test_seq: flash_ctrl_rd_buff_evict_vseq
      run_opts: ["+en_cov=1"]
      reseed: 5
    }
    {
      name: flash_ctrl_phy_arb
      uvm_test_seq: flash_ctrl_phy_arb_vseq
      run_opts: ["+zero_delays=1"]
      reseed: 20
    }
    {
      name: flash_ctrl_hw_sec_otp
      uvm_test_seq: flash_ctrl_hw_sec_otp_vseq
      run_opts: ["+test_timeout_ns=300_000_000_000"]
      reseed: 50
    }
    {
      name: flash_ctrl_erase_suspend
      uvm_test_seq: flash_ctrl_erase_suspend_vseq
      run_opts: ["+zero_delays=1"]
      reseed: 5
    }
    {
      name: flash_ctrl_hw_rma
      uvm_test_seq: flash_ctrl_hw_rma_vseq
      run_opts: ["+flash_program_latency=5", "+test_timeout_ns=300_000_000_000"]
      reseed: 3
    }
    {
      name: flash_ctrl_hw_rma_reset
      uvm_test_seq: flash_ctrl_hw_rma_reset_vseq
      run_opts: ["+flash_program_latency=5", "+test_timeout_ns=300_000_000_000"]
      reseed: 20
    }
    {
      name: flash_ctrl_otp_reset
      uvm_test_seq: flash_ctrl_otp_reset_vseq
      run_opts: ["+test_timeout_ns=300_000_000_000"]
      reseed: 80
    }
    {
      name: flash_ctrl_host_ctrl_arb
      uvm_test_seq: flash_ctrl_host_ctrl_arb_vseq
      run_opts: ["+zero_delays=1", "+test_timeout_ns=300_000_000_000"]
      reseed: 5
    }
    {
      name: flash_ctrl_mp_regions
      uvm_test_seq: flash_ctrl_mp_regions_vseq
      run_opts: ["+multi_alert=1", "+test_timeout_ns=300_000_000_000",
                 "+fast_rcvr_recov_err", "+op_readonly_on_info1_partition=0"]
      reseed: 20
    }
    {
      name: flash_ctrl_fetch_code
      uvm_test_seq: flash_ctrl_fetch_code_vseq
      run_opts: ["+op_readonly_on_info_partition=1",
                 "+op_readonly_on_info1_partition=1"]
      reseed: 10
    }
    {
      name: flash_ctrl_full_mem_access
      uvm_test_seq: flash_ctrl_full_mem_access_vseq
      run_opts: ["+test_timeout_ns=500_000_000_000"]
      reseed: 5
      run_timeout_mins: 180
    }
    {
      name: flash_ctrl_error_prog_type
      uvm_test_seq: flash_ctrl_error_prog_type_vseq
      run_opts: ["+op_readonly_on_info_partition=1",
                 "+op_readonly_on_info1_partition=1"]
      reseed: 5
    }
    {
      name: flash_ctrl_error_prog_win
      uvm_test_seq: flash_ctrl_error_prog_win_vseq
      reseed: 10
    }
    {
      name: flash_ctrl_error_mp
      uvm_test_seq: flash_ctrl_error_mp_vseq
      run_opts: ["+test_timeout_ns=300_000_000_000", "+op_readonly_on_info_partition=0",
                 "+op_readonly_on_info1_partition=0", "+op_readonly_on_info2_partition=0"]
      reseed: 10
    }
    {
      name: flash_ctrl_invalid_op
      uvm_test_seq: flash_ctrl_invalid_op_vseq
      run_opts: ["+fast_rcvr_recov_err"]
      reseed: 20
    }
    {
      name: flash_ctrl_mid_op_rst
      uvm_test_seq: flash_ctrl_mid_op_rst_vseq
      reseed: 5
    }
    {
      name: flash_ctrl_wo
      uvm_test_seq: flash_ctrl_rw_vseq
      run_opts: ["+scb_otf_en=1", "+otf_num_rw=100", "+otf_num_hr=0", "+otf_rd_pct=0", "+ecc_mode=1"]
      reseed: 20
    }
    {
      name: flash_ctrl_write_word_sweep
      uvm_test_seq: flash_ctrl_write_word_sweep_vseq
      run_opts: ["+scb_otf_en=1"]
      reseed: 1
    }
    {
      name: flash_ctrl_read_word_sweep
      uvm_test_seq: flash_ctrl_read_word_sweep_vseq
      run_opts: ["+scb_otf_en=1"]
      reseed: 1
    }
    {
      name: flash_ctrl_ro
      uvm_test_seq: flash_ctrl_rw_vseq
      run_opts: ["+scb_otf_en=1", "+otf_num_rw=100", "+otf_num_hr=1000", "+otf_wr_pct=0", "+ecc_mode=1"]
      reseed: 20
    }
    {
      name: flash_ctrl_rw
      uvm_test_seq: flash_ctrl_rw_vseq
      run_opts: ["+scb_otf_en=1", "+test_timeout_ns=5_000_000_000", "+ecc_mode=1"]
      reseed: 20
    }
    {
      name: flash_ctrl_read_word_sweep_serr
      uvm_test_seq: flash_ctrl_read_word_sweep_vseq
      run_opts: ["+scb_otf_en=1", "+ecc_mode=2", "+serr_pct=3"]
      reseed: 5
    }
    {
      name: flash_ctrl_ro_serr
      uvm_test_seq: flash_ctrl_rw_vseq
      run_opts: ["+scb_otf_en=1", "+ecc_mode=2", "+serr_pct=3",
                 "+otf_num_rw=100", "+otf_num_hr=1000", "+otf_wr_pct=0"]
      reseed: 10
    }
    {
      name: flash_ctrl_rw_serr
      uvm_test_seq: flash_ctrl_rw_vseq
      run_opts: ["+scb_otf_en=1", "+ecc_mode=2", "+serr_pct=3",
                 "+otf_num_rw=100", "+otf_num_hr=1000"]
      reseed: 10
    }
    {
      name: flash_ctrl_serr_counter
      uvm_test_seq: flash_ctrl_serr_counter_vseq
      run_opts: ["+scb_otf_en=1", "+ecc_mode=2", "+serr_pct=1",
                 "+otf_num_rw=50", "+otf_num_hr=5"]
      reseed: 5
    }
    {
      name: flash_ctrl_serr_address
      uvm_test_seq: flash_ctrl_serr_address_vseq
      run_opts: ["+scb_otf_en=1", "+ecc_mode=2", "+serr_pct=1",
                 "+otf_num_rw=5", "+otf_num_hr=0"]
      reseed: 5
    }
    {
      name: flash_ctrl_read_word_sweep_derr
      uvm_test_seq: flash_ctrl_read_word_sweep_vseq
      run_opts: ["+scb_otf_en=1", "+ecc_mode=3", "+derr_pct=3",
                 "+bypass_alert_ready_to_end_check=1"]
      reseed: 5
    }
    {
      name: flash_ctrl_ro_derr
      uvm_test_seq: flash_ctrl_rw_vseq
      run_opts: ["+scb_otf_en=1", "+ecc_mode=3", "+derr_pct=3",
                 "+otf_num_rw=100", "+otf_num_hr=1000", "+otf_wr_pct=0",
                 "+bypass_alert_ready_to_end_check=1"]
      reseed: 10
    }
    {
      name: flash_ctrl_rw_derr
      uvm_test_seq: flash_ctrl_rw_vseq
      run_opts: ["+scb_otf_en=1", "+ecc_mode=3", "+derr_pct=3",
                 "+otf_num_rw=100", "+otf_num_hr=1000",
                 "+bypass_alert_ready_to_end_check=1"]
      reseed: 10
    }
    {
      name: flash_ctrl_derr_detect
      uvm_test_seq: flash_ctrl_derr_detect_vseq
      run_opts: ["+scb_otf_en=1", "+ecc_mode=3", "+derr_pct=4",
                 "+otf_num_rw=50", "+otf_num_hr=200",
                 "+rerun=5", "+otf_wr_pct=1"]
      reseed: 5
    }
    {
      name: flash_ctrl_oversize_error
      uvm_test_seq: flash_ctrl_oversize_error_vseq
      run_opts: ["+scb_otf_en=1", "+ecc_mode=2", "+serr_pct=0",
                 "+otf_num_hr=1000", "+otf_num_rw=100",
                 "+otf_wr_pct=4", "+otf_rd_pct=4"]
      reseed: 5
    }
    {
      name: flash_ctrl_integrity
      uvm_test_seq: flash_ctrl_rw_vseq
      run_opts: ["+scb_otf_en=1", "+ecc_mode=4", "+ierr_pct=3",
                 "+bypass_alert_ready_to_end_check=1"]
      reseed: 5
    }
    {
      name: flash_ctrl_intr_rd
      uvm_test_seq: flash_ctrl_intr_rd_vseq
      run_opts: ["+scb_otf_en=1", "+ecc_mode=1", "+en_always_read=1"]
      reseed: 40
    }
    {
      name: flash_ctrl_intr_wr
      uvm_test_seq: flash_ctrl_intr_wr_vseq
      run_opts: ["+scb_otf_en=1", "+ecc_mode=1", "+test_timeout_ns=500_000_000"]
      reseed: 10
    }
    {
      name: flash_ctrl_intr_rd_slow_flash
      uvm_test_seq: flash_ctrl_intr_rd_vseq
      run_opts: ["+scb_otf_en=1", "+flash_read_latency=50", "+flash_program_latency=500", "+test_timeout_ns=500_000_000"]
      reseed: 40
    }
    {
      name: flash_ctrl_intr_wr_slow_flash
      uvm_test_seq: flash_ctrl_intr_wr_vseq
      run_opts: ["+scb_otf_en=1", "+flash_read_latency=50", "+flash_program_latency=500",
                 "+rd_buf_en_to=500_000", "+test_timeout_ns=1_000_000_000"]
      reseed: 10
    }
    {
      name: flash_ctrl_prog_reset
      uvm_test_seq: flash_ctrl_prog_reset_vseq
      run_opts: ["+scb_otf_en=1", "+ecc_mode=1", "+test_timeout_ns=500_000_000"]
      reseed: 30
    }
    {
      name: flash_ctrl_rw_evict
      uvm_test_seq: flash_ctrl_rw_evict_vseq
      run_opts: ["+scb_otf_en=1", "+ecc_mode=1", "+en_always_read=1"]
      reseed: 40
    }
    {
      name: flash_ctrl_rw_evict_all_en
      uvm_test_seq: flash_ctrl_rw_evict_vseq
      run_opts: ["+scb_otf_en=1", "+ecc_mode=1", "+en_always_read=1",
                 "+en_always_prog=1", "en_rnd_data=0"]
      reseed: 40
    }
    {
      name: flash_ctrl_re_evict
      uvm_test_seq: flash_ctrl_re_evict_vseq
      run_opts: ["+scb_otf_en=1", "+ecc_mode=1", "+en_always_read=1"]
      reseed: 20
    }
    {
      name: flash_ctrl_disable
      uvm_test_seq: flash_ctrl_disable_vseq
      run_opts: ["+scb_otf_en=1", "+ecc_mode=2", "+en_always_all=1",
                 "+bypass_alert_ready_to_end_check=1"]
      reseed: 50
    }
    {
      name: flash_ctrl_sec_cm
      run_timeout_mins: 180
    }
    {
      name: flash_ctrl_sec_info_access
      uvm_test_seq: flash_ctrl_info_part_access_vseq
      reseed: 50
    }
    {
      name: flash_ctrl_stress_all
      reseed: 5
    }
    {
      name: flash_ctrl_connect
      uvm_test_seq: flash_ctrl_connect_vseq
      reseed: 80
    }
    {
      name: flash_ctrl_rd_intg
      uvm_test_seq: flash_ctrl_rd_path_intg_vseq
      run_opts: ["+scb_otf_en=1", "+ecc_mode=1",
                 "+otf_num_hr=100", "+en_always_read=1"]
      reseed: 3
    }
    {
      name: flash_ctrl_wr_intg
      uvm_test_seq: flash_ctrl_wr_path_intg_vseq
      run_opts: ["+scb_otf_en=1", "+otf_num_rw=10", "+otf_num_hr=0", "+ecc_mode=1",
                 "+en_always_prog=1", "+otf_rd_pct=0"]
      reseed: 3
    }
    {
      name: flash_ctrl_access_after_disable
      uvm_test_seq: flash_ctrl_access_after_disable_vseq
      run_opts: ["+scb_otf_en=1", "+ecc_mode=1", "+otf_num_rw=5", "+otf_num_hr=0",
                 "+en_always_all=1", "+bypass_alert_ready_to_end_check=1"]
      reseed: 3
    }
    {
      name: flash_ctrl_fs_sup
      uvm_test_seq: flash_ctrl_filesystem_support_vseq
      run_opts: ["+scb_otf_en=1", "+ecc_mode=1", "+en_always_all=1", "+en_all_info_acc=1"]
      reseed: 5
    }
    {
      name: flash_ctrl_phy_arb_redun
      uvm_test_seq: flash_ctrl_phy_arb_redun_vseq
      run_opts: ["+scb_otf_en=1", "+otf_num_rw=5", "+otf_num_hr=10", "+ecc_mode=1",
                 "+en_always_all=1", "+bypass_alert_ready_to_end_check=1"]
      reseed: 5
    }
    {
      name: flash_ctrl_phy_host_grant_err
      uvm_test_seq: flash_ctrl_phy_host_grant_err_vseq
      run_opts: ["+scb_otf_en=1", "+otf_num_rw=5", "+otf_num_hr=50", "+ecc_mode=1",
                 "+en_always_all=1", "+bypass_alert_ready_to_end_check=1"]
      reseed: 5
    }
    {
      name: flash_ctrl_phy_ack_consistency
      uvm_test_seq: flash_ctrl_phy_ack_consistency_vseq
      run_opts: ["+scb_otf_en=1", "+otf_num_rw=5", "+otf_num_hr=10", "+ecc_mode=1", "+bank0_pct=8",
                 "+otf_rd_pct=4", "+en_always_all=1", "+bypass_alert_ready_to_end_check=1"]
      reseed: 5
    }
    {
      name: flash_ctrl_config_regwen
      uvm_test_seq: flash_ctrl_config_regwen_vseq
      run_opts: ["+scb_otf_en=1", "+ecc_mode=1", "+en_always_all=1"]
      reseed: 5
    }
    {
      name: flash_ctrl_rma_err
      uvm_test_seq: flash_ctrl_hw_rma_err_vseq
      run_opts: ["+flash_program_latency=5", "+flash_erase_latency=50", "+test_timeout_ns=300_000_000_000"]
      reseed: 3
    }
    {
      name: flash_ctrl_lcmgr_intg
      uvm_test_seq: flash_ctrl_lcmgr_intg_vseq
      run_opts: ["+scb_otf_en=1", "+ecc_mode=1",
                 "+en_always_all=1", "+bypass_alert_ready_to_end_check=1"]
      reseed: 20
    }
    {
      name: flash_ctrl_hw_read_seed_err
      uvm_test_seq: flash_ctrl_hw_read_seed_err_vseq
      run_opts: ["+scb_otf_en=1", "+ecc_mode=1",
                 "+en_always_all=1", "+bypass_alert_ready_to_end_check=1"]
      reseed: 20
    }
    {
      name: flash_ctrl_hw_prog_rma_wipe_err
      uvm_test_seq: flash_ctrl_hw_prog_rma_wipe_err_vseq
      run_opts: ["+scb_otf_en=1", "+ecc_mode=1", "+flash_program_latency=5",
                 "+en_always_all=1", "+bypass_alert_ready_to_end_check=1"]
      reseed: 20
    }
    {
      name: flash_ctrl_rd_ooo
      uvm_test_seq: flash_ctrl_rd_ooo_vseq
      run_opts: ["+scb_otf_en=1", "+otf_num_rw=10", "+otf_num_hr=100",
                 "+ecc_mode=1"]
      reseed: 1
    }
    {
      name: flash_ctrl_host_addr_infection
      uvm_test_seq: flash_ctrl_host_addr_infection_vseq
      run_opts: ["+scb_otf_en=1", "+ecc_mode=1",
                 "+otf_num_hr=100", "+en_always_read=1"]
      reseed: 3
    }
 ]

  // List of regressions.
  regressions: [
    {
      name: smoke
      tests: ["flash_ctrl_smoke"]
    }
    {
      // For test clean up run subset of tests
      name: evict
      tests: ["flash_ctrl_rw_evict",
              "flash_ctrl_re_evict",
              "flash_ctrl_rw_evict_all_en"
              ]
    }
    {
      name: flash_err
      tests: ["flash_ctrl_error_mp", "flash_ctrl_error_prog_win",
              "flash_ctrl_error_prog_type"
             ]
    }
  ]
}
