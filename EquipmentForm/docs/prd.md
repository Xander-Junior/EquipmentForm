# Equipment Form PRD (Draft)

## Purpose
Outline the mobile workflow for capturing equipment lifecycle forms without relying on Microsoft tooling.

## Goals
- Offline-first data capture on company-issued phones.
- Reduce manual template editing errors.
- Generate PDF outputs matching official templates for received, returned, and replaced equipment.

## User Flows
### Equipment Received
- Capture assignee details (name, department, email) via photo/OCR or manual entry.
- Record device identifiers and accessories handed over.
- Export finalized PDF for signature and archive.

### Equipment Returned
- Capture device identifiers being returned and condition notes.
- Confirm accessories checklist.
- Export PDF for handoff confirmation.

### Equipment Replaced
- Capture both old and new device details with labeled photos.
- Record reason for replacement and accessory status.
- Export PDF showing paired old/new records.

## Non-Goals
- No backend integration in MVP.
- No digital signature capture (handled post-export).

## Open Questions
- Final OCR accuracy targets per field.
- Device support matrix and minimum OS versions.

## OCR Benchmarks (M1 Goals)
- Accuracy thresholds enforced in CI:
  - Asset/Service/Serial ≥ 98%
  - Name/Department/Email ≥ 97%
- Latency targets (median ≤ 900 ms, p95 ≤ 1.5 s) captured in automated benchmark report.
- Low-confidence handling: prompt user to re-crop/retake when confidence < 90%.

## Equipment Rules (M2 Scope)
- Distinguish **primary equipment** (laptops, phones, tablets) from **accessories** (adapters, bags, mice).
- Accessories append to the main device line (e.g., “Dell Latitude 7420 WITH ADAPTER”) and **do not** create separate detail rows.
- **Asset Tag format**: `<LOC>-<TYPE>-<NUMBER>` where LOC ∈ {ACC, TAK, LON}, TYPE ∈ {LT, MB, DT, TB}. Normalize user/OCR input to canonical hyphenated form.
- **Device-specific requirements**:
  - Laptops/Desktops: require Asset Tag + Service Tag; capture optional Warranty Expiry (WE) where available.
  - Phones/Tablets: require Asset Tag (if issued) + Serial + IMEI (15 digits).
- **Form-specific structure**:
  - Received/Returned: single primary equipment block; accessories inline.
  - Replaced: two blocks (**NEW** and **OLD**) with full identifier sets; photos labeled per block.
- Export forms must replicate template layout; identifiers printed exactly as “ASSET-TAG: …”, “SERVICE TAG: …”, etc.
