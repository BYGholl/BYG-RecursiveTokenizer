
## v4.6.1-dataset-smoke-string-escape-hotfix
- Hotfix: dataset benchmark smoke PowerShell JSON string now uses `${i}:` to avoid `$i:` parser ambiguity.
- No codec, container, public API, JSON schema, diagnostic schema, or magic change.
- Version and magic remain `v4.6-real-dataset-benchmark-suite` / `BYG46DB`.

## v4.6-real-dataset-benchmark-suite
- Added public API file-wrapper helpers and file wrapper smoke coverage.
- Added `FILE_WRAPPER_CONTRACT.md` and `tests/embed_api_file_wrapper.cpp`.
- Added official report target `o\r\v46_file_wrapper_api_guard.txt`.
- Current container magic is `BYG46DB`.
- Preserved v4.3 API negative/error contract guard, v4.2 reproducibility guard, v4.1 packaging guard, and all codec regression gates.

## v4.6-real-dataset-benchmark-suite
- Added public API negative tests for corrupt byte-vector inputs.
- Added CLI JSON error contract guard for inspect --json failure output.
- Added API_ERROR_CONTRACT.json and tests/embed_api_negative.cpp.
- Preserved v4.2 reproducible build metadata, v4.1 packaging, v4.0 RC, JSON schema, compatibility, corruption, large-file, ratio and forced no-ZIP guards.

## v4.6-real-dataset-benchmark-suite
- Added deterministic reproducible build metadata via `BUILD_REPRODUCIBILITY.json`.
- Added source hash guard and `o\r\v46_build_reproducibility.txt` report target.
- Current container magic is `BYG46DB`.
- Preserved v4.1 packaging install guard, v4.0 release candidate checklist, v3.9 public header guard, CLI JSON schema guard, compatibility guard, manifest audit, large-file guard, corruption tests, ratio reporting, and forced no-ZIP portability validation.


## v4.6.1-packaging-stage-cli-dir-hotfix

- Hotfix: packaging install guard now creates `o\cli` before writing staged CLI smoke outputs.
- No codec, container, JSON schema, public API, or magic change.
- Version and magic remain `v4.6-real-dataset-benchmark-suite` / `BYG46DB`.

## v4.6-real-dataset-benchmark-suite
- Added minimal `CMakeLists.txt` for packagers.
- Added `INSTALL_LAYOUT.md` documenting `bin/`, `include/`, and `share/byg` staged layout.
- Added packaging install guard and `o\r\v46_packaging_install_guard.txt` report target.
- Preserved v4.0 release candidate checklist, public header guard, CLI JSON schema guard, compatibility matrix, manifest audit, large-file guard, corruption tests, regression baseline, normal mode, and forced no-ZIP portability mode.
- Current container magic is `BYG46DB`.

## v4.6-real-dataset-benchmark-suite
- Promoted the v3.x feature set to a v4.6 packaging release.
- Added `RELEASE_CANDIDATE_CHECKLIST.md`.
- Added the `release_candidate_checklist_guard` acceptance layer.
- Added `o\r\v46_release_candidate_checklist.txt` report target.
- Kept public header API, CLI JSON schema, manifest audit, compatibility matrix, large-file guard, corruption tests, ratio reports, regression baseline, normal ZIP mode, and forced no-ZIP mode under official coverage.
- Current container magic is `BYG46DB`.

## v4.6-real-dataset-benchmark-suite

- Added public C++ header `include/byg/byg.hpp` for embedding smoke tests.
- Added minimal API functions: `compress_bytes`, `decompress_bytes`, `inspect_bytes`, `version`, and `format_magic`.
- Added `tests/embed_api_smoke.cpp` and official `library_api_embedding_guard`.
- Added `o\r\v46_library_api_guard.txt` report target.
- Preserved CLI JSON schema guard, cross-version compatibility, release manifest audit, large-file guard, corruption guard, CLI negative tests, ratio reporting, and regression baseline guard.

## v4.6.1-doc-format-guard-hotfix

- Packaging/doc hotfix only.
- Added the exact `Cross-version compatibility guard` wording to FORMAT.md so the v4.6 documentation guard aligns with the existing cross-version test layer.
- Codec behavior, magic `BYG46DB`, CLI JSON schema, and official v4.6 acceptance targets are unchanged.

## v4.6-real-dataset-benchmark-suite

- Added `RELEASE_MANIFEST.json` with version, magic, source file, required file, guard, and report target metadata.
- Added release manifest audit to `run_tests.ps1`.
- Added `o\r\v46_manifest_audit.txt` report.
- Preserved v3.5.2 large-file guard, container corruption tests, CLI negative tests, ratio reporting, regression baseline, normal ZIP mode, and forced no-ZIP mode.

## v4.6-real-dataset-benchmark-suite

- Fixed the large-file guard deterministic byte generator on Windows PowerShell.
- The LCG now performs multiplication in UInt64 and masks to 32 bits before byte extraction.
- Preserves v3.5 large-file guard, container corruption tests, CLI negative tests, ratio reporting, regression baseline, normal ZIP mode, and forced no-ZIP mode.

