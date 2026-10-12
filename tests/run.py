"""Run all addon files and behavioral tests in Lua 5.1. Requires lupa.

python tests/run.py [--deps path/to/local/python-packages]
"""
from pathlib import Path
import sys
if '--deps' in sys.argv:
    sys.path.insert(0, sys.argv[sys.argv.index('--deps')+1])
from lupa.lua51 import LuaRuntime
root = Path(__file__).resolve().parents[1]
lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute((root / 'tests/mock.lua').read_text(encoding='utf-8'))
namespace = lua.table()
lua.globals().F = namespace
files = [p.strip() for p in (root/'Fishcraft.toc').read_text().splitlines() if p.strip() and not p.startswith('#')]
for p in files:
    path = root / p.replace('\\','/')
    source = path.read_text(encoding='utf-8')
    fn = lua.eval('function(code, name) local fn, err = loadstring(code, name); assert(fn, err); return fn end')(source, '@'+p)
    fn('Fishcraft', namespace)
print(f'PASS: Lua 5.1 syntax and TOC load order ({len(files)} files)')
lua.execute((root / 'tests/spec.lua').read_text(encoding='utf-8'))
print('All local tests passed. WoW secure execution and rendering still require client testing.')
