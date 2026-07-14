$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -LiteralPath $scriptRoot

# v4.6 packaging-install-and-cmake-lite path guard: Bridge workspaces can become long or double-nested. If this
# project is started from a risky path, relocate the whole extracted project to
# a short TEMP path and run there exactly once. This does not change the source
# or test logic; it only avoids Windows child-process/path edge cases.
if (-not $env:BYG_V46_SHORTPATH_ACTIVE) {
    $cwdText = (Get-Location).Path
    $riskyPath = ($cwdText.Length -gt 150 -or $cwdText -match "BYG_Codex_Bridge_v1_90_3[6-9].*BYG_Codex_Bridge_v1_90_3[6-9]")
    if ($riskyPath) {
        $shortRoot = Join-Path $env:TEMP ("byg_v46_selfrun_" + (Get-Date -Format "HHmmss") + "_" + ([Guid]::NewGuid().ToString("N")).Substring(0,8))
        New-Item -ItemType Directory -Path $shortRoot -Force | Out-Null
        $dest = Join-Path $shortRoot (Split-Path -Leaf $scriptRoot)
        Copy-Item -LiteralPath $scriptRoot -Destination $dest -Recurse -Force
        Write-Host "v4.6 path guard: risky path detected ($($cwdText.Length) chars); rerunning from $dest"
        $env:BYG_V46_SHORTPATH_ACTIVE = "1"
        $psExe = Join-Path $PSHOME "powershell.exe"
        if (-not (Test-Path -LiteralPath $psExe)) { $psExe = "powershell.exe" }
        & $psExe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $dest "run_tests.ps1")
        exit $LASTEXITCODE
    }
}


Write-Host "BYG Recursive Tokenizer C++ v4.6-real-dataset-benchmark-suite"
Write-Host "Report mode: real dataset benchmark suite; diagnostics and debug dump mode; dataset benchmark smoke; streaming API and file wrapper tests; negative API and error contract tests; deterministic reproducible build metadata; packaging install and CMake lite; stable release candidate; library API and embedding header; CLI machine-readable JSON and stable schema; cross-version compatibility and migration check; manifest release audit and reproducibility; streaming large-file and memory guard; container fuzz and corruption tests; CLI usability and exit codes; ratio reporting and regression baseline; normal ZIP dependency + forced no-ZIP portability validation"
Write-Host "Workspace: $PWD"

$exe = Join-Path $PWD "bin\byg.exe"
$src = Join-Path $PWD "src\byg.cpp"
New-Item -ItemType Directory -Path "bin" -Force | Out-Null

Write-Host "g++ build başlıyor: $src"
& g++ -std=c++17 -O2 -Wall -Wextra -pedantic $src -o $exe
if ($LASTEXITCODE -ne 0) { throw "g++ build failed" }
Write-Host "BUILD_OK: $exe"

function New-Dir($p) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
function Get-Size($p) { return (Get-Item -LiteralPath $p).Length }
function Get-Sha($p) { return (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant() }
function Write-Utf8NoBom($path, $text) {
    $parent = Split-Path -Parent $path
    if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    [System.IO.File]::WriteAllText($path, $text, [System.Text.UTF8Encoding]::new($false))
}
function Write-Bytes($path, [byte[]]$bytes) {
    $parent = Split-Path -Parent $path
    if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    [System.IO.File]::WriteAllBytes($path, $bytes)
}
function Make-Zip($srcPath, $zipPath) {
    $tmp = $zipPath + ".tmp.zip"
    if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force }
    if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
    Compress-Archive -LiteralPath $srcPath -DestinationPath $tmp -Force
    Move-Item -LiteralPath $tmp -Destination $zipPath -Force
}
function Read-KvFile($path) {
    $h = @{}
    if (Test-Path -LiteralPath $path) {
        foreach ($line in Get-Content -LiteralPath $path) {
            $idx = $line.IndexOf('=')
            if ($idx -gt 0) {
                $k = $line.Substring(0, $idx)
                $v = $line.Substring($idx + 1)
                $h[$k] = $v
            }
        }
    }
    return $h
}
function Safe-Name($s) { return ($s -replace '[\\/:*?""<>|]', '_') }
function Round-Ratio($num, $den, $digits) {
    if ([double]$den -eq 0) { return 0 }
    return [math]::Round(([double]$num / [double]$den), $digits)
}
function Round-DeltaPct($selected, $zip) {
    if ([double]$zip -eq 0) { return 0 }
    return [math]::Round(((([double]$selected - [double]$zip) / [double]$zip) * 100.0), 2)
}

function Assert-DocContains($path, $needle) {
    if (-not (Test-Path -LiteralPath $path)) { throw "DOC_MISSING: $path" }
    $text = Get-Content -LiteralPath $path -Raw
    if ([string]::IsNullOrWhiteSpace($text)) { throw "DOC_EMPTY: $path" }
    if ($text -notmatch [regex]::Escape($needle)) { throw "DOC_CONTENT_MISSING: $path :: $needle" }
}

$requiredDocs = @("README.txt", "CHANGELOG.md", "FORMAT.md", "RELEASE_NOTES.md", "VERSION.txt", "REGRESSION_BASELINE_v3_1.json", "RELEASE_MANIFEST.json", "COMPATIBILITY_MATRIX.json", "CLI_JSON_SCHEMA.json", "RELEASE_CANDIDATE_CHECKLIST.md", "include\byg\byg.hpp", "tests\embed_api_smoke.cpp", "CMakeLists.txt", "INSTALL_LAYOUT.md", "BUILD_REPRODUCIBILITY.json", "API_ERROR_CONTRACT.json", "tests\embed_api_negative.cpp", "FILE_WRAPPER_CONTRACT.md", "tests\embed_api_file_wrapper.cpp", "src\byg.cpp", "run_tests.ps1", "DIAGNOSTIC_CONTRACT.json", "DATASET_BENCHMARK_PLAN.md", "DATASET_BENCHMARK_SUITE.md")
foreach ($doc in $requiredDocs) {
    if (-not (Test-Path -LiteralPath $doc)) { throw "DOC_REQUIRED_FILE_MISSING: $doc" }
    if ((Get-Item -LiteralPath $doc).Length -le 0) { throw "DOC_REQUIRED_FILE_EMPTY: $doc" }
}
Assert-DocContains "README.txt" "CLI examples"
Assert-DocContains "README.txt" "Forced no-ZIP portability test"
Assert-DocContains "README.txt" "Expanded real corpus"
Assert-DocContains "README.txt" "Ratio reporting and regression baseline"
Assert-DocContains "FORMAT.md" "Byte-level container layout"
Assert-DocContains "FORMAT.md" "Real corpus expansion notes"
Assert-DocContains "FORMAT.md" "v3.2 Ratio metrics"
Assert-DocContains "FORMAT.md" "BYG46DB"
Assert-DocContains "REGRESSION_BASELINE_v3_1.json" "v3.1-real-corpus-expansion"
Assert-DocContains "RELEASE_MANIFEST.json" "v4.6-real-dataset-benchmark-suite"
Assert-DocContains "RELEASE_MANIFEST.json" "BYG46DB"
Assert-DocContains "COMPATIBILITY_MATRIX.json" "BYG46DB"
Assert-DocContains "COMPATIBILITY_MATRIX.json" "BYG36MA"
Assert-DocContains "CLI_JSON_SCHEMA.json" "byg.inspect.v1"
Assert-DocContains "CLI_JSON_SCHEMA.json" "inspect --json"
Assert-DocContains "RELEASE_CANDIDATE_CHECKLIST.md" "API schema frozen"
Assert-DocContains "RELEASE_CANDIDATE_CHECKLIST.md" "CLI JSON schema frozen"
Assert-DocContains "RELEASE_CANDIDATE_CHECKLIST.md" "Release candidate acceptance gates"
Assert-DocContains "README.txt" "Packaging Install and CMake Lite"
Assert-DocContains "README.txt" "Packaging install and CMake lite"
Assert-DocContains "FORMAT.md" "v4.6 Packaging install guard"
Assert-DocContains "CMakeLists.txt" "install(TARGETS byg"
Assert-DocContains "CMakeLists.txt" "install(DIRECTORY include/"
Assert-DocContains "INSTALL_LAYOUT.md" "bin/byg.exe"
Assert-DocContains "INSTALL_LAYOUT.md" "include/byg/byg.hpp"
Assert-DocContains "INSTALL_LAYOUT.md" "share/byg"
Assert-DocContains "README.txt" "Deterministic Reproducible Build Metadata"
Assert-DocContains "README.txt" "BUILD_REPRODUCIBILITY.json"
Assert-DocContains "FORMAT.md" "v4.6 Build reproducibility guard"
Assert-DocContains "FORMAT.md" "Source hash guard"
Assert-DocContains "BUILD_REPRODUCIBILITY.json" "source_hashes"
Assert-DocContains "BUILD_REPRODUCIBILITY.json" "run_tests.ps1"
Assert-DocContains "README.txt" "Stable Release Candidate"
Assert-DocContains "FORMAT.md" "API/CLI schema frozen"
Assert-DocContains "README.txt" "Library API and embedding header"
Assert-DocContains "FORMAT.md" "v4.6 Packaging Install and CMake Lite"
Assert-DocContains "include\byg\byg.hpp" "compress_bytes"
Assert-DocContains "include\byg\byg.hpp" "decompress_bytes"
Assert-DocContains "include\byg\byg.hpp" "inspect_bytes"
Assert-DocContains "tests\embed_api_smoke.cpp" "BYG_LIBRARY_API_SMOKE_OK"
Assert-DocContains "README.txt" "inspect --json"
Assert-DocContains "README.txt" "Cross-version compatibility"
Assert-DocContains "FORMAT.md" "Cross-version compatibility guard"
Assert-DocContains "README.txt" "CLI usability and exit codes"
Assert-DocContains "README.txt" "Negative CLI tests"
Assert-DocContains "README.txt" "Container fuzz and corruption tests"
Assert-DocContains "README.txt" "Large-file and memory guard"
Assert-DocContains "README.txt" "Release manifest audit"
Assert-DocContains "FORMAT.md" "CLI exit-code contract"
Assert-DocContains "FORMAT.md" "Container parser corruption guard"
Assert-DocContains "FORMAT.md" "Large-file guard"
Assert-DocContains "FORMAT.md" "v4.6 CLI JSON schema guard"
Assert-DocContains "CHANGELOG.md" "v4.6-real-dataset-benchmark-suite"
Assert-DocContains "RELEASE_NOTES.md" "v4.6 Packaging Install and CMake Lite"
Assert-DocContains "VERSION.txt" "v4.6-real-dataset-benchmark-suite"
Assert-DocContains "README.txt" "Negative API and error contract tests"
Assert-DocContains "FORMAT.md" "v4.6 API negative/error contract guard"
Assert-DocContains "API_ERROR_CONTRACT.json" "byg.error_contract.v1"
Assert-DocContains "API_ERROR_CONTRACT.json" "bad magic"
Assert-DocContains "API_ERROR_CONTRACT.json" "container too small"
Assert-DocContains "tests\embed_api_negative.cpp" "BYG_API_NEGATIVE_SMOKE_OK"
Assert-DocContains "README.txt" "Streaming API and file wrapper tests"
Assert-DocContains "FORMAT.md" "v4.6 File wrapper API guard"
Assert-DocContains "FILE_WRAPPER_CONTRACT.md" "File wrapper API tests"
Assert-DocContains "FILE_WRAPPER_CONTRACT.md" "BYG_FILE_WRAPPER_SMOKE_OK"
Assert-DocContains "tests\embed_api_file_wrapper.cpp" "BYG_FILE_WRAPPER_SMOKE_OK"
Assert-DocContains "include\byg\byg.hpp" "compress_file"
Assert-DocContains "include\byg\byg.hpp" "decompress_file"
Assert-DocContains "include\byg\byg.hpp" "inspect_file"

Assert-DocContains "README.txt" "Diagnostics and Debug Dump Mode"
Assert-DocContains "README.txt" "Dataset benchmark smoke"
Assert-DocContains "FORMAT.md" "v4.6 Diagnostic dump guard"
Assert-DocContains "FORMAT.md" "v4.6 Dataset benchmark smoke guard"
Assert-DocContains "DIAGNOSTIC_CONTRACT.json" "byg.diagnostic_contract.v1"
Assert-DocContains "DIAGNOSTIC_CONTRACT.json" "byg.diagnose.v1"
Assert-DocContains "DATASET_BENCHMARK_PLAN.md" "BYG_DATASET_BENCHMARK_SMOKE_OK"
Assert-DocContains "CLI_JSON_SCHEMA.json" "byg.diagnose.v1"
Assert-DocContains "README.txt" "Real Dataset Benchmark Suite"
Assert-DocContains "FORMAT.md" "v4.6 Real dataset benchmark suite guard"
Assert-DocContains "DATASET_BENCHMARK_SUITE.md" "BYG_REAL_DATASET_BENCHMARK_SUITE_OK"
Write-Host "Documentation guard OK: README, FORMAT, CHANGELOG, RELEASE_NOTES, VERSION, REGRESSION_BASELINE_v3_1, RELEASE_MANIFEST, COMPATIBILITY_MATRIX present and aligned for v4.6 real dataset benchmark suite"


# v4.6: machine-readable release manifest audit. This catches packaging drift
# between VERSION.txt, FORMAT.md, docs, report target names, and the release guard list.
$manifestPath = "RELEASE_MANIFEST.json"
$manifestAuditPath = "o\r\v46_manifest_audit.txt"
$manifestAuditDir = Split-Path -Parent $manifestAuditPath
if ($manifestAuditDir) { New-Item -ItemType Directory -Path $manifestAuditDir -Force | Out-Null }
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$versionText = (Get-Content -LiteralPath "VERSION.txt" -Raw).Trim()
$formatText = Get-Content -LiteralPath "FORMAT.md" -Raw
if ($manifest.version -ne "v4.6-real-dataset-benchmark-suite") { throw "MANIFEST_VERSION_VALUE_FAIL" }
if ($versionText -ne $manifest.version) { throw "MANIFEST_VERSION_MISMATCH" }
if ($manifest.magic -ne "BYG46DB") { throw "MANIFEST_MAGIC_VALUE_FAIL" }
if ($formatText -notmatch [regex]::Escape([string]$manifest.magic)) { throw "MANIFEST_MAGIC_FORMAT_MISMATCH" }
foreach ($requiredFile in $manifest.required_files) {
    if (-not (Test-Path -LiteralPath $requiredFile)) { throw "MANIFEST_REQUIRED_FILE_MISSING: $requiredFile" }
    if ((Get-Item -LiteralPath $requiredFile).Length -le 0) { throw "MANIFEST_REQUIRED_FILE_EMPTY: $requiredFile" }
}
$guardNames = @($manifest.guard_list)
foreach ($guardName in @("documentation_guard", "release_manifest_audit", "build_reproducibility_guard", "api_negative_error_contract_guard", "file_wrapper_api_guard", "diagnostic_dump_guard", "dataset_benchmark_smoke_guard", "real_dataset_benchmark_suite_guard", "release_candidate_checklist_guard", "packaging_install_guard", "cross_version_compatibility_guard", "cli_json_schema_guard", "library_api_embedding_guard", "cli_negative_tests", "container_corruption_tests", "large_file_memory_guard", "normal_zip_dependency_mode", "ratio_reporting", "regression_baseline_guard", "forced_no_zip_portability_mode")) {
    if ($guardNames -notcontains $guardName) { throw "MANIFEST_GUARD_MISSING: $guardName" }
}
$reportTargets = @($manifest.report_targets)
foreach ($reportTarget in @("o\r\v46_manifest_audit.txt", "o\r\v46_build_reproducibility.txt", "o\r\v46_api_negative_error_contract.txt", "o\r\v46_diagnostic_dump_guard.txt", "o\r\v46_dataset_benchmark_smoke.txt", "o\r\v46_real_dataset_benchmark_suite.csv", "o\r\v46_real_dataset_benchmark_suite_summary.txt", "o\r\v46_file_wrapper_api_guard.txt", "o\r\v46_release_candidate_checklist.txt", "o\r\v46_packaging_install_guard.txt", "o\r\v46_cross_version_compatibility.txt", "o\r\v46_cli_json_schema_guard.txt", "o\r\v46_library_api_guard.txt", "o\r\v46_large_file_memory_guard.txt", "o\r\v46_forced_no_zip_validation_report.csv", "o\r\v46_summary.txt")) {
    if ($reportTargets -notcontains $reportTarget) { throw "MANIFEST_REPORT_TARGET_MISSING: $reportTarget" }
}
$manifestAuditLines = @()
$manifestAuditLines += "manifest_version=$($manifest.version)"
$manifestAuditLines += "version_txt=$versionText"
$manifestAuditLines += "manifest_magic=$($manifest.magic)"
$manifestAuditLines += "required_files=$($manifest.required_files.Count)"
$manifestAuditLines += "guard_count=$($manifest.guard_list.Count)"
$manifestAuditLines += "report_target_count=$($manifest.report_targets.Count)"
$manifestAuditLines += "status=OK"
$manifestAuditLines | Set-Content -LiteralPath $manifestAuditPath -Encoding UTF8
Write-Host "Release manifest audit OK: version, magic, required files, guard list and report targets aligned"




