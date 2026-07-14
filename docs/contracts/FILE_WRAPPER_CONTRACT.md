# BYG v4.6 File Wrapper Contract

## File wrapper API tests
The v4.6 diagnostics and debug dump mode add file-oriented helpers on top of the public byte-vector API in `include/byg/byg.hpp`.

Required helper names:
- `byg::read_file_bytes`
- `byg::write_file_bytes`
- `byg::compress_file`
- `byg::decompress_file`
- `byg::inspect_file`

## Wrapper semantics
The wrappers are deterministic convenience functions. They do not introduce a new container backend; they use the same public API stored_raw container path as `compress_bytes`, `decompress_bytes`, and `inspect_bytes`.

## Acceptance markers
The official guard compiles `tests/embed_api_file_wrapper.cpp`, runs large-file and empty-file wrapper roundtrips, checks missing-input failure behavior, validates CLI/API file-path roundtrip consistency, and writes `o\r\v46_file_wrapper_api_guard.txt`. The required smoke marker is `BYG_FILE_WRAPPER_SMOKE_OK`.
