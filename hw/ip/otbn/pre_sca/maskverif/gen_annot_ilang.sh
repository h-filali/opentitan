#!/bin/bash

# Copyright lowRISC contributors (OpenTitan project).
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# Generates the annotated .ilang file for otbn_mask_accelerator_sca_wrapper
# by inserting MaskVerif ## annotations into the base ilang produced by Yosys.
#
# The annotations label:
#   - share0_i / share1_i  : secret input shares (512 bits each, bit-paired)
#   - rand_i               : randomness (386 bits)
#   - sum_o                : secret output shares (64 bits: [31:0]=s0, [63:32]=s1)
#   - everything else      : public inputs / public outputs
#
# Run from this directory (hw/ip/otbn/pre_sca/maskverif/):
#   ./gen_annot_ilang.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ILANG_DIR="$SCRIPT_DIR/../../pre_syn/ilang_out"
SRC="$ILANG_DIR/otbn_mask_accelerator_sca_wrapper.ilang"
DST="$ILANG_DIR/otbn_mask_accelerator_sca_wrapper_annot.ilang"

if [ ! -f "$SRC" ]; then
    echo >&2 "Error: base ilang not found at $SRC"
    echo >&2 "Run hw/ip/otbn/pre_syn/gen_ilang_mask_accelerator.sh first."
    exit 1
fi

echo "Generating annotations..."

# Write everything up to (and including) the top-level module declaration line,
# then inject the ## annotation block, then write the rest unchanged.
python3 - "$SRC" "$DST" <<'PYEOF'
import sys

src_path, dst_path = sys.argv[1], sys.argv[2]

MODULE_LINE = "module \\otbn_mask_accelerator_sca_wrapper"

# Build the annotation block (inserted right after the module declaration).
def build_annotations(width=32, vec_size=8):
    stages = (width - 1).bit_length()          # $clog2(32) = 5
    rand_width = 2 * (stages * width + 1)      # 322
    double_width = 2 * width                   # 64
    flat_share = vec_size * double_width       # 512

    lines = []

    # Public inputs
    lines.append("  ## public \\clk_i \\rst_ni \\wvalid_i \\q_i \\mask_op_i")

    # Public outputs
    lines.append("  ## public output \\wready_o \\rvalid_o \\mask_fifo_err_o \\ctr_err_o")

    # Randomness (all bits of rand_i — auto-expands)
    lines.append("  ## random \\rand_i")

    # Secret inputs: bit i of share0_i and share1_i are the two shares of secret bit i.
    # Syntax: ## input : s<i> [ \share0_i [i] \share1_i [i] ]
    for i in range(flat_share):
        lines.append(
            f"  ## input [ \\share0_i [{i}] \\share1_i [{i}] ]"
        )

    # Secret outputs: sum_o[i] and sum_o[i+32] are the two shares of output bit i.
    # Syntax: ## output [ \sum_o [i] \sum_o [i+width] ]
    for i in range(width):
        lines.append(
            f"  ## output [ \\sum_o [{i}] \\sum_o [{i + width}] ]"
        )

    return lines

annot_lines = build_annotations()

with open(src_path) as f:
    src_lines = f.readlines()

with open(dst_path, "w") as f:
    inserted = False
    for line in src_lines:
        f.write(line)
        if not inserted and line.strip() == MODULE_LINE:
            for a in annot_lines:
                f.write(a + "\n")
            inserted = True

if not inserted:
    print(f"WARNING: module declaration '{MODULE_LINE}' not found — annotations were NOT inserted.",
          file=sys.stderr)
    sys.exit(1)

print(f"Written {len(annot_lines)} annotation lines to {dst_path}")

# Post-process to make the ilang compatible with MaskVerif:
#
# 1. Replace '/' with '_' throughout the file.
#    Yosys embeds full source file paths in auto-generated cell/wire names.
#    MaskVerif's lexer does not accept '/' in identifiers.
#
# 2. Strip parameter values from module-level parameter declarations.
#    MaskVerif's grammar only accepts "parameter \Name" (no value).
import re

with open(dst_path) as f:
    content = f.read()

content = content.replace('/', '_')
content = re.sub(r'(\bparameter\s+\\\S+)\s+\S+', r'\1', content)

with open(dst_path, "w") as f:
    f.write(content)

print("Post-processing done ('/' sanitised, parameter values stripped).")
PYEOF

# Sequential abstraction: promote DFF Q wires to module-level inputs and remove
# DFF cells.  MaskVerif analyses circuits as DAGs; DFF feedback creates cycles
# that break the topological sort (assertion at ilang.ml:505).  Treating DFF Q
# outputs as primary inputs (free variables from the previous cycle) breaks the
# cycle and is the standard single-cycle abstraction used with MaskVerif.
python3 - "$DST" <<'PYEOF2'
import sys, re

path = sys.argv[1]
with open(path) as f:
    content = f.read()

# Match a complete DFF cell block:
#   "  cell $_DFF...\n" followed by lines with 4-space indent, then "  end\n"
cell_re = re.compile(r'  cell \$_DFF\S[^\n]*\n(?:    [^\n]*\n)*  end\n')