# v4.6: deterministic reproducible build metadata guard. This verifies that
# BUILD_REPRODUCIBILITY.json describes the current source tree and that the
# recorded source hashes match the files shipped in this artifact.
$buildReproPath = "BUILD_REPRODUCIBILITY.json"
$buildReproReportPath = "o\r\v46_build_reproducibility.txt"
$buildReproReportDir = Split-Path -Parent $buildReproReportPath
if ($buildReproReportDir) { New-Item -ItemType Directory -Path $buildReproReportDir -Force | Out-Null }
$buildRepro = Get-Content -LiteralPath $buildReproPath -Raw | ConvertFrom-Json
if ($buildRepro.version -ne "v4.6-real-dataset-benchmark-suite") { throw "BUILD_REPRO_VERSION_MISMATCH" }
if ($buildRepro.magic -ne "BYG46DB") { throw "BUILD_REPRO_MAGIC_MISMATCH" }
if ($buildRepro.compiler_command -notmatch "g\+\+ -std=c\+\+17") { throw "BUILD_REPRO_COMPILER_COMMAND_MISSING" }
$sourceHashes = $buildRepro.source_hashes
foreach ($requiredSourceHash in @("src/byg.cpp", "include/byg/byg.hpp", "run_tests.ps1", "CMakeLists.txt", "RELEASE_MANIFEST.json", "tests/embed_api_negative.cpp", "API_ERROR_CONTRACT.json", "tests/embed_api_file_wrapper.cpp", "FILE_WRAPPER_CONTRACT.md", "DIAGNOSTIC_CONTRACT.json", "DATASET_BENCHMARK_PLAN.md", "DATASET_BENCHMARK_SUITE.md")) {
    $entry = $sourceHashes | Where-Object { $_.path -eq $requiredSourceHash } | Select-Object -First 1
    if (-not $entry) { throw "BUILD_REPRO_SOURCE_HASH_ENTRY_MISSING: $requiredSourceHash" }
    $literalPath = $requiredSourceHash -replace '/', '\'
    if (-not (Test-Path -LiteralPath $literalPath)) { throw "BUILD_REPRO_SOURCE_FILE_MISSING: $literalPath" }
    $actualSourceHash = (Get-FileHash -LiteralPath $literalPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualSourceHash -ne ([string]$entry.sha256).ToLowerInvariant()) { throw "BUILD_REPRO_SOURCE_HASH_MISMATCH: $requiredSourceHash" }
}
$buildReproLines = @()
$buildReproLines += "Build reproducibility guard: OK"
$buildReproLines += "version=$($buildRepro.version)"
$buildReproLines += "magic=$($buildRepro.magic)"
$buildReproLines += "compiler_command=$($buildRepro.compiler_command)"
$buildReproLines += "source_hash_count=$($sourceHashes.Count)"
$buildReproLines += "guarded_sources=src/byg.cpp;include/byg/byg.hpp;run_tests.ps1;CMakeLists.txt;RELEASE_MANIFEST.json;tests/embed_api_negative.cpp;API_ERROR_CONTRACT.json;tests/embed_api_file_wrapper.cpp;FILE_WRAPPER_CONTRACT.md;DIAGNOSTIC_CONTRACT.json;DATASET_BENCHMARK_PLAN.md;DATASET_BENCHMARK_SUITE.md"
$buildReproLines += "status=OK"
$buildReproLines | Set-Content -LiteralPath $buildReproReportPath -Encoding UTF8
Write-Host "Build reproducibility guard OK: BUILD_REPRODUCIBILITY.json source hash metadata aligned"

# v4.6: release candidate checklist guard. This confirms that the package
# explicitly freezes the public API and CLI JSON schema surfaces before running
# the heavier codec and portability tests.
$rcChecklistPath = "RELEASE_CANDIDATE_CHECKLIST.md"
$rcChecklistReportPath = "o\r\v46_release_candidate_checklist.txt"
$rcChecklistReportDir = Split-Path -Parent $rcChecklistReportPath
if ($rcChecklistReportDir) { New-Item -ItemType Directory -Path $rcChecklistReportDir -Force | Out-Null }
$rcChecklistText = Get-Content -LiteralPath $rcChecklistPath -Raw
foreach ($marker in @("API schema frozen", "CLI JSON schema frozen", "Container format frozen", "Release candidate acceptance gates", "BYG46DB", "BYG_LIBRARY_API_SMOKE_OK")) {
    if ($rcChecklistText -notmatch [regex]::Escape($marker)) { throw "RC_CHECKLIST_MARKER_MISSING: $marker" }
}
$rcChecklistLines = @()
$rcChecklistLines += "version=v4.6-real-dataset-benchmark-suite"
$rcChecklistLines += "magic=BYG46DB"
$rcChecklistLines += "api_schema_frozen=true"
$rcChecklistLines += "cli_json_schema_frozen=true"
$rcChecklistLines += "container_format_frozen=true"
$rcChecklistLines += "acceptance_gates=present"
$rcChecklistLines += "status=OK"
$rcChecklistLines | Set-Content -LiteralPath $rcChecklistReportPath -Encoding UTF8
Write-Host "Release candidate checklist guard OK: API/CLI schema freeze markers and acceptance gates aligned"


