# Quick start

## Build with g++ on Windows

```powershell
New-Item -ItemType Directory -Force bin | Out-Null
g++ -std=c++17 -O2 -Wall -Wextra -pedantic src/byg.cpp -o bin/byg.exe
.\bin\byg.exe --version
```

## Compress / extract

```powershell
.\bin\byg.exe compress input.jsonl output.byg
.\bin\byg.exe extract output.byg restored.jsonl
.\bin\byg.exe inspect output.byg --json
.\bin\byg.exe diagnose output.byg --json
```

## Full tests

```powershell
powershell -ExecutionPolicy Bypass -File .\run_tests.ps1
```
