# Dataset benchmark smoke plan

Version: v4.6-real-dataset-benchmark-suite
Magic: BYG46DB

This package adds an extra dataset benchmark smoke guard for AI/dataset-like files.
It is not a claim of universal compression superiority. It checks that diagnostic
metadata, JSONL-style repeated data, telemetry-like CSV data and natural-ish text
can be compressed, diagnosed, extracted and benchmarked with stable reports.

Guard marker: Dataset benchmark smoke guard
Report marker: BYG_DATASET_BENCHMARK_SMOKE_OK
Report target: o\r\v46_dataset_benchmark_smoke.txt

Datasets:
- ai_dataset_conversations.jsonl
- eval_results.jsonl
- telemetry_metrics.csv
- mixed_prompt_archive.txt

Required behavior:
- compress/extract roundtrip hash equality
- diagnose --json parses as byg.diagnose.v1
- benchmark report contains raw_size and selected_size
- average selected/raw ratio is recorded