# v4.6: packaging install and CMake-lite guard. This validates the install
# layout without requiring CMake to be installed on the runner. The CMakeLists
# contract is marker-checked, then the official binary/header/share layout is
# staged and a consumer smoke program is built against staged include/.
$packagingReportPath = "o\r\v46_packaging_install_guard.txt"
$packagingReportDir = Split-Path -Parent $packagingReportPath
if ($packagingReportDir) { New-Item -ItemType Directory -Path $packagingReportDir -Force | Out-Null }
$cmakeText = Get-Content -LiteralPath "CMakeLists.txt" -Raw
foreach ($marker in @("project(BYGRecursiveTokenizer VERSION 4.6", "add_executable(byg src/byg.cpp)", "install(TARGETS byg RUNTIME DESTINATION bin)", "install(DIRECTORY include/ DESTINATION include)", "target_include_directories(byg_header INTERFACE")) {
    if ($cmakeText -notmatch [regex]::Escape($marker)) { throw "PACKAGING_CMAKE_MARKER_MISSING: $marker" }
}
$installLayoutText = Get-Content -LiteralPath "INSTALL_LAYOUT.md" -Raw
foreach ($marker in @("bin/byg.exe", "include/byg/byg.hpp", "share/byg", "Packaging install and CMake lite")) {
    if ($installLayoutText -notmatch [regex]::Escape($marker)) { throw "PACKAGING_INSTALL_LAYOUT_MARKER_MISSING: $marker" }
}
$stageRoot = Join-Path $PWD "o\package_stage"
if (Test-Path -LiteralPath $stageRoot) { Remove-Item -LiteralPath $stageRoot -Recurse -Force }
New-Item -ItemType Directory -Path (Join-Path $stageRoot "bin"), (Join-Path $stageRoot "include\byg"), (Join-Path $stageRoot "share\byg") -Force | Out-Null
Copy-Item -LiteralPath $exe -Destination (Join-Path $stageRoot "bin\byg.exe") -Force
Copy-Item -LiteralPath "include\byg\byg.hpp" -Destination (Join-Path $stageRoot "include\byg\byg.hpp") -Force
foreach ($shareFile in @("CLI_JSON_SCHEMA.json", "COMPATIBILITY_MATRIX.json", "RELEASE_MANIFEST.json", "RELEASE_CANDIDATE_CHECKLIST.md", "INSTALL_LAYOUT.md", "API_ERROR_CONTRACT.json", "BUILD_REPRODUCIBILITY.json", "FILE_WRAPPER_CONTRACT.md", "DIAGNOSTIC_CONTRACT.json", "DATASET_BENCHMARK_PLAN.md", "DATASET_BENCHMARK_SUITE.md")) {
    Copy-Item -LiteralPath $shareFile -Destination (Join-Path $stageRoot ("share\byg\" + $shareFile)) -Force
}
$stagedExe = Join-Path $stageRoot "bin\byg.exe"
$cliOutDir = Join-Path $PWD "o\cli"
New-Item -ItemType Directory -Path $cliOutDir -Force | Out-Null
& $stagedExe --version > "o\cli\staged_version.txt"
if ($LASTEXITCODE -ne 0) { throw "PACKAGING_STAGED_CLI_VERSION_FAILED" }
$stagedVersionText = Get-Content -LiteralPath "o\cli\staged_version.txt" -Raw
if ($stagedVersionText -notmatch "v4.6-real-dataset-benchmark-suite") { throw "PACKAGING_STAGED_CLI_VERSION_MISMATCH" }
$packSmokeExe = Join-Path $PWD "bin\byg_packaging_smoke.exe"
& g++ -std=c++17 -O2 -Wall -Wextra -pedantic -I (Join-Path $stageRoot "include") "tests\embed_api_smoke.cpp" -o $packSmokeExe
if ($LASTEXITCODE -ne 0) { throw "PACKAGING_STAGED_HEADER_COMPILE_FAILED" }
& $packSmokeExe > "o\cli\packaging_smoke.out.txt"
if ($LASTEXITCODE -ne 0) { throw "PACKAGING_STAGED_HEADER_SMOKE_FAILED" }
$packSmokeText = Get-Content -LiteralPath "o\cli\packaging_smoke.out.txt" -Raw
if ($packSmokeText -notmatch "BYG_LIBRARY_API_SMOKE_OK") { throw "PACKAGING_STAGED_HEADER_SMOKE_MARKER_MISSING" }
$packagingLines = @()
$packagingLines += "Packaging install guard: OK"
$packagingLines += "cmake_lite_markers=OK"
$packagingLines += "stage_root=$stageRoot"
$packagingLines += "staged_cli=bin/byg.exe"
$packagingLines += "staged_header=include/byg/byg.hpp"
$packagingLines += "staged_share=share/byg"
$packagingLines += "staged_version=v4.6-real-dataset-benchmark-suite"
$packagingLines += "staged_header_smoke=BYG_LIBRARY_API_SMOKE_OK"
$packagingLines += "status=OK"
$packagingLines | Set-Content -LiteralPath $packagingReportPath -Encoding UTF8
Write-Host "Packaging install guard OK: CMake lite markers, staged bin/include/share layout, staged CLI and staged header smoke passed"


function Invoke-CliCase {
    param(
        [string]$Name,
        [string[]]$CliArgs,
        [int]$ExpectedExit,
        [string]$ExpectedText,
        [switch]$UseStdErr
    )
    $outPath = Join-Path "o\cli" ($Name + ".out.txt")
    $errPath = Join-Path "o\cli" ($Name + ".err.txt")

    # Native commands that intentionally write to stderr can be converted into
    # NativeCommandError records by Windows PowerShell when $ErrorActionPreference=Stop.
    # Use ProcessStartInfo so CLI negative tests can assert stderr and exit codes
    # deterministically without terminating the harness before $LASTEXITCODE is checked.
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $exe
    $quotedArgs = @()
    foreach ($arg in $CliArgs) {
        $escaped = $arg.Replace('"', '\"')
        $quotedArgs += ('"' + $escaped + '"')
    }
    $psi.Arguments = ($quotedArgs -join ' ')
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi
    [void]$proc.Start()
    $stdoutText = $proc.StandardOutput.ReadToEnd()
    $stderrText = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()
    $code = $proc.ExitCode

    Set-Content -LiteralPath $outPath -Value $stdoutText -Encoding UTF8
    Set-Content -LiteralPath $errPath -Value $stderrText -Encoding UTF8

    if ($code -ne $ExpectedExit) { throw "CLI_EXIT_FAIL: $Name expected=$ExpectedExit actual=$code" }
    $txt = if ($UseStdErr) { $stderrText } else { $stdoutText }
    if ($txt -notmatch [regex]::Escape($ExpectedText)) { throw "CLI_TEXT_FAIL: $Name expected text=$ExpectedText" }
}

New-Item -ItemType Directory -Path "o\cli" -Force | Out-Null
[System.IO.File]::WriteAllBytes((Join-Path $PWD "o\cli\corrupt.byg"), [byte[]](66,65,68,33,0,1,2,3))
New-Item -ItemType Directory -Path "o\cli\dir_output" -Force | Out-Null

Invoke-CliCase -Name "help" -CliArgs @("--help") -ExpectedExit 0 -ExpectedText "commands:"
Invoke-CliCase -Name "version" -CliArgs @("--version") -ExpectedExit 0 -ExpectedText "v4.6-real-dataset-benchmark-suite"
Invoke-CliCase -Name "compress_missing" -CliArgs @("compress") -ExpectedExit 2 -ExpectedText "usage: byg compress" -UseStdErr
Invoke-CliCase -Name "unknown_command" -CliArgs @("no_such_command") -ExpectedExit 2 -ExpectedText "ERROR: unknown command" -UseStdErr
Invoke-CliCase -Name "inspect_corrupt" -CliArgs @("inspect", "o\cli\corrupt.byg") -ExpectedExit 1 -ExpectedText "ERROR:" -UseStdErr
Invoke-CliCase -Name "extract_corrupt" -CliArgs @("extract", "o\cli\corrupt.byg", "o\cli\bad.raw") -ExpectedExit 1 -ExpectedText "ERROR:" -UseStdErr

& $exe make-sample 25 "o\cli\tiny_source.txt" | Out-Null
if ($LASTEXITCODE -ne 0) { throw "CLI_SETUP_MAKE_SAMPLE_FAILED" }
& $exe compress "o\cli\tiny_source.txt" "o\cli\tiny.byg" | Out-Null
if ($LASTEXITCODE -ne 0) { throw "CLI_SETUP_COMPRESS_FAILED" }
Invoke-CliCase -Name "extract_output_directory" -CliArgs @("extract", "o\cli\tiny.byg", "o\cli\dir_output") -ExpectedExit 1 -ExpectedText "ERROR:" -UseStdErr

$cliNegativeReportPath = "o\r\v46_cli_negative_tests.txt"
$cliLines = @()
$cliLines += "CLI negative tests: OK"
$cliLines += "help/version exit code: OK"
$cliLines += "usage error exit code 2: OK"
$cliLines += "unknown command exit code 2: OK"
$cliLines += "corrupt container exit code 1: OK"
$cliLines += "extract output directory error exit code 1: OK"
$cliNegativeReportDir = Split-Path -Parent $cliNegativeReportPath
if ($cliNegativeReportDir -and -not (Test-Path -LiteralPath $cliNegativeReportDir)) {
    New-Item -ItemType Directory -Path $cliNegativeReportDir -Force | Out-Null
}
$cliLines | Set-Content -LiteralPath $cliNegativeReportPath -Encoding UTF8
Write-Host "CLI negative tests OK: help/version, usage error, unknown command, corrupt container, extract output path failure"


# v4.6: CLI machine-readable JSON schema guard. Validates stdout JSON and
# report-file JSON path for inspect --json without weakening legacy key=value inspect.
$jsonGuardPath = "o\r\v46_cli_json_schema_guard.txt"
$jsonGuardDir = Split-Path -Parent $jsonGuardPath
if ($jsonGuardDir -and -not (Test-Path -LiteralPath $jsonGuardDir)) {
    New-Item -ItemType Directory -Path $jsonGuardDir -Force | Out-Null
}
& $exe inspect "o\cli\tiny.byg" --json > "o\cli\tiny.inspect.json"
if ($LASTEXITCODE -ne 0) { throw "CLI_JSON_STDOUT_INSPECT_FAILED" }
& $exe inspect "o\cli\tiny.byg" "o\cli\tiny.inspect.report.json" --json | Out-Null
if ($LASTEXITCODE -ne 0) { throw "CLI_JSON_REPORT_INSPECT_FAILED" }
$jsonText = Get-Content -LiteralPath "o\cli\tiny.inspect.json" -Raw
$jsonReportText = Get-Content -LiteralPath "o\cli\tiny.inspect.report.json" -Raw
$jsonObj = $jsonText | ConvertFrom-Json
$jsonReportObj = $jsonReportText | ConvertFrom-Json
$requiredJsonFields = @("schema", "tool", "version", "format", "selected_backend", "payload_submode", "decision_reason", "zip_dependency", "zip_dependency_available", "container_payload_flag", "template_id", "original_size", "checksum_fnv1a32", "header_size", "payload_size", "container_size")
foreach ($field in $requiredJsonFields) {
    if (-not ($jsonObj.PSObject.Properties.Name -contains $field)) { throw "CLI_JSON_FIELD_MISSING: $field" }
    if (-not ($jsonReportObj.PSObject.Properties.Name -contains $field)) { throw "CLI_JSON_REPORT_FIELD_MISSING: $field" }
}
if ($jsonObj.schema -ne "byg.inspect.v1") { throw "CLI_JSON_SCHEMA_VALUE_FAIL" }
if ($jsonObj.format -ne "BYG46DB") { throw "CLI_JSON_FORMAT_VALUE_FAIL" }
if ($jsonObj.version -notmatch "v4.6-real-dataset-benchmark-suite") { throw "CLI_JSON_VERSION_VALUE_FAIL" }
if ($jsonObj.selected_backend -notin @("BYGZ_TEMPLATE", "BYG_STORED", "ZIP_FALLBACK")) { throw "CLI_JSON_BACKEND_VALUE_FAIL" }
if ($jsonObj.payload_submode -notin @("template_id_only", "stored_raw", "fallback_lz", "fallback_zip_payload")) { throw "CLI_JSON_SUBMODE_VALUE_FAIL" }
if ($jsonObj.zip_dependency_available.GetType().Name -ne "Boolean") { throw "CLI_JSON_BOOL_TYPE_FAIL" }
foreach ($numField in @("template_id", "original_size", "checksum_fnv1a32", "header_size", "payload_size", "container_size")) {
    $value = $jsonObj.$numField
    if (-not ($value -is [int] -or $value -is [long] -or $value -is [decimal] -or $value -is [double])) { throw "CLI_JSON_NUMERIC_TYPE_FAIL: $numField" }
}
if ($jsonReportObj.schema -ne $jsonObj.schema) { throw "CLI_JSON_REPORT_SCHEMA_MISMATCH" }
if ($jsonReportObj.format -ne $jsonObj.format) { throw "CLI_JSON_REPORT_FORMAT_MISMATCH" }
$jsonGuardLines = @()
$jsonGuardLines += "CLI JSON schema guard: OK"
$jsonGuardLines += "schema=$($jsonObj.schema)"
$jsonGuardLines += "format=$($jsonObj.format)"
$jsonGuardLines += "selected_backend=$($jsonObj.selected_backend)"
$jsonGuardLines += "payload_submode=$($jsonObj.payload_submode)"
$jsonGuardLines += "required_fields=$($requiredJsonFields.Count)"
$jsonGuardLines += "stdout_json=o\cli\tiny.inspect.json"
$jsonGuardLines += "report_json=o\cli\tiny.inspect.report.json"
$jsonGuardLines += "status=OK"
$jsonGuardLines | Set-Content -LiteralPath $jsonGuardPath -Encoding UTF8
Write-Host "CLI JSON schema guard OK: inspect --json stdout/report, required fields and primitive types aligned"


# v4.6: diagnostic dump mode guard. Validates text and JSON diagnostic output,
# checksum verification, roundtrip status and read-only debug fields.
$diagGuardPath = "o\r\v46_diagnostic_dump_guard.txt"
$diagGuardDir = Split-Path -Parent $diagGuardPath
if ($diagGuardDir -and -not (Test-Path -LiteralPath $diagGuardDir)) { New-Item -ItemType Directory -Path $diagGuardDir -Force | Out-Null }
New-Item -ItemType Directory -Path "o\diagnose" -Force | Out-Null
& $exe make-sample 12 "o\diagnose\diag_source.txt" | Out-Null
if ($LASTEXITCODE -ne 0) { throw "DIAG_MAKE_SAMPLE_FAILED" }
& $exe compress "o\diagnose\diag_source.txt" "o\diagnose\diag_container.byg" | Out-Null
if ($LASTEXITCODE -ne 0) { throw "DIAG_COMPRESS_FAILED" }
& $exe diagnose "o\diagnose\diag_container.byg" "o\diagnose\diag_report.txt" | Out-Null
if ($LASTEXITCODE -ne 0) { throw "DIAG_TEXT_FAILED" }
$diagText = Get-Content -LiteralPath "o\diagnose\diag_report.txt" -Raw
foreach ($needle in @("diagnostic_dump=OK", "format=BYG46DB", "checksum_verify=OK", "roundtrip_ok=true", "selected_backend=BYGZ_TEMPLATE", "payload_preview_hex=")) {
    if ($diagText -notmatch [regex]::Escape($needle)) { throw "DIAG_TEXT_MARKER_MISSING: $needle" }
}
& $exe diagnose "o\diagnose\diag_container.byg" "o\diagnose\diag_report.json" --json | Out-Null
if ($LASTEXITCODE -ne 0) { throw "DIAG_JSON_FAILED" }
$diagJson = Get-Content -LiteralPath "o\diagnose\diag_report.json" -Raw | ConvertFrom-Json
foreach ($field in @("schema", "tool", "version", "format", "command", "ok", "selected_backend", "payload_submode", "decision_reason", "container_payload_flag", "template_id", "original_size", "checksum_fnv1a32", "checksum_verify", "header_size", "payload_size", "container_size", "zip_dependency", "zip_dependency_available", "roundtrip_ok")) {
    if (-not ($diagJson.PSObject.Properties.Name -contains $field)) { throw "DIAG_JSON_FIELD_MISSING: $field" }
}
if ($diagJson.schema -ne "byg.diagnose.v1") { throw "DIAG_JSON_SCHEMA_FAIL" }
if ($diagJson.format -ne "BYG46DB") { throw "DIAG_JSON_FORMAT_FAIL" }
if ($diagJson.command -ne "diagnose") { throw "DIAG_JSON_COMMAND_FAIL" }
if ($diagJson.ok -ne $true) { throw "DIAG_JSON_OK_FAIL" }
if ($diagJson.checksum_verify -ne "OK") { throw "DIAG_JSON_CHECKSUM_FAIL" }
if ($diagJson.roundtrip_ok -ne $true) { throw "DIAG_JSON_ROUNDTRIP_FAIL" }

function Invoke-DiagCliCaptureForErrorJson($CliArgs, $StdoutPath, $StderrPath) {
    $parentOut = Split-Path -Parent $StdoutPath
    if ($parentOut) { New-Item -ItemType Directory -Path $parentOut -Force | Out-Null }
    $parentErr = Split-Path -Parent $StderrPath
    if ($parentErr) { New-Item -ItemType Directory -Path $parentErr -Force | Out-Null }
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $exe
    # Windows PowerShell 5.1 on .NET Framework does not reliably expose
    # ProcessStartInfo.ArgumentList. Use the same quoted .Arguments fallback
    # as the earlier CLI negative-test runner so diagnostic error JSON capture
    # remains compatible with Bridge's default Windows PowerShell host.
    $quotedArgs = @()
    foreach ($arg in $CliArgs) {
        $escaped = $arg.Replace('"', '\"')
        $quotedArgs += ('"' + $escaped + '"')
    }
    $psi.Arguments = ($quotedArgs -join ' ')
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi
    [void]$proc.Start()
    $stdoutText = $proc.StandardOutput.ReadToEnd()
    $stderrText = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()
    Set-Content -LiteralPath $StdoutPath -Value $stdoutText -Encoding UTF8
    Set-Content -LiteralPath $StderrPath -Value $stderrText -Encoding UTF8
    return $proc.ExitCode
}
$diagErrExit = Invoke-DiagCliCaptureForErrorJson -CliArgs @("diagnose", "o\cli\corrupt.byg", "o\diagnose\diag_error.json", "--json") -StdoutPath "o\diagnose\diag_error.stdout.txt" -StderrPath "o\diagnose\diag_error.stderr.txt"
if ($diagErrExit -ne 1) { throw "DIAG_JSON_ERROR_EXIT_FAIL" }
$diagErrJson = Get-Content -LiteralPath "o\diagnose\diag_error.json" -Raw | ConvertFrom-Json
if ($diagErrJson.schema -ne "byg.error.v1") { throw "DIAG_ERROR_SCHEMA_FAIL" }
if ($diagErrJson.command -ne "diagnose") { throw "DIAG_ERROR_COMMAND_FAIL" }
$diagGuardLines = @()
$diagGuardLines += "Diagnostic dump guard: OK"
$diagGuardLines += "schema=$($diagJson.schema)"
$diagGuardLines += "format=$($diagJson.format)"
$diagGuardLines += "checksum_verify=$($diagJson.checksum_verify)"
$diagGuardLines += "roundtrip_ok=$($diagJson.roundtrip_ok)"
$diagGuardLines += "text_report=o\diagnose\diag_report.txt"
$diagGuardLines += "json_report=o\diagnose\diag_report.json"
$diagGuardLines += "error_json=o\diagnose\diag_error.json"
$diagGuardLines += "status=OK"
$diagGuardLines | Set-Content -LiteralPath $diagGuardPath -Encoding UTF8
Write-Host "Diagnostic dump guard OK: diagnose text/json reports, checksum verification and error schema aligned"

# v4.6: extra dataset benchmark smoke guard for AI/dataset-like data.
$datasetGuardPath = "o\r\v46_dataset_benchmark_smoke.txt"
$datasetGuardDir = Split-Path -Parent $datasetGuardPath
if ($datasetGuardDir -and -not (Test-Path -LiteralPath $datasetGuardDir)) { New-Item -ItemType Directory -Path $datasetGuardDir -Force | Out-Null }
New-Item -ItemType Directory -Path "o\dataset_bench" -Force | Out-Null
$aiJsonl = New-Object System.Text.StringBuilder
for ($i=0; $i -lt 250; $i++) {
    [void]$aiJsonl.Append("{`"id`":$i,`"source`":`"eval_only`",`"messages`": [{`"role`":`"system`",`"content`":`"You are BYG dataset compressor test.`"},{`"role`":`"user`",`"content`":`"Soru $i için kısa analiz yap.`"},{`"role`":`"assistant`",`"content`":`"Cevap ${i}: yapı tekrar ediyor ama içerik değişiyor.`"}],`"meta`":{`"lang`":`"tr`",`"split`":`"eval`"}}`n")
}
Write-Utf8NoBom "o\dataset_bench\ai_dataset_conversations.jsonl" $aiJsonl.ToString()
$evalJsonl = New-Object System.Text.StringBuilder
for ($i=0; $i -lt 300; $i++) { [void]$evalJsonl.Append("{`"case_id`":`"case_$i`",`"category`":`"tool_choice`",`"score`":$($i % 5),`"passed`":$([string](($i % 3) -ne 0)).ToLower(),`"notes`":`"structured repeated eval output`"}`n") }
Write-Utf8NoBom "o\dataset_bench\eval_results.jsonl" $evalJsonl.ToString()
$csv = New-Object System.Text.StringBuilder
[void]$csv.Append("ts,metric,host,value,tag`n")
for ($i=0; $i -lt 800; $i++) { [void]$csv.Append("2026-07-14T10:$('{0:D2}' -f ($i % 60)):00Z,loss,worker$($i%8),$($i%17),dataset_benchmark`n") }
Write-Utf8NoBom "o\dataset_bench\telemetry_metrics.csv" $csv.ToString()
$text = New-Object System.Text.StringBuilder
for ($i=0; $i -lt 120; $i++) { [void]$text.Append("Prompt archive block $i :: system/user/assistant schema repeats while natural Turkish text changes slightly for benchmark realism.`n") }
Write-Utf8NoBom "o\dataset_bench\mixed_prompt_archive.txt" $text.ToString()
$datasetNames = @("ai_dataset_conversations.jsonl", "eval_results.jsonl", "telemetry_metrics.csv", "mixed_prompt_archive.txt")
$datasetLines = @()
$datasetLines += "Dataset benchmark smoke guard: OK"
$datasetLines += "marker=BYG_DATASET_BENCHMARK_SMOKE_OK"
$totalRaw = 0
$totalSelected = 0
foreach ($name in $datasetNames) {
    $srcPath = "o\dataset_bench\$name"
    $bygPath = "o\dataset_bench\$name.byg"
    $outPath = "o\dataset_bench\$name.out"
    $diagPath = "o\dataset_bench\$name.diagnose.json"
    $benchPath = "o\dataset_bench\$name.benchmark.txt"
    & $exe compress $srcPath $bygPath | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "DATASET_BENCH_COMPRESS_FAIL: $name" }
    & $exe extract $bygPath $outPath | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "DATASET_BENCH_EXTRACT_FAIL: $name" }
    if ((Get-Sha $srcPath) -ne (Get-Sha $outPath)) { throw "DATASET_BENCH_HASH_FAIL: $name" }
    & $exe diagnose $bygPath $diagPath --json | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "DATASET_BENCH_DIAG_FAIL: $name" }
    $dj = Get-Content -LiteralPath $diagPath -Raw | ConvertFrom-Json
    if ($dj.schema -ne "byg.diagnose.v1") { throw "DATASET_BENCH_DIAG_SCHEMA_FAIL: $name" }
    if ($dj.roundtrip_ok -ne $true) { throw "DATASET_BENCH_DIAG_ROUNDTRIP_FAIL: $name" }
    & $exe benchmark $srcPath $benchPath | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "DATASET_BENCH_BENCHMARK_FAIL: $name" }
    $kv = Read-KvFile $benchPath
    if (-not $kv.ContainsKey("raw_size") -or -not $kv.ContainsKey("selected_size")) { throw "DATASET_BENCH_KV_MISSING: $name" }
    $rawN = [int64]$kv["raw_size"]
    $selN = [int64]$kv["selected_size"]
    $totalRaw += $rawN
    $totalSelected += $selN
    $datasetLines += "$name raw=$rawN selected=$selN ratio=$(Round-Ratio $selN $rawN 6) backend=$($kv["backend"]) submode=$($kv["payload_submode"]) diag_schema=$($dj.schema)"
}
$datasetLines += "total_raw=$totalRaw"
$datasetLines += "total_selected=$totalSelected"
$datasetLines += "avg_selected_raw_ratio=$(Round-Ratio $totalSelected $totalRaw 6)"
$datasetLines += "BYG_DATASET_BENCHMARK_SMOKE_OK"
$datasetLines += "status=OK"
$datasetLines | Set-Content -LiteralPath $datasetGuardPath -Encoding UTF8
Write-Host "Dataset benchmark smoke guard OK: JSONL/CSV/text AI dataset samples roundtrip, diagnose and benchmark reports passed"

# v4.6: real dataset benchmark suite guard. This is deliberately larger than
# the v4.5 smoke test and records ratio + timing + backend decision metrics for
# AI/dataset-like JSONL, CSV, prompt archive, and entropy-control samples.
$realSuiteCsvPath = "o\r\v46_real_dataset_benchmark_suite.csv"
$realSuiteSummaryPath = "o\r\v46_real_dataset_benchmark_suite_summary.txt"
$realSuiteDir = Split-Path -Parent $realSuiteCsvPath
if ($realSuiteDir -and -not (Test-Path -LiteralPath $realSuiteDir)) { New-Item -ItemType Directory -Path $realSuiteDir -Force | Out-Null }
New-Item -ItemType Directory -Path "o\real_dataset_suite" -Force | Out-Null

function New-RepeatedDatasetUntilMinBytes($Path, [string]$Kind, [int]$MinBytes) {
    $sb = New-Object System.Text.StringBuilder
    $i = 0
    while ([System.Text.Encoding]::UTF8.GetByteCount($sb.ToString()) -lt $MinBytes) {
        if ($Kind -eq "conversation_jsonl") {
            [void]$sb.Append("{`"id`":$i,`"dataset`":`"conversation`",`"messages`": [{`"role`":`"system`",`"content`":`"BYG benchmark system prompt with repeated schema.`"},{`"role`":`"user`",`"content`":`"Kullanıcı örneği ${i}: dataset sıkıştırma testi için açıklama istiyor.`"},{`"role`":`"assistant`",`"content`":`"Yanıt ${i}: aynı JSONL şeması korunur, metin doğal ama tekrarlı kalır.`"}],`"meta`":{`"lang`":`"tr`",`"split`":`"train`",`"source`":`"synthetic-realism`"}}`n")
        } elseif ($Kind -eq "eval_jsonl") {
            [void]$sb.Append("{`"case_id`":`"eval_$i`",`"category`":`"instruction_following`",`"prompt_tokens`":$($i%4096),`"completion_tokens`":$((($i*7)%2048)+64),`"passed`":$([string](($i % 4) -ne 0)).ToLower(),`"notes`":`"structured eval output with repeated keys and varied values`"}`n")
        } elseif ($Kind -eq "telemetry_csv") {
            if ($i -eq 0) { [void]$sb.Append("ts,host,metric,value,unit,tag,run_id`n") }
            [void]$sb.Append("2026-07-14T11:$('{0:D2}' -f ($i % 60)):00Z,worker$($i%16),tokens_per_second,$([math]::Round(12.5 + ($i%90)/10.0,2)),tok_s,dataset_suite,run_$($i%12)`n")
        } elseif ($Kind -eq "prompt_archive") {
            [void]$sb.Append("--- prompt-block-$i ---`nSYSTEM: BYG dataset benchmark suite keeps structure inspectable.`nUSER: Bu örnekte tekrar eden prompt arşivi satırı ${i} var.`nASSISTANT: Cevap doğal Türkçe kalırken format ve anahtarlar tekrar ediyor.`n")
        }
        $i++
    }
    Write-Utf8NoBom $Path $sb.ToString()
}
function New-EntropyControl($Path, [int]$Bytes) {
    $buf = New-Object byte[] ($Bytes)
    $rng = [System.Random]::new(4606)
    $rng.NextBytes($buf)
    Write-Bytes $Path $buf
}

