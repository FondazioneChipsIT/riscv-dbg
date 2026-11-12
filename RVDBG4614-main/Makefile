# Copyright 2026 EuroCDP contributors.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# RVDBG4614 (RISC-V debug module) - physical design and simulation flow.

MAKEFILE_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

TOP = RVDBG4614

.DEFAULT_GOAL := help

# PDK: the IHP SG13G2 open PDK installed on the system (e.g. IIC-OSIC-TOOLS).
PDK_ROOT ?= /foss/pdks
PDK      ?= ihp-sg13g2
PDK_DIR  := $(PDK_ROOT)/$(PDK)

# IIC-OSIC-TOOLS ships an OpenROAD build matched to LibreLane besides the
# standalone (newer) OpenROAD; use it when available.
OPENROAD_LIBRELANE_BIN ?= /foss/tools/openroad-librelane/bin
ifneq ($(wildcard $(OPENROAD_LIBRELANE_BIN)/openroad),)
export PATH := $(OPENROAD_LIBRELANE_BIN):$(PATH)
endif

LIBRELANE_DIR   := Flow/scripts/LibreLane
LIBRELANE_FLAGS := --manual-pdk --pdk-root $(PDK_ROOT) --pdk $(PDK)
LIBRELANE_CMD   := librelane $(LIBRELANE_FLAGS) $(LIBRELANE_DIR)/config.yaml
PNR_DIR         := PlaceAndRoute
SYNTH_DIR       := synthesis
VERIF_DIR       := verification
TB_DIR          := testbench
FLOW_FINAL_DIR  := $(LIBRELANE_DIR)/final
RELEASE_DIR     := ../release/v.1.0.0

# Most recent LibreLane run (override with RUN_TAG=<tag>)
RUN_TAG ?= $(shell ls -1t $(LIBRELANE_DIR)/runs 2>/dev/null | head -n 1)
RUN_DIR  = $(LIBRELANE_DIR)/runs/$(RUN_TAG)

CORNERS := nom_fast_1p32V_m40C nom_slow_1p08V_125C nom_typ_1p20V_25C

# Verilator-compatible copy of the IHP standard-cell models (gate-level sims)
STDCELL_PATCH     := $(TB_DIR)/patches/verilator_stdcell.patch
STDCELL_BUILD_DIR := $(TB_DIR)/build
STDCELL_MODELS    := $(STDCELL_BUILD_DIR)/$(PDK)/libs.ref/sg13g2_stdcell/verilog/sg13g2_stdcell.v

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-22s %s\n", $$1, $$2}'
.PHONY: help

all: ## Run the LibreLane flow and package the whole macro
	$(MAKE) check-pdk
	$(MAKE) librelane
	$(MAKE) copy-results
.PHONY: all

check-pdk: ## Check that the IHP SG13G2 PDK is available in PDK_ROOT
	@test -d $(PDK_DIR)/libs.tech/librelane || \
		(echo "ERROR: $(PDK) not found in PDK_ROOT=$(PDK_ROOT)"; exit 1)
	@echo "Using $(PDK) from $(PDK_DIR) (commit $$(cat $(PDK_DIR)/COMMIT 2>/dev/null || echo unknown))"
.PHONY: check-pdk

copy-results: ## Copy results from LibreLane to PlaceAndRoute, synthesis and verification
	$(MAKE) copy-pnr
	$(MAKE) copy-synthesis
	$(MAKE) copy-verification
.PHONY: copy-results

librelane: ## Run LibreLane with Magic and KLayout DRC checks
	$(LIBRELANE_CMD) --save-views-to $(FLOW_FINAL_DIR)/
.PHONY: librelane

librelane-nodrc: ## Run LibreLane without DRC checks
	$(LIBRELANE_CMD) --save-views-to $(FLOW_FINAL_DIR)/ --skip KLayout.DRC --skip Magic.DRC --skip KLayout.Antenna --skip KLayout.Density
.PHONY: librelane-nodrc

librelane-magicdrc: ## Run LibreLane with only Magic DRC checks
	$(LIBRELANE_CMD) --save-views-to $(FLOW_FINAL_DIR)/ --skip KLayout.DRC
.PHONY: librelane-magicdrc

