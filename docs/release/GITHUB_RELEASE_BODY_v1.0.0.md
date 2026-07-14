# BYG Recursive Tokenizer v1.0.0

First public release of BYG Recursive Tokenizer, based on internal engine v4.6.2.

This release focuses on dataset-oriented compression/tokenization for structured and repetitive data such as AI datasets, JSONL conversations, CSV telemetry, logs, prompt archives, and evaluation corpora.

## Internal build

- Engine: `v4.6-real-dataset-benchmark-suite`
- Hotfix package: `v4.6.2-dataset-suite-zip-size-hotfix`
- Format magic: `BYG46DB`
- Compiler target: C++17 / g++

## Core features

- BYG/BYGZ selector
- ZIP fallback path
- stored_raw path for entropy/random data
- forced no-ZIP portability mode
- inspect JSON mode
- diagnose JSON/text debug dump mode
- public C++ header API
- file wrapper API
- corruption/fuzz checks
- regression baseline guard
- reproducible build metadata
- real dataset benchmark suite

## Validation summary

- Build: OK
- Documentation guard: OK
- Release manifest audit: OK
- Build reproducibility guard: OK
- Release candidate checklist guard: OK
- Packaging install guard: OK
- CLI negative tests: OK
- CLI JSON schema guard: OK
- Diagnostic dump guard: OK
- Dataset benchmark smoke guard: OK
- Real dataset benchmark suite guard: OK
- API negative/error contract guard: OK
- File wrapper API guard: OK
- Library API embedding guard: OK
- Cross-version compatibility guard: OK
- Container fuzz/corruption tests: OK
- Large-file and memory guard: OK
- Regression baseline guard: OK
- Normal mode roundtrip: 44/44
- Forced no-ZIP roundtrip: 44/44

## Real dataset benchmark suite

- Samples: 5
- Total raw size: 4,719,063 bytes
- Total BYG selected size: 630,055 bytes
- Total ZIP size: 672,014 bytes
- BYG selected/raw ratio: 0.133513
- ZIP/raw ratio: 0.142404
- BYG vs ZIP total delta: -6.24%

Dataset breakdown:

- `conversation_1mb.jsonl`: BYG 21,574 bytes, ZIP 21,576 bytes, delta -0.01%
- `eval_1mb.jsonl`: BYG 50,012 bytes, ZIP 49,998 bytes, delta +0.03%
- `telemetry_1mb.csv`: BYG 7,426 bytes, ZIP 49,107 bytes, delta -84.88%
- `prompt_archive_1mb.txt`: BYG 26,735 bytes, ZIP 26,737 bytes, delta -0.01%
- `entropy_control_512kb.bin`: BYG 524,308 bytes, ZIP 524,596 bytes, delta -0.05%

## Important note

BYG Recursive Tokenizer is not a universal replacement for ZIP, 7z, zstd, or Brotli. It is best treated as an experimental dataset-oriented container/tokenizer compressor. It performs best on structured and repetitive data, while safely falling back or storing raw data when needed.