New-RepeatedDatasetUntilMinBytes "o\real_dataset_suite\conversation_1mb.jsonl" "conversation_jsonl" 1048576
New-RepeatedDatasetUntilMinBytes "o\real_dataset_suite\eval_1mb.jsonl" "eval_jsonl" 1048576
New-RepeatedDatasetUntilMinBytes "o\real_dataset_suite\telemetry_1mb.csv" "telemetry_csv" 1048576
New-RepeatedDatasetUntilMinBytes "o\real_dataset_suite\prompt_archive_1mb.txt" "prompt_archive" 1048576
New-EntropyControl "o\real_dataset_suite\entropy_control_512kb.bin" 524288

$suiteNames = @("conversation_1mb.jsonl", "eval_1mb.jsonl", "telemetry_1mb.csv", "prompt_archive_1mb.txt", "entropy_control_512kb.bin")
$csvRows = @()
$csvRows += "name,raw_size,selected_size,zip_size,selected_raw_ratio,zip_raw_ratio,byg_vs_zip_delta_percent,backend,payload_submode,decision_reason,compress_ms,extract_ms,diagnose_schema,roundtrip_ok"
$totalSuiteRaw = 0
$totalSuiteSelected = 0
$totalSuiteZip = 0
foreach ($name in $suiteNames) {
    $srcPath = "o\real_dataset_suite\$name"
    $bygPath = "o\real_dataset_suite\$name.byg"
    $outPath = "o\real_dataset_suite\$name.out"
    $diagPath = "o\real_dataset_suite\$name.diagnose.json"
    $benchPath = "o\real_dataset_suite\$name.benchmark.txt"
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    & $exe compress $srcPath $bygPath | Out-Null
    $sw.Stop()
    if ($LASTEXITCODE -ne 0) { throw "REAL_DATASET_SUITE_COMPRESS_FAIL: $name" }
    $compressMs = [math]::Round($sw.Elapsed.TotalMilliseconds, 3)
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    & $exe extract $bygPath $outPath | Out-Null
    $sw.Stop()
    if ($LASTEXITCODE -ne 0) { throw "REAL_DATASET_SUITE_EXTRACT_FAIL: $name" }
    $extractMs = [math]::Round($sw.Elapsed.TotalMilliseconds, 3)
    $roundtripOk = ((Get-Sha $srcPath) -eq (Get-Sha $outPath))
    if (-not $roundtripOk) { throw "REAL_DATASET_SUITE_HASH_FAIL: $name" }
    & $exe diagnose $bygPath $diagPath --json | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "REAL_DATASET_SUITE_DIAG_FAIL: $name" }
    $dj = Get-Content -LiteralPath $diagPath -Raw | ConvertFrom-Json
    if ($dj.schema -ne "byg.diagnose.v1") { throw "REAL_DATASET_SUITE_DIAG_SCHEMA_FAIL: $name" }
    if ($dj.roundtrip_ok -ne $true) { throw "REAL_DATASET_SUITE_DIAG_ROUNDTRIP_FAIL: $name" }
    $zipBaselinePath = "o\real_dataset_suite\$name.zip"
    Make-Zip $srcPath $zipBaselinePath
    $zipN = Get-Size $zipBaselinePath
    & $exe benchmark $srcPath $benchPath | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "REAL_DATASET_SUITE_BENCHMARK_FAIL: $name" }
    $kv = Read-KvFile $benchPath
    foreach ($needed in @("raw_size", "selected_size", "backend", "payload_submode", "decision_reason")) {
        if (-not $kv.ContainsKey($needed)) { throw "REAL_DATASET_SUITE_KV_MISSING: $name :: $needed" }
    }
    $rawN = [int64]$kv["raw_size"]
    $selN = [int64]$kv["selected_size"]
    $totalSuiteRaw += $rawN
    $totalSuiteSelected += $selN
    $totalSuiteZip += $zipN
    $csvRows += "$name,$rawN,$selN,$zipN,$(Round-Ratio $selN $rawN 6),$(Round-Ratio $zipN $rawN 6),$(Round-DeltaPct $selN $zipN),$($kv["backend"]),$($kv["payload_submode"]),$($kv["decision_reason"]),$compressMs,$extractMs,$($dj.schema),$roundtripOk"
}
$csvRows | Set-Content -LiteralPath $realSuiteCsvPath -Encoding UTF8
$summaryLines = @()
$summaryLines += "Real dataset benchmark suite guard: OK"
$summaryLines += "marker=BYG_REAL_DATASET_BENCHMARK_SUITE_OK"
$summaryLines += "samples=$($suiteNames.Count)"
$summaryLines += "total_raw=$totalSuiteRaw"
$summaryLines += "total_selected=$totalSuiteSelected"
$summaryLines += "total_zip=$totalSuiteZip"
$summaryLines += "total_selected_raw_ratio=$(Round-Ratio $totalSuiteSelected $totalSuiteRaw 6)"
$summaryLines += "total_zip_raw_ratio=$(Round-Ratio $totalSuiteZip $totalSuiteRaw 6)"
$summaryLines += "total_byg_vs_zip_delta_percent=$(Round-DeltaPct $totalSuiteSelected $totalSuiteZip)"
$summaryLines += "csv=o\r\v46_real_dataset_benchmark_suite.csv"
$summaryLines += "status=OK"
$summaryLines | Set-Content -LiteralPath $realSuiteSummaryPath -Encoding UTF8
Write-Host "Real dataset benchmark suite guard OK: 1MB-class JSONL/CSV/text and entropy-control samples roundtrip, diagnose, timing and ratio reports passed"


# v4.6: negative public API and CLI JSON error contract guard.
# This verifies exception-safe byte-vector failure paths and machine-readable
# inspect --json error output for corrupt containers.
$apiNegReportPath = "o\r\v46_api_negative_error_contract.txt"
$apiNegReportDir = Split-Path -Parent $apiNegReportPath
if ($apiNegReportDir -and -not (Test-Path -LiteralPath $apiNegReportDir)) {
    New-Item -ItemType Directory -Path $apiNegReportDir -Force | Out-Null
}
$errorContract = Get-Content -LiteralPath "API_ERROR_CONTRACT.json" -Raw | ConvertFrom-Json
if ($errorContract.schema -ne "byg.error_contract.v1") { throw "API_ERROR_CONTRACT_SCHEMA_FAIL" }
if ($errorContract.version -ne "v4.6-real-dataset-benchmark-suite") { throw "API_ERROR_CONTRACT_VERSION_FAIL" }
if ($errorContract.magic -ne "BYG46DB") { throw "API_ERROR_CONTRACT_MAGIC_FAIL" }
foreach ($marker in @("container too small", "bad magic", "unsupported public-api backend", "payload size mismatch", "checksum mismatch")) {
    if (@($errorContract.api_negative_cases) -notcontains $marker) { throw "API_ERROR_CONTRACT_CASE_MISSING: $marker" }
}
$apiNegExe = Join-Path $PWD "bin\byg_api_negative_smoke.exe"
& g++ -std=c++17 -O2 -Wall -Wextra -pedantic -Iinclude "tests\embed_api_negative.cpp" -o $apiNegExe
if ($LASTEXITCODE -ne 0) { throw "API_NEGATIVE_SMOKE_BUILD_FAILED" }
& $apiNegExe > "o\cli\api_negative_smoke.out.txt"
if ($LASTEXITCODE -ne 0) { throw "API_NEGATIVE_SMOKE_RUN_FAILED" }
$apiNegSmokeText = Get-Content -LiteralPath "o\cli\api_negative_smoke.out.txt" -Raw
if ($apiNegSmokeText -notmatch "BYG_API_NEGATIVE_SMOKE_OK") { throw "API_NEGATIVE_SMOKE_MARKER_MISSING" }
if ($apiNegSmokeText -notmatch "BYG46DB") { throw "API_NEGATIVE_MAGIC_MARKER_MISSING" }
function Invoke-CliCaptureForErrorJson([string[]]$CliArgs, [string]$StdoutPath, [string]$StderrPath) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $exe
    $quotedArgs = @()
    foreach ($arg in $CliArgs) {
        $escaped = $arg.Replace('"', '\"')
        $quotedArgs += ('"' + $escaped + '"')
    }
    $psi.Arguments = ($quotedArgs -join ' ')
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi
    [void]$proc.Start()
    $stdoutText = $proc.StandardOutput.ReadToEnd()
    $stderrText = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()
    Set-Content -LiteralPath $StdoutPath -Value $stdoutText -Encoding UTF8
    Set-Content -LiteralPath $StderrPath -Value $stderrText -Encoding UTF8
    return $proc.ExitCode
}
$jsonErrExit = Invoke-CliCaptureForErrorJson -CliArgs @("inspect", "o\cli\corrupt.byg", "--json") -StdoutPath "o\cli\corrupt.inspect.error.json" -StderrPath "o\cli\corrupt.inspect.error.stderr.txt"
if ($jsonErrExit -ne 1) { throw "CLI_JSON_ERROR_EXIT_FAIL" }
$jsonErrObj = Get-Content -LiteralPath "o\cli\corrupt.inspect.error.json" -Raw | ConvertFrom-Json
foreach ($field in @("schema", "tool", "version", "format", "command", "ok", "error", "exit_code")) {
    if (-not ($jsonErrObj.PSObject.Properties.Name -contains $field)) { throw "CLI_JSON_ERROR_FIELD_MISSING: $field" }
}
if ($jsonErrObj.schema -ne "byg.error.v1") { throw "CLI_JSON_ERROR_SCHEMA_VALUE_FAIL" }
if ($jsonErrObj.format -ne "BYG46DB") { throw "CLI_JSON_ERROR_FORMAT_VALUE_FAIL" }
if ($jsonErrObj.command -ne "inspect") { throw "CLI_JSON_ERROR_COMMAND_VALUE_FAIL" }
if ($jsonErrObj.ok -ne $false) { throw "CLI_JSON_ERROR_OK_VALUE_FAIL" }
if ($jsonErrObj.exit_code -ne 1) { throw "CLI_JSON_ERROR_EXIT_CODE_VALUE_FAIL" }
if ([string]::IsNullOrWhiteSpace([string]$jsonErrObj.error)) { throw "CLI_JSON_ERROR_MESSAGE_EMPTY" }
$jsonErrReportExit = Invoke-CliCaptureForErrorJson -CliArgs @("inspect", "o\cli\corrupt.byg", "o\cli\corrupt.inspect.error.report.json", "--json") -StdoutPath "o\cli\corrupt.inspect.error.report.stdout.txt" -StderrPath "o\cli\corrupt.inspect.error.report.stderr.txt"
if ($jsonErrReportExit -ne 1) { throw "CLI_JSON_ERROR_REPORT_EXIT_FAIL" }
$jsonErrReportObj = Get-Content -LiteralPath "o\cli\corrupt.inspect.error.report.json" -Raw | ConvertFrom-Json
if ($jsonErrReportObj.schema -ne $jsonErrObj.schema) { throw "CLI_JSON_ERROR_REPORT_SCHEMA_MISMATCH" }
if ($jsonErrReportObj.format -ne $jsonErrObj.format) { throw "CLI_JSON_ERROR_REPORT_FORMAT_MISMATCH" }
$apiNegLines = @()
$apiNegLines += "API negative/error contract guard: OK"
$apiNegLines += "api_negative_smoke=o\cli\api_negative_smoke.out.txt"
$apiNegLines += "api_negative_cases=5"
$apiNegLines += "cli_json_error_schema=$($jsonErrObj.schema)"
$apiNegLines += "cli_json_error_format=$($jsonErrObj.format)"
$apiNegLines += "stdout_json_error=o\cli\corrupt.inspect.error.json"
$apiNegLines += "report_json_error=o\cli\corrupt.inspect.error.report.json"
$apiNegLines += "status=OK"
$apiNegLines | Set-Content -LiteralPath $apiNegReportPath -Encoding UTF8
Write-Host "API negative/error contract guard OK: public API corrupt byte-vector paths and CLI JSON error schema aligned"


# v4.6: public file wrapper API guard. This compiles a host program against
# include/byg/byg.hpp and verifies file-oriented wrappers, large/empty payload
# roundtrips, missing-input errors, and CLI/API file-path consistency.
$fileWrapperReportPath = "o\r\v46_file_wrapper_api_guard.txt"
$fileWrapperReportDir = Split-Path -Parent $fileWrapperReportPath
if ($fileWrapperReportDir -and -not (Test-Path -LiteralPath $fileWrapperReportDir)) {
    New-Item -ItemType Directory -Path $fileWrapperReportDir -Force | Out-Null
}
$fileWrapperExe = Join-Path $PWD "bin\byg_file_wrapper_smoke.exe"
& g++ -std=c++17 -O2 -Wall -Wextra -pedantic -Iinclude "tests\embed_api_file_wrapper.cpp" -o $fileWrapperExe
if ($LASTEXITCODE -ne 0) { throw "FILE_WRAPPER_SMOKE_BUILD_FAILED" }
& $fileWrapperExe > "o\cli\file_wrapper_smoke.out.txt"
if ($LASTEXITCODE -ne 0) { throw "FILE_WRAPPER_SMOKE_RUN_FAILED" }
$fileWrapperSmokeText = Get-Content -LiteralPath "o\cli\file_wrapper_smoke.out.txt" -Raw
if ($fileWrapperSmokeText -notmatch "BYG_FILE_WRAPPER_SMOKE_OK") { throw "FILE_WRAPPER_SMOKE_MARKER_MISSING" }
if ($fileWrapperSmokeText -notmatch "v4.6-real-dataset-benchmark-suite") { throw "FILE_WRAPPER_VERSION_MARKER_MISSING" }
if ($fileWrapperSmokeText -notmatch "BYG46DB") { throw "FILE_WRAPPER_MAGIC_MARKER_MISSING" }
New-Item -ItemType Directory -Path "o\file_wrapper" -Force | Out-Null
& $exe make-sample 12 "o\file_wrapper\cli_api_source.txt" | Out-Null
if ($LASTEXITCODE -ne 0) { throw "FILE_WRAPPER_CLI_MAKE_SAMPLE_FAILED" }
& $exe compress "o\file_wrapper\cli_api_source.txt" "o\file_wrapper\cli_api_container.byg" | Out-Null
if ($LASTEXITCODE -ne 0) { throw "FILE_WRAPPER_CLI_COMPRESS_FAILED" }
& $exe extract "o\file_wrapper\cli_api_container.byg" "o\file_wrapper\cli_api_restored.txt" | Out-Null
if ($LASTEXITCODE -ne 0) { throw "FILE_WRAPPER_CLI_EXTRACT_FAILED" }
if ((Get-Sha "o\file_wrapper\cli_api_source.txt") -ne (Get-Sha "o\file_wrapper\cli_api_restored.txt")) { throw "FILE_WRAPPER_CLI_ROUNDTRIP_HASH_FAIL" }
$fileWrapperLines = @()
$fileWrapperLines += "File wrapper API guard: OK"
$fileWrapperLines += "sample=tests/embed_api_file_wrapper.cpp"
$fileWrapperLines += "functions=read_file_bytes,write_file_bytes,compress_file,decompress_file,inspect_file"
$fileWrapperLines += "smoke_output=o\cli\file_wrapper_smoke.out.txt"
$fileWrapperLines += "smoke_marker=BYG_FILE_WRAPPER_SMOKE_OK"
$fileWrapperLines += "large_file_wrapper_roundtrip=OK"
$fileWrapperLines += "empty_file_wrapper_roundtrip=OK"
$fileWrapperLines += "missing_input_error=OK"
$fileWrapperLines += "cli_api_file_path_consistency=OK"
$fileWrapperLines += "status=OK"
$fileWrapperLines | Set-Content -LiteralPath $fileWrapperReportPath -Encoding UTF8
Write-Host "File wrapper API guard OK: public file wrappers, large/empty roundtrip, missing-input error and CLI/API path consistency passed"


