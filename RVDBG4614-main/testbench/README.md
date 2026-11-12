# RVDBG4614 testbenches

## Croc SoC system testbench (RTL, post-synthesis, post-PnR)

The debug module is verified in a complete system: the
[Croc](https://github.com/pulp-platform/croc) SoC with a CVE2 (CV32E20) core,
where the PULP `dmi_jtag` + `dm_obi_top` pair is replaced by the `RVDBG4614`
macro (`rtl/croc_domain.sv`). The Croc VIP (`rtl/test/croc_vip.sv`) drives the
JTAG port of the macro and runs the following sequence (`rtl/test/tb_croc_soc.sv`):

1. JTAG IDCODE check and debug module activation (`dmcontrol.dmactive`);
2. System Bus Access write and read-back of the SRAM;
3. program load (`helloworld.hex`) through System Bus Access with auto-increment;
4. hart wake-up, halt request (`dmcontrol.haltreq`) and check of `dmstatus.allhalted`;
5. debug module self test (`jtag_dm_selftest`): debug spec version check,
   abstract command register read of `dpc`, GPR write/read-back through
   abstract commands, program buffer execution (`addi; ebreak`) and check of
   the result, register restore;
6. resume request and wait for the end of the program (UART "Hello World" and
   return code read over System Bus Access).

| Variant | DUT | Command (from `RVDBG4614-main/`) |
| --- | --- | --- |
| RTL | `../rtl/RVDBG4614.sv` and riscv-dbg RTL | `make simulate-rtl` |
| Post-synthesis | `../synthesis/netlist/RVDBG4614.nl.v` | `make simulate-postsynth` |
| Post-PnR | `../PlaceAndRoute/netlist/RVDBG4614.nl.v` | `make simulate-postpnr` |

Gate-level simulations use the IHP SG13G2 standard-cell models from
`$PDK_ROOT/ihp-sg13g2`, patched for Verilator (`patches/verilator_stdcell.patch`,
from the Croc project). `make stdcell-models` creates the patched copy in
`build/`. Simulations are zero-delay (functional) Verilator runs.

Files: `run_verilator.sh` (build/run script), `croc_rtl.f`, `croc_postsynth.f`,
`croc_postpnr.f` (file lists), `helloworld.hex` (Croc test program), `rtl/`
(Croc SoC, CVE2 core and verification IP).

## Upstream riscv-dbg testbenches

`riscv-dbg/` contains the original riscv-dbg verification environment (`tb/`,
`sva/`, `ci/`), with paths updated for this repository layout. The Verilator
regressions are run from the repository root with:

```
make -C RVDBG4614-main/testbench/riscv-dbg/ci dm-mem jtag-dmi multihart-resume
```

They need Bender and network access (dependency checkout), and `z3` in `PATH`
for the constrained-random JTAG/DMI test. The `compliance` target additionally
builds riscv-openocd and a CV32E40P-based model.
