"""Run the Lua 5.1 regression suite without installing anything into WoW.

Usage: python tests/run_lua.py [--lua-dll PATH_TO_LUA_5_1_LIBRARY]
On this workstation the existing OBS Studio Lua 5.1 library is used read-only.
"""
import argparse
import ctypes
import ctypes.util
import os
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("--lua-dll", default=os.environ.get("GEARTAGS_LUA_DLL"))
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
library = args.lua_dll
if not library:
    candidate = Path(r"C:\Program Files\obs-studio\bin\64bit\lua51.dll")
    library = str(candidate) if candidate.exists() else ctypes.util.find_library("lua5.1")
if not library:
    raise SystemExit("A Lua 5.1 library is required. Pass --lua-dll PATH.")

if os.name == "nt":
    dll_directory = os.add_dll_directory(str(Path(library).resolve().parent))
lua = ctypes.CDLL(library)
lua.luaL_newstate.restype = ctypes.c_void_p
lua.luaL_openlibs.argtypes = [ctypes.c_void_p]
lua.luaL_loadfile.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
lua.luaL_loadfile.restype = ctypes.c_int
lua.lua_pcall.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int]
lua.lua_pcall.restype = ctypes.c_int
lua.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.POINTER(ctypes.c_size_t)]
lua.lua_tolstring.restype = ctypes.c_char_p
lua.lua_settop.argtypes = [ctypes.c_void_p, ctypes.c_int]
lua.lua_close.argtypes = [ctypes.c_void_p]
state = lua.luaL_newstate()
if not state:
    raise SystemExit("Could not create Lua state")
lua.luaL_openlibs(state)
os.chdir(root)

def fail(context):
    message = lua.lua_tolstring(state, -1, None)
    raise RuntimeError(f"{context}: {message.decode('utf-8', errors='replace') if message else 'unknown Lua error'}")

try:
    files = sorted(root.rglob("*.lua"))
    for file in files:
        if lua.luaL_loadfile(state, str(file.relative_to(root)).replace("\\", "/").encode()):
            fail(f"Syntax check {file.name}")
        lua.lua_settop(state, 0)
    print(f"Lua 5.1 syntax: {len(files)} files OK", flush=True)
    if lua.luaL_loadfile(state, b"tests/spec.lua"):
        fail("Load tests")
    if lua.lua_pcall(state, 0, 0, 0):
        fail("Test suite")
finally:
    lua.lua_close(state)