# v4.6: public C++ library API and embedding header guard.
# This compiles a small host program against include/byg/byg.hpp and verifies
# version/magic, byte-vector compression, inspection, and decompression roundtrip.
$apiGuardPath = "o\r\v46_library_api_guard.txt"
$apiGuardDir = Split-Path -Parent $apiGuardPath
if ($apiGuardDir -and -not (Test-Path -LiteralPath $apiGuardDir)) {
    New-Item -ItemType Directory -Path $apiGuardDir -Force | Out-Null
}
$apiExe = Join-Path $PWD "bin\byg_api_smoke.exe"
& g++ -std=c++17 -O2 -Wall -Wextra -pedantic -Iinclude "tests\embed_api_smoke.cpp" -o $apiExe
if ($LASTEXITCODE -ne 0) { throw "LIBRARY_API_SMOKE_BUILD_FAILED" }
& $apiExe > "o\cli\library_api_smoke.out.txt"
if ($LASTEXITCODE -ne 0) { throw "LIBRARY_API_SMOKE_RUN_FAILED" }
$apiSmokeText = Get-Content -LiteralPath "o\cli\library_api_smoke.out.txt" -Raw
if ($apiSmokeText -notmatch "BYG_LIBRARY_API_SMOKE_OK") { throw "LIBRARY_API_SMOKE_MARKER_MISSING" }
if ($apiSmokeText -notmatch "v4.6-real-dataset-benchmark-suite") { throw "LIBRARY_API_VERSION_MARKER_MISSING" }
if ($apiSmokeText -notmatch "BYG46DB") { throw "LIBRARY_API_MAGIC_MARKER_MISSING" }
$apiGuardLines = @()
$apiGuardLines += "Library API embedding guard: OK"
$apiGuardLines += "header=include/byg/byg.hpp"
$apiGuardLines += "sample=tests/embed_api_smoke.cpp"
$apiGuardLines += "functions=compress_bytes,decompress_bytes,inspect_bytes,version,format_magic"
$apiGuardLines += "smoke_output=o\cli\library_api_smoke.out.txt"
$apiGuardLines += "status=OK"
$apiGuardLines | Set-Content -LiteralPath $apiGuardPath -Encoding UTF8
Write-Host "Library API embedding guard OK: include/byg/byg.hpp compile and byte-vector roundtrip smoke passed"

# v4.6: cross-version compatibility and migration-policy guard. The current
# prototype writes only the current magic. Older magic samples must be rejected
# deterministically with bad-magic errors instead of being silently accepted or
# misparsed as current containers.
$compatReportPath = "o\r\v46_cross_version_compatibility.txt"
$compatReportDir = Split-Path -Parent $compatReportPath
if ($compatReportDir -and -not (Test-Path -LiteralPath $compatReportDir)) {
    New-Item -ItemType Directory -Path $compatReportDir -Force | Out-Null
}
function Write-CompatMagic([string]$SourcePath, [string]$DestPath, [string]$MagicText) {
    [byte[]]$bytes = [System.IO.File]::ReadAllBytes((Join-Path $PWD $SourcePath))
    [byte[]]$magicBytes = [System.Text.Encoding]::ASCII.GetBytes($MagicText)
    if ($magicBytes.Length -ne 7) { throw "COMPAT_MAGIC_LENGTH_FAIL: $MagicText" }
    if ($bytes.Length -lt 7) { throw "COMPAT_SOURCE_TOO_SMALL" }
    for ($i = 0; $i -lt 7; $i++) { $bytes[$i] = $magicBytes[$i] }
    [System.IO.File]::WriteAllBytes((Join-Path $PWD $DestPath), $bytes)
}
& $exe make-sample 25 "o\compat\tiny_source.txt" | Out-Null
if ($LASTEXITCODE -ne 0) { throw "COMPAT_SETUP_MAKE_SAMPLE_FAILED" }
& $exe compress "o\compat\tiny_source.txt" "o\compat\current.byg" | Out-Null
if ($LASTEXITCODE -ne 0) { throw "COMPAT_SETUP_COMPRESS_FAILED" }
& $exe inspect "o\compat\current.byg" "o\compat\current.inspect.txt" | Out-Null
if ($LASTEXITCODE -ne 0) { throw "COMPAT_CURRENT_INSPECT_FAILED" }
$currentInspect = Get-Content -LiteralPath "o\compat\current.inspect.txt" -Raw
if ($currentInspect -notmatch "format=BYG46DB") { throw "COMPAT_CURRENT_FORMAT_MISMATCH" }
& $exe extract "o\compat\current.byg" "o\compat\current.raw" | Out-Null
if ($LASTEXITCODE -ne 0) { throw "COMPAT_CURRENT_EXTRACT_FAILED" }
if ((Get-Sha "o\compat\tiny_source.txt") -ne (Get-Sha "o\compat\current.raw")) { throw "COMPAT_CURRENT_ROUNDTRIP_FAIL" }

$compatLines = @()
$compatLines += "current_magic=BYG46DB"
$compatLines += "current_roundtrip=OK"
foreach ($oldMagic in @("BYG45DG", "BYG44FW", "BYG43NE", "BYG42RB", "BYG41PK", "BYG40RC", "BYG39LH", "BYG38JS", "BYG37CV", "BYG36MA", "BYG352G", "BYG34FC", "BYG301C")) {
    $caseName = "old_magic_" + $oldMagic
    $casePath = "o\compat\$caseName.byg"
    Write-CompatMagic "o\compat\current.byg" $casePath $oldMagic
    Invoke-CliCase -Name ("compat_inspect_" + $oldMagic) -CliArgs @("inspect", $casePath) -ExpectedExit 1 -ExpectedText "ERROR: bad magic" -UseStdErr
    Invoke-CliCase -Name ("compat_extract_" + $oldMagic) -CliArgs @("extract", $casePath, "o\compat\$caseName.raw") -ExpectedExit 1 -ExpectedText "ERROR: bad magic" -UseStdErr
    $compatLines += "$oldMagic=rejected_bad_magic"
}
$compatLines += "migration_policy=explicit_reject_unsupported_magic"
$compatLines += "status=OK"
$compatLines | Set-Content -LiteralPath $compatReportPath -Encoding UTF8
Write-Host "Cross-version compatibility guard OK: current BYG46DB roundtrip, older magic samples rejected deterministically"



# v4.6 preserved v3.4 container fuzz and corruption tests. These are parser-hardening
# negative cases for malformed BYG containers. They intentionally expect
# non-zero exits and stderr text, but must not terminate the PowerShell harness.
function Copy-ByteArray([byte[]]$Bytes) {
    $copy = New-Object byte[] ($Bytes.Length)
    [Array]::Copy($Bytes, $copy, $Bytes.Length)
    return $copy
}
function Truncate-ByteArray([byte[]]$Bytes, [int]$DropCount) {
    $newLen = [Math]::Max(0, $Bytes.Length - $DropCount)
    $copy = New-Object byte[] ($newLen)
    if ($newLen -gt 0) { [Array]::Copy($Bytes, $copy, $newLen) }
    return $copy
}
function Write-FuzzBytes($Path, [byte[]]$Bytes) {
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    [System.IO.File]::WriteAllBytes((Join-Path $PWD $Path), $Bytes)
}

New-Item -ItemType Directory -Path "o\fuzz" -Force | Out-Null
& $exe make-sample 1 "o\fuzz\template_source.txt" | Out-Null
if ($LASTEXITCODE -ne 0) { throw "FUZZ_SETUP_TEMPLATE_SAMPLE_FAILED" }
& $exe compress "o\fuzz\template_source.txt" "o\fuzz\template_valid.byg" | Out-Null
if ($LASTEXITCODE -ne 0) { throw "FUZZ_SETUP_TEMPLATE_COMPRESS_FAILED" }
& $exe make-sample 25 "o\fuzz\stored_source.txt" | Out-Null
if ($LASTEXITCODE -ne 0) { throw "FUZZ_SETUP_STORED_SAMPLE_FAILED" }
& $exe compress "o\fuzz\stored_source.txt" "o\fuzz\stored_valid.byg" | Out-Null
if ($LASTEXITCODE -ne 0) { throw "FUZZ_SETUP_STORED_COMPRESS_FAILED" }
& $exe make-sample 1 "o\fuzz\fallback_source.txt" | Out-Null
if ($LASTEXITCODE -ne 0) { throw "FUZZ_SETUP_FALLBACK_SAMPLE_FAILED" }
Add-Content -LiteralPath "o\fuzz\fallback_source.txt" -Encoding UTF8 -Value "v3.4 corruption mutation marker that breaks exact template equality while remaining compressible."
& $exe compress "o\fuzz\fallback_source.txt" "o\fuzz\fallback_valid.byg" | Out-Null
if ($LASTEXITCODE -ne 0) { throw "FUZZ_SETUP_FALLBACK_COMPRESS_FAILED" }

[byte[]]$templateBytes = [System.IO.File]::ReadAllBytes((Join-Path $PWD "o\fuzz\template_valid.byg"))
[byte[]]$storedBytes = [System.IO.File]::ReadAllBytes((Join-Path $PWD "o\fuzz\stored_valid.byg"))
[byte[]]$fallbackBytes = [System.IO.File]::ReadAllBytes((Join-Path $PWD "o\fuzz\fallback_valid.byg"))

Write-FuzzBytes "o\fuzz\too_small.byg" ([byte[]](1,2,3,4))
$badMagic = Copy-ByteArray $templateBytes
[byte[]]$badMagicText = [System.Text.Encoding]::ASCII.GetBytes("BADMAGC")
[Array]::Copy($badMagicText, 0, $badMagic, 0, 7)
Write-FuzzBytes "o\fuzz\bad_magic.byg" $badMagic
$unknownBackend = Copy-ByteArray $templateBytes
$unknownBackend[7] = 99
Write-FuzzBytes "o\fuzz\unknown_backend.byg" $unknownBackend
$badTemplate = Copy-ByteArray $templateBytes
$badTemplate[8] = 99
Write-FuzzBytes "o\fuzz\bad_template_id.byg" $badTemplate
$storedTrunc = Truncate-ByteArray $storedBytes 1
Write-FuzzBytes "o\fuzz\stored_truncated.byg" $storedTrunc
$storedChecksum = Copy-ByteArray $storedBytes
$storedChecksum[$storedChecksum.Length - 1] = [byte](($storedChecksum[$storedChecksum.Length - 1] + 1) % 255)
Write-FuzzBytes "o\fuzz\stored_checksum_mismatch.byg" $storedChecksum
$fallbackTrunc = Truncate-ByteArray $fallbackBytes 1
Write-FuzzBytes "o\fuzz\fallback_truncated.byg" $fallbackTrunc

Invoke-CliCase -Name "fuzz_too_small_inspect" -CliArgs @("inspect", "o\fuzz\too_small.byg") -ExpectedExit 1 -ExpectedText "container too small" -UseStdErr
Invoke-CliCase -Name "fuzz_bad_magic_inspect" -CliArgs @("inspect", "o\fuzz\bad_magic.byg") -ExpectedExit 1 -ExpectedText "bad magic" -UseStdErr
Invoke-CliCase -Name "fuzz_unknown_backend_inspect" -CliArgs @("inspect", "o\fuzz\unknown_backend.byg") -ExpectedExit 1 -ExpectedText "unknown backend" -UseStdErr
Invoke-CliCase -Name "fuzz_bad_template_extract" -CliArgs @("extract", "o\fuzz\bad_template_id.byg", "o\fuzz\bad_template.raw") -ExpectedExit 1 -ExpectedText "bad template id" -UseStdErr
Invoke-CliCase -Name "fuzz_stored_truncated_extract" -CliArgs @("extract", "o\fuzz\stored_truncated.byg", "o\fuzz\stored_truncated.raw") -ExpectedExit 1 -ExpectedText "payload truncated" -UseStdErr
Invoke-CliCase -Name "fuzz_stored_checksum_extract" -CliArgs @("extract", "o\fuzz\stored_checksum_mismatch.byg", "o\fuzz\stored_checksum.raw") -ExpectedExit 1 -ExpectedText "checksum mismatch" -UseStdErr
Invoke-CliCase -Name "fuzz_fallback_truncated_extract" -CliArgs @("extract", "o\fuzz\fallback_truncated.byg", "o\fuzz\fallback_truncated.raw") -ExpectedExit 1 -ExpectedText "ERROR:" -UseStdErr

$corruptionReportPath = "o\r\v46_container_corruption_tests.txt"
$corruptionLines = @()
$corruptionLines += "Container fuzz and corruption tests: OK"
$corruptionLines += "too_small inspect: OK"
$corruptionLines += "bad_magic inspect: OK"
$corruptionLines += "unknown_backend inspect: OK"
$corruptionLines += "invalid_template_id extract: OK"
$corruptionLines += "stored_payload_truncated extract: OK"
$corruptionLines += "stored_checksum_mismatch extract: OK"
$corruptionLines += "fallback_payload_truncated extract: OK"
$corruptionReportDir = Split-Path -Parent $corruptionReportPath
if ($corruptionReportDir -and -not (Test-Path -LiteralPath $corruptionReportDir)) {
    New-Item -ItemType Directory -Path $corruptionReportDir -Force | Out-Null
}
$corruptionLines | Set-Content -LiteralPath $corruptionReportPath -Encoding UTF8
Write-Host "Container fuzz and corruption tests OK: magic, backend, template id, payload truncation, checksum mismatch"


foreach ($d in @("s", "s\c", "s\r", "s\m", "o", "o\c", "o\x", "o\z", "o\r", "o\sel", "o\bench")) { New-Dir $d }


# v4.6: large-file and memory guard. The codec still uses whole-file buffers in
# this prototype, so this guard does not claim true streaming implementation.
# It verifies that larger inputs remain deterministic, roundtrip-safe, and do
# not regress into ZIP payload when ZIP dependency is forced unavailable.
function Write-LargeGuardBytes($Path, [int]$Length, [int]$Seed) {
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    $bytes = New-Object byte[] $Length
    # v4.6 preserves hotfix: use .NET Random for deterministic test bytes instead of
    # PowerShell bitwise UInt32/UInt64 arithmetic. Windows PowerShell treats
    # 0xffffffff as signed -1 in some expressions, which can break UInt64 casts.
    $rng = New-Object System.Random($Seed)
    $rng.NextBytes($bytes)
    [System.IO.File]::WriteAllBytes((Join-Path $PWD $Path), $bytes)
}
function Invoke-LargeRoundtripCase {
    param(
        [string]$Name,
        [string]$SourcePath,
        [switch]$ForceNoZip
    )
    $prefix = if ($ForceNoZip) { "forced_" } else { "normal_" }
    $safe = Safe-Name($Name)
    $bygPath = Join-Path "o\large" ($prefix + $safe + ".byg")
    $rawPath = Join-Path "o\large" ($prefix + $safe + ".raw")
    $inspectPath = Join-Path "o\large" ($prefix + $safe + ".inspect.txt")
    $oldForce = $env:BYG_FORCE_NO_ZIP
    try {
        if ($ForceNoZip) { $env:BYG_FORCE_NO_ZIP = "1" } else { Remove-Item Env:BYG_FORCE_NO_ZIP -ErrorAction SilentlyContinue }
        & $exe compress $SourcePath $bygPath | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "LARGE_COMPRESS_FAIL: $Name force=$ForceNoZip" }
        & $exe extract $bygPath $rawPath | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "LARGE_EXTRACT_FAIL: $Name force=$ForceNoZip" }
        & $exe inspect $bygPath | Set-Content -LiteralPath $inspectPath -Encoding UTF8
        if ($LASTEXITCODE -ne 0) { throw "LARGE_INSPECT_FAIL: $Name force=$ForceNoZip" }
    } finally {
        if ($null -eq $oldForce) { Remove-Item Env:BYG_FORCE_NO_ZIP -ErrorAction SilentlyContinue } else { $env:BYG_FORCE_NO_ZIP = $oldForce }
    }
    $srcSha = Get-Sha $SourcePath
    $rawSha = Get-Sha $rawPath
    if ($srcSha -ne $rawSha) { throw "LARGE_ROUNDTRIP_SHA_FAIL: $Name force=$ForceNoZip" }
    $rawSize = Get-Size $SourcePath
    $containerSize = Get-Size $bygPath
    $inspect = Read-KvFile $inspectPath
    $submode = [string]$inspect["payload_submode"]
    if ($ForceNoZip -and $submode -eq "fallback_zip_payload") { throw "LARGE_FORCED_ZIP_PAYLOAD_FAIL: $Name" }
    return [pscustomobject]@{
        name=$Name; force_no_zip=[bool]$ForceNoZip; raw=$rawSize; container=$containerSize;
        backend=[string]$inspect["backend"]; payload_submode=$submode; decision_reason=[string]$inspect["decision_reason"];
        zip_dependency_available=[string]$inspect["zip_dependency_available"]; sha_ok=$true
    }
}

