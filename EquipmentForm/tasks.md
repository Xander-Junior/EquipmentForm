# Milestone -1 — Guardrails & CI

## Tasks
- [x] Copy governance assets into repo (.github, PR template, pre-commit hook)
- [x] Create documentation scaffold (`docs/prd.md`, `adrs/`, `tasks.md`) and link sample flows
- [x] Establish testing directories (`test/golden`, `test/ocr_bench`) with placeholder tests
- [x] Prepare OCR sample dataset folder (`samples/ocr/*`) and document usage
- [x] Draft ADR-0001 covering stack choice and export naming/versioning policy
- [x] Verify CI prerequisites: `flutter analyze`, `flutter test`, golden placeholder, OCR dataset check

## Definition of Ready
- [x] Governance pack available (`/governance`)
- [x] Sample dataset location chosen (`samples/ocr/Eqpt_details`)
- [x] Flutter SDK access confirmed for local CI checks

## Definition of Done
- [x] PRD skeleton committed with core flows
- [x] ADR-0001 committed and referenced from README/tasks
- [x] CI workflow and pre-commit hook operational
- [x] Placeholder tests pass locally (`flutter analyze`, `flutter test`)
- [x] OCR sample dataset documented in `test/ocr_bench/README.md`

---

# Milestone 0 — Flutter Foundation

## Tasks
- [x] Install core tooling dependencies (`go_router`, `flutter_riverpod`, `drift`, `path_provider`, `flutter_secure_storage`, `freezed_annotation`, `json_annotation`, `sqlite3_flutter_libs`)
- [x] Configure project structure under `lib/app`, `lib/data`, and `lib/features/...`
- [x] Implement global error hooks with logging for Flutter and zone errors
- [x] Define route map (`home → formTypeSelect → profileCapture → deviceCapture → review → export`) with stub screens
- [x] Create `Session` model (freezed) and Drift database with repository exposing `save/load`
- [x] Ensure repository leverages secure storage for latest-session pointer
- [x] Add Riverpod providers (`router`, `sessionRepository`, `secureStore`, etc.)
- [x] Write smoke tests: app boot/navigation, repository persistence (including relaunch scenario)
- [x] Update ADR-0001 with Drift encryption note
- [x] Run build runner to generate code, ensure `flutter analyze` and `flutter test` pass

## Definition of Ready
- [x] Milestone -1 guardrails satisfied
- [x] Dependency list confirmed and approved
- [x] Test strategy for navigation & persistence outlined
- [ ] Device for physical verification available (to be coordinated)

## Definition of Done
- [x] Tooling dependencies installed and locked in `pubspec`/`pubspec.lock`
- [x] Route map navigable via stubs; smoke tests verify transitions
- [x] `SessionRepository.save/load` proven with automated tests
- [x] Error hooks log uncaught Flutter and zone errors
- [x] Session persists across relaunch (automated test)
- [x] Physical device verification recorded (boot + save/load)
- [x] `flutter analyze` and `flutter test` succeed in CI

---

# Milestone 1 — OCR Spike

## Tasks
- [x] Configure camera permissions and capture scaffolding for Android/iOS
- [x] Implement `OcrService` interface with no-op default and register via DI
- [x] Add parsing & normalization utilities with unit coverage (asset tags, names)
- [x] Create benchmark harness entry point for OCR accuracy suite referencing sample dataset
- [x] Document benchmark thresholds and success criteria in PRD/tasks
- [x] Add placeholder bench report template under `test/ocr_bench`
- [x] Wire capture UI enhancements (back navigation, tips, re-crop, take/import placeholders)
- [x] Bundle OCR sample assets under `assets/samples/ocr/eqpt_details/`
- [x] Generate PDF v0 for Equipment Received using `pdf` package
- [x] Add diagnostics screen with device/OCR metadata
- [x] Extend benchmark reporting with latency + confusion counts and CI gating
- [x] Integrate ML Kit-backed `OcrServiceMlKit` with DI fallback for non-mobile platforms

## Definition of Ready
- [x] OCR sample dataset available (`assets/samples/ocr/eqpt_details`)
- [x] Target accuracy thresholds agreed and recorded in PRD/tasks
- [ ] Device list for benchmark capture confirmed

## Definition of Done
- [x] Camera permissions active on Android/iOS builds
- [x] `OcrService` abstraction integrated and referenced by capture flow scaffolding
- [x] Normalization utilities tested and ready for M2 reuse
- [x] OCR benchmark harness executes on sample dataset, producing report artifact
- [x] Low-confidence handling strategy captured in docs/UI
- [x] Bench results committed with thresholds met or documented gap
- [x] CI enforces accuracy/latency thresholds on `test/ocr_bench`
- [x] Diagnostics screen exposed via router actions
- [x] PDF v0 (Equipment Received) generated programmatically with unit coverage

---

# Milestone 2 — Equipment Rules & Full Forms

## Tasks
- [x] Implement equipment taxonomy (primary vs accessories) with inline accessory annotations
- [x] Add device-kind rules (Laptop: Asset+Service+WE; Phone: Asset/Serial+IMEI) and per-field validators
- [x] Build normalization helpers (asset tag parser, IMEI, WE) with unit tests
- [x] Define `/EquipmentForm/eqpt_template_ref/field_map.yaml` and bind renderer for Received/Returned/Replaced
- [x] Add goldens for all three PDF outputs using embedded Noto fonts
- [x] Enable real capture (camera/gallery via `image_picker`), HEIC→JPEG conversion, EXIF orientation fix, and pre-processing toggle
- [ ] Introduce diagnostics for capture pipeline (legibility toggle state)
- [x] Document equipment rules in PRD and update ADR-0001 (DI-swappable OCR already noted)
- [x] Draft ADR for SQLCipher rollout plan (M3)

## Definition of Ready
- [x] Sample templates reviewed (`eqpt_template_ref/` PDFs)
- [x] OCR dataset & benchmark thresholds defined
- [ ] Device list for capture validation confirmed (phones with HEIC + JPEG)

## Definition of Done
- [x] Equipment taxonomy enforced in UI/domain (primary rows + accessory inline text)
- [x] Validation + normalization guardrails with unit coverage
- [ ] PDF renderer outputs all form types with goldens (Noto fonts, no warnings)
- [x] Capture flow uses real camera/gallery, handles HEIC/EXIF, and exposes preprocessing toggle
- [x] Latest OCR benchmark report reflects production capture results with thresholds met
- [x] ADR for SQLCipher committed with phased rollout plan
