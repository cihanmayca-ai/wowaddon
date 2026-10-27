# GearTags tests

From the repository root, run `lua5.1 tests/spec.lua` with Lua 5.1, or run
`python tests/run_lua.py --lua-dll "path/to/lua51.dll"` with an existing Lua 5.1 library.

The suite currently contains 50 automated checks and an explicit WoW API/UI mock.
It does not replace in-game rendering, taint, or third-party addon compatibility tests.

See [DEVELOPMENT.md](../DEVELOPMENT.md) for the test scope and implementation notes.