librelane-klayoutdrc: ## Run LibreLane with only KLayout DRC checks
	$(LIBRELANE_CMD) --save-views-to $(FLOW_FINAL_DIR)/ --skip Magic.DRC
.PHONY: librelane-klayoutdrc

librelane-openroad: ## Open the last LibreLane run in OpenROAD GUI
	$(LIBRELANE_CMD) --last-run --flow OpenInOpenROAD
.PHONY: librelane-openroad

librelane-klayout: ## Open the last LibreLane run in KLayout
	$(LIBRELANE_CMD) --last-run --flow OpenInKLayout
.PHONY: librelane-klayout

copy-pnr: ## Copy final views to PlaceAndRoute/
	mkdir -p $(PNR_DIR)/gds $(PNR_DIR)/netlist $(PNR_DIR)/lef $(PNR_DIR)/def
	mkdir -p $(PNR_DIR)/timing/sdf $(PNR_DIR)/timing/lib $(PNR_DIR)/parasitics/spef
	rm -f $(PNR_DIR)/gds/$(TOP).gds $(PNR_DIR)/gds/$(TOP).gds.gz
	cp $(FLOW_FINAL_DIR)/gds/$(TOP).gds $(PNR_DIR)/gds/$(TOP).gds
	gzip -n $(PNR_DIR)/gds/$(TOP).gds
	cp $(FLOW_FINAL_DIR)/nl/$(TOP).nl.v $(PNR_DIR)/netlist/$(TOP).nl.v
	cp $(FLOW_FINAL_DIR)/pnl/$(TOP).pnl.v $(PNR_DIR)/netlist/$(TOP).pnl.v
	cp $(FLOW_FINAL_DIR)/lef/$(TOP).lef $(PNR_DIR)/lef/$(TOP).lef
	cp $(FLOW_FINAL_DIR)/def/$(TOP).def $(PNR_DIR)/def/$(TOP).def
	rm -f $(PNR_DIR)/timing/sdf/$(TOP)* $(PNR_DIR)/timing/lib/$(TOP)*
	for c in $(CORNERS); do \
		cp $(FLOW_FINAL_DIR)/sdf/$$c/$(TOP)__$$c.sdf $(PNR_DIR)/timing/sdf/$(TOP)__$$c.sdf; \
		cp $(FLOW_FINAL_DIR)/lib/$$c/$(TOP)__$$c.lib $(PNR_DIR)/timing/lib/$(TOP)__$$c.lib; \
	done
	cp $(FLOW_FINAL_DIR)/spef/nom/$(TOP).nom.spef $(PNR_DIR)/parasitics/spef/$(TOP).nom.spef
.PHONY: copy-pnr

