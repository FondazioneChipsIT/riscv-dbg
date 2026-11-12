# Digital Hard IP Quality Assessment using IPRL scale

This questionnaire supports self-assessment of an IP block using the IP Readiness
Level (IPRL) scale. It follows EuroCDP D5.3, *Open IP Concept*.

## Assessment guidance

- Complete a copy in the IP repository's `doc/` directory for the assessed release.
- Mark a question `[x]` when it is true and add links to supporting design files,
  documentation, reports, or measurements. Leave other questions unchecked and
  explain missing evidence or non-applicability where relevant.
- **Assessment rule:** the achieved IPRL is the highest level with at least one
  true answer at that level and at every lower level. Unanswered or non-applicable
  questions do not count as true answers.
- **Catalog acceptance:** D5.3 specifies a minimum of IPRL 5 for digital IP and
  requires IP designed for open PDKs.

## Assessment record

- IP name: RVDBG4614 (PULP riscv-dbg debug module, repository `IHP_D_RVDBG4614`)
- Assessed release / commit: v.1.0.0 (riscv-dbg upstream `643607e` + EuroCDP packaging)
- Target open PDK / revision: IHP SG13G2 (IHP-Open-PDK `be443daab937daa9154c9c4e73584524f431bd97`)
- Assessor / date: [to be completed by the EuroCDP assessor] / 2026-11-11
- Achieved IPRL: 5 (see note below)
- Evidence summary and known limitations: [overview](overview.md),
  [datasheet](Datasheet.md), [specification](Specification.md),
  [release notes](../release/v.1.0.0/ReleaseNote.md). Pre-silicon; no LEC,
  no code coverage, zero-delay gate-level simulation only.

Note: by the assessment rule, the questions marked true at IPRL 6 (complete
views, PVT corners, integration instructions) would allow IPRL 6. Consistently
with the other EuroCDP digital hard IPs, IPRL 5 is claimed because full
functional verification with documented coverage (IPRL 5 and 6) and LEC have
not been completed.

---

## IPRL 1 - Basic principles observed

- [x] Is the IP functionality clearly described? - [overview](overview.md), [debug-system.md](debug-system.md)
- [x] Have the potential applications of the IP been identified and described? - [overview](overview.md): run-control debug of RISC-V harts (CVE2/Ibex, CV32E40P, CVA6, Croc, Cheshire)

## IPRL 2 - Concept formulation

- [x] Is the IP architecture described at the block level? - [specification](Specification.md) section 3
- [x] Are the IP requirements and specifications clearly described, including I/O descriptions and whether it includes a standard interface? - [specification](Specification.md) sections 2 and 4 (JTAG, OBI)

## IPRL 3 - Experimental proof of concept

- [x] Have the core functionalities of the system been implemented at RTL level? - `RVDBG4614-main/rtl/`
- [x] Has the RTL model been provided? - `RVDBG4614-main/rtl/RVDBG4614.sv`, `RVDBG4614-main/rtl/riscv-dbg/`
- [x] Has a complete behavioral simulation flow been provided? - `make simulate-rtl`, `RVDBG4614-main/testbench/riscv-dbg/ci`
- [x] Has a testbench been provided? - `RVDBG4614-main/testbench/`
- [x] Has the basic functionality of the IP been demonstrated? - Croc SoC simulation: SBA load, halt, abstract commands, program buffer, resume

## IPRL 4 - Component prototype

- [x] Has the RTL been fully developed with all features implemented? - all features of upstream riscv-dbg for the selected configuration
- [x] Has the design been synthesized (e.g. FPGA or ASIC)? - `RVDBG4614-main/synthesis/` (Yosys, IHP SG13G2)
- [x] Has a complete post-synthesis simulation been carried out (e.g. FPGA or ASIC) or a logic equivalence check (LEC) report provided? - `make simulate-postsynth` (passed)
- [x] Have preliminary post-synthesis Power, Performance, and Area (PPA) results been provided (e.g. on FPGA or ASIC)? - `RVDBG4614-main/synthesis/reports/` (stat, staprepnr)
- [x] Has the IP been able to run preliminary application code (e.g. an accelerator running machine learning code on simulation or FPGA)? - debugger-driven program load and execution of `helloworld` on the Croc SoC in simulation

## IPRL 5 - Full design at layout level

- [ ] Has full verification been completed and documented, including 100% code coverage with waivers? - not done: no coverage measurement
- [x] Has the place-and-route stage been successfully completed and corresponding constraints provided? - `RVDBG4614-main/PlaceAndRoute/`, `RVDBG4614-main/constraints/sdc/`
- [ ] Has the LEC between the RTL and the post-place-and-route design been performed? - not done
- [x] Have final post-layout PPA results been provided? - [datasheet](Datasheet.md), `RVDBG4614-main/verification/sta/`
- [x] Have the post-place-and-route simulations been performed, and are the corresponding testbenches provided? - `make simulate-postpnr` (passed, zero-delay)
- [x] Has signoff been completed in the target technology node? - DRC/antenna/LVS clean, 3-corner STA with no setup/hold, slew or capacitance violations: `RVDBG4614-main/verification/`

## IPRL 6 - Full design for SoC integration

- [x] Have all IP views been completed? - `release/v.1.0.0/views/`
- [ ] Has full functional verification been completed with documented coverage? - not done
- [x] Has the IP been characterized across process, voltage and temperature (PVT) corners? - Liberty/SDF/STA for nom_slow_1p08V_125C, nom_typ_1p20V_25C, nom_fast_1p32V_m40C
- [x] Are there clear instructions on how to use and integrate the IP? - [specification](Specification.md) section 5, [README](../README.md)

## IPRL 7 - Lab demonstrator prototype

- [ ] Has the silicon prototype (e.g. through a multi-project wafer (MPW)) been demonstrated on an application development board or another platform, and tested in a laboratory environment?
- [ ] Has the application development board been provided and fully documented?
- [ ] Have the key performance metrics at the application level been provided?

## IPRL 8 - In-field demonstrator prototype

- [ ] Has the IP undergone full qualification, including design-for-manufacturing and design-for-testability features such as scan chains, built-in self-tests (BISTs), and related structures?
- [ ] Has the IP passed industry-standard compliance and certification testing?
- [ ] Has this IP been fabricated in final mask production?
- [ ] Has the IP been deployed in an end-use prototype?
- [ ] Has the IP been tested in a pilot production run or customer field trial?

## IPRL 9 - Commercial application

- [ ] Has this IP been used in product production?
- [ ] Has this IP been commercially deployed?
- [ ] Has the product reliability been demonstrated in the field?
- [ ] Are the IP authors providing support for bug fixing or enhancement requests?
- [ ] Does the IP documentation include complete supporting material, including training resources?
