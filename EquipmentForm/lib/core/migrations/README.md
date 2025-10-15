# Migration Framework

This module encapsulates JSON-based schema migrations for session-like payloads. Migrations are ordered, idempotent, and operate exclusively on deep copies to avoid partial writes.

## Schema versioning

- Versions are monotonically increasing integers (`SchemaVersion`).
- The current module-level version is declared in `schema.dart` (`kCurrentSchemaVersion`).
- Payloads store their version in `_schemaVersion`; absence implies version `0`.

## Adding a migration

1. Create a file named `migrations_XXXX_description.dart` where `XXXX` is zero-padded (e.g. `0002_new_field.dart`).
2. Implement `Migration` with `from` and `to` (must be consecutive).
3. Append the migration to the list in `registry.dart` in ascending `from` order.
4. Add table-driven tests covering idempotency and edge cases.

## Dry runs

Use `MigrationRegistry.runAll` with `dryRun: true` to inspect transformations without changing the input map. The returned map reflects the would-be result, and telemetry is still emitted.

```dart
import 'package:equipment_form_app/core/migrations/registry.dart';
import 'package:equipment_form_app/core/migrations/schema.dart';
import 'package:equipment_form_app/core/migrations/telemetry.dart';
import 'package:equipment_form_app/core/migrations/migrations_0001_equipment_model.dart';

final registry = MigrationRegistry([
  Migrations0001EquipmentModel(),
]);

final input = {
  "equipment": {"makeModel": "Dell Latitude 7420"},
};

final result = registry.runAll(
  input,
  currentVersion: kCurrentSchemaVersion,
  dryRun: true,
  telemetry: DebugMigrationTelemetry(),
);
// input unchanged; result has structured fields and _schemaVersion == 1
```

## Telemetry

Implement `MigrationTelemetry` to capture applied, skipped, or failed migrations. The debug implementation keeps in-memory counters and prints summaries inside asserts. Production call sites can inject their own implementation to integrate with monitoring.

## Wiring into persistence

`SessionCodec` (see `lib/data/session/session_codec.dart`) wraps all load/save payloads. It always performs a dry-run to publish telemetry. When the `FF_NORMALIZED_EQUIPMENT_MODEL` flag is disabled, the codec returns the original JSON untouched. When the flag is enabled, it applies the migrations non-dry and returns the migrated payload while still deep-copying inputs to avoid in-place mutation.

## Running with the feature flag

Use Dart defines to toggle the flag at runtime:

```bash
flutter test -d chrome --dart-define=FF_NORMALIZED_EQUIPMENT_MODEL=true
flutter run --dart-define=FF_NORMALIZED_EQUIPMENT_MODEL=true
```
