import '../../core/config/feature_flags.dart';
import '../../core/migrations/registry.dart';
import '../../core/migrations/schema.dart';
import '../../core/migrations/telemetry.dart';
import '../../core/migrations/utils.dart';

typedef TelemetryListener = void Function(
    String phase, DebugMigrationTelemetry telemetry);

class SessionCodec {
  SessionCodec({
    MigrationRegistry? registry,
    TelemetryListener? telemetryListener,
  })  : _registry = registry ?? createDefaultMigrationRegistry(),
        _telemetryListener = telemetryListener;

  final MigrationRegistry _registry;
  final TelemetryListener? _telemetryListener;

  Map<String, dynamic> decode(Map<String, dynamic> raw) {
    final dryTelemetry = DebugMigrationTelemetry();
    _registry.runAll(
      deepCopy(raw),
      currentVersion: kCurrentSchemaVersion,
      dryRun: true,
      telemetry: dryTelemetry,
    );
    _logTelemetry('decode[dryRun]', dryTelemetry);

    if (!FeatureFlags.normalizedEquipmentModel) {
      return deepCopy(raw);
    }

    final applyTelemetry = DebugMigrationTelemetry();
    final migrated = _registry.runAll(
      deepCopy(raw),
      currentVersion: kCurrentSchemaVersion,
      telemetry: applyTelemetry,
    );
    _logTelemetry('decode[apply]', applyTelemetry);
    return migrated;
  }

  Map<String, dynamic> encode(Map<String, dynamic> raw) {
    final dryTelemetry = DebugMigrationTelemetry();
    _registry.runAll(
      deepCopy(raw),
      currentVersion: kCurrentSchemaVersion,
      dryRun: true,
      telemetry: dryTelemetry,
    );
    _logTelemetry('encode[dryRun]', dryTelemetry);

    if (!FeatureFlags.normalizedEquipmentModel) {
      return deepCopy(raw);
    }

    final applyTelemetry = DebugMigrationTelemetry();
    final migrated = _registry.runAll(
      deepCopy(raw),
      currentVersion: kCurrentSchemaVersion,
      telemetry: applyTelemetry,
    );
    _logTelemetry('encode[apply]', applyTelemetry);
    return migrated;
  }

  void _logTelemetry(String phase, DebugMigrationTelemetry telemetry) {
    assert(() {
      final message =
          '[SessionCodec] $phase applied=${telemetry.migrationsApplied} skipped=${telemetry.migrationsSkipped} failed=${telemetry.migrationsFailed}';
      // ignore: avoid_print
      print(message);
      return true;
    }());
    _telemetryListener?.call(phase, telemetry);
  }
}
