// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

module mbx_sysif
  import tlul_pkg::*;
  import mbx_reg_pkg::*;
#(
  parameter int unsigned                    CfgSramAddrWidth         = 32,
  parameter int unsigned                    CfgSramDataWidth         = 32,
  // PCIe capabilities
  parameter bit                             DoeIrqSupport            = 1'b1,
  parameter bit                             DoeAsyncMsgSupport       = 1'b1,
  parameter bit                             EnableRacl               = 1'b0,
  parameter bit                             RaclErrorRsp             = 1'b1,
  parameter top_racl_pkg::racl_policy_sel_t RaclPolicySelVecSoc[NumRegsSoc]   = '{NumRegsSoc{0}},
  parameter top_racl_pkg::racl_policy_sel_t RaclPolicySelWinSocWdata = 0,
  parameter top_racl_pkg::racl_policy_sel_t RaclPolicySelWinSocRdata = 0
) (
  input  logic                           clk_i,
  input  logic                           rst_ni,
  // Device port to the system fabric
  input  tlul_pkg::tl_h2d_t              tl_sys_i,
  output tlul_pkg::tl_d2h_t              tl_sys_o,
  output logic                           intg_err_o,
  // Custom interrupt to the system requester
  output logic                           doe_intr_support_o,
  output logic                           doe_intr_en_o,
  output logic                           doe_intr_o,
  // Asynchronous message to the requester
  output logic                           doe_async_msg_support_o,
  output logic                           doe_async_msg_en_o,
  input  logic                           doe_async_msg_set_i,
  input  logic                           doe_async_msg_clear_i,
  // Abort clearing from the host
  input  logic                           sysif_abort_ack_i,
  // Access to the control register
  output logic                           sysif_control_abort_set_o,
  output logic                           sysif_control_go_set_o,
  // Access to the status register
  input  logic                           sysif_status_busy_valid_i,
  input  logic                           sysif_status_busy_i,
  output logic                           sysif_status_busy_o,
  input  logic                           sysif_status_doe_intr_ready_set_i,
  input  logic                           sysif_status_error_set_i,
  output logic                           sysif_status_error_o,
  input  logic                           sysif_status_ready_valid_i,
  input  logic                           sysif_status_ready_i,
  output logic                           sysif_status_ready_o,
  // Alias of the interrupt address and data registers to the host interface
  output logic [CfgSramAddrWidth-1:0]    sysif_intr_msg_addr_o,
  output logic [CfgSramDataWidth-1:0]    sysif_intr_msg_data_o,
  // Control lines for backpressuring the bus
  input  logic                           imbx_pending_i,
  input  logic                           ombx_pending_i,
  // Data interface for inbound and outbound mailbox
  output logic                           write_data_write_valid_o,
  output logic [CfgSramDataWidth-1:0]    write_data_o,
  output logic                           read_data_read_valid_o,
  output logic                           read_data_write_valid_o,
  input  logic [CfgSramDataWidth-1:0]    read_data_i,
  // RACL interface
  input  top_racl_pkg::racl_policy_vec_t racl_policies_i,
  output top_racl_pkg::racl_error_log_t  racl_error_o
);

  mbx_soc_reg2hw_t reg2hw;
  mbx_soc_hw2reg_t hw2reg;

  top_racl_pkg::racl_error_log_t racl_error[3];
  if (EnableRacl) begin : gen_racl_error_arb
    // Arbitrate between all simultaneously valid error log requests.
    prim_racl_error_arb #(
      .N ( 3 )
    ) u_prim_err_arb (
      .clk_i,
      .rst_ni,
      .error_log_i ( racl_error   ),
      .error_log_o ( racl_error_o )
    );
  end else begin : gen_no_racl_error_arb
    logic unused_signals;
    always_comb begin
      unused_signals = ^{racl_error[0] ^ racl_error[1] ^ racl_error[2]};
      racl_error_o   = '0;
    end
  end

  // Interface for the custom register interface with bus blocking support
  tlul_pkg::tl_h2d_t tl_win_h2d[2];
  tlul_pkg::tl_d2h_t tl_win_d2h[2];

  // SEC_CM: BUS.INTEGRITY
  mbx_soc_reg_top #(
    .EnableRacl(EnableRacl),
    .RaclErrorRsp(RaclErrorRsp),
    .RaclPolicySelVec(RaclPolicySelVecSoc)
  ) u_soc_regs (
    .clk_i            ( clk_i               ),
    .rst_ni           ( rst_ni              ),
    .tl_i             ( tl_sys_i            ),
    .tl_o             ( tl_sys_o            ),
    .tl_win_o         ( tl_win_h2d          ),
    .tl_win_i         ( tl_win_d2h          ),
    .reg2hw           ( reg2hw              ),
    .hw2reg           ( hw2reg              ),
    .racl_policies_i  ( racl_policies_i     ),
    .racl_error_o     ( racl_error[0]       ),
    .intg_err_o       ( intg_err_o          )
  );

  // Straps for the external capability header registers
  assign doe_intr_support_o      = DoeIrqSupport;
  assign doe_async_msg_support_o = DoeAsyncMsgSupport;
  // DOE IRQ is generated when:
  // - the host wrote a complete message to the outbound mailbox
  // - there is an error
  // - there is an asynchronous message
  // request
  assign doe_intr_o = DoeIrqSupport & reg2hw.soc_status.doe_intr_status.q;

  // Fiddle rising edge of writing the abort and go bit
  assign sysif_control_abort_set_o  = reg2hw.soc_control.abort.qe & reg2hw.soc_control.abort.q;
  assign hw2reg.soc_control.abort.d = 1'b0;

  assign sysif_control_go_set_o  = reg2hw.soc_control.go.qe & reg2hw.soc_control.go.q;
  assign hw2reg.soc_control.go.d = 1'b0;

  // Manual implementation of the doe_intr_en bit
  // Gate the data input with the feature flag
  // SWAccess: RW
  // HWAccess: RO
  prim_subreg #(
    .DW      (1),
    .SwAccess(prim_subreg_pkg::SwAccessRW),
    .RESVAL  (1'h0)
  ) u_soc_control_doe_intr_en (
    .clk_i   (clk_i),
    .rst_ni  (rst_ni),
    // from register interface
    .we     (reg2hw.soc_control.doe_intr_en.qe),
    .wd     (reg2hw.soc_control.doe_intr_en.q & DoeIrqSupport),
    // HWAccess: hro
    .de     (1'b0),
    .d      (1'b0),
    // to internal hardware
    .qe     (),
    .q      (doe_intr_en_o),
    .ds     (hw2reg.soc_control.doe_intr_en.d),
    .qs     ()
  );

  // Manual implementation of the doe_async_msg_en bit
  // Gate the data input with the feature flag
  // SWAccess: RW
  // HWAccess: RO
  prim_subreg #(
    .DW      (1),
    .SwAccess(prim_subreg_pkg::SwAccessRW),
    .RESVAL  (1'h0)
  ) u_soc_control_doe_async_msg_en (
    .clk_i   (clk_i),
    .rst_ni  (rst_ni),
    // from register interface
    .we     (reg2hw.soc_control.doe_async_msg_en.qe),
    .wd     (reg2hw.soc_control.doe_async_msg_en.q & DoeAsyncMsgSupport),
    // HWAccess: hro
    .de     (1'b0),
    .d      (1'b0),
    // to internal hardware
    .qe     (),
    .q      (doe_async_msg_en_o),
    .ds     (hw2reg.soc_control.doe_async_msg_en.d),
    .qs     ()
  );

  // Fiddle out status register bits for external write logic
  assign sysif_status_busy_o  = reg2hw.soc_status.busy.q;
  assign sysif_status_error_o = reg2hw.soc_status.error.q;

  // External read logic
  assign hw2reg.soc_status.busy.de = sysif_status_busy_valid_i;
  assign hw2reg.soc_status.busy.d  = sysif_status_busy_i;

  // Gate the async msg setter with the feature strap and the enable bit
  logic async_msg_set_gated;
  assign async_msg_set_gated = DoeAsyncMsgSupport & doe_async_msg_en_o & doe_async_msg_set_i;

  // Interrupt is triggered by the outbound handler if the message has been written to
  // the memory and can be read by the system, an error is raised, or if there is an asynchronous
  // message request coming from the host.
  // The interrupt is cleared by the SOC firmware via the RW1C behavior or when an abort is
  // acknowledged by the host
  assign hw2reg.soc_status.doe_intr_status.de = DoeIrqSupport &
                                                (sysif_status_doe_intr_ready_set_i |
                                                 sysif_abort_ack_i                 |
                                                 sysif_status_error_set_i          |
                                                 async_msg_set_gated);
  assign hw2reg.soc_status.doe_intr_status.d  = (sysif_status_doe_intr_ready_set_i |
                                                 sysif_status_error_set_i          |
                                                 async_msg_set_gated)              &
                                                 ~sysif_abort_ack_i;

  // Async message status is updated by the host interface when enabled
  // and cleared in all cases on an abort and abort ack/FW reset
  assign hw2reg.soc_status.doe_async_msg_status.de = (DoeAsyncMsgSupport & doe_async_msg_en_o &
                                                     (doe_async_msg_set_i |
                                                      doe_async_msg_clear_i))  |
                                                     sysif_control_abort_set_o |
                                                     sysif_abort_ack_i;
  assign hw2reg.soc_status.doe_async_msg_status.d  = doe_async_msg_set_i;

  // Error is cleared when writing the abort bit or on a FW-based reset
  assign hw2reg.soc_status.error.de = sysif_status_error_set_i |
                                      sysif_control_abort_set_o |
                                      sysif_abort_ack_i;
  assign hw2reg.soc_status.error.d  = sysif_status_error_set_i;

  // Set by OT firmware (w1s)
  // Cleared by SoC firmware (w1c)
  assign hw2reg.soc_status.ready.de = sysif_status_ready_valid_i;
  assign hw2reg.soc_status.ready.d  = sysif_status_ready_i;
  // Ready bit indication into hardware
  assign sysif_status_ready_o = reg2hw.soc_status.ready.q;

  // Dedicated TLUL adapter for implementing the write data mailbox register via a register window.
  // We use the register window to access the internal bus signals, allowing the mailbox to halt
  // the bus if there are too many outstanding requests.
  logic reg_wdata_we;
  logic [top_pkg::TL_DW-1:0] reg_wdata_wdata;
  tlul_adapter_reg_racl #(
    .RegAw             ( SocAw                    ),
    .RegDw             ( top_pkg::TL_DW           ),
    .EnableDataIntgGen ( 0                        ),
    .EnableRacl        ( EnableRacl               ),
    .RaclErrorRsp      ( RaclErrorRsp             ),
    .RaclPolicySelVec  ( RaclPolicySelWinSocWdata )
  ) u_wdata_reg_if (
    .clk_i            ( clk_i                        ),
    .rst_ni           ( rst_ni                       ),
    .tl_i             ( tl_win_h2d[MBX_WDATA_IDX]    ),
    .tl_o             ( tl_win_d2h[MBX_WDATA_IDX]    ),
    .en_ifetch_i      ( prim_mubi_pkg::MuBi4False    ),
    .intg_error_o     (                              ),
    .racl_policies_i  ( racl_policies_i              ),
    .racl_error_o     ( racl_error[1]                ),
    .we_o             ( reg_wdata_we                 ),
    // No Reading of the write register. Always reads zero
    .re_o             (                              ),
    .addr_o           (                              ),
    .wdata_o          ( reg_wdata_wdata              ),
    .be_o             (                              ),
    .busy_i           ( imbx_pending_i               ),
    .rdata_i          ( '0                           ),
    .error_i          ( 1'b0                         )
  );

  // Dedicated TLUL adapter for implementing the read data mailbox register via a register window.
  // We use the register window to access the internal bus signals, allowing the mailbox to halt
  // the bus if there are too many outstanding requests. The register is implemented as hwext
  // outside of this hierarchy
  tlul_adapter_reg_racl #(
    .RegAw             ( SocAw                    ),
    .RegDw             ( top_pkg::TL_DW           ),
    .EnableDataIntgGen ( 0                        ),
    .EnableRacl        ( EnableRacl               ),
    .RaclErrorRsp      ( RaclErrorRsp             ),
    .RaclPolicySelVec  ( RaclPolicySelWinSocRdata )
  ) u_rdata_reg_if (
    .clk_i            ( clk_i                        ),
    .rst_ni           ( rst_ni                       ),
    .tl_i             ( tl_win_h2d[MBX_RDATA_IDX]    ),
    .tl_o             ( tl_win_d2h[MBX_RDATA_IDX]    ),
    .en_ifetch_i      ( prim_mubi_pkg::MuBi4False    ),
    .intg_error_o     (                              ),
    .racl_policies_i  ( racl_policies_i              ),
    .racl_error_o     ( racl_error[2]                ),
    // No writing to the read register
    .we_o             ( read_data_write_valid_o      ),
    .re_o             ( read_data_read_valid_o       ),
    .addr_o           (                              ),
    // Write values are ignored. A Write simply means the read has occurred.
    .wdata_o          (                              ),
    .be_o             (                              ),
    .busy_i           ( ombx_pending_i               ),
    .rdata_i          ( read_data_i                  ),
    .error_i          ( 1'b0                         )
  );

  // Manual implementation of the write read mailbox register.
  // The manual implementation of the register via a register window is needed to expose the
  // internal register interface of the TLUL bus to halt the bus if there too many outstanding
  // requests.
  logic mbx_wrdata_flds_we;
  prim_flop #(
    .Width(1),
    .ResetValue(0)
  ) u_mbxwrdat0_qe (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .d_i(mbx_wrdata_flds_we),
    .q_o(write_data_write_valid_o)
  );
  prim_subreg #(
    .DW      (CfgSramDataWidth),
    .SwAccess(prim_subreg_pkg::SwAccessWO),
    .RESVAL  (32'h0)
  ) u_reg_wrdata (
    .clk_i   (clk_i),
    .rst_ni  (rst_ni),

    // from register interface
    .we     (reg_wdata_we),
    .wd     (reg_wdata_wdata),

    // from internal hardware
    .de     (1'b0),
    .d      ('0),

    // to internal hardware
    .qe     (mbx_wrdata_flds_we),
    .q      (write_data_o),
    .ds     (),

    // to register interface (read)
    .qs     ()
  );

  // Forward IRQ addr and data register to the host interface
  assign sysif_intr_msg_addr_o = reg2hw.soc_doe_intr_msg_addr.q;
  assign sysif_intr_msg_data_o = reg2hw.soc_doe_intr_msg_data.q;

  // Assertions
  `ASSERT(DataWidthCheck_A, CfgSramDataWidth == top_pkg::TL_DW)
endmodule
