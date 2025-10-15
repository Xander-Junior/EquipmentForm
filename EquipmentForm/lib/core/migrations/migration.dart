import 'schema.dart';
import 'telemetry.dart';

abstract class Migration {
  SchemaVersion get from;
  SchemaVersion get to;
  String get id;

  Map<String, dynamic> migrate(
    Map<String, dynamic> json, {
    MigrationTelemetry? telemetry,
  });
}
