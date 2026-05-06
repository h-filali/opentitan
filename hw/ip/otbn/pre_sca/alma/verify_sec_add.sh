#!/bin/bash
# Copyright lowRISC contributors (OpenTitan project).
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# Script to formally verify the masking of the SEC_ADD unit using Alma.

set -e

# Ensure the Alma virtualenv's packages are found regardless of PYTHONPATH
# overrides from the calling environment (e.g. nix develop).
ALMA_SITE_PACKAGES="${HOME}/alma/dev/lib/python3.10/site-packages"
export PYTHONPATH="${ALMA_SITE_PACKAGES}${PYTHONPATH:+:${PYTHONPATH}}"

# Argument parsing
TARGET_TYPE="${1:-mask_accelerator}"
case "$TARGET_TYPE" in
  test)    export TOP_MODULE=otbn_sec_add_sca_test_wrapper ;;
  hpc2)    export TOP_MODULE=prim_hpc2_sca_wrapper ;;
  hpc2o)   export TOP_MODULE=prim_hpc2o_sca_wrapper ;;
  hpc3)    export TOP_MODULE=prim_hpc3_sca_wrapper ;;
  hpc3o)   export TOP_MODULE=prim_hpc3o_sca_wrapper ;;
  sec_add) export TOP_MODULE=otbn_sec_add_sca_wrapper ;;
  *)       export TOP_MODULE=otbn_mask_accelerator_sca_wrapper ;;
esac

TESTBENCH=${TOP_MODULE}

echo "Verifying ${TOP_MODULE} using Alma"

# Parse
./parse.py --top-module ${TOP_MODULE} \
--source ${REPO_TOP}/hw/ip/otbn/pre_syn/syn_out/latest/generated/${TOP_MODULE}.alma.v \
--netlist tmp/circuit.v --log-yosys

# Label
sed -i 's/\(share0_i\s\[\)\([0-9]\+:0\)\(\]\s=\s\)unimportant/\1\2\3secret \2/g' tmp/labels.txt
sed -i 's/\(share0_i\s=\s\)unimportant/\1secret 0:0/g' tmp/labels.txt
sed -i 's/\(share1_i\s\[\)\([0-9]\+:0\)\(\]\s=\s\)unimportant/\1\2\3secret \2/g' tmp/labels.txt
sed -i 's/\(share1_i\s=\s\)unimportant/\1secret 0:0/g' tmp/labels.txt
sed -i 's/\(rand_i\(\s\[[0-9]\+:0\]\)\?\s=\s\)unimportant/\1random/g' tmp/labels.txt

# Trace
./trace.py --testbench ${REPO_TOP}/hw/ip/otbn/pre_sca/alma/cpp/verilator_tb_${TESTBENCH}.cpp \
  --netlist tmp/circuit.v --c-compiler gcc -o tmp/circuit

# Verify
./verify.py --json tmp/circuit.json \
  --label tmp/labels.txt \
  --top-module ${TOP_MODULE} \
  --vcd tmp/tmp.vcd \
  --rst-name rst_ni --rst-phase 0 \
  --probe-duration once \
  --mode transient \
  --glitch-behavior strict \
  --cycles 25
