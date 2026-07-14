
# v4.6.1 Dataset Smoke String Escape Hotfix

This hotfix fixes a PowerShell parser ambiguity in the dataset benchmark smoke generator by escaping the loop-variable interpolation before a colon. Codec behavior, public API, diagnostic JSON schema, error schema, and container magic are unchanged.

# v4.6 Diagnostics and Debug Dump Mode

v4.6 adds file-wrapper API smoke coverage on top of the v4.3 negative API and error contract layer. The new file-wrapper guard validates large payload, empty file, missing-input, and CLI/API file-path consistency behavior while preserving all existing release gates.

# v4.6 Negative API and Error Contract Tests

v4.6 adds negative public API and CLI JSON error contract coverage while preserving all v4.2 reproducible build metadata and release candidate acceptance gates. The new report is `o\r\v46_api_negative_error_contract.txt`.

# v4.6 Deterministic Reproducible Build Metadata

v4.6 adds reproducible build metadata on top of the v4.1 packaging install and CMake-lite release line. The new `BUILD_REPRODUCIBILITY.json` records source file hashes and release metadata, and the official test suite writes `o\r\v46_build_reproducibility.txt`.

The codec behavior, public C++ API, CLI JSON schema, packaging layout, compatibility policy, and regression acceptance gates remain under the same official harness coverage.


# v4.6.1 Packaging Stage CLI Dir Hotfix

This hotfix creates the `o\cli` report directory before packaging install guard writes staged CLI output files. Codec behavior, public API, JSON schema, and container magic are unchanged.

# v4.6 Packaging Install and CMake Lite

v4.6 adds packaging/install readiness on top of the v4.0 stable release candidate line. The codec, public header, CLI JSON schema, deterministic old-magic rejection policy, and regression acceptance gates remain under the same official harness coverage.

New artifacts:
- `CMakeLists.txt`
- `INSTALL_LAYOUT.md`
- `o\r\v46_packaging_install_guard.txt`

The packaging guard stages `bin/byg.exe`, `include/byg/byg.hpp`, and share metadata, then validates a staged header consumer build with g++.

# v4.6 Packaging Install and CMake Lite

v4.6 is the stable release candidate for the current BYG Recursive Tokenizer C++ prototype line. It freezes the public C++ header surface and the existing CLI JSON schema while preserving all v3.9 guards.

New in this package:
- `RELEASE_CANDIDATE_CHECKLIST.md`
- `release_candidate_checklist_guard`
- `o\r\v46_release_candidate_checklist.txt`

The RC acceptance gates require documentation guard, manifest audit, release candidate checklist guard, CLI JSON schema guard, library API embedding guard, cross-version compatibility guard, container corruption tests, large-file memory guard, CLI negative tests, regression baseline guard, normal ZIP dependency mode, and forced no-ZIP portability mode to pass.

# v4.6 Packaging Install and CMake Lite

v4.6 adds a small public C++ embedding header while preserving the v3.8 CLI JSON schema behavior and all v3.7/v3.6 guard layers.

New files:
- `include/byg/byg.hpp`
- `tests/embed_api_smoke.cpp`

New official report:
- `o\r\v46_library_api_guard.txt`

The public header is intentionally small and suitable for host-side smoke integration: `compress_bytes`, `decompress_bytes`, `inspect_bytes`, `version`, and `format_magic`.

# v4.6 Packaging Install and CMake Lite

v4.6 adds an explicit cross-version compatibility and migration-policy layer.

The release includes `COMPATIBILITY_MATRIX.json` and the official test suite writes `o\r\v46_cross_version_compatibility.txt`.

Current behavior:
- Current `BYG46DB` containers inspect/extract/roundtrip normally.
- Older magic samples (`BYG36MA`, `BYG352G`, `BYG34FC`, `BYG301C`) are rejected deterministically with `ERROR: bad magic`.
- This avoids accidental silent misparse until an explicit migration reader is implemented.

Preserved guards:
- release manifest audit
- large-file and memory guard
- container fuzz/corruption tests
- CLI negative tests
- ratio reporting
- regression baseline
- normal ZIP dependency mode
- forced no-ZIP portability mode


## v4.6 Packaging Install and CMake Lite
Adds a stable `byg.inspect.v1` JSON output contract for automation and Bridge parsing. Existing v3.7 compatibility and migration guards are preserved.

## v4.6.1 Doc Format Guard Hotfix

This package is a documentation-guard hotfix for the v4.6 artifact. It adds the exact `Cross-version compatibility guard` wording to FORMAT.md. Codec behavior, `BYG46DB` magic, and JSON schema behavior are unchanged.

## v4.6 Diagnostics and Debug Dump Mode

This release adds diagnostic dump mode and extra dataset benchmark smoke coverage while preserving the v4.4
file wrapper API, v4.3 error contract, v4.2 reproducibility metadata and all roundtrip/fallback guards.


## v4.6.2-winps-processstartinfo-hotfix

- Hotfix only: replaced the v4.6 diagnostic error JSON capture helper's ProcessStartInfo.ArgumentList usage with quoted .Arguments for Windows PowerShell 5.1 compatibility.
- Codec behavior, public API, container magic BYG46DB, and v4.6 diagnostic schemas are unchanged.


## v4.6 Real Dataset Benchmark Suite

This release adds a larger AI/dataset-focused benchmark suite with JSONL, CSV, prompt archive and entropy-control samples. It records ratio, timing, backend, payload submode, decision reason and diagnose metadata while preserving all v4.5 diagnostics and debug dump guards.
