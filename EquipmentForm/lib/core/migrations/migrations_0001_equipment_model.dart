import '../equipment_model/equipment_model.dart' show ParseStatus;
import '../equipment_model/normalizer.dart';
import 'migration.dart';
import 'schema.dart';
import 'telemetry.dart';
import 'utils.dart';

class Migrations0001EquipmentModel implements Migration {
  @override
  SchemaVersion get from => 0;

  @override
  SchemaVersion get to => 1;

  @override
  String get id => '0001_equipment_model_split';

  @override
  Map<String, dynamic> migrate(
    Map<String, dynamic> json, {
    MigrationTelemetry? telemetry,
  }) {
    _migrateNode(json);
    setSchemaVersion(json, to);
    return json;
  }

  void _migrateNode(dynamic node) {
    if (node is Map<String, dynamic>) {
      _migrateEquipment(node);
      for (final value in node.values) {
        _migrateNode(value);
      }
    } else if (node is Iterable) {
      for (final element in node) {
        _migrateNode(element);
      }
    }
  }

  void _migrateEquipment(Map<String, dynamic> map) {
    if (!map.containsKey('makeModel')) return;
    final legacy = map['makeModel'];
    if (legacy is! String) return;

    final result = parseMakeModel(legacy);
    if (result.status == ParseStatus.fail || result.value == null) {
      return;
    }

    final model = result.value!;
    map['make'] = model.make;
    map['family'] = model.family;
    map['modelNumber'] = model.modelNumber;
    map.remove('makeModel');
  }
}
