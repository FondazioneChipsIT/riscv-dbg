# Copyright 2026 EuroCDP contributors.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Timing constraints for the RVDBG4614 RISC-V debug module hard macro.
# Used by LibreLane for place-and-route (PNR_SDC_FILE) and sign-off STA
# (SIGNOFF_SDC_FILE). The JTAG/CDC methodology follows the Croc SoC constraints.

#####################
## Design settings ##
#####################

# System clock period comes from the LibreLane configuration (CLOCK_PERIOD).
set TCK_SYS $::env(CLOCK_PERIOD)
# JTAG test clock period (25 ns = 40 MHz). The JTAG clock must always be slower
# than the system clock (see riscv-dbg issue #163).
set TCK_JTG 25.0

# Clock-domain crossings (see the CDC section below):
#  - bundled data / handshake paths must settle within one period of the
#    faster clock, so that any change propagates within one cycle of either
#    clock;
#  - synchronizer first stages get a tighter bound for metastability margin.
set CDC_MAX_DELAY      [expr min($TCK_SYS, $TCK_JTG)]
set CDC_SYNC_MAX_DELAY 3.0


##################
## Input Clocks ##
##################
puts "Clocks..."

create_clock -name clk_sys -period $TCK_SYS [get_ports clk_i]
create_clock -name clk_jtg -period $TCK_JTG [get_ports jtag_tck_i]

set_clock_uncertainty $::env(CLOCK_UNCERTAINTY_CONSTRAINT) [all_clocks]
set_clock_transition  $::env(CLOCK_TRANSITION_CONSTRAINT)  [all_clocks]

# Functional mode only: testmode_i selects the non-inverted TCK for the TDO
# flops in dmi_jtag_tap (DFT). Fixing it to 0 keeps the TDO flops on the falling
# TCK edge, as in normal operation.
set_case_analysis 0 [get_ports testmode_i]


##############################
## Driving cells and loads  ##
##############################

set_max_fanout $::env(MAX_FANOUT_CONSTRAINT) [current_design]
if { [info exists ::env(MAX_TRANSITION_CONSTRAINT)] } {
    set_max_transition $::env(MAX_TRANSITION_CONSTRAINT) [current_design]
}

set clock_ports [get_ports {clk_i jtag_tck_i}]
set data_inputs [list]
foreach port [all_inputs] {
    set name [get_name $port]
    if { $name ne "clk_i" && $name ne "jtag_tck_i" } {
        lappend data_inputs $port
    }
}

set_driving_cell \
    -lib_cell [lindex [split $::env(SYNTH_DRIVING_CELL) "/"] 0] \
    -pin      [lindex [split $::env(SYNTH_DRIVING_CELL) "/"] 1] \
    $data_inputs
if { [info exists ::env(SYNTH_CLK_DRIVING_CELL)] } {
    set clk_driving_cell $::env(SYNTH_CLK_DRIVING_CELL)
} else {
    set clk_driving_cell $::env(SYNTH_DRIVING_CELL)
}
set_driving_cell \
    -lib_cell [lindex [split $clk_driving_cell "/"] 0] \
    -pin      [lindex [split $clk_driving_cell "/"] 1] \
    $clock_ports

set_load [expr $::env(OUTPUT_CAP_LOAD) / 1000.0] [all_outputs]


#####################
## Clock crossings ##
#####################
puts "CDC..."

# clk_sys and clk_jtg are asynchronous. The only paths between them are inside
# the DMI clock-domain crossing (i_dmi_jtag/i_dmi_cdc): two cdc_2phase_clearable
# instances (request and response), each with a cdc_reset_ctrlr built from
# 4-phase handshakes. Their payload (DMI request/response and reset-controller
# state) is bundled data: it is launched in the source domain and only sampled
# in the destination domain after the matching req/ack edge has gone through a
# synchronizer, so it is stable for several destination cycles.
#
# Instead of single-cycle setup checks, all crossing paths are bounded by
# CDC_MAX_DELAY and hold is not checked across domains.
# Note: -ignore_clock_latency is intentionally not used: it crashes the
# timing-driven global placement of the OpenROAD version used here. Including
# the (small) clock-tree latencies makes the constraint slightly conservative.
set_max_delay $CDC_MAX_DELAY -from [get_clocks clk_sys] -to [get_clocks clk_jtg]
set_max_delay $CDC_MAX_DELAY -from [get_clocks clk_jtg] -to [get_clocks clk_sys]
set_false_path -hold -from [get_clocks clk_sys] -to [get_clocks clk_jtg]
set_false_path -hold -from [get_clocks clk_jtg] -to [get_clocks clk_sys]

