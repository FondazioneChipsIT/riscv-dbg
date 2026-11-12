// Copyright 2026 EuroCDP contributors.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// RVDBG4614 - RISC-V Debug Module hard macro
//
// Top level of the RVDBG4614 hard macro. It bundles the two halves of the
// PULP RISC-V debug system (riscv-dbg) into a single block with flat ports:
//
//   - dmi_jtag:   JTAG Debug Transport Module (DTM). JTAG TAP + DMI access
//                 registers, running in the JTAG (TCK) clock domain, plus a
//                 2-phase clock-domain-crossing (dmi_cdc) into clk_i.
//   - dm_obi_top: Debug Module (DM) with an OBI subordinate port (debug ROM,
//                 program buffer, abstract-command and data memory) and an OBI
//                 manager port (System Bus Access, SBA).
//
// Fixed configuration of this hard macro:
//   - one hart (NrHarts = 1)
//   - 32-bit OBI data/address buses (BusWidth = 32)
//   - 4-bit OBI transaction identifiers (IdWidth = 4)
//   - DmBaseAddress != 0: the debug ROM is position independent (uses auipc)
//     and needs two debug scratch registers in the core (hartinfo.nscratch=2).
//     The macro can be mapped at any 4 KiB-aligned base address; the core must
//     jump to <base> + 0x800 on debug entry (dm::HaltAddress) and to
//     <base> + 0x810 on a debug exception (dm::ExceptionAddress).
//   - JTAG IDCODE = 32'h0000_0DB3 (upstream dmi_jtag default)
//
// Clock domains:
//   - clk_i       : system clock (DM, OBI ports, CDC destination side)
//   - jtag_tck_i  : JTAG test clock (TAP and DMI registers)
// The only crossings between the two are inside dmi_cdc (cdc_2phase_clearable).

module RVDBG4614 (
  // System clock, reset and test mode
  input  logic        clk_i,            // system clock
  input  logic        rst_ni,           // asynchronous active-low reset (connect PoR, not ndmreset)
  input  logic        testmode_i,       // DFT test mode (tie to 0 in functional mode)

  // JTAG interface
  input  logic        jtag_tck_i,       // JTAG test clock
  input  logic        jtag_tms_i,       // JTAG test mode select
  input  logic        jtag_trst_ni,     // JTAG test reset (active low)
  input  logic        jtag_tdi_i,       // JTAG test data in
  output logic        jtag_tdo_o,       // JTAG test data out
  output logic        jtag_tdo_oe_o,    // JTAG test data out enable

  // Hart control / status
  output logic        ndmreset_o,       // non-debug-module reset request
  output logic        dmactive_o,       // debug module is active
  output logic        debug_req_o,      // debug request to the hart (halt request)
  input  logic        unavailable_i,    // hart is unavailable (e.g. powered down)
  input  logic [31:0] hartinfo_i,       // hart information, see dm::hartinfo_t

  // OBI subordinate port (core -> debug module memory)
  input  logic        slave_req_i,
  output logic        slave_gnt_o,
  input  logic        slave_we_i,
  input  logic [31:0] slave_addr_i,
  input  logic [3:0]  slave_be_i,
  input  logic [31:0] slave_wdata_i,
  input  logic [3:0]  slave_aid_i,
  output logic        slave_rvalid_o,
  output logic [31:0] slave_rdata_o,
  output logic [3:0]  slave_rid_o,

  // OBI manager port (System Bus Access: debug module -> system)
  output logic        master_req_o,
  output logic [31:0] master_addr_o,
  output logic        master_we_o,
  output logic [31:0] master_wdata_o,
  output logic [3:0]  master_be_o,
  input  logic        master_gnt_i,
  input  logic        master_rvalid_i,
  input  logic        master_err_i,
  input  logic        master_other_err_i,
  input  logic [31:0] master_rdata_i
);

  localparam int unsigned   NrHarts       = 1;
  localparam int unsigned   BusWidth      = 32;
  localparam int unsigned   IdWidth       = 4;
  localparam int unsigned   DmBaseAddress = 'h1000;
  localparam logic [31:0]   IdcodeValue   = 32'h0000_0DB3;

  // Debug Module Interface (DMI) between DTM and DM
  logic          dmi_rst_n;
  logic          dmi_req_valid, dmi_req_ready;
  logic          dmi_resp_valid, dmi_resp_ready;
  dm::dmi_req_t  dmi_req;
  dm::dmi_resp_t dmi_resp;

  dm::hartinfo_t [NrHarts-1:0] hartinfo;
  assign hartinfo[0] = dm::hartinfo_t'(hartinfo_i);

  // -------------------------------
  // JTAG Debug Transport Module
  // -------------------------------
  dmi_jtag #(
    .IdcodeValue ( IdcodeValue )
  ) i_dmi_jtag (
    .clk_i,
    .rst_ni,
    .testmode_i,

    .dmi_rst_no       ( dmi_rst_n      ),
    .dmi_req_o        ( dmi_req        ),
    .dmi_req_valid_o  ( dmi_req_valid  ),
    .dmi_req_ready_i  ( dmi_req_ready  ),

    .dmi_resp_i       ( dmi_resp       ),
    .dmi_resp_ready_o ( dmi_resp_ready ),
    .dmi_resp_valid_i ( dmi_resp_valid ),

    .tck_i            ( jtag_tck_i     ),
    .tms_i            ( jtag_tms_i     ),
    .trst_ni          ( jtag_trst_ni   ),
    .td_i             ( jtag_tdi_i     ),
    .td_o             ( jtag_tdo_o     ),
    .tdo_oe_o         ( jtag_tdo_oe_o  )
  );

  // -------------------------------
  // Debug Module (OBI wrapper)
  // -------------------------------
  dm_obi_top #(
    .IdWidth       ( IdWidth       ),
    .NrHarts       ( NrHarts       ),
    .BusWidth      ( BusWidth      ),
    .DmBaseAddress ( DmBaseAddress )
  ) i_dm_obi_top (
    .clk_i,
    .rst_ni,
    .testmode_i,
    .ndmreset_o,
    .dmactive_o,
    .debug_req_o        ( debug_req_o        ),
    .unavailable_i      ( unavailable_i      ),
    .hartinfo_i         ( hartinfo           ),

    .slave_req_i,
    .slave_gnt_o,
    .slave_we_i,
    .slave_addr_i,
    .slave_be_i,
    .slave_wdata_i,
    .slave_aid_i,
    .slave_rvalid_o,
    .slave_rdata_o,
    .slave_rid_o,

    .master_req_o,
    .master_addr_o,
    .master_we_o,
    .master_wdata_o,
    .master_be_o,
    .master_gnt_i,
    .master_rvalid_i,
    .master_err_i,
    .master_other_err_i,
    .master_rdata_i,

    .dmi_rst_ni         ( dmi_rst_n          ),
    .dmi_req_valid_i    ( dmi_req_valid      ),
    .dmi_req_ready_o    ( dmi_req_ready      ),
    .dmi_req_i          ( dmi_req            ),

    .dmi_resp_valid_o   ( dmi_resp_valid     ),
    .dmi_resp_ready_i   ( dmi_resp_ready     ),
    .dmi_resp_o         ( dmi_resp           )
  );

endmodule : RVDBG4614
