#!/usr/bin/env bash
# Copyright 2026 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Authors:
# - Philippe Sauter <phsauter@iis.ee.ethz.ch>
#
# Compiles the dm_mem testbench once and runs its Questa parameter matrix.

set -euo pipefail

TB_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# Repository root (Bender package root): <root>/RVDBG4614-main/testbench/riscv-dbg/tb
ROOT=$(cd "${TB_DIR}/../../../.." && pwd)
BUILD_DIR=$(mktemp -d)
trap 'rm -r "${BUILD_DIR}"' EXIT

BENDER=${BENDER:-bender}
VSIM=${VSIM:-vsim}

cd "${ROOT}"
"${BENDER}" script vsim -n -t dm_mem_test \
  --vlog-arg="-svinputport=compat" \
  --vlog-arg="-override_timescale 1ns/1ps" \
  > "${BUILD_DIR}/compile.tcl"
echo 'return 0' >> "${BUILD_DIR}/compile.tcl"

cd "${BUILD_DIR}"
"${VSIM}" -c -do 'exit -code [source compile.tcl]'
"${VSIM}" -c -do "source {${TB_DIR}/dm_mem/test_access_widths_vsim.tcl}"
