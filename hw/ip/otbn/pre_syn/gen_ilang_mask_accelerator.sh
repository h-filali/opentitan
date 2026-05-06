#!/bin/bash

# Copyright lowRISC contributors (OpenTitan project).
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# Generates a .ilang (RTLIL) file for otbn_mask_accelerator_sca_wrapper using Yosys.
# Run from the hw/ip/otbn/pre_syn/ directory.

set -e
set -o pipefail

error () {
    echo >&2 "$@"
    exit 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"        # hw/ip/otbn
PRIM_DIR="$(cd "$SRC_DIR/../prim" && pwd)"      # hw/ip/prim
PRIM_XILINX_DIR="$(cd "$SRC_DIR/../prim_xilinx" && pwd)"  # hw/ip/prim_xilinx
IP_DIR="$(cd "$SRC_DIR/.." && pwd)"             # hw/ip

TOP_MODULE="otbn_mask_accelerator_sca_wrapper"
OUT_DIR="$SCRIPT_DIR/ilang_out"
GEN_DIR="$OUT_DIR/generated"
OUTPUT_ILANG="$OUT_DIR/${TOP_MODULE}.ilang"

mkdir -p "$GEN_DIR"

#-------------------------------------------------------------------------
# Collect package files for sv2v
#-------------------------------------------------------------------------
OT_DEP_PACKAGES=(
    "$IP_DIR"/otbn/../../top_earlgrey/rtl/*_pkg.sv
    "$IP_DIR"/edn/rtl/*_pkg.sv
    "$IP_DIR"/csrng/rtl/*_pkg.sv
    "$IP_DIR"/entropy_src/rtl/*_pkg.sv
    "$IP_DIR"/lc_ctrl/rtl/*_pkg.sv
    "$IP_DIR"/tlul/rtl/*_pkg.sv
    "$PRIM_DIR"/rtl/*_pkg.sv
    "$IP_DIR"/prim_generic/rtl/*_pkg.sv
    "$IP_DIR"/keymgr/rtl/*_pkg.sv
    "$IP_DIR"/otp_ctrl/rtl/*_pkg.sv
)

#-------------------------------------------------------------------------
# Dependency sources (prim_* and sub-modules of mask_accelerator)
#-------------------------------------------------------------------------
OT_DEP_SOURCES=(
    "$SRC_DIR/pre_sca/rtl/otbn_mask_accelerator_sca_wrapper.sv"
    "$SRC_DIR/rtl/otbn_mask_accelerator.sv"
    "$SRC_DIR/rtl/otbn_sec_add_mod.sv"
    "$SRC_DIR/rtl/otbn_sec_add.sv"
    "$PRIM_DIR/rtl/prim_blanker.sv"
    "$PRIM_DIR/rtl/prim_fifo_sync.sv"
    "$PRIM_DIR/rtl/prim_fifo_sync_cnt.sv"
    "$PRIM_DIR/rtl/prim_count.sv"
    "$PRIM_DIR/rtl/prim_hpc2.sv"
    "$PRIM_DIR/rtl/prim_hpc3.sv"
    "$PRIM_XILINX_DIR/rtl/prim_flop.sv"
    "$PRIM_XILINX_DIR/rtl/prim_flop_en.sv"
    "$PRIM_XILINX_DIR/rtl/prim_buf.sv"
    "$PRIM_XILINX_DIR/rtl/prim_and2.sv"
    "$PRIM_XILINX_DIR/rtl/prim_xor2.sv"
    "$PRIM_XILINX_DIR/rtl/prim_inv.sv"
)

#-------------------------------------------------------------------------
# Convert dependency sources with sv2v
#-------------------------------------------------------------------------
echo "Converting dependency sources with sv2v..."
for file in "${OT_DEP_SOURCES[@]}"; do
    module=$(basename -s .sv "$file")

    sv2v \
        --define=SYNTHESIS --define=SYNTHESIS_MEMORY_BLACK_BOXING --define=YOSYS \
        "${OT_DEP_PACKAGES[@]}" \
        "$SRC_DIR/rtl/"*_pkg.sv \
        -I"$PRIM_DIR/rtl" \
        "$file" \
        > "$GEN_DIR/${module}.v"

    # Remove calls to $value$plusargs() — Yosys doesn't support this.
    sed -i '/$value\$plusargs(.*/d' "$GEN_DIR/${module}.v"
done

#-------------------------------------------------------------------------
# Convert remaining OTBN RTL sources with sv2v (for any cross-references)
#-------------------------------------------------------------------------
echo "Converting OTBN core RTL sources with sv2v..."
for file in "$SRC_DIR/rtl/"*.sv; do
    module=$(basename -s .sv "$file")

    # Skip packages (already handled above)
    if echo "$module" | grep -q '_pkg$'; then
        continue
    fi

    sv2v \
        --define=SYNTHESIS \
        "${OT_DEP_PACKAGES[@]}" \
        "$SRC_DIR/rtl/"*_pkg.sv \
        -I"$PRIM_DIR/rtl" \
        "$file" \
        > "$GEN_DIR/${module}.v"

    sed -i '/\.StateEnumT(logic \[.*/d' "$GEN_DIR/${module}.v"
    sed -i '/\.StateEnumT_otbn_pkg.*Width.*(.*/d' "$GEN_DIR/${module}.v"
done

#-------------------------------------------------------------------------
# Run Yosys to generate .ilang
#-------------------------------------------------------------------------
echo "Running Yosys..."
yosys -p "
    read_verilog -sv $GEN_DIR/*.v
    attrmap -tocase keep -imap dont_touch=\"yes\" keep=1 -imap dont_touch=\"no\" keep=0 -remove keep=0
    hierarchy -check -top $TOP_MODULE
    proc
    flatten
    memory_map
    opt -purge
    async2sync
    techmap -map $SCRIPT_DIR/dffe_map.v
    techmap
    opt_expr
    opt_clean -purge
    abc -g AND
    opt -purge
    write_rtlil $OUTPUT_ILANG
" 2>&1 | tee "$OUT_DIR/${TOP_MODULE}_yosys.log" || error "Yosys failed — check $OUT_DIR/${TOP_MODULE}_yosys.log"

echo ""
echo "Done. Output: $OUTPUT_ILANG"
