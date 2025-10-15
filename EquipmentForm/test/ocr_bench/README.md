# OCR Benchmark Dataset

This directory stores assets and documentation for the OCR accuracy suite.

- Primary sample set currently lives in `assets/samples/ocr/eqpt_details/` and ships with the app bundle.
- Each image reflects real capture conditions (mixed lighting, angles, and form types).
- Tests assert both the directory and at least one image file exist to catch missing assets quickly.
- `ground_truth.json` defines expected field values for the benchmark; update it alongside new assets.
- Benchmark reports (`latest_report.md`) capture accuracy, latency, and confusion counts per CI run.
