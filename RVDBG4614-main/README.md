# RVDBG4614

Design views for `RVDBG4614`, the RISC-V debug module hard macro (PULP
riscv-dbg: JTAG DTM + Debug Module) implemented in IHP SG13G2.

Use the IP name for top-level schematics, netlists, and GDS cells.

| Directory | Contents |
| --- | --- |
| `rtl/` | `RVDBG4614.sv` (hard-macro top), `riscv-dbg/` (upstream sources and debug ROM), `common_cells/` (v1.40.0, vendored), `tc_clk.sv` (IHP SG13G2 clock cells) |
| `constraints/sdc/` | `RVDBG4614.sdc`: two asynchronous clocks (`clk_i`, `jtag_tck_i`), CDC and I/O constraints |
| `Flow/scripts/LibreLane/` | LibreLane Classic-flow configuration (`config.yaml`), pin order, lint waivers |
| `Flow/scripts/ORFS/` | reserved for an OpenROAD-flow-scripts flow (not used) |
| `synthesis/` | Yosys netlist, SPICE netlist, pre-layout SDF, area/timing/power reports |
| `PlaceAndRoute/` | routed netlists, GDS, LEF, DEF, Liberty and SDF per corner, SPEF |
| `testbench/` | Croc SoC testbench (RTL / post-synthesis / post-PnR, Verilator) and the upstream riscv-dbg testbenches (`riscv-dbg/`) |
| `verification/` | lint, DRC, antenna, LVS and STA reports, final flow metrics |

Run `make help` for the list of flow and simulation targets.
