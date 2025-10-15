# ADR-0001: Flutter Stack & Export Naming Policy

- **Status**: Accepted
- **Date**: 2025-09-25

## Context
The MVP must run entirely on mobile devices without backend dependencies, support offline capture, and render PDFs that mirror official equipment forms. We require on-device OCR to preserve privacy and operate in limited connectivity environments.

## Decision
- Build the application with **Flutter (Dart 3)** as a single codebase for iOS and Android.
- Use **Google ML Kit Text Recognition** for on-device OCR, with abstraction to allow future engines.
- Adopt the `pdf` and `printing` Flutter packages for deterministic PDF rendering and export.
- Persist device data with **Drift** over SQLite for structured offline storage. Drift runs unencrypted in the MVP; keys and sensitive identifiers are protected via OS sandboxing and secure storage references until SQLCipher/field-level encryption is introduced in a later milestone.
- Secure storage holds the latest-session pointer; if secure-storage reads fail or return corrupt data we clear the pointer and surface a warning, preferring a safe retry over stale data usage.
- OCR engines are injected via the `OcrService` abstraction, allowing ML Kit today and alternate providers (on-device LLM, cloud OCR) to be swapped without touching the UI layer.
- Define export naming as `YYYYMMDD/{FormType}/{LastFirst}_{Dept}_{FormType}_{AssetTag}_{timestamp}.pdf`.
- Embed a `template_version` metadata field and suffix filenames with `v{templateVersion}`.

## Consequences
- Flutter enables shared UI/state logic and strong community support for camera/OCR integrations.
- ML Kit provides high accuracy for printed text offline; abstraction allows swapping engines if requirements change.
- The naming convention keeps outputs sortable by date, form type, and person while maintaining uniqueness with timestamps.
- Template versioning in metadata and filenames keeps archives traceable if layouts change.
- Future backend services must honor the same naming/version scheme when ingesting PDFs.

## Follow-up
- Document template versions in `docs/prd.md` once finalized.
- Evaluate fallback OCR libraries during Milestone M1 accuracy bench.
