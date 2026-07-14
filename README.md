# BYG Recursive Tokenizer

Experimental dataset-oriented tokenizer/compressor with BYG/BYGZ selection, ZIP fallback, diagnostics and benchmark guards.

BYG Recursive Tokenizer is designed for dataset-like text and structured corpora where repeated patterns, stable schemas, telemetry-like rows and prompt archives appear often.

## What it optimizes for

- Dataset shards, eval files, prompt archives and telemetry-like text.
- Safe backend selection between BYG/BYGZ, ZIP fallback and raw storage.
- Diagnostics, reproducibility metadata and API/file-wrapper contract tests.
- Practical compression behavior instead of forcing one algorithm onto every file.

## Performance profile

The ranges below are practical expectations by category. They are not universal guarantees. Lower selected/raw ratio is better.

| Data category | Expected selected/raw range | Typical behavior | Notes |
|---|---:|---|---|
| Repetitive telemetry or CSV | 0.7% - 5% | Strong win | Best case for repeated columns, recurring values and stable row shape. |
| Structured JSONL conversations | 2% - 6% | Strong compression | Works well when message/schema patterns repeat across rows. |
| Eval JSONL / instruction data | 3% - 8% | Strong compression | Usually close to or slightly better than ZIP fallback depending on diversity. |
| Prompt archive / plain text | 2% - 8% | Strong compression | Repeated phrasing and section headers help a lot. |
| Mixed real dataset bundle | 13% - 15% | Stable overall | Average depends heavily on whether high-entropy samples are included. |
| Source/docs package | 15% - 45% | Good general compression | Text-heavy source trees compress well, but small-file overhead can matter. |
| Small files / metadata-heavy input | 90% - 110% | Overhead can dominate | Very small files may not benefit much. |
| High-entropy binary/random data | about 100% | Stored safely | BYG should avoid pretending random data compresses. |

## Benchmark snapshot

Observed v4.6 real dataset benchmark suite results:

| Sample | Raw size | BYG selected size | BYG/raw | ZIP/raw | BYG vs ZIP |
|---|---:|---:|---:|---:|---:|
| conversation_1mb.jsonl | 1,048,588 | 21,574 | 2.06% | 2.06% | -0.01% |
| eval_1mb.jsonl | 1,048,770 | 50,012 | 4.77% | 4.77% | +0.03% |
| telemetry_1mb.csv | 1,048,637 | 7,426 | 0.71% | 4.68% | -84.88% |
| prompt_archive_1mb.txt | 1,048,780 | 26,735 | 2.55% | 2.55% | -0.01% |
| entropy_control_512kb.bin | 524,288 | 524,308 | 100.00% | 100.06% | -0.05% |

Suite total:

| Metric | Value |
|---|---:|
| Total raw size | 4,719,063 bytes |
| Total BYG selected size | 630,055 bytes |
| Total ZIP size | 672,014 bytes |
| BYG selected/raw | 13.35% |
| ZIP/raw | 14.24% |
| BYG vs ZIP delta | -6.24% |

Interpretation:

- On telemetry-like CSV data, BYG can outperform ordinary ZIP-style baselines by a large margin.
- On JSONL and prompt archives, BYG is usually close to ZIP fallback and can still select the safer/smaller representation.
- On high-entropy input, BYG stores safely instead of forcing fake compression.
- The selector is the important part: different corpora get different backend/submode decisions.

## Quick start

Build with g++:

    g++ -std=c++17 -O2 -Wall -Wextra -pedantic src/byg.cpp -o byg

On Windows with g++:

    g++ -std=c++17 -O2 -Wall -Wextra -pedantic src/byg.cpp -o bin/byg.exe

## Repository layout

    src/                 C++ CLI/source implementation
    include/byg/         Embeddable public header
    tests/               Embedding/API smoke and negative tests
    scripts/             Build and regression scripts
    docs/                Format, benchmark, release and contract documents

## Important docs

- docs/QUICKSTART.md
- docs/FORMAT.md
- docs/INDEX.md
- docs/benchmarks/DATASET_BENCHMARK_SUITE.md
- docs/contracts/FILE_WRAPPER_CONTRACT.md
- docs/release/RELEASE_NOTES.md

## Public release

Public repository release: v1.0.1

Internal engine line:
v4.6-real-dataset-benchmark-suite

Magic:
BYG46DB

## Notes

v1.0.1 is a repository layout cleanup release. It keeps the source line intact while making the public GitHub view cleaner.