# Synchronizer first stages (common_cells sync, reg_q[0]) only see the toggling
# req/ack signals of the handshakes: keep these paths short to maximize the
# metastability resolution time. The flops are found through the name of their
# output net, which is preserved by synthesis and place-and-route.
set cdc_sync_d_pins [list]
foreach net [get_nets -hierarchical {*.i_sync.reg_q\[0\]}] {
    foreach q_pin [get_pins -of_objects $net -filter "direction == output"] {
        foreach pin [get_pins -of_objects [get_cells -of_objects $q_pin] -filter "direction == input"] {
            if { [get_property $pin lib_pin_name] eq "D" } {
                lappend cdc_sync_d_pins $pin
            }
        }
    }
}
puts "CDC: [llength $cdc_sync_d_pins] synchronizer first-stage flops found"
if { [llength $cdc_sync_d_pins] > 0 } {
    set_max_delay $CDC_SYNC_MAX_DELAY -to $cdc_sync_d_pins
}


###########
## Reset ##
###########
puts "Resets..."

# Asynchronous resets: deassertion must reach all flops within one cycle.
set_input_delay -max [expr $TCK_SYS * 0.10] -clock clk_sys [get_ports rst_ni]
set_false_path  -hold -from [get_ports rst_ni]
set_max_delay   $TCK_SYS -from [get_ports rst_ni]

set_input_delay -max [expr $TCK_JTG * 0.10] -clock clk_jtg [get_ports jtag_trst_ni]
set_false_path  -hold -from [get_ports jtag_trst_ni]
set_max_delay   $TCK_JTG -from [get_ports jtag_trst_ni]


##########
## JTAG ##
##########
puts "JTAG..."

# The JTAG probe drives TDI/TMS on the falling TCK edge; the TAP samples them
# on the rising edge.
set_input_delay  -min -add_delay -clock clk_jtg -clock_fall [expr $TCK_JTG * 0.10] [get_ports {jtag_tdi_i jtag_tms_i}]
set_input_delay  -max -add_delay -clock clk_jtg -clock_fall [expr $TCK_JTG * 0.25] [get_ports {jtag_tdi_i jtag_tms_i}]

# TDO/TDO_OE are launched on the falling TCK edge and sampled by the probe on
# the next rising edge.
set_output_delay -min -add_delay -clock clk_jtg [expr $TCK_JTG * 0.10] [get_ports {jtag_tdo_o jtag_tdo_oe_o}]
set_output_delay -max -add_delay -clock clk_jtg [expr $TCK_JTG * 0.20] [get_ports {jtag_tdo_o jtag_tdo_oe_o}]


###############################
## System-side I/O (clk_sys) ##
###############################
puts "Input/Outputs..."

set sys_in_list [get_ports {
    slave_req_i slave_we_i slave_addr_i* slave_be_i* slave_wdata_i* slave_aid_i*
    master_gnt_i master_rvalid_i master_err_i master_other_err_i master_rdata_i*
    unavailable_i hartinfo_i*
}]
set sys_out_list [get_ports {
    slave_gnt_o slave_rvalid_o slave_rdata_o* slave_rid_o*
    master_req_o master_addr_o* master_we_o master_wdata_o* master_be_o*
    ndmreset_o dmactive_o debug_req_o
}]

set_input_delay  -min -add_delay -clock clk_sys [expr $TCK_SYS * 0.10] $sys_in_list
set_input_delay  -max -add_delay -clock clk_sys [expr $TCK_SYS * 0.30] $sys_in_list
set_output_delay -min -add_delay -clock clk_sys [expr $TCK_SYS * 0.10] $sys_out_list
set_output_delay -max -add_delay -clock clk_sys [expr $TCK_SYS * 0.30] $sys_out_list

# Quasi-static configuration / status inputs: keep them within one cycle but do
# not check hold (they change only while the hart is idle or reset).
set_false_path -hold -from [get_ports {hartinfo_i* unavailable_i}]

# Propagated clocks after CTS (LibreLane resets this before CTS as needed).
if { [info exists ::env(OPENLANE_SDC_IDEAL_CLOCKS)] && $::env(OPENLANE_SDC_IDEAL_CLOCKS) } {
    unset_propagated_clock [all_clocks]
} else {
    set_propagated_clock [all_clocks]
}
