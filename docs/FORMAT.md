# BYG v4.6 Diagnostics and Debug Dump Mode Container Notes

Magic: `BYG46DB` (7 bytes)

## v4.6 File wrapper API guard
The v4.6 file wrapper API guard compiles `tests/embed_api_file_wrapper.cpp`, validates public header file-wrapper helpers, checks large-file and empty-file wrapper roundtrips, verifies missing-input failure behavior, checks CLI/API file-path consistency, and writes `o\r\v46_file_wrapper_api_guard.txt`. The smoke marker is `BYG_FILE_WRAPPER_SMOKE_OK`.

## File wrapper semantics
The file wrappers are deterministic convenience functions over the byte-vector public API. They preserve the same container format and do not add a new backend.

# BYG v4.6 Negative API and Error Contract Tests Container Notes

Magic: `BYG46DB` (7 bytes)

## v4.6 API negative/error contract guard
The v4.6 API negative/error contract guard compiles `tests/embed_api_negative.cpp`, validates public header corrupt byte-vector failure paths, checks `API_ERROR_CONTRACT.json`, and verifies `inspect --json` error output schema `byg.error.v1`. The report is `o\r\v46_api_negative_error_contract.txt`.

## CLI JSON error contract
`inspect --json` on invalid containers returns exit code 1 and emits a machine-readable error object with schema `byg.error.v1`, command `inspect`, ok=false, error text, and exit_code=1. The legacy non-json CLI error path continues to write `ERROR:` diagnostics to stderr.

# BYG v4.6 Deterministic Reproducible Build Metadata Container Notes

Magic: `BYG46DB` (7 bytes)

## v4.6 Build reproducibility guard
The Build reproducibility guard validates `BUILD_REPRODUCIBILITY.json`, checks the recorded version and magic, recomputes SHA256 for guarded source files, and writes `o\r\v46_build_reproducibility.txt`.

## v4.6 Source hash guard
The Source hash guard covers `src/byg.cpp`, `include/byg/byg.hpp`, `run_tests.ps1`, `CMakeLists.txt`, and `RELEASE_MANIFEST.json`. The guard is intentionally metadata-only: codec behavior, public API, CLI JSON schema, and packaging layout remain unchanged except for the current version and magic markers.

# BYG v4.6 Packaging Install and CMake Lite Container Notes

Magic: `BYG46DB` (7 bytes)

## v4.6 Packaging install guard
The packaging install guard validates `CMakeLists.txt`, `INSTALL_LAYOUT.md`, the staged install layout, staged CLI execution, and embedding-header compilation from the staged `include` directory. The report is `o\r\v46_packaging_install_guard.txt`.

CMake lite requires `install(TARGETS byg RUNTIME DESTINATION bin)` and `install(DIRECTORY include/ DESTINATION include)` markers. The official test harness does not require a CMake executable; it validates the package layout and uses g++ for the consumer smoke compile.

# BYG v4.6 Packaging Install and CMake Lite Container Notes

Magic: `BYG46DB` (7 bytes)

## v4.6 Packaging Install and CMake Lite
The v4.6 packaging release keeps the current container reader policy, public C++ header API, CLI JSON schema, release manifest, compatibility matrix, and test reports under a frozen acceptance checklist.

## API/CLI schema frozen
Public API names in `include/byg/byg.hpp` and the existing `inspect --json` `byg.inspect.v1` fields are frozen for this release candidate. The Release candidate checklist guard validates `RELEASE_CANDIDATE_CHECKLIST.md` and writes `o\r\v46_release_candidate_checklist.txt`.

# BYG v4.6 Packaging Install and CMake Lite Container Notes

Magic: `BYG46DB` (7 bytes)

## v4.6 Packaging Install and CMake Lite
The public header `include/byg/byg.hpp` provides a small host-embedding API: `compress_bytes`, `decompress_bytes`, `inspect_bytes`, `version`, and `format_magic`. The library API embedding guard compiles `tests/embed_api_smoke.cpp`, verifies a byte-vector roundtrip, checks primitive inspection fields, and records `o\r\v46_library_api_guard.txt`.

## v4.6 CLI JSON schema guard
`inspect --json` continues to emit `byg.inspect.v1` with stable fields.

## Cross-version compatibility guard
The Cross-version compatibility guard validates the current `BYG46DB` container path and deterministic rejection for unsupported older magic values.

# BYG v4.6 Packaging Install and CMake Lite Container Notes

Magic: `BYG46DB` (7 bytes)

Byte-level container layout:

| Offset | Size | Field | Meaning |
|---:|---:|---|---|
| 0 | 7 | magic | ASCII `BYG46DB` |
| 7 | 1 | backend byte | Selected backend/submode discriminator |
| 8 | var | payload fields | Backend-specific compact payload |

Backend byte mapping:

| Backend byte | Public backend | Payload submode | Container payload flag |
|---:|---|---|---|
| `1` | BYGZ_TEMPLATE | `template_id_only` | `backend_byte_1_template_id_only` |
| `2` | BYG_STORED | `stored_raw` | `backend_byte_2_stored_raw` |
| `3` | ZIP_FALLBACK | `fallback_lz` | `backend_byte_3_fallback_lz` |
| `4` | ZIP_FALLBACK | `fallback_zip_payload` | `backend_byte_4_fallback_zip_payload` |

Real corpus expansion notes:
- v3.2 expands the real/expanded corpus from 8 samples to 14 samples.
- Added cases include Markdown documentation, JSONL config bundles, TSV telemetry, medium random entropy, binary payload edge case, and tiny JSON.
- These samples are not controlled templates; they are intended to exercise fallback and stored paths more realistically.
- The public backend remains intentionally coarse while inspect/select reports payload_submode and decision_reason.

