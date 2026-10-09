import os, re, sys
CAL = os.path.expanduser('~/chipsalliance/chipsalliance/caliptra-rtl')
OT  = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
def rev(s):
    s = re.sub(r'`CALIPTRA_PRIM_MODULE_NAME\((\w+)\)', r'prim_\1', s)
    s = re.sub(r'^\s*`include "caliptra_prim_module_name_macros.svh"\s*\n', '', s, flags=re.M)
    s = re.sub(r'\bcaliptra_prim_generic_', 'prim_', s)
    s = re.sub(r'\bu_caliptra_prim_', 'u_prim_', s)
    s = re.sub(r'\bcaliptra_prim_', 'prim_', s)
    s = s.replace('`CALIPTRA_', '`')
    s = re.sub(r'\bCALIPTRA_INC_ASSERT\b', 'INC_ASSERT', s)
    return s
def put(src, dst):
    open(dst, 'w').write(rev(open(src).read()))
log = []
# prims
skip = {'prim_assert.sv','prim_assert_dummy_macros.svh','prim_assert_standard_macros.svh',
        'prim_assert_yosys_macros.svh','prim_assert_sec_cm.svh','prim_flop_macros.sv',
        'prim_module_name_macros.svh','prim_pkg.sv'}
for f in sorted(os.listdir(f'{CAL}/src/caliptra_prim/rtl')):
    o = f.replace('caliptra_prim_', 'prim_', 1)
    if o in skip or not f.startswith('caliptra_prim_'): log.append(f'skip prim {f}'); continue
    dst = f'{OT}/hw/ip/prim/rtl/{o}'
    if os.path.exists(dst): put(f'{CAL}/src/caliptra_prim/rtl/{f}', dst); log.append(f'prim {o}')
    else: log.append(f'skip prim {f} (no OT counterpart / wrapper)')
for f in sorted(os.listdir(f'{CAL}/src/caliptra_prim_generic/rtl')):
    o = f.replace('caliptra_prim_generic_', 'prim_', 1)
    dst = f'{OT}/hw/ip/prim_generic/rtl/{o}'
    if os.path.exists(dst): put(f'{CAL}/src/caliptra_prim_generic/rtl/{f}', dst); log.append(f'generic {o}')
    else: log.append(f'skip generic {f}')
# SHA3 (es-update uses src/kmac)
for f in ['sha3_pkg.sv','sha3.sv','sha3pad.sv','keccak_round.sv','keccak_2share.sv']:
    put(f'{CAL}/src/kmac/rtl/{f}', f'{OT}/hw/ip/kmac/rtl/{f}'); log.append(f'sha3 {f}')
# entropy_src RTL (except AHB top and reg_top/reg_pkg, which are regenerated as TL-UL)
for f in sorted(os.listdir(f'{CAL}/src/entropy_src/rtl')):
    if f in ('entropy_src.sv','entropy_src_reg_top.sv','entropy_src_reg_pkg.sv'): continue
    put(f'{CAL}/src/entropy_src/rtl/{f}', f'{OT}/hw/ip/entropy_src/rtl/{f}'); log.append(f'es {f}')
# hjson
open(f'{OT}/hw/ip/entropy_src/data/entropy_src.hjson','w').write(open(f'{CAL}/src/entropy_src/data/entropy_src.hjson').read())
log.append('es hjson')
print('\n'.join(log))