copy-synthesis: ## Copy synthesis netlists, reports and pre-layout SDFs to synthesis/
	mkdir -p $(SYNTH_DIR)/netlist $(SYNTH_DIR)/reports $(SYNTH_DIR)/sdf
	cp $(RUN_DIR)/*-yosys-synthesis/$(TOP).nl.v $(SYNTH_DIR)/netlist/$(TOP).nl.v
	cp $(FLOW_FINAL_DIR)/spice/$(TOP).spice $(SYNTH_DIR)/netlist/$(TOP).spice
	rm -f $(SYNTH_DIR)/reports/*.rpt $(SYNTH_DIR)/sdf/$(TOP)*
	cp $(RUN_DIR)/*-yosys-synthesis/reports/stat.rpt $(SYNTH_DIR)/reports/stat.rpt
	cp $(RUN_DIR)/*-openroad-staprepnr/summary.rpt $(SYNTH_DIR)/reports/staprepnr_summary.rpt
	cp $(RUN_DIR)/*-openroad-stapostpnr/summary.rpt $(SYNTH_DIR)/reports/stapostpnr_summary.rpt
	for c in $(CORNERS); do \
		cp $(RUN_DIR)/*-openroad-staprepnr/$$c/$(TOP)__$$c.sdf $(SYNTH_DIR)/sdf/$(TOP)__$$c.sdf; \
		cp $(RUN_DIR)/*-openroad-staprepnr/$$c/power.rpt $(SYNTH_DIR)/reports/staprepnr_$${c}_power.rpt; \
		cp $(RUN_DIR)/*-openroad-stapostpnr/$$c/power.rpt $(SYNTH_DIR)/reports/stapostpnr_$${c}_power.rpt; \
	done
.PHONY: copy-synthesis

copy-verification: ## Copy lint, DRC, LVS, antenna and STA reports to verification/
	mkdir -p $(VERIF_DIR)/lint $(VERIF_DIR)/drc $(VERIF_DIR)/lvs $(VERIF_DIR)/sta
	cp $(RUN_DIR)/*-verilator-lint/verilator-lint.log $(VERIF_DIR)/lint/verilator-lint.log
	cp $(RUN_DIR)/*-magic-drc/reports/drc.magic.rpt $(VERIF_DIR)/drc/drc.magic.rpt
	cp $(RUN_DIR)/*-klayout-drc/reports/drc.klayout.json $(VERIF_DIR)/drc/drc.klayout.json
	cp $(RUN_DIR)/*-openroad-checkantennas-1/reports/antenna_summary.rpt $(VERIF_DIR)/drc/antenna.openroad.rpt
	cp $(RUN_DIR)/*-netgen-lvs/reports/lvs.netgen.rpt $(VERIF_DIR)/lvs/lvs.netgen.rpt
	cp $(RUN_DIR)/*-openroad-stapostpnr/summary.rpt $(VERIF_DIR)/sta/stapostpnr_summary.rpt
	for c in $(CORNERS); do \
		cp $(RUN_DIR)/*-openroad-stapostpnr/$$c/max.rpt $(VERIF_DIR)/sta/stapostpnr_$${c}_max.rpt; \
		cp $(RUN_DIR)/*-openroad-stapostpnr/$$c/min.rpt $(VERIF_DIR)/sta/stapostpnr_$${c}_min.rpt; \
	done
	cp $(RUN_DIR)/final/metrics.csv $(VERIF_DIR)/metrics.csv
.PHONY: copy-verification

release: ## Copy the final LibreLane views to release/v.1.0.0/views
	mkdir -p $(RELEASE_DIR)/views
	cp -r $(FLOW_FINAL_DIR)/. $(RELEASE_DIR)/views/
	cp $(FLOW_FINAL_DIR)/gds/$(TOP).gds $(RELEASE_DIR)/$(TOP).gds
.PHONY: release

$(STDCELL_MODELS): $(STDCELL_PATCH)
	mkdir -p $(STDCELL_BUILD_DIR)/$(PDK)/libs.ref/sg13g2_stdcell/verilog
	cp -f $(PDK_DIR)/libs.ref/sg13g2_stdcell/verilog/sg13g2_stdcell.v $(PDK_DIR)/libs.ref/sg13g2_stdcell/verilog/sg13g2_udp.v \
		$(STDCELL_BUILD_DIR)/$(PDK)/libs.ref/sg13g2_stdcell/verilog/
	cd $(STDCELL_BUILD_DIR) && patch -p1 < $(MAKEFILE_DIR)/$(STDCELL_PATCH)

stdcell-models: $(STDCELL_MODELS) ## Build Verilator-compatible IHP standard-cell models
.PHONY: stdcell-models

simulate-rtl: ## Run RTL simulation with Verilator
	cd $(MAKEFILE_DIR)/$(TB_DIR) && ./run_verilator.sh --build-rtl --run-rtl ./helloworld.hex
.PHONY: simulate-rtl

simulate-postsynth: $(STDCELL_MODELS) ## Run post-synthesis simulation with Verilator
	cd $(MAKEFILE_DIR)/$(TB_DIR) && ./run_verilator.sh --build-postsynth --run-postsynth ./helloworld.hex
.PHONY: simulate-postsynth

simulate-postpnr: $(STDCELL_MODELS) ## Run post place-and-route simulation with Verilator
	cd $(MAKEFILE_DIR)/$(TB_DIR) && ./run_verilator.sh --build-postpnr --run-postpnr ./helloworld.hex
.PHONY: simulate-postpnr

simulate-all: ## Run RTL, post-synthesis and post-PnR simulations
	$(MAKE) simulate-rtl
	$(MAKE) simulate-postsynth
	$(MAKE) simulate-postpnr
.PHONY: simulate-all