Detailed behavior is reported through:
- `payload_submode`
- `decision_reason`
- `container_payload_flag`
- `zip_dependency`
- `zip_dependency_available`

ZIP payload portability:
- `fallback_zip_payload` requires the PowerShell Compress-Archive / Expand-Archive toolchain.
- If ZIP dependency is unavailable or forced off with `BYG_FORCE_NO_ZIP=1`, the compressor falls back to `fallback_lz`.
- In forced no-ZIP mode, `decision_reason=zip_dependency_unavailable_lz_fallback` is expected for fallback LZ containers.


## v3.2 Ratio metrics

Normal-mode CSV rows include derived ratio columns:

| Column | Meaning |
|---|---|
| `selected_raw_ratio` | `selected / raw`, rounded to 6 decimals. |
| `zip_raw_ratio` | `zip / raw`, rounded to 6 decimals. |
| `byg_vs_zip_delta_percent` | `((selected - zip) / zip) * 100`, rounded to 2 decimals. Negative means BYG is smaller than ZIP. |

## v3.2 Regression baseline

`REGRESSION_BASELINE_v3_1.json` captures the accepted v3.1 guard baseline. v3.2 must keep the expanded 44-sample roundtrip, 14 real corpus samples, selector consistency, transparent fallback max overhead cap, and no-ZIP portability guarantees.


## CLI exit-code contract

| Case | Exit code | Notes |
|---|---:|---|
| `--help`, `help`, `-h` | 0 | Prints command list. |
| `--version`, `version`, `-V` | 0 | Prints version line. |
| Successful command | 0 | Valid output produced. |
| Missing argument / unknown command | 2 | Usage-level error. |
| Invalid container / read-write failure | 1 | Runtime or IO failure. |


## v3.3.4 test harness note retained
The container format is unchanged beyond the current magic marker. CLI negative tests capture native stderr through ProcessStartInfo.


## v3.4 Container parser corruption guard

Current magic marker: BYG46DB.

The parser now rejects unknown backend bytes during container parsing instead of
allowing `inspect` to report an ambiguous UNKNOWN backend. v3.4 also validates
malformed containers through automated corruption cases:

- bad magic => parse failure
- unknown backend byte => parse failure
- invalid template id => extract failure
- stored payload truncated => parse failure
- fallback payload truncated => parse/decode failure
- stored payload checksum mutation => checksum mismatch

These checks are negative CLI/parser tests; success means the tool exits non-zero
with deterministic diagnostics and the harness continues.


## Cross-version compatibility guard

The Cross-version compatibility guard validates the current `BYG46DB` container path and the deterministic rejection policy for unsupported older magic values. Older magic samples such as `BYG36MA`, `BYG352G`, `BYG34FC`, and `BYG301C` must fail with explicit bad-magic diagnostics until a deliberate migration reader is implemented.

## v4.6 Large-file guard

Current magic marker: BYG46DB.

The v4.6 guard validates larger text, repeated-pattern, deterministic-entropy, and mixed-block inputs in both normal mode and forced no-ZIP mode. Forced no-ZIP large-file cases must not emit `fallback_zip_payload`; they must roundtrip through available non-ZIP paths. The dedicated report is `o\r\v46_large_file_memory_guard.txt`.

This prototype still reads whole files into memory. The guard is therefore a regression and memory-safety test surface, not a streaming API guarantee.


## v4.6 packaging install and CMake lite

The large-file guard deterministic byte generator now performs its LCG arithmetic in UInt64 and masks to 32 bits before byte extraction, avoiding Windows PowerShell UInt32 overflow during test data generation.


## v4.6 Library API guard

`RELEASE_MANIFEST.json` is the machine-readable release manifest for this artifact.
It records version `v4.6-real-dataset-benchmark-suite`, magic `BYG46DB`, required source/doc files,
expected guard list, and official report targets. `run_tests.ps1` audits this
manifest before running codec tests so release packaging drift is caught early.


## v4.6 Library API guard
The byte container magic is BYG46DB. `inspect --json` emits schema `byg.inspect.v1` with stable field names for automation: schema, version, format, selected_backend, payload_submode, decision_reason, zip_dependency, zip_dependency_available, container_payload_flag, template_id, original_size, checksum_fnv1a32, header_size, payload_size, container_size.

## v4.6 Diagnostic dump guard

Current magic: BYG46DB
Diagnostic command: `diagnose <input.byg> [report] [--json]`.
Diagnostic JSON schema: `byg.diagnose.v1`.
The diagnostic dump reports header/payload/checksum/backend decisions and uses `checksum_verify=OK` plus
`roundtrip_ok=true` for healthy containers. It is read-only and does not mutate the input container.

## v4.6 Dataset benchmark smoke guard

Dataset benchmark smoke guard validates JSONL/CSV/text-like AI dataset samples with compress/extract roundtrip,
`diagnose --json`, and benchmark report generation. Marker: `BYG_DATASET_BENCHMARK_SMOKE_OK`.


## v4.6 Real dataset benchmark suite guard

The v4.6 Real dataset benchmark suite guard generates AI/dataset-like 1 MB-class JSONL, CSV and prompt-archive samples plus an entropy-control binary sample. It verifies compress/extract roundtrip, diagnose JSON schema `byg.diagnose.v1`, selected/raw ratio, ZIP/raw ratio, BYG-vs-ZIP delta percent, backend, payload submode, decision reason and timing fields. Marker: `BYG_REAL_DATASET_BENCHMARK_SUITE_OK`.
