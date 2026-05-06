#!/bin/bash

# Copyright lowRISC contributors (OpenTitan project).
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# This script drives the experimental Yosys synthesis flow. More details can be found in README.md

set -e
set -o pipefail

error () {
    echo >&2 "$@"
    exit 1
}

teelog () {
    tee "$LR_SYNTH_OUT_DIR/log/$1.log"
}

if [ ! -f syn_setup_sec_add.sh ]; then
    error "No syn_setup_sec_add.sh file: see README.md for instructions"
fi

#-------------------------------------------------------------------------
# setup flow variables
#-------------------------------------------------------------------------
TARGET_TYPE="${1:-mask_accelerator}"
source syn_setup_sec_add.sh

#-------------------------------------------------------------------------
# prepare output folders
#-------------------------------------------------------------------------
mkdir -p "$LR_SYNTH_OUT_DIR/generated"
mkdir -p "$LR_SYNTH_OUT_DIR/log"
mkdir -p "$LR_SYNTH_OUT_DIR/reports/timing"

rm -f syn_out/latest
ln -s "${LR_SYNTH_OUT_DIR#syn_out/}" syn_out/latest

#-------------------------------------------------------------------------
# use sv2v to convert all SystemVerilog files to Verilog
#-------------------------------------------------------------------------
export LR_SYNTH_SRC_DIR="../../$LR_SYNTH_IP_NAME"

# Get OpenTitan dependency sources.
OT_DEP_SOURCES=()
# Include the pre-SCA wrapper only when one exists for this target.
_pre_sca_wrapper="$LR_SYNTH_SRC_DIR/pre_sca/rtl/${LR_SYNTH_TOP_MODULE}.sv"
if [ -f "$_pre_sca_wrapper" ]; then
    OT_DEP_SOURCES+=("$_pre_sca_wrapper")
fi
OT_DEP_SOURCES+=(
    # "$LR_SYNTH_SRC_DIR"/rtl/otbn_mask_accelerator.sv
    # "$LR_SYNTH_SRC_DIR"/rtl/otbn_sec_add_mod.sv
    # "$LR_SYNTH_SRC_DIR"/rtl/otbn_sec_add.sv
    "$LR_SYNTH_SRC_DIR"/../prim/rtl/prim_blanker.sv
    "$LR_SYNTH_SRC_DIR"/../prim/rtl/prim_fifo_sync.sv
    "$LR_SYNTH_SRC_DIR"/../prim/rtl/prim_fifo_sync_cnt.sv
    "$LR_SYNTH_SRC_DIR"/../prim/rtl/prim_count.sv
    "$LR_SYNTH_SRC_DIR"/../prim/rtl/prim_flop_x.sv
    "$LR_SYNTH_SRC_DIR"/../prim/rtl/prim_hpc2.sv
    "$LR_SYNTH_SRC_DIR"/../prim/rtl/prim_hpc3.sv
    "$LR_SYNTH_SRC_DIR"/../prim_xilinx/rtl/prim_flop.sv
    "$LR_SYNTH_SRC_DIR"/../prim_xilinx/rtl/prim_flop_en.sv
    "$LR_SYNTH_SRC_DIR"/../prim_xilinx/rtl/prim_buf.sv
    "$LR_SYNTH_SRC_DIR"/../prim_xilinx/rtl/prim_and2.sv
    "$LR_SYNTH_SRC_DIR"/../prim_xilinx/rtl/prim_xor2.sv
    "$LR_SYNTH_SRC_DIR"/../prim_xilinx/rtl/prim_inv.sv
)

# Get OpenTitan dependency packages.
OT_DEP_PACKAGES=(
    "$LR_SYNTH_SRC_DIR"/../../top_earlgrey/rtl/*_pkg.sv
    "$LR_SYNTH_SRC_DIR"/../edn/rtl/*_pkg.sv
    "$LR_SYNTH_SRC_DIR"/../csrng/rtl/*_pkg.sv
    "$LR_SYNTH_SRC_DIR"/../entropy_src/rtl/*_pkg.sv
    "$LR_SYNTH_SRC_DIR"/../lc_ctrl/rtl/*_pkg.sv
    "$LR_SYNTH_SRC_DIR"/../tlul/rtl/*_pkg.sv
    "$LR_SYNTH_SRC_DIR"/../prim/rtl/*_pkg.sv
    "$LR_SYNTH_SRC_DIR"/../prim_generic/rtl/*_pkg.sv
    "$LR_SYNTH_SRC_DIR"/../keymgr/rtl/*_pkg.sv
    "$LR_SYNTH_SRC_DIR"/../otp_ctrl/rtl/*_pkg.sv
)

# Convert OpenTitan dependency sources.
for file in "${OT_DEP_SOURCES[@]}"; do
    module=`basename -s .sv $file`

    # Skip packages
    if echo "$module" | grep -q '_pkg$'; then
        continue
    fi

    sv2v \
        --define=SYNTHESIS --define=SYNTHESIS_MEMORY_BLACK_BOXING --define=YOSYS \
        "${OT_DEP_PACKAGES[@]}" \
        "$LR_SYNTH_SRC_DIR"/rtl/*_pkg.sv \
        -I"$LR_SYNTH_SRC_DIR"/../prim/rtl \
        $file \
        > "$LR_SYNTH_OUT_DIR/generated/${module}.v"

    # Remove calls to $value$plusargs(). Yosys doesn't seem to support this.
    sed -i '/$value$plusargs(.*/d' $LR_SYNTH_OUT_DIR/generated/${module}.v
done

# Rename the prim_sparse_fsm_flop module. For some reason, sv2v decides to append a suffix.
# sed -i 's/module prim_sparse_fsm_flop_.*/module prim_sparse_fsm_flop \(/g' \
#     $LR_SYNTH_OUT_DIR/generated/prim_sparse_fsm_flop.v

# Get and convert core sources.
for file in "$LR_SYNTH_SRC_DIR"/rtl/*.sv; do
    module=`basename -s .sv $file`

    # Skip packages
    if echo "$module" | grep -q '_pkg$'; then
        continue
    fi

    sv2v \
        --define=SYNTHESIS \
        "${OT_DEP_PACKAGES[@]}" \
        "$LR_SYNTH_SRC_DIR"/rtl/*_pkg.sv \
        -I"$LR_SYNTH_SRC_DIR"/../prim/rtl \
        $file \
        > "$LR_SYNTH_OUT_DIR/generated/${module}.v"

    # Rename prim_sparse_fsm_flop instances. For some reason, sv2v decides to append a suffix.
    # sed -i 's/prim_sparse_fsm_flop_.*/prim_sparse_fsm_flop \#(/g' \
    #     $LR_SYNTH_OUT_DIR/generated/${module}.v

done

#-------------------------------------------------------------------------
# run Yosys synthesis
#-------------------------------------------------------------------------
yosys -c ./tcl/yosys_run_synth_sec_add.tcl |& teelog syn || {
    error "Failed to synthesize RTL with Yosys"
}

#-------------------------------------------------------------------------
# run static timing analysis
#-------------------------------------------------------------------------
if [[ $LR_SYNTH_TIMING_RUN == 1 ]] ; then
    sta ./tcl/sta_run_reports.tcl |& teelog sta || {
        error "Failed to run static timing analysis"
    }

    ./translate_timing_rpts.sh
fi

#-------------------------------------------------------------------------
# report kGE number
#-------------------------------------------------------------------------
python/get_kge.py $LR_SYNTH_CELL_LIBRARY_PATH $LR_SYNTH_OUT_DIR/reports/area.rpt
