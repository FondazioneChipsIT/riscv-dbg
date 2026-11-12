#!/usr/bin/env bash
# Copyright 2026 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Authors:
# - Philippe Sauter <phsauter@iis.ee.ethz.ch>

set -euo pipefail

# Lint the riscv-dbg sources and the RVDBG4614 hard-macro wrapper. Vendored
# third-party code (common_cells, Croc SoC testbench, CVE2) is excluded.

while IFS= read -r -d '' file; do
  if [[ -f "${file}" ]]; then
    printf '%s\0' "${file}"
  fi
done < <(git ls-files -z -- \
  ':(glob)RVDBG4614-main/rtl/riscv-dbg/**/*.sv' \
  ':(glob)RVDBG4614-main/rtl/RVDBG4614.sv' \
  ':(glob)RVDBG4614-main/testbench/riscv-dbg/**/*.sv' \
  ':(glob)RVDBG4614-main/testbench/riscv-dbg/**/*.v') \
  | xargs -0 verible-verilog-lint \
      --lint_fatal \
      --parse_fatal \
      --waiver_files .github/verible.waiver