New-Item -ItemType Directory -Path "s\large", "o\large", "o\r" -Force | Out-Null
$largeText = New-Object System.Text.StringBuilder
for ($i = 0; $i -lt 18000; $i++) {
    [void]$largeText.Append("large text corpus line ")
    [void]$largeText.Append($i)
    [void]$largeText.Append(" :: BYG v4.6 streaming guard repeated semantic text payload for compression ratio stability.`n")
}
Write-Utf8NoBom "s\large\large_text_corpus.txt" $largeText.ToString()
$patternBuilder = New-Object System.Text.StringBuilder
for ($i = 0; $i -lt 22000; $i++) { [void]$patternBuilder.Append("ABCD-1234-BYG-LARGE-PATTERN-") }
Write-Utf8NoBom "s\large\large_repeated_pattern.txt" $patternBuilder.ToString()
Write-LargeGuardBytes "s\large\large_binary_entropy.bin" 524288 1337
$mixed = New-Object System.Collections.Generic.List[byte]
$mixedText = [System.Text.Encoding]::UTF8.GetBytes("BYG mixed block header v4.5`n")
for ($block = 0; $block -lt 1024; $block++) {
    $mixed.AddRange($mixedText)
    for ($j = 0; $j -lt 256; $j++) { $mixed.Add([byte](($block + $j) -band 255)) }
    $mixed.AddRange([byte[]](65,66,67,68,49,50,51,52))
}
Write-Bytes "s\large\large_mixed_block.bin" ([byte[]]$mixed.ToArray())

$largeCases = @(
    @{ name="large_text_corpus"; path="s\large\large_text_corpus.txt" },
    @{ name="large_repeated_pattern"; path="s\large\large_repeated_pattern.txt" },
    @{ name="large_binary_entropy"; path="s\large\large_binary_entropy.bin" },
    @{ name="large_mixed_block"; path="s\large\large_mixed_block.bin" }
)
$largeRows = @()
foreach ($case in $largeCases) {
    $largeRows += Invoke-LargeRoundtripCase -Name $case.name -SourcePath $case.path
    $largeRows += Invoke-LargeRoundtripCase -Name $case.name -SourcePath $case.path -ForceNoZip
}
$largeRoundtripOk = ($largeRows | Where-Object { $_.sha_ok }).Count
if ($largeRoundtripOk -ne 8) { throw "LARGE_ROUNDTRIP_COUNT_FAIL: $largeRoundtripOk/8" }
$largeForcedZipPayload = ($largeRows | Where-Object { $_.force_no_zip -and $_.payload_submode -eq "fallback_zip_payload" }).Count
if ($largeForcedZipPayload -ne 0) { throw "LARGE_FORCED_ZIP_PAYLOAD_COUNT_FAIL: $largeForcedZipPayload" }
$largeReportPath = "o\r\v46_large_file_memory_guard.txt"
$largeRows | Select-Object name,force_no_zip,raw,container,backend,payload_submode,decision_reason,zip_dependency_available,sha_ok | Format-Table -AutoSize | Out-String | Set-Content -LiteralPath $largeReportPath -Encoding UTF8
Write-Host "Large-file and memory guard OK: 4 samples, normal+forced no-ZIP roundtrip 8/8, forced fallback_zip_payload=0"


$controlledNames = @(
"01_code_cpp_engine.cpp", "02_code_python_pipeline.py", "03_code_js_dashboard.js",
"04_story_turkish_mystery.txt", "05_daily_chat_mixed_tr.txt", "06_lise_sinavi_deneme.txt",
"07_doktor_raporu_sentetik.txt", "08_dataset_game_events.csv", "09_dataset_orders.json",
"10_server_log_rotating.txt", "11_nginx_access.log", "12_markdown_design.md", "13_html_report.html",
"14_css_stylesheet.css", "15_sql_dump.sql", "16_xml_catalog.xml", "17_yaml_services.yml",
"18_finans_defteri.csv", "19_hukuk_sozlesme_taslak.txt", "20_protocol_spec_frames.txt",
"21_hex_dump_mixed.txt", "22_base64_payload.txt", "23_random_entropy.bin", "24_low_entropy_binary.bin",
"25_tiny_note.txt", "26_gps_route_dataset.csv", "27_game_save_inventory.jsonl",
"28_iot_sensor_timeseries.csv", "29_email_mbox.txt", "30_project_manifest_jsonl.txt"
)

$rows = @()
$controlledByg = 0
$controlledBygz = 0
$controlledZip = 0
$controlledAny = 0
$selectorCorrect = 0
$totalRows = 0
$templateHeaderTotal = 0
$templateHeaderCount = 0
$storedHeaderTotal = 0
$storedHeaderCount = 0
$fallbackHeaderTotal = 0
$fallbackHeaderCount = 0
$roundtripOK = 0
$submodeCounts = @{}
$reasonCounts = @{}
$payloadFlagCounts = @{}
$zipDependencyCounts = @{}
$zipDependencyAvailableCounts = @{}

Write-Host "Selftest starting: v4.6 real dataset benchmark suite, controlled 30 samples plus expanded real corpus"
Write-Host "=========================================================================================================================================================================="

for ($i = 1; $i -le 30; $i++) {
    $name = $controlledNames[$i - 1]
    $safe = ("c" + $i.ToString("00"))
    $srcPath = Join-Path "s\c" $name
    $bygPath = Join-Path "o\c" ($safe + ".byg")
    $restPath = Join-Path "o\x" ($safe + ".raw")
    $zipPath = Join-Path "o\z" ($safe + ".zip")
    $inspectPath = Join-Path "o\r" ($safe + ".inspect.txt")
    $selectPath = Join-Path "o\sel" ($safe + ".select.txt")

    & $exe make-sample $i $srcPath | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "make-sample failed: $name" }
    & $exe compress $srcPath $bygPath | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "compress failed: $name" }
    & $exe extract $bygPath $restPath | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "extract failed: $name" }
    & $exe inspect $bygPath > $inspectPath 2>&1
    if ($LASTEXITCODE -ne 0) { throw "inspect failed: $name" }
    & $exe select $srcPath > $selectPath 2>&1
    if ($LASTEXITCODE -ne 0) { throw "select failed: $name" }

    Make-Zip $srcPath $zipPath

    $shaA = Get-Sha $srcPath
    $shaB = Get-Sha $restPath
    if ($shaA -ne $shaB) { throw "roundtrip mismatch: $name" }
    $roundtripOK++

    $rawSize = Get-Size $srcPath
    $selectedSize = Get-Size $bygPath
    $zipSize = Get-Size $zipPath
    $inspect = Read-KvFile $inspectPath
    $select = Read-KvFile $selectPath
    $backend = $inspect["selected_backend"]
    $payloadSubmode = $inspect["payload_submode"]
    if (-not $payloadSubmode) { $payloadSubmode = "unknown" }
    $decisionReason = $inspect["decision_reason"]
    if (-not $decisionReason) { $decisionReason = $select["decision_reason"] }
    if (-not $decisionReason) { $decisionReason = "unknown" }
    $zipDependency = $inspect["zip_dependency"]
    if (-not $zipDependency) { $zipDependency = $select["zip_dependency"] }
    if (-not $zipDependency) { $zipDependency = "unknown" }
    $zipDependencyAvailable = $inspect["zip_dependency_available"]
    if (-not $zipDependencyAvailable) { $zipDependencyAvailable = $select["zip_dependency_available"] }
    if (-not $zipDependencyAvailable) { $zipDependencyAvailable = "unknown" }
    $payloadFlag = $inspect["container_payload_flag"]
    if (-not $payloadFlag) { $payloadFlag = "not_applicable" }
    if (-not $submodeCounts.ContainsKey($payloadSubmode)) { $submodeCounts[$payloadSubmode] = 0 }
    $submodeCounts[$payloadSubmode]++
    if (-not $reasonCounts.ContainsKey($decisionReason)) { $reasonCounts[$decisionReason] = 0 }
    $reasonCounts[$decisionReason]++
    if (-not $payloadFlagCounts.ContainsKey($payloadFlag)) { $payloadFlagCounts[$payloadFlag] = 0 }
    $payloadFlagCounts[$payloadFlag]++
    if (-not $zipDependencyCounts.ContainsKey($zipDependency)) { $zipDependencyCounts[$zipDependency] = 0 }
    $zipDependencyCounts[$zipDependency]++
    if (-not $zipDependencyAvailableCounts.ContainsKey($zipDependencyAvailable)) { $zipDependencyAvailableCounts[$zipDependencyAvailable] = 0 }
    $zipDependencyAvailableCounts[$zipDependencyAvailable]++
    $hint = $select["selected_backend"]
    $hintSubmode = $select["payload_submode"]
    $headerSize = [int64]$inspect["header_size"]
    $payloadSize = [int64]$inspect["payload_size"]
    $overheadVsZip = $selectedSize - $zipSize
    $winner = "ZIP"
    if ($selectedSize -lt $zipSize) { $winner = "BYG" }
    if ($backend -eq "BYGZ_TEMPLATE") { $winner = "BYGZ" }

    if ($winner -eq "BYG") { $controlledByg++ }
    if ($winner -eq "BYGZ") { $controlledBygz++ }
    if ($winner -eq "ZIP") { $controlledZip++ }
    if ($selectedSize -lt $zipSize) { $controlledAny++ }
    if ($hint -eq $backend) { $selectorCorrect++ }
    $totalRows++

    if ($backend -eq "BYGZ_TEMPLATE") { $templateHeaderTotal += $headerSize; $templateHeaderCount++ }
    elseif ($backend -eq "BYG_STORED") { $storedHeaderTotal += $headerSize; $storedHeaderCount++ }
    else { $fallbackHeaderTotal += $headerSize; $fallbackHeaderCount++ }

    $rows += [pscustomobject]@{ phase="controlled"; group="controlled"; name=$name; raw=$rawSize; selected=$selectedSize; zip=$zipSize; winner=$winner; backend=$backend; payload_submode=$payloadSubmode; decision_reason=$decisionReason; zip_dependency=$zipDependency; zip_dependency_available=$zipDependencyAvailable; container_payload_flag=$payloadFlag; hint=$hint; hint_submode=$hintSubmode; hint_ok=($hint -eq $backend); header=$headerSize; payload=$payloadSize; overhead_vs_zip=$overheadVsZip; suspicious=$false }
    "{0,-35} raw={1,8} selected={2,8} zip={3,8} winner={4,-4} backend={5,-14} submode={6,-20} header={7,3} payload={8,8} ovh_zip={9,7} ok=True" -f $name,$rawSize,$selectedSize,$zipSize,$winner,$backend,$payloadSubmode,$headerSize,$payloadSize,$overheadVsZip
}

Write-Host "=========================================================================================================================================================================="
Write-Host "Real corpus overhead validation starting"
Write-Host "=========================================================================================================================================================================="

$realSamples = @()

$cpp = @"
#include <iostream>
#include <vector>
#include <string>
struct Node { std::string name; int value; };
int main(){
    std::vector<Node> nodes;
    for(int i=0;i<1200;i++) nodes.push_back({"node_"+std::to_string(i%37), i*31%997});
    long long sum=0;
    for(const auto& n: nodes) sum += n.value;
    std::cout << sum << std::endl;
}
"@
Write-Utf8NoBom "s\r\real_cpp_project.cpp" (($cpp + "`n") * 32)
$realSamples += @{ group="realish"; name="real_cpp_project.cpp"; path="s\r\real_cpp_project.cpp"; expected="ZIP_FALLBACK" }

$jsonLines = New-Object System.Collections.Generic.List[string]
for ($i=0; $i -lt 2500; $i++) { $jsonLines.Add('{"id":' + $i + ',"user":"u' + ($i % 113) + '","score":' + (($i * 17) % 1000) + ',"tags":["alpha","beta","g' + ($i % 9) + '"],"ok":true}') }
Write-Utf8NoBom "s\r\events.jsonl" ($jsonLines -join "`n")
$realSamples += @{ group="realish"; name="events.jsonl"; path="s\r\events.jsonl"; expected="ZIP_FALLBACK" }

$logLines = New-Object System.Collections.Generic.List[string]
for ($i=0; $i -lt 3000; $i++) {
    $minuteText = ([int]([math]::Floor($i / 60) % 60)).ToString("00")
    $secondText = ([int]($i % 60)).ToString("00")
    $logLines.Add("2026-07-13T12:" + $minuteText + ":" + $secondText + "Z INFO worker=" + ($i % 19) + " route=/api/v1/items/" + ($i % 251) + " status=200 bytes=" + (900 + ($i % 4096)))
}
Write-Utf8NoBom "s\r\server.log" ($logLines -join "`n")
$realSamples += @{ group="realish"; name="server.log"; path="s\r\server.log"; expected="ZIP_FALLBACK" }

$csvLines = New-Object System.Collections.Generic.List[string]
$csvLines.Add("ts,device,temp,humidity,voltage")
for ($i=0; $i -lt 2200; $i++) { $csvLines.Add("2026-07-13T12:$(([int]($i%60)).ToString('00')):00Z,d$($i%73),$([math]::Round(22 + (($i*17)%130)/10,1)),$([math]::Round(40 + (($i*11)%300)/10,1)),$([math]::Round(3.2 + (($i*7)%50)/100,2))") }
Write-Utf8NoBom "s\r\metrics.csv" ($csvLines -join "`n")
$realSamples += @{ group="realish"; name="metrics.csv"; path="s\r\metrics.csv"; expected="ZIP_FALLBACK" }

& $exe make-sample 1 "s\m\c01_base.cpp" | Out-Null
$m1 = [System.IO.File]::ReadAllText((Resolve-Path "s\m\c01_base.cpp"), [System.Text.Encoding]::UTF8) + "`nMUTATION_BREAKS_TEMPLATE_EXACT_MATCH=1`n"
Write-Utf8NoBom "s\m\01_code_cpp_engine_mutated.cpp" $m1
$realSamples += @{ group="mutated"; name="01_code_cpp_engine_mutated.cpp"; path="s\m\01_code_cpp_engine_mutated.cpp"; expected="ZIP_FALLBACK" }

& $exe make-sample 21 "s\m\c21_base.txt" | Out-Null
$m21 = [System.IO.File]::ReadAllText((Resolve-Path "s\m\c21_base.txt"), [System.Text.Encoding]::UTF8) + "`nTHIS_MUTATION_SHOULD_FORCE_SAFE_BEHAVIOR`n"
Write-Utf8NoBom "s\m\21_hex_dump_mixed_mutated.txt" $m21
$realSamples += @{ group="mutated"; name="21_hex_dump_mixed_mutated.txt"; path="s\m\21_hex_dump_mixed_mutated.txt"; expected="ZIP_FALLBACK" }

$rng = [System.Random]::new(12345)
$bytes = New-Object byte[] 32768
$rng.NextBytes($bytes)
Write-Bytes "s\r\random_entropy.bin" $bytes
$realSamples += @{ group="realish"; name="random_entropy.bin"; path="s\r\random_entropy.bin"; expected="BYG_STORED" }

Write-Utf8NoBom "s\r\tiny_note.txt" "mini test note"
$realSamples += @{ group="realish"; name="tiny_note.txt"; path="s\r\tiny_note.txt"; expected="BYG_STORED" }

$mdLines = New-Object System.Collections.Generic.List[string]
for ($i=0; $i -lt 1200; $i++) {
    $mdLines.Add("## Section " + ($i % 37))
    $mdLines.Add("- item: api_" + ($i % 53))
    $mdLines.Add("- result: ok")
    $mdLines.Add("- note: release corpus expansion line " + $i + " with repeated telemetry and docs text")
}
Write-Utf8NoBom "s\r\docs_markdown.md" ($mdLines -join "`n")
$realSamples += @{ group="expanded"; name="docs_markdown.md"; path="s\r\docs_markdown.md"; expected="ZIP_FALLBACK" }

$configLines = New-Object System.Collections.Generic.List[string]
for ($i=0; $i -lt 1800; $i++) {
    $configLines.Add('{"service":"svc' + ($i % 31) + '","env":"prod","limits":{"cpu":' + (($i % 8) + 1) + ',"mem":' + (128 + (($i % 17) * 64)) + '},"flags":["a","b","c"],"path":"/opt/app/' + ($i % 101) + '"}')
}
Write-Utf8NoBom "s\r\config_bundle.jsonl" ($configLines -join "`n")
$realSamples += @{ group="expanded"; name="config_bundle.jsonl"; path="s\r\config_bundle.jsonl"; expected="ZIP_FALLBACK" }

$tsvLines = New-Object System.Collections.Generic.List[string]
$tsvLines.Add("time`tname`tvalue`tstate")
for ($i=0; $i -lt 2500; $i++) {
    $state = if (($i % 3) -eq 0) { "off" } else { "on" }
    $tsvLines.Add("2026-07-14T08:" + (($i % 60).ToString("00")) + ":00Z`tnode_" + ($i % 47) + "`t" + (($i * 13) % 10007) + "`t" + $state)
}
Write-Utf8NoBom "s\r\telemetry.tsv" ($tsvLines -join "`n")
$realSamples += @{ group="expanded"; name="telemetry.tsv"; path="s\r\telemetry.tsv"; expected="ZIP_FALLBACK" }

$rng2 = [System.Random]::new(9981)
$mediumRandom = New-Object byte[] 49152
$rng2.NextBytes($mediumRandom)
Write-Bytes "s\r\medium_random_entropy.bin" $mediumRandom
$realSamples += @{ group="expanded"; name="medium_random_entropy.bin"; path="s\r\medium_random_entropy.bin"; expected="BYG_STORED" }

