# Equipment Model Parser

This module provides a pure parser for legacy equipment make/model strings.

## Overview

`parseMakeModel` accepts a raw string and produces a normalized `EquipmentModel` with `make`, `family`, and `modelNumber` fields. The parser is stateless and side‑effect free except for optional telemetry injections.

### Key rules

- Inputs are trimmed, whitespace collapsed, and capped at 80 characters.
- Tokenization splits on whitespace, hyphen, and underscore.
- Vendor inference prioritises the vendor map, then family keywords. Supported families:
  - Dell: `Latitude`, `Precision`, `XPS`
  - Lenovo: `ThinkPad`, `IdeaPad`
  - HP: `EliteBook`, `ProBook`
- Fast paths catch common “family + model” patterns before more expensive processing.
- Regex coverage includes values such as `Latitude 7420`, `Latitude-7420`, `Lat 7420`, `DELL PRECISION 5560`, `ThinkPad T480`, `LENOVO THINKPAD-X1`, `HP EliteBook 840 G5`, `ProBook-450 G9`, and `XPS 13 9310`.

### Telemetry

`NormalizeTelemetry` lets callers observe parser outcomes (`ok`, `fallback`, `fail`). The default `DevNormalizeTelemetry` keeps in-memory counters for fallback/fail rates and average parse durations. It prints summaries inside assertions so release builds remain silent.

### Adding new patterns

1. Extend the vendor or family maps in `vendor_map.dart`.
2. Add any new fast-path regex if the family needs special handling.
3. Update `normalizer_test.dart` with table-driven cases for the new inputs (covering `ok`, `fallback`, and `fail` expectations).
4. If the family implies a new vendor, add the mapping to `_familyToVendor`.

### Example

```dart
import 'package:equipment_form_app/core/equipment_model/normalizer.dart';

void main() {
  final result = parseMakeModel('Dell Latitude 7420');
  if (result.status == ParseStatus.ok) {
    print('${result.value!.make} ${result.value!.family} ${result.value!.modelNumber}');
  }
}
```

### Telemetry integration

Inject a custom telemetry implementation by passing `telemetry:` to `parseMakeModel`. Implement `NormalizeTelemetry` to hook into production monitoring or analytics as needed.

### Consuming in UI

```dart
import 'package:equipment_form_app/core/config/feature_flags.dart';
import 'package:equipment_form_app/core/equipment_model/label.dart';

final label = readLabelFromJson(equipmentJson);
final text = FeatureFlags.normalizedEquipmentModel && label.isStructured
    ? label.toDisplayUpper()
    : (equipmentJson['makeModel'] as String? ?? '');
```
