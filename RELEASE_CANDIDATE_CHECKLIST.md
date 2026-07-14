# v4.6 Packaging Install and CMake Lite Checklist

This package marks the v3.x feature line as a v4.6 packaging release.

## API schema frozen
- Public header path is frozen for this RC: `include/byg/byg.hpp`.
- Public API names are frozen for this RC: `byg::version`, `byg::format_magic`, `byg::compress_bytes`, `byg::decompress_bytes`, and `byg::inspect_bytes`.
- The library API embedding guard must compile `tests/embed_api_smoke.cpp` and produce `BYG_LIBRARY_API_SMOKE_OK`.

## CLI JSON schema frozen
- `inspect --json` keeps schema `byg.inspect.v1`.
- Existing JSON field names and primitive types are frozen for this RC.
- Additional fields may only be append-only after v4.6.

## Container format frozen
- Current magic is `BYG46DB`.
- Unsupported older magic values remain deterministically rejected until explicit migration readers are implemented.
- `COMPATIBILITY_MATRIX.json` documents the current compatibility policy.

## Release candidate acceptance gates
- Documentation guard must pass.
- Release manifest audit must pass.
- Release candidate checklist guard must pass.
- CLI JSON schema guard must pass.
- Library API embedding guard must pass.
- Cross-version compatibility guard must pass.
- Container corruption tests must pass.
- Large-file memory guard must pass.
- CLI negative tests must pass.
- Normal roundtrip must remain `44/44`.
- Forced no-ZIP roundtrip must remain `44/44`.
- Large-file extra roundtrip must remain `8/8`.
- Forced no-ZIP `fallback_zip_payload` count must remain `0`.
- Normal fallback max overhead must remain `<= 50`.
- Compile warnings must remain `0`.

Current post-RC diagnostic marker: BYG46DB
Diagnostic JSON schema frozen: byg.diagnose.v1