# Collect Q wire names from all DFF cell blocks.
# Two wire-name formats can appear in Yosys RTLIL:
#   \name        – backslash-prefixed (normal signal names)
#   $abc$...$nXX[K] – dollar-prefixed ABC internal wires, [K] is part of the name
dff_q_wires = set()
for m in cell_re.finditer(content):
    q_m = re.search(r'    connect \\Q ([\\$]\S*)', m.group(0))
    if q_m:
        dff_q_wires.add(q_m.group(1))

# Promote each DFF Q wire to a primary input so MaskVerif treats it as a Vwire.
# Two declaration formats:
#   "wire width N \name"  – backslash-prefixed with explicit width
#   "wire $name"          – dollar-prefixed, always 1-bit, no width keyword
promoted = 0
for q_wire in sorted(dff_q_wires):
    if q_wire.startswith('\\'):
        # Backslash-prefixed: "wire width N \name" → "wire input N \name"
        pat = re.compile(r'(  wire )width( \d+ ' + re.escape(q_wire) + r')')
        content, n = re.subn(pat, r'\1input\2', content)
    else:
        # Dollar-prefixed: bare "wire $name" → "wire input 1 $name"
        pat = re.compile(r'^(  wire )(' + re.escape(q_wire) + r')$',
                         re.MULTILINE)
        content, n = re.subn(pat, r'\1input 1 \2', content)
    promoted += n

# Remove all DFF cell blocks (they are replaced by the promoted input wires).
content, removed = cell_re.subn('', content)

with open(path, 'w') as f:
    f.write(content)

print(f"Sequential abstraction: {promoted} DFF Q wires promoted to inputs, "
      f"{removed} DFF cells removed.")
PYEOF2

# Bit-select expansion: MaskVerif only handles \wire [N] indexing for wires
# pre-registered through its annotation mechanism (e.g. share0_i, rand_i).
# All other wires referenced as \wire [N] in cell connect statements — wide
# register files from memory_map, intermediate storage, etc. — cause an
# "invalid index" parse error.  Fix: rename \wire [N] → \wire__BIT_N__ and
# replace the original wide wire declaration with per-bit 1-bit declarations.
python3 - "$DST" <<'PYEOF3'
import sys, re

path = sys.argv[1]
with open(path) as f:
    content = f.read()

bit_sel_pat = re.compile(r'(\\[\w.$]+) \[(\d+)\]')
wire_name_pat = re.compile(r'\\[\w.$]+')

# Collect ALL wire names referenced in annotation lines (with or without [N]).
# MaskVerif pre-registers annotated wires and handles their [N] bit-selects
# natively; module input/output ports are also handled natively via add_input.
# Expanding any of these would break annotation references.
annot_names = set()
for line in content.splitlines():
    if line.strip().startswith('##'):
        for m in wire_name_pat.finditer(line):
            annot_names.add(m.group(0))

# Collect (wire → set_of_bits) from non-annotation lines.
indexed = {}
for line in content.splitlines():
    if line.strip().startswith('##'):
        continue
    for m in bit_sel_pat.finditer(line):
        wname = m.group(1)
        if wname not in annot_names:
            indexed.setdefault(wname, set()).add(m.group(2))

if not indexed:
    print("Bit-select expansion: nothing to do.")
    sys.exit(0)

# For each wire: remove the original (wide) declaration, collect new 1-bit decls.
# Skip wires where the declaration is not found or is already 1-bit — those
# either don't exist (can't create orphaned Kother wires) or work natively.
new_decls = []
skip_wires = set()
for wname in sorted(indexed):
    bits = sorted(indexed[wname], key=int)
    # Yosys RTLIL format: "wire width W [input|output] N \name"
    # The input/output keyword appears after "width W", not at the start.
    pat = re.compile(
        r'^  wire\b[^\n]* ' + re.escape(wname) + r'\n',
        re.MULTILINE
    )
    m = pat.search(content)
    if not m:
        skip_wires.add(wname)
        continue
    width_m = re.search(r'(?:width|input|output) (\d+)', m.group(0))
    declared_width = int(width_m.group(1)) if width_m else 1
    if declared_width <= 1:
        skip_wires.add(wname)
        continue
    dm = re.search(r'\b(input|output)\b', m.group(0))
    attr_str = dm.group(1) + ' ' if dm else ''
    content = pat.sub('', content, count=1)
    prefix = attr_str if attr_str else 'width '
    for bit in bits:
        new_decls.append(f'  wire {prefix}1 {wname}__BIT_{bit}__')

for wname in skip_wires:
    del indexed[wname]

# Insert new 1-bit declarations just before the first existing wire declaration.
first_wire = content.find('\n  wire ')
if first_wire >= 0 and new_decls:
    content = (content[:first_wire + 1]
               + '\n'.join(new_decls) + '\n'
               + content[first_wire + 1:])

# Replace \wname [N] → \wname__BIT_N__ everywhere except annotation lines.
lines_out = []
for line in content.splitlines(keepends=True):
    if line.strip().startswith('##'):
        lines_out.append(line)
    else:
        def _sub(m, _idx=indexed):
            wname, bit = m.group(1), m.group(2)
            return f'{wname}__BIT_{bit}__' if wname in _idx else m.group(0)
        lines_out.append(bit_sel_pat.sub(_sub, line))

content = ''.join(lines_out)

with open(path, 'w') as f:
    f.write(content)

total = sum(len(v) for v in indexed.values())
print(f"Bit-select expansion: {len(indexed)} wide wire(s), {total} individual bits.")
PYEOF3

echo "Done. Annotated ilang: $DST"
