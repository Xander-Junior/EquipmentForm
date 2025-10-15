import 'package:flutter_test/flutter_test.dart';

import 'package:equipment_form_app/core/migrations/migration.dart';
import 'package:equipment_form_app/core/migrations/registry.dart';
import 'package:equipment_form_app/core/migrations/schema.dart';
import 'package:equipment_form_app/core/migrations/telemetry.dart';
import 'package:equipment_form_app/core/migrations/utils.dart';

void main() {
  group('MigrationRegistry', () {
    test('applies migration, bumps version, and is idempotent', () {
      final registry = MigrationRegistry([_DummyMigration()]);
      final telemetry = DebugMigrationTelemetry();
      final Map<String, dynamic> payload = <String, dynamic>{};

      final result = registry.runAll(
        payload,
        currentVersion: kCurrentSchemaVersion,
        telemetry: telemetry,
      );

      expect(result, same(payload));
      expect(payload['foo'], 'bar');
      expect(getSchemaVersion(payload), kCurrentSchemaVersion);
      expect(telemetry.migrationsApplied, 1);
      expect(telemetry.migrationsSkipped, 0);

      telemetry.reset();
      registry.runAll(
        payload,
        currentVersion: kCurrentSchemaVersion,
        telemetry: telemetry,
      );

      expect(telemetry.migrationsApplied, 0);
      expect(telemetry.migrationsSkipped, 1);
      expect(payload['foo'], 'bar');
      expect(getSchemaVersion(payload), kCurrentSchemaVersion);
    });

    test('dry run returns copy without mutating original', () {
      final registry = MigrationRegistry([_DummyMigration()]);
      final telemetry = DebugMigrationTelemetry();
      final Map<String, dynamic> payload = <String, dynamic>{'original': true};

      final result = registry.runAll(
        payload,
        currentVersion: kCurrentSchemaVersion,
        dryRun: true,
        telemetry: telemetry,
      );

      expect(payload.containsKey('foo'), isFalse);
      expect(getSchemaVersion(payload), 0);
      expect(result['foo'], 'bar');
      expect(getSchemaVersion(result), kCurrentSchemaVersion);
      expect(telemetry.migrationsApplied, 1);
    });

    test('errors surface and leave payload unchanged', () {
      final registry = MigrationRegistry([_ThrowingMigration()]);
      final telemetry = DebugMigrationTelemetry();
      final Map<String, dynamic> payload = <String, dynamic>{'start': true};

      expect(
        () => registry.runAll(
          payload,
          currentVersion: kCurrentSchemaVersion,
          telemetry: telemetry,
        ),
        throwsA(isA<StateError>()),
      );

      expect(payload, {'start': true});
      expect(getSchemaVersion(payload), 0);
      expect(telemetry.migrationsFailed, 1);
    });
  });
}

class _DummyMigration implements Migration {
  @override
  SchemaVersion get from => 0;

  @override
  SchemaVersion get to => 1;

  @override
  String get id => '0000_dummy';

  @override
  Map<String, dynamic> migrate(
    Map<String, dynamic> json, {
    MigrationTelemetry? telemetry,
  }) {
    json['foo'] = 'bar';
    return json;
  }
}

class _ThrowingMigration implements Migration {
  @override
  SchemaVersion get from => 0;

  @override
  SchemaVersion get to => 1;

  @override
  String get id => '9999_throw';

  @override
  Map<String, dynamic> migrate(
    Map<String, dynamic> json, {
    MigrationTelemetry? telemetry,
  }) {
    throw StateError('boom');
  }
}