$rng3 = [System.Random]::new(2048)
$mixedBinary = New-Object byte[] 49152
$rng3.NextBytes($mixedBinary)
Write-Bytes "s\r\mixed_binary_payload.bin" $mixedBinary
$realSamples += @{ group="expanded"; name="mixed_binary_payload.bin"; path="s\r\mixed_binary_payload.bin"; expected="BYG_STORED" }

Write-Utf8NoBom "s\r\tiny_json.json" '{"ok":true,"n":7}'
$realSamples += @{ group="expanded"; name="tiny_json.json"; path="s\r\tiny_json.json"; expected="BYG_STORED" }


$expectedTotal = 30 + $realSamples.Count
$expectedRealCorpusCount = 14
if ($realSamples.Count -lt $expectedRealCorpusCount) { throw "REAL_CORPUS_EXPANSION_SAMPLE_COUNT_TOO_LOW" }

$realSuspicious = 0
$realishLargeTiny = 0
$realSelectorCorrect = 0
$realRoundtrip = 0
$zipFallbackOverheadTotal = 0
$zipFallbackCount = 0
$zipFallbackMaxOverhead = -999999999
$zipFallbackMinOverhead = 999999999

$realIndex = 0
foreach ($s in $realSamples) {
    $realIndex++
    $safe = Safe-Name ($s.group + "_" + $s.name)
    $short = "r" + $realIndex.ToString("00")
    $srcPath = $s.path
    # v2.5.3: keep source filenames realistic, but keep all generated output paths short.
    # This avoids Windows/Bridge long-path failures in compress/extract/inspect/select artifacts.
    $bygPath = Join-Path "o\c" ($short + ".byg")
    $restPath = Join-Path "o\x" ($short + ".raw")
    $zipPath = Join-Path "o\z" ($short + ".zip")
    $inspectPath = Join-Path "o\r" ($short + ".inspect.txt")
    $selectPath = Join-Path "o\sel" ($short + ".select.txt")

    & $exe compress $srcPath $bygPath | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "compress failed: $($s.group)/$($s.name)" }
    & $exe extract $bygPath $restPath | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "extract failed: $($s.group)/$($s.name)" }
    & $exe inspect $bygPath > $inspectPath 2>&1
    if ($LASTEXITCODE -ne 0) { throw "inspect failed: $($s.group)/$($s.name)" }
    & $exe select $srcPath > $selectPath 2>&1
    if ($LASTEXITCODE -ne 0) { throw "select failed: $($s.group)/$($s.name)" }
    Make-Zip $srcPath $zipPath

    if ((Get-Sha $srcPath) -ne (Get-Sha $restPath)) { throw "roundtrip mismatch: $($s.group)/$($s.name)" }
    $realRoundtrip++

    $rawSize = Get-Size $srcPath
    $selectedSize = Get-Size $bygPath
    $zipSize = Get-Size $zipPath
    $inspect = Read-KvFile $inspectPath
    $select = Read-KvFile $selectPath
    $backend = $inspect["selected_backend"]
    $payloadSubmode = $inspect["payload_submode"]
    if (-not $payloadSubmode) { $payloadSubmode = "unknown" }
    $decisionReason = $inspect["decision_reason"]
    if (-not $decisionReason) { $decisionReason = $select["decision_reason"] }
    if (-not $decisionReason) { $decisionReason = "unknown" }
    $zipDependency = $inspect["zip_dependency"]
    if (-not $zipDependency) { $zipDependency = $select["zip_dependency"] }
    if (-not $zipDependency) { $zipDependency = "unknown" }
    $zipDependencyAvailable = $inspect["zip_dependency_available"]
    if (-not $zipDependencyAvailable) { $zipDependencyAvailable = $select["zip_dependency_available"] }
    if (-not $zipDependencyAvailable) { $zipDependencyAvailable = "unknown" }
    $payloadFlag = $inspect["container_payload_flag"]
    if (-not $payloadFlag) { $payloadFlag = "not_applicable" }
    if (-not $submodeCounts.ContainsKey($payloadSubmode)) { $submodeCounts[$payloadSubmode] = 0 }
    $submodeCounts[$payloadSubmode]++
    if (-not $reasonCounts.ContainsKey($decisionReason)) { $reasonCounts[$decisionReason] = 0 }
    $reasonCounts[$decisionReason]++
    if (-not $payloadFlagCounts.ContainsKey($payloadFlag)) { $payloadFlagCounts[$payloadFlag] = 0 }
    $payloadFlagCounts[$payloadFlag]++
    if (-not $zipDependencyCounts.ContainsKey($zipDependency)) { $zipDependencyCounts[$zipDependency] = 0 }
    $zipDependencyCounts[$zipDependency]++
    if (-not $zipDependencyAvailableCounts.ContainsKey($zipDependencyAvailable)) { $zipDependencyAvailableCounts[$zipDependencyAvailable] = 0 }
    $zipDependencyAvailableCounts[$zipDependencyAvailable]++
    $hint = $select["selected_backend"]
    $hintSubmode = $select["payload_submode"]
    $headerSize = [int64]$inspect["header_size"]
    $payloadSize = [int64]$inspect["payload_size"]
    $overheadVsZip = $selectedSize - $zipSize
    $suspicious = ($rawSize -gt 10000 -and $selectedSize -le 64 -and $s.group -ne "controlled")
    if ($suspicious) { $realSuspicious++ }
    if ($suspicious -and $s.group -eq "realish") { $realishLargeTiny++ }
    if ($backend -eq $s.expected) { $realSelectorCorrect++ }
    if ($hint -eq $backend) { $selectorCorrect++ }
    $totalRows++

    if ($backend -eq "BYGZ_TEMPLATE") { $templateHeaderTotal += $headerSize; $templateHeaderCount++ }
    elseif ($backend -eq "BYG_STORED") { $storedHeaderTotal += $headerSize; $storedHeaderCount++ }
    else { $fallbackHeaderTotal += $headerSize; $fallbackHeaderCount++; $zipFallbackOverheadTotal += $overheadVsZip; $zipFallbackCount++; if ($overheadVsZip -gt $zipFallbackMaxOverhead) { $zipFallbackMaxOverhead = $overheadVsZip }; if ($overheadVsZip -lt $zipFallbackMinOverhead) { $zipFallbackMinOverhead = $overheadVsZip } }

    $winner = "ZIP"
    if ($selectedSize -lt $zipSize) { $winner = "BYG" }
    if ($backend -eq "BYGZ_TEMPLATE") { $winner = "BYGZ" }

    $rows += [pscustomobject]@{ phase="real"; group=$s.group; name=$s.name; raw=$rawSize; selected=$selectedSize; zip=$zipSize; winner=$winner; backend=$backend; payload_submode=$payloadSubmode; decision_reason=$decisionReason; zip_dependency=$zipDependency; zip_dependency_available=$zipDependencyAvailable; container_payload_flag=$payloadFlag; hint=$hint; hint_submode=$hintSubmode; hint_ok=($hint -eq $backend); expected=$s.expected; expected_ok=($backend -eq $s.expected); header=$headerSize; payload=$payloadSize; overhead_vs_zip=$overheadVsZip; suspicious=$suspicious }
    "{0,-10} {1,-36} raw={2,8} selected={3,8} zip={4,8} winner={5,-4} backend={6,-14} submode={7,-20} header={8,3} payload={9,8} ovh_zip={10,7} expected_ok={11} suspicious={12}" -f $s.group,$s.name,$rawSize,$selectedSize,$zipSize,$winner,$backend,$payloadSubmode,$headerSize,$payloadSize,$overheadVsZip,($backend -eq $s.expected),$suspicious
}

$csvPath = "o\r\v46_container_fuzz_and_corruption_tests_report.csv"
$summaryPath = "o\r\v46_summary.txt"
$benchPath = "o\r\benchmark_real_corpus.txt"
$inspectFirstPath = "o\r\inspect_c01.txt"
$ratioSummaryPath = "o\r\v46_ratio_summary.csv"
$ratioBackendSubmodePath = "o\r\v46_ratio_backend_submode_summary.csv"
$regressionCheckPath = "o\r\v46_regression_baseline_check.txt"
$baselinePath = "REGRESSION_BASELINE_v3_1.json"
$baseline = Get-Content -LiteralPath $baselinePath -Raw | ConvertFrom-Json

$rows = foreach ($r in $rows) {
    $selectedRawRatio = Round-Ratio $r.selected $r.raw 6
    $zipRawRatio = Round-Ratio $r.zip $r.raw 6
    $deltaPct = Round-DeltaPct $r.selected $r.zip
    $r | Select-Object *, @{Name='selected_raw_ratio';Expression={$selectedRawRatio}}, @{Name='zip_raw_ratio';Expression={$zipRawRatio}}, @{Name='byg_vs_zip_delta_percent';Expression={$deltaPct}}
}

$rows | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8

$ratioRows = $rows | ForEach-Object {
    [pscustomobject]@{
        phase=$_.phase; group=$_.group; name=$_.name; backend=$_.backend; payload_submode=$_.payload_submode; raw=$_.raw; selected=$_.selected; zip=$_.zip; selected_raw_ratio=$_.selected_raw_ratio; zip_raw_ratio=$_.zip_raw_ratio; byg_vs_zip_delta_percent=$_.byg_vs_zip_delta_percent
    }
}
$ratioRows | Export-Csv -LiteralPath $ratioSummaryPath -NoTypeInformation -Encoding UTF8

$backendSubmodeSummary = $rows | Group-Object backend,payload_submode | ForEach-Object {
    $g = $_.Group
    $first = $g[0]
    [pscustomobject]@{
        backend=$first.backend
        payload_submode=$first.payload_submode
        count=$g.Count
        avg_selected_raw_ratio=[math]::Round((($g | Measure-Object -Property selected_raw_ratio -Average).Average), 6)
        avg_zip_raw_ratio=[math]::Round((($g | Measure-Object -Property zip_raw_ratio -Average).Average), 6)
        avg_byg_vs_zip_delta_percent=[math]::Round((($g | Measure-Object -Property byg_vs_zip_delta_percent -Average).Average), 2)
    }
}
$backendSubmodeSummary | Export-Csv -LiteralPath $ratioBackendSubmodePath -NoTypeInformation -Encoding UTF8
$ratioOverallSelectedRaw = [math]::Round((($rows | Measure-Object -Property selected_raw_ratio -Average).Average), 6)
$ratioOverallZipRaw = [math]::Round((($rows | Measure-Object -Property zip_raw_ratio -Average).Average), 6)
$ratioOverallDeltaPct = [math]::Round((($rows | Measure-Object -Property byg_vs_zip_delta_percent -Average).Average), 2)
Copy-Item -LiteralPath "o\r\c01.inspect.txt" -Destination $inspectFirstPath -Force
& $exe benchmark "s\r\real_cpp_project.cpp" $benchPath | Out-Null
if ($LASTEXITCODE -ne 0) { throw "benchmark failed" }

$avgTemplateHeader = if ($templateHeaderCount -gt 0) { [math]::Round($templateHeaderTotal / $templateHeaderCount, 2) } else { 0 }
$avgStoredHeader = if ($storedHeaderCount -gt 0) { [math]::Round($storedHeaderTotal / $storedHeaderCount, 2) } else { 0 }
$avgFallbackHeader = if ($fallbackHeaderCount -gt 0) { [math]::Round($fallbackHeaderTotal / $fallbackHeaderCount, 2) } else { 0 }
$avgZipFallbackOverhead = if ($zipFallbackCount -gt 0) { [math]::Round($zipFallbackOverheadTotal / $zipFallbackCount, 2) } else { 0 }

