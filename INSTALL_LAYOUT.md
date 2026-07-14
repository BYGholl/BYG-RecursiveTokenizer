# BYG v4.6 Install Layout

Packaging install and CMake lite defines a minimal installable layout without making CMake a runtime dependency for the codec.

Expected staged layout:

```text
bin/byg.exe
include/byg/byg.hpp
share/byg/CLI_JSON_SCHEMA.json
share/byg/COMPATIBILITY_MATRIX.json
share/byg/RELEASE_MANIFEST.json
share/byg/RELEASE_CANDIDATE_CHECKLIST.md
share/byg/INSTALL_LAYOUT.md
```

The packaging install guard copies `bin/byg.exe`, `include/byg/byg.hpp`, and share metadata into `o/package_stage`, compiles an embedding smoke test against the staged `include` path, runs the staged CLI `--version`, and writes `o\r\v46_packaging_install_guard.txt`.

CMake lite markers:
- CMakeLists.txt
- install(TARGETS byg RUNTIME DESTINATION bin)
- install(DIRECTORY include/ DESTINATION include)
- target_compile_features(byg PRIVATE cxx_std_17)
- target_include_directories(byg_header INTERFACE)
