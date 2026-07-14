BYG Recursive Tokenizer

**BYG Recursive Tokenizer v1.0.0** is an experimental dataset-oriented tokenizer/compressor for structured and repetitive data such as AI datasets, JSONL conversations, CSV telemetry, logs, prompt archives, and evaluation corpora.

This public v1.0.0 release is based on the internal engine package:

- Internal engine: `v4.6-real-dataset-benchmark-suite`
- Hotfix package: `v4.6.2-dataset-suite-zip-size-hotfix`
- Format magic: `BYG46DB`
- Language: C++17
- Primary compiler: `g++`

> BYG Recursive Tokenizer is **not** intended to replace ZIP/7z/zstd/Brotli for every file type. It is best treated as an experimental dataset-oriented container/tokenizer compressor with safe fallback behavior.

## What it does

The tool selects a storage path per input:

- **BYGZ template/token path** when structure is detected.
- **BYG fallback/LZ path** when that is better than ZIP.
- **ZIP payload fallback** when ZIP wins.
- **stored_raw** when data is high entropy, already compressed, or too small to safely compress.

The goal is not to blindly compress everything. The goal is to make the decision visible, reproducible, and safe.

## Good use cases

- AI training/evaluation datasets
- JSONL conversation datasets
- prompt/response archives
- CSV telemetry and metrics
- logs and repeated structured text
- benchmark snapshots
- local experiment archives

## Poor use cases

- video, image, audio, archives, and already-compressed files
- encrypted/high-entropy blobs where compression is not expected
- replacing mature general-purpose compressors in production without independent testing

## v1.0.0 benchmark summary

Real dataset benchmark suite from the v1.0.0 release candidate:

| Dataset | Raw bytes | BYG selected | ZIP | BYG vs ZIP |
|---|---:|---:|---:|---:|
| `conversation_1mb.jsonl` | 1,048,588 | 21,574 | 21,576 | -0.01% |
| `eval_1mb.jsonl` | 1,048,770 | 50,012 | 49,998 | +0.03% |
| `telemetry_1mb.csv` | 1,048,637 | 7,426 | 49,107 | -84.88% |
| `prompt_archive_1mb.txt` | 1,048,780 | 26,735 | 26,737 | -0.01% |
| `entropy_control_512kb.bin` | 524,288 | 524,308 | 524,596 | -0.05% |

Total benchmark:

- Total raw size: `4,719,063` bytes
- Total BYG selected size: `630,055` bytes
- Total ZIP size: `672,014` bytes
- BYG selected/raw ratio: `0.133513`
- ZIP/raw ratio: `0.142404`
- BYG vs ZIP total delta: `-6.24%`

Interpretation: BYG is close to ZIP on JSONL/prompt text, much better on the telemetry CSV sample, and safely stores high-entropy data.

## Validated guards

The internal v4.6.2 package passed the following checks:

- g++ build
- documentation guard
- release manifest audit
- build reproducibility guard
- release candidate checklist guard
- packaging/install guard
- CLI negative tests
- CLI JSON schema guard
- diagnostic dump guard
- dataset benchmark smoke guard
- real dataset benchmark suite guard
- API negative/error contract guard
- file wrapper API guard
- library API embedding guard
- cross-version compatibility guard
- container fuzz/corruption tests
- large-file and memory guard
- regression baseline guard
- normal roundtrip: `44/44`
- forced no-ZIP roundtrip: `44/44`

## Build with g++

From the repository root:

```powershell
New-Item -ItemType Directory -Force bin | Out-Null
g++ -std=c++17 -O2 -Wall -Wextra -pedantic src/byg.cpp -o bin/byg.exe
.\bin\byg.exe --version
```

On Linux/macOS-like shells:

```bash
mkdir -p bin
g++ -std=c++17 -O2 -Wall -Wextra -pedantic src/byg.cpp -o bin/byg
./bin/byg --version
```

Expected version string:

```text
BYG Recursive Tokenizer C++ v4.6-real-dataset-benchmark-suite
```

## Basic CLI usage

```powershell
# Compress
.\bin\byg.exe compress input.jsonl output.byg

# Extract
.\bin\byg.exe extract output.byg restored.jsonl

# Inspect machine-readable metadata
.\bin\byg.exe inspect output.byg --json

# Diagnose container/debug details
.\bin\byg.exe diagnose output.byg --json

# Run benchmark report
.\bin\byg.exe benchmark input.jsonl report.txt
```

## Run the full validation suite

Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\run_tests.ps1
```

The suite generates reports under `o\r\` and temporary binaries under `bin\`.

## Public C++ API

Header:

```cpp
#include "include/byg/byg.hpp"
```

Useful API functions include:

- `byg::version()`
- `byg::format_magic()`
- `byg::compress_bytes()`
- `byg::decompress_bytes()`
- `byg::inspect_bytes()`
- `byg::read_file_bytes()`
- `byg::write_file_bytes()`
- `byg::compress_file()`
- `byg::decompress_file()`
- `byg::inspect_file()`

See `tests/embed_api_smoke.cpp`, `tests/embed_api_negative.cpp`, and `tests/embed_api_file_wrapper.cpp` for examples.

## Repository notes

Generated files are intentionally ignored:

- `bin/`
- `o/`
- `build/`
- `dist/`
- `*.byg`
- `*.zip`

## Status

This is a first public release. The format is experimental and may change before long-term stable compatibility is promised.
