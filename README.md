# RVDBG4614 - RISC-V Debug Module

RVDBG4614 is a hard-macro packaging of the PULP Platform
[riscv-dbg](https://github.com/pulp-platform/riscv-dbg) debug system: a RISC-V
External Debug Support (v0.13.2) compliant Debug Module (DM) with program
buffer and System Bus Access, together with its JTAG Debug Transport Module
(DTM). It provides run-control debug (halt, resume, single step, register and
memory access) for RISC-V cores such as CV32E20/CVE2, Ibex, CV32E40P and CVA6.

Within the EuroCDP project the original IP was reorganized according to the
EuroCDP IP directory and release structure. The resulting package was enhanced
with a reproducible LibreLane physical-design flow for the IHP SG13G2 open PDK,
a gate-level capable simulation flow, implementation reports and release
deliverables.

The EuroCDP IP documentation is in the [`doc`](doc/) folder
([overview](doc/overview.md), [datasheet](doc/Datasheet.md),
[specification](doc/Specification.md), [IPRL assessment](doc/IPRL-Digital-Hard-IP.md)),
together with the original upstream description of the debug system
([debug-system.md](doc/debug-system.md)). The original upstream README is kept
as [PULP_README.md](PULP_README.md).

- `RVDBG4614-main/`: implementation views; top cell `RVDBG4614`.
- `doc/`: datasheet, specification, metadata, and completed IPRL questionnaire.
- `dependencies/`: dependency IP packages (none).
- `release/v.1.0.0/`: `RVDBG4614.gds`, release notes, all macro views and `measurements/`.

## Repository structure

```text
.
├── RVDBG4614-main/              implementation (EuroCDP digital IP structure)
│   ├── Makefile                 flow entry point (make help)
│   ├── rtl/                     RVDBG4614.sv top, riscv-dbg sources, common_cells, tc_clk
│   ├── constraints/sdc/         timing constraints
│   ├── Flow/scripts/LibreLane/  LibreLane (Classic flow) configuration
│   ├── synthesis/               synthesis netlist, SDF and reports
│   ├── PlaceAndRoute/           routed netlist, GDS, LEF, DEF, Liberty, SDF, SPEF
│   ├── testbench/               Croc SoC testbench + upstream riscv-dbg testbenches
│   └── verification/            lint, DRC, LVS, antenna and STA reports
├── doc/                         EuroCDP documentation and metadata (info.json)
├── release/v.1.0.0/             release notes and views
├── Bender.yml, src_files.yml    upstream package manifests (paths updated)
└── PULP_README.md, CHANGELOG.md, LICENSE, LICENSE.SiFive
```

`Bender.yml` is kept at the repository root so that the repository can still be
used as a [Bender](https://github.com/pulp-platform/bender) dependency.

## Requirements

The flow was developed and run in the
[IIC-OSIC-TOOLS](https://github.com/iic-jku/IIC-OSIC-TOOLS) environment, which
provides LibreLane, OpenROAD, Yosys, Magic, Netgen, KLayout, Verilator and the
IHP SG13G2 PDK under `/foss/pdks`. Another PDK installation can be selected
with `PDK_ROOT=<path>` (the directory that contains `ihp-sg13g2/`).

## Running the flow

From `RVDBG4614-main/`, run the complete RTL-to-GDS LibreLane flow and copy the
results into the `synthesis/`, `PlaceAndRoute/` and `verification/` folders:

```
make all
```

The simulation flow covers RTL, post-synthesis and post-place-and-route
simulations, which can be executed with:

```
make simulate-rtl
make simulate-postsynth
make simulate-postpnr
```

To check the full list of makefile commands run:

```
make help
```

## Development

Development, issues, merge requests, and releases are managed in the
authoritative EuroCDP GitLab repository on code.europa.eu. Approved content is
published through a GitLab push mirror to the EuroCDP GitHub organization.

## Repository notice (GitHub mirror)

> This repository is a public mirror of the EuroCDP development repository
> hosted on code.europa.eu. Development, issues, merge requests, and releases
> are managed in GitLab. Changes made directly in this GitHub repository
> may be overwritten.

## License

The riscv-dbg sources are licensed under the Solderpad Hardware License v0.51
(see [LICENSE](LICENSE)); parts derived from SiFive code are licensed under the
Apache License 2.0 (see [LICENSE.SiFive](LICENSE.SiFive)). Vendored third-party
code (common_cells, Croc SoC testbench, CVE2) keeps its original license
headers.