## v4.6-real-dataset-benchmark-suite

- Added large-file and memory guard tests.
- Added normal + forced no-ZIP large roundtrip validation for four larger sample classes.
- Added `o\r\v46_large_file_memory_guard.txt` report.
- Preserved v3.4 container corruption tests, CLI negative tests, ratio reporting, and regression baseline guard.

# Changelog

## v4.6-real-dataset-benchmark-suite

- Added container fuzz and corruption tests.
- Hardened parser behavior for unknown backend bytes.
- Added `o\r\v46_container_corruption_tests.txt` report.
- Preserved CLI negative tests, ratio reporting, regression baseline, normal ZIP dependency mode and forced no-ZIP portability mode.
- Preserved v3.1 regression baseline guard.


- Fixes Windows PowerShell native stderr handling in CLI negative tests.
- `Invoke-CliCase` now uses `System.Diagnostics.ProcessStartInfo` to capture stdout, stderr, and exit code without converting expected native stderr into a terminating PowerShell error.
- Codec behavior unchanged from v3.3.x.

# CHANGELOG

## v4.6-real-dataset-benchmark-suite
- Expanded the official real/expanded corpus from 8 to 14 samples.
- Added Markdown docs, JSONL config bundle, TSV telemetry, medium random entropy, binary payload and tiny JSON cases.
- Updated normal and forced no-ZIP roundtrip expectations from 38/38 to 44/44.
- Added real corpus expansion documentation markers to README and FORMAT guards.
- Preserved v3.0.1 release-polish codec behavior, documentation guard, normal ZIP dependency validation and forced no-ZIP portability validation.

## v3.0.1-release-polish
- Polished the v3.0 release-candidate package without changing the validated codec behavior.
- Added README CLI examples aligned with CLI help.
- Expanded FORMAT.md with a byte-level container layout table.
- Added documentation guard checks to run_tests.ps1.
- Updated release metadata to BYG301C / v3.0.1-release-polish.
- Kept normal ZIP dependency validation and forced no-ZIP portability validation.

## v3.0-release-candidate-package
- Promoted v2.9.1 into release-candidate packaging.
- Added release-focused README and format notes.
- Kept dual-mode validation: normal ZIP dependency mode plus forced no-ZIP mode.

## v2.9.1-forced-no-zip-reason-hotfix
- Fixed forced no-ZIP inspect/CSV decision_reason reporting.

## v2.9-portability-fallback-validation
- Added forced no-ZIP validation mode.

## v2.8.1-warning-cleanup-and-dependency-check-wireup
- Wired dependency availability into actual decision path and removed compile warning.

## v2.8-native-zip-payload-cleanup-and-portability
- Added ZIP dependency and container payload flag metadata.

## v2.7-backend-transparency-and-decision-report
- Added payload submode and decision reason reporting.

## v2.6-fallback-max-overhead-reducer
- Added hybrid fallback_zip_payload to cap worst-case overhead.


## v4.6-real-dataset-benchmark-suite

- Added `--help`, `help`, `-h`, `--version`, `version`, and `-V`.
- Standardized unknown command output and exit code 2.
- Added CLI negative tests for usage errors, corrupt containers, and output path failures.
- Preserved v3.2 ratio reporting and regression baseline behavior.


## v4.6-real-dataset-benchmark-suite

- Fixed documentation guard marker drift in `run_tests.ps1`.
- FORMAT.md guard now checks the current `BYG46DB` magic instead of the older `BYG32RC` marker.
- Preserves v3.3 CLI usability / exit-code tests and v3.2 ratio/regression guards.


## v4.6-real-dataset-benchmark-suite
- Fixed PowerShell CLI negative-test harness argument splatting by replacing the ambiguous Args parameter with CliArgs.
- Codec behavior unchanged from v3.3.1.
- Documentation guard, regression baseline, normal mode, and forced no-ZIP mode are preserved.


## v4.6-real-dataset-benchmark-suite
- Added `inspect --json` machine-readable output.
- Added CLI JSON schema guard and CLI_JSON_SCHEMA.json.
- Preserved cross-version compatibility, manifest audit, large-file, corruption, CLI negative, ratio and baseline guards.

## v4.6-real-dataset-benchmark-suite

- Added CLI diagnostic dump mode: `diagnose <input.byg> [report] [--json]`.
- Added diagnostic JSON schema `byg.diagnose.v1`.
- Added `DIAGNOSTIC_CONTRACT.json`.
- Added dataset benchmark smoke guard for AI/dataset-like JSONL, CSV and text samples.
- Preserved v4.4 file-wrapper API guard and all previous guards.


## v4.6.2-winps-processstartinfo-hotfix

- Hotfix only: replaced the v4.6 diagnostic error JSON capture helper's ProcessStartInfo.ArgumentList usage with quoted .Arguments for Windows PowerShell 5.1 compatibility.
- Codec behavior, public API, container magic BYG46DB, and v4.6 diagnostic schemas are unchanged.
