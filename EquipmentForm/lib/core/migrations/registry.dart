import 'migration.dart';
import 'migrations_0001_equipment_model.dart';
import 'schema.dart';
import 'telemetry.dart';
import 'utils.dart';

class MigrationRegistry {
  MigrationRegistry(this.migrations) {
    if (migrations.isEmpty) return;
    for (var i = 0; i < migrations.length; i++) {
      final migration = migrations[i];
      if (migration.to != migration.from + 1) {
        throw ArgumentError(
            'Migration ${migration.id} must increment version by 1');
      }
      if (i > 0) {
        final prev = migrations[i - 1];
        if (prev.to != migration.from) {
          throw ArgumentError(
            'Migration ordering invalid: ${prev.id} (to:${prev.to}) -> ${migration.id} (from:${migration.from})',
          );
        }
      }
    }
  }

  final List<Migration> migrations;

  Map<String, dynamic> runAll(
    Map<String, dynamic> json, {
    required SchemaVersion currentVersion,
    bool dryRun = false,
    MigrationTelemetry? telemetry,
  }) {
    final originalVersion = getSchemaVersion(json);
    if (originalVersion >= currentVersion) {
      telemetry?.skipped(id: 'all', reason: 'up_to_date');
      return dryRun ? deepCopy(json) : json;
    }

    var working = deepCopy(json);
    var version = originalVersion;

    for (final migration in migrations) {
      if (version >= currentVersion) break;
      if (version != migration.from) {
        telemetry?.skipped(
          id: migration.id,
          reason: 'version_mismatch($version!=${migration.from})',
        );
        continue;
      }

      Map<String, dynamic> migrated;
      try {
        migrated = migration.migrate(deepCopy(working), telemetry: telemetry);
      } catch (error) {
        telemetry?.failed(id: migration.id, error: error.toString());
        rethrow;
      }

      setSchemaVersion(migrated, migration.to);
      version = migration.to;
      working = migrated;
      telemetry?.applied(id: migration.id);
    }

    if (dryRun) {
      return working;
    }

    json
      ..clear()
      ..addAll(working);
    return json;
  }
}

List<Migration> defaultMigrations() => [
      Migrations0001EquipmentModel(),
    ];

MigrationRegistry createDefaultMigrationRegistry() =>
    MigrationRegistry(defaultMigrations());