$submodeSummary = (($submodeCounts.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join "; ")
$reasonSummary = (($reasonCounts.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join "; ")
$payloadFlagSummary = (($payloadFlagCounts.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join "; ")
$zipDependencySummary = (($zipDependencyCounts.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join "; ")
$zipAvailabilitySummary = (($zipDependencyAvailableCounts.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join "; ")
$summary = @()
$summary += "BYG Recursive Tokenizer C++ v4.6 negative-api-and-error-contract-tests summary"
$summary += "Controlled samples: 30"
$summary += "Controlled BYG wins: $controlledByg/30"
$summary += "Controlled BYGZ wins: $controlledBygz/30"
$summary += "Controlled ZIP wins: $controlledZip/30"
$summary += "Controlled Any BYG option beats ZIP: $controlledAny/30"
$summary += "Roundtrip OK total: $($roundtripOK + $realRoundtrip)/$expectedTotal"
$summary += "Real corpus samples: $($realSamples.Count)"
$summary += "Real corpus expansion target: $expectedRealCorpusCount"
$summary += "Real roundtrip OK: $realRoundtrip/$($realSamples.Count)"
$summary += "Real suspicious tiny-token count: $realSuspicious"
$summary += "Realish large-file tiny-token count: $realishLargeTiny"
$summary += "Selector hint consistency total: $selectorCorrect/$totalRows"
$summary += "Real expected backend correct: $realSelectorCorrect/$($realSamples.Count)"
$summary += "Template avg header size: $avgTemplateHeader"
$summary += "Stored avg header size: $avgStoredHeader"
$summary += "Fallback avg header size: $avgFallbackHeader"
$summary += "ZIP_FALLBACK avg overhead vs external zip: $avgZipFallbackOverhead"
$summary += "Overall selected/raw ratio avg: $ratioOverallSelectedRaw"
$summary += "Overall zip/raw ratio avg: $ratioOverallZipRaw"
$summary += "Overall BYG vs ZIP delta percent avg: $ratioOverallDeltaPct"
$summary += "Payload submode counts: $submodeSummary"
$summary += "Decision reason counts: $reasonSummary"
$summary += "Container payload flag counts: $payloadFlagSummary"
$summary += "ZIP dependency counts: $zipDependencySummary"
$summary += "ZIP dependency availability counts: $zipAvailabilitySummary"
$summary += "v2.4.1 fallback avg overhead baseline: 16974.43"
$summary += "v4.6 normal-mode fallback max overhead target: <= 50"
$summary += "ZIP_FALLBACK min overhead vs external zip: $zipFallbackMinOverhead"
$summary += "ZIP_FALLBACK max overhead vs external zip: $zipFallbackMaxOverhead"
$summary += "CSV report: $csvPath"
$summary += "Ratio row report: $ratioSummaryPath"
$summary += "Backend/submode ratio report: $ratioBackendSubmodePath"
$summary += "Regression baseline check: $regressionCheckPath"
$summary += "CLI negative tests: $cliNegativeReportPath"
$summary += "Diagnostic dump guard: $diagGuardPath"
$summary += "Dataset benchmark smoke guard: $datasetGuardPath"
$summary += "CLI JSON schema guard: $jsonGuardPath"
$summary += "Library API embedding guard: $apiGuardPath"
$summary += "Cross-version compatibility: $compatReportPath"
$summary += "Container corruption tests: $corruptionReportPath"
$summary += "Large-file memory guard: $largeReportPath"
$summary += "Release manifest audit: $manifestAuditPath"
$summary += "Inspect report: $inspectFirstPath"
$summary += "Benchmark report: $benchPath"
$summary | Set-Content -LiteralPath $summaryPath -Encoding UTF8

Write-Host "=========================================================================================================================================================================="
Write-Host "Controlled samples                    : 30"
Write-Host "Controlled BYG wins                   : $controlledByg/30"
Write-Host "Controlled BYGZ wins                  : $controlledBygz/30"
Write-Host "Controlled ZIP wins                   : $controlledZip/30"
Write-Host "Controlled Any BYG option beats ZIP   : $controlledAny/30"
Write-Host "Roundtrip OK total                    : $($roundtripOK + $realRoundtrip)/$expectedTotal"
Write-Host "Real corpus samples                   : $($realSamples.Count)"
Write-Host "Real corpus expansion target          : $expectedRealCorpusCount"
Write-Host "Real roundtrip OK                     : $realRoundtrip/$($realSamples.Count)"
Write-Host "Real suspicious tiny-token count      : $realSuspicious"
Write-Host "Realish large-file tiny-token count   : $realishLargeTiny"
Write-Host "Selector hint consistency total       : $selectorCorrect/$totalRows"
Write-Host "Real expected backend correct         : $realSelectorCorrect/$($realSamples.Count)"
Write-Host "Template avg header size              : $avgTemplateHeader"
Write-Host "Stored avg header size                : $avgStoredHeader"
Write-Host "Fallback avg header size              : $avgFallbackHeader"
Write-Host "ZIP_FALLBACK avg overhead vs zip      : $avgZipFallbackOverhead"
Write-Host "Overall selected/raw ratio avg        : $ratioOverallSelectedRaw"
Write-Host "Overall zip/raw ratio avg             : $ratioOverallZipRaw"
Write-Host "Overall BYG vs ZIP delta percent avg  : $ratioOverallDeltaPct"
Write-Host "Payload submode counts               : $submodeSummary"
Write-Host "Decision reason counts               : $reasonSummary"
Write-Host "Container payload flag counts        : $payloadFlagSummary"
Write-Host "ZIP dependency counts                : $zipDependencySummary"
Write-Host "ZIP dependency availability counts   : $zipAvailabilitySummary"
Write-Host "v2.4.1 fallback avg overhead baseline : 16974.43"
Write-Host "v4.6 normal-mode fallback max overhead target     : <= 50"
Write-Host "ZIP_FALLBACK min overhead vs zip      : $zipFallbackMinOverhead"
Write-Host "ZIP_FALLBACK max overhead vs zip      : $zipFallbackMaxOverhead"
Write-Host "CSV report                            : $csvPath"
Write-Host "Ratio row report                      : $ratioSummaryPath"
Write-Host "Backend/submode ratio report          : $ratioBackendSubmodePath"
Write-Host "Regression baseline check             : $regressionCheckPath"
Write-Host "CLI negative tests                   : $cliNegativeReportPath"
Write-Host "Diagnostic dump guard               : $diagGuardPath"
Write-Host "Dataset benchmark smoke guard       : $datasetGuardPath"
Write-Host "CLI JSON schema guard                : $jsonGuardPath"
Write-Host "Library API embedding guard          : $apiGuardPath"
Write-Host "Cross-version compatibility          : $compatReportPath"
Write-Host "Container corruption tests           : $corruptionReportPath"
Write-Host "Large-file memory guard              : $largeReportPath"
Write-Host "Release manifest audit               : $manifestAuditPath"
Write-Host "Summary report                        : $summaryPath"
Write-Host "Inspect report                        : $inspectFirstPath"
Write-Host "Benchmark report                      : $benchPath"

if (($roundtripOK + $realRoundtrip) -ne $expectedTotal) { throw "ROUNDTRIP_FAIL" }
if ($realSuspicious -ne 0) { throw "SUSPICIOUS_TINY_TOKEN_FAIL" }
if ($realishLargeTiny -ne 0) { throw "REALISH_LARGE_TINY_TOKEN_FAIL" }
if ($realSelectorCorrect -ne $realSamples.Count) { throw "REAL_EXPECTED_BACKEND_FAIL" }
if ($templateHeaderCount -gt 0 -and $avgTemplateHeader -gt 20) { throw "TEMPLATE_HEADER_TOO_LARGE" }
if ($zipFallbackCount -gt 0 -and $avgZipFallbackOverhead -ge 12000) { throw "FALLBACK_AVG_OVERHEAD_NOT_IMPROVED" }
if ($zipFallbackMaxOverhead -gt 50) { throw "FALLBACK_MAX_OVERHEAD_NOT_TRANSPARENTLY_CAPPED_BELOW_50" }
if ($avgZipFallbackOverhead -ge 0) { throw "FALLBACK_AVG_OVERHEAD_NOT_NEGATIVE" }
if (-not $submodeCounts.ContainsKey("fallback_zip_payload") -or $submodeCounts["fallback_zip_payload"] -lt 6) { throw "FALLBACK_ZIP_PAYLOAD_SUBMODE_NOT_REPORTED" }
if (-not $submodeCounts.ContainsKey("fallback_lz") -or $submodeCounts["fallback_lz"] -lt 3) { throw "FALLBACK_LZ_SUBMODE_NOT_REPORTED" }
if (-not $zipDependencyCounts.ContainsKey("powershell_compress_archive_expand_archive")) { throw "ZIP_DEPENDENCY_NOT_REPORTED" }
if (-not $payloadFlagCounts.ContainsKey("backend_byte_4_fallback_zip_payload") -or $payloadFlagCounts["backend_byte_4_fallback_zip_payload"] -lt 6) { throw "ZIP_PAYLOAD_FLAG_NOT_REPORTED" }
if (-not $zipDependencyAvailableCounts.ContainsKey("true")) { throw "ZIP_DEPENDENCY_AVAILABILITY_NOT_REPORTED_TRUE" }

$baselineExpectedTotal = [int]$baseline.expected_total
$baselineRealCorpus = [int]$baseline.real_corpus_samples
$baselineMaxOverhead = [int]$baseline.normal_zipfallback_max_overhead_vs_zip
$baselineAvgOverhead = [double]$baseline.normal_zipfallback_avg_overhead_vs_zip
$normalRoundtripTotal = $roundtripOK + $realRoundtrip
$regressionLines = @()
$regressionLines += "Regression baseline source: $baselinePath"
$regressionLines += "Baseline version: $($baseline.version)"
$regressionLines += "Normal roundtrip total: $normalRoundtripTotal/$expectedTotal; baseline expected_total=$baselineExpectedTotal"
$regressionLines += "Real corpus samples: $($realSamples.Count); baseline=$baselineRealCorpus"
$regressionLines += "Selector consistency: $selectorCorrect/$totalRows; baseline expected_total=$baselineExpectedTotal"
$regressionLines += "ZIP_FALLBACK max overhead: $zipFallbackMaxOverhead; baseline=$baselineMaxOverhead; hard_cap=50"
$regressionLines += "ZIP_FALLBACK avg overhead: $avgZipFallbackOverhead; baseline=$baselineAvgOverhead"
$regressionLines += "Overall selected/raw ratio avg: $ratioOverallSelectedRaw"
$regressionLines += "Overall zip/raw ratio avg: $ratioOverallZipRaw"
$regressionLines += "Overall BYG vs ZIP delta percent avg: $ratioOverallDeltaPct"
$regressionLines | Set-Content -LiteralPath $regressionCheckPath -Encoding UTF8
if ($normalRoundtripTotal -lt $baselineExpectedTotal) { throw "REGRESSION_BASELINE_ROUNDTRIP_REGRESSED" }
if ($realSamples.Count -lt $baselineRealCorpus) { throw "REGRESSION_BASELINE_REAL_CORPUS_REGRESSED" }
if ($selectorCorrect -lt $baselineExpectedTotal) { throw "REGRESSION_BASELINE_SELECTOR_REGRESSED" }
if ($zipFallbackMaxOverhead -gt 50) { throw "REGRESSION_BASELINE_MAX_OVERHEAD_HARD_CAP_REGRESSED" }
if ($zipFallbackMaxOverhead -gt [math]::Max($baselineMaxOverhead, 50)) { throw "REGRESSION_BASELINE_MAX_OVERHEAD_REGRESSED" }
if ($avgZipFallbackOverhead -ge 0) { throw "REGRESSION_BASELINE_AVG_OVERHEAD_REGRESSED" }
Write-Host "Regression baseline guard             : OK against $baselinePath"

Write-Host "=========================================================================================================================================================================="
Write-Host "Forced no-ZIP dependency validation starting"
Write-Host "=========================================================================================================================================================================="

$env:BYG_FORCE_NO_ZIP = "1"
$noZipRoundtrip = 0
$noZipSelectorCorrect = 0
$noZipExpectedCorrect = 0
$noZipFallbackZipPayloadCount = 0
$noZipFallbackLzCount = 0
$noZipStoredCount = 0
$noZipTemplateCount = 0
$noZipDependencyFalseCount = 0
$noZipUnavailableReasonCount = 0
$noZipRows = @()

for ($i = 1; $i -le 30; $i++) {
    $name = $controlledNames[$i - 1]
    $safe = "nz_c" + $i.ToString("00")
    $srcPath = Join-Path "s\c" $name
    $bygPath = Join-Path "o\nozip" ($safe + ".byg")
    $restPath = Join-Path "o\nozip" ($safe + ".raw")
    $inspectPath = Join-Path "o\nozip" ($safe + ".inspect.txt")
    $selectPath = Join-Path "o\nozip" ($safe + ".select.txt")
    & $exe compress $srcPath $bygPath | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "nozip compress failed: $name" }
    & $exe extract $bygPath $restPath | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "nozip extract failed: $name" }
    & $exe inspect $bygPath > $inspectPath 2>&1
    if ($LASTEXITCODE -ne 0) { throw "nozip inspect failed: $name" }
    & $exe select $srcPath > $selectPath 2>&1
    if ($LASTEXITCODE -ne 0) { throw "nozip select failed: $name" }
    if ((Get-Sha $srcPath) -ne (Get-Sha $restPath)) { throw "nozip roundtrip mismatch: $name" }
    $noZipRoundtrip++
    $inspect = Read-KvFile $inspectPath
    $select = Read-KvFile $selectPath
    $backend = $inspect["selected_backend"]
    $sub = $inspect["payload_submode"]
    $avail = $inspect["zip_dependency_available"]
    $reason = $inspect["decision_reason"]
    if ($sub -eq "fallback_zip_payload") { $noZipFallbackZipPayloadCount++ }
    if ($sub -eq "fallback_lz") { $noZipFallbackLzCount++ }
    if ($sub -eq "stored_raw") { $noZipStoredCount++ }
    if ($sub -eq "template_id_only") { $noZipTemplateCount++ }
    if ($avail -eq "false") { $noZipDependencyFalseCount++ }
    if ($reason -eq "zip_dependency_unavailable_lz_fallback") { $noZipUnavailableReasonCount++ }
    if ($select["selected_backend"] -eq $backend) { $noZipSelectorCorrect++ }
    $noZipRows += [pscustomobject]@{ mode="forced_no_zip"; phase="controlled"; name=$name; backend=$backend; payload_submode=$sub; decision_reason=$reason; zip_dependency_available=$avail }
}

$realIndex = 0
foreach ($s in $realSamples) {
    $realIndex++
    $short = "nz_r" + $realIndex.ToString("00")
    $srcPath = $s.path
    $bygPath = Join-Path "o\nozip" ($short + ".byg")
    $restPath = Join-Path "o\nozip" ($short + ".raw")
    $inspectPath = Join-Path "o\nozip" ($short + ".inspect.txt")
    $selectPath = Join-Path "o\nozip" ($short + ".select.txt")
    & $exe compress $srcPath $bygPath | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "nozip compress failed: $($s.group)/$($s.name)" }
    & $exe extract $bygPath $restPath | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "nozip extract failed: $($s.group)/$($s.name)" }
    & $exe inspect $bygPath > $inspectPath 2>&1
    if ($LASTEXITCODE -ne 0) { throw "nozip inspect failed: $($s.group)/$($s.name)" }
    & $exe select $srcPath > $selectPath 2>&1
    if ($LASTEXITCODE -ne 0) { throw "nozip select failed: $($s.group)/$($s.name)" }
    if ((Get-Sha $srcPath) -ne (Get-Sha $restPath)) { throw "nozip roundtrip mismatch: $($s.group)/$($s.name)" }
    $noZipRoundtrip++
    $inspect = Read-KvFile $inspectPath
    $select = Read-KvFile $selectPath
    $backend = $inspect["selected_backend"]
    $sub = $inspect["payload_submode"]
    $avail = $inspect["zip_dependency_available"]
    $reason = $inspect["decision_reason"]
    if ($sub -eq "fallback_zip_payload") { $noZipFallbackZipPayloadCount++ }
    if ($sub -eq "fallback_lz") { $noZipFallbackLzCount++ }
    if ($sub -eq "stored_raw") { $noZipStoredCount++ }
    if ($sub -eq "template_id_only") { $noZipTemplateCount++ }
    if ($avail -eq "false") { $noZipDependencyFalseCount++ }
    if ($reason -eq "zip_dependency_unavailable_lz_fallback") { $noZipUnavailableReasonCount++ }
    if ($select["selected_backend"] -eq $backend) { $noZipSelectorCorrect++ }
    if ($backend -eq $s.expected) { $noZipExpectedCorrect++ }
    $noZipRows += [pscustomobject]@{ mode="forced_no_zip"; phase="real"; group=$s.group; name=$s.name; backend=$backend; payload_submode=$sub; decision_reason=$reason; zip_dependency_available=$avail; expected=$s.expected; expected_ok=($backend -eq $s.expected) }
}

$env:BYG_FORCE_NO_ZIP = $null
$noZipCsvPath = "o\r\v46_forced_no_zip_validation_report.csv"
$noZipRows | Export-Csv -LiteralPath $noZipCsvPath -NoTypeInformation -Encoding UTF8
Add-Content -LiteralPath $summaryPath -Encoding UTF8 -Value "Forced no-ZIP roundtrip OK: $noZipRoundtrip/$expectedTotal"
Add-Content -LiteralPath $summaryPath -Encoding UTF8 -Value "Forced no-ZIP selector consistency: $noZipSelectorCorrect/$expectedTotal"
Add-Content -LiteralPath $summaryPath -Encoding UTF8 -Value "Forced no-ZIP real expected backend correct: $noZipExpectedCorrect/$($realSamples.Count)"
Add-Content -LiteralPath $summaryPath -Encoding UTF8 -Value "Forced no-ZIP fallback_zip_payload count: $noZipFallbackZipPayloadCount"
Add-Content -LiteralPath $summaryPath -Encoding UTF8 -Value "Forced no-ZIP fallback_lz count: $noZipFallbackLzCount"
Add-Content -LiteralPath $summaryPath -Encoding UTF8 -Value "Forced no-ZIP stored_raw count: $noZipStoredCount"
Add-Content -LiteralPath $summaryPath -Encoding UTF8 -Value "Forced no-ZIP template_id_only count: $noZipTemplateCount"
Add-Content -LiteralPath $summaryPath -Encoding UTF8 -Value "Forced no-ZIP dependency availability false count: $noZipDependencyFalseCount"
Add-Content -LiteralPath $summaryPath -Encoding UTF8 -Value "Forced no-ZIP unavailable reason count: $noZipUnavailableReasonCount"
Add-Content -LiteralPath $summaryPath -Encoding UTF8 -Value "Forced no-ZIP CSV report: $noZipCsvPath"

Write-Host "Forced no-ZIP roundtrip OK          : $noZipRoundtrip/$expectedTotal"
Write-Host "Forced no-ZIP selector consistency  : $noZipSelectorCorrect/$expectedTotal"
Write-Host "Forced no-ZIP real expected backend : $noZipExpectedCorrect/$($realSamples.Count)"
Write-Host "Forced no-ZIP fallback_zip_payload  : $noZipFallbackZipPayloadCount"
Write-Host "Forced no-ZIP fallback_lz           : $noZipFallbackLzCount"
Write-Host "Forced no-ZIP stored_raw            : $noZipStoredCount"
Write-Host "Forced no-ZIP template_id_only      : $noZipTemplateCount"
Write-Host "Forced no-ZIP dependency false      : $noZipDependencyFalseCount"
Write-Host "Forced no-ZIP unavailable reasons   : $noZipUnavailableReasonCount"
Write-Host "Forced no-ZIP CSV report            : $noZipCsvPath"

if ($noZipRoundtrip -ne $expectedTotal) { throw "FORCED_NO_ZIP_ROUNDTRIP_FAIL" }
if ($noZipSelectorCorrect -ne $expectedTotal) { throw "FORCED_NO_ZIP_SELECTOR_FAIL" }
if ($noZipExpectedCorrect -ne $realSamples.Count) { throw "FORCED_NO_ZIP_EXPECTED_BACKEND_FAIL" }
if ($noZipFallbackZipPayloadCount -ne 0) { throw "FORCED_NO_ZIP_STILL_USED_ZIP_PAYLOAD" }
if ($noZipFallbackLzCount -lt 9) { throw "FORCED_NO_ZIP_FALLBACK_LZ_NOT_USED_ENOUGH" }
if ($noZipDependencyFalseCount -ne $expectedTotal) { throw "FORCED_NO_ZIP_DEPENDENCY_FALSE_NOT_REPORTED" }
if ($noZipUnavailableReasonCount -lt 9) { throw "FORCED_NO_ZIP_UNAVAILABLE_REASON_NOT_REPORTED" }
if ($noZipRoundtrip -lt [int]$baseline.forced_no_zip_roundtrip_ok) { throw "REGRESSION_BASELINE_FORCED_NO_ZIP_ROUNDTRIP_REGRESSED" }
if ($noZipSelectorCorrect -lt [int]$baseline.forced_no_zip_selector_consistency) { throw "REGRESSION_BASELINE_FORCED_NO_ZIP_SELECTOR_REGRESSED" }
if ($noZipFallbackZipPayloadCount -ne [int]$baseline.forced_no_zip_fallback_zip_payload) { throw "REGRESSION_BASELINE_FORCED_NO_ZIP_ZIP_PAYLOAD_REGRESSED" }
Add-Content -LiteralPath $regressionCheckPath -Encoding UTF8 -Value "Forced no-ZIP roundtrip: $noZipRoundtrip/$expectedTotal"
Add-Content -LiteralPath $regressionCheckPath -Encoding UTF8 -Value "Forced no-ZIP selector: $noZipSelectorCorrect/$expectedTotal"
Add-Content -LiteralPath $regressionCheckPath -Encoding UTF8 -Value "Forced no-ZIP fallback_zip_payload: $noZipFallbackZipPayloadCount"
Add-Content -LiteralPath $regressionCheckPath -Encoding UTF8 -Value "Regression baseline guard: OK"

Write-Host "FINAL: C++ v4.6 real-dataset-benchmark-suite official run_tests completed."
