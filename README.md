# BYG Recursive Tokenizer

Experimental dataset-oriented tokenizer/compressor with BYG/BYGZ selection, ZIP fallback, diagnostics and benchmark guards.

This repository is the public source layout for BYG Recursive Tokenizer.

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
