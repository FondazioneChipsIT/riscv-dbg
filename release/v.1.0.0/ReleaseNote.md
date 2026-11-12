# RVDBG4614 release v.1.0.0

This is the first release of the RVDBG4614 macro, a hard-macro implementation
of the PULP Platform riscv-dbg RISC-V debug system (JTAG Debug Transport
Module and Debug Module, RISC-V Debug Specification v0.13.2). The release
targets the Leibniz Institute for High Performance Microelectronics (IHP)
130nm BiCMOS process design kit using the SG13G2 standard-cell library. In
addition to the synthesizable RTL implementation, the release includes a
placed-and-routed hard macro and the associated logical, physical, timing,
and verification views required for integration into a larger design.

## Contents

- `RVDBG4614.gds`: production GDSII of the macro.
- `views/`: all LibreLane final views (GDS, LEF, DEF, Liberty and SDF for the
  three corners, SPEF, netlists, SPICE, Magic and OpenDB views, SDC, metrics,
  layout render).
- `measurements/`: empty (no silicon available).

## Configuration

One hart, 32-bit OBI subordinate (debug memory) and manager (System Bus
Access) ports, 4-bit OBI IDs, 8-word program buffer, 2 data registers, JTAG
IDCODE `0x0000_0DB3`, position-independent debug ROM (two debug scratch
registers required in the hart).

## Results

- Die 400 µm × 500 µm, all 263 signal pins on the east side; 118 101 µm²
  standard-cell area (64.9 % utilization); 1 119 flip-flops.
- `clk_i` 100 MHz and `jtag_tck_i` 40 MHz met in all corners
  (worst setup slack +1.80 ns, worst hold slack +0.10 ns).
- DRC (Magic, KLayout): 0 violations; antenna: 0; LVS: circuits match uniquely.
- Verified by RTL, post-synthesis and post-route simulation in the Croc SoC
  with a CVE2 core, and by the upstream riscv-dbg Verilator regressions.

## Source and tools

- riscv-dbg upstream commit `643607e` (pulp-platform/riscv-dbg master), with
  one non-functional change in `dm_mem.sv` (see `CHANGELOG.md`).
- common_cells v1.40.0 (vendored subset of modules).
- LibreLane 3.0.2, OpenROAD `dcf36133`, Yosys 0.64, Magic 8.3.636,
  Netgen 1.5.318, KLayout 0.30.8, Verilator 5.046.
- IHP-Open-PDK `be443daab937daa9154c9c4e73584524f431bd97`.

See `doc/overview.md` and `doc/Datasheet.md` for details and known limitations.
