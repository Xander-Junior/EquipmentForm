import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:equipment_form_app/core/migrations/migrations_0001_equipment_model.dart';
import 'package:equipment_form_app/core/migrations/registry.dart';
import 'package:equipment_form_app/core/migrations/schema.dart';
import 'package:equipment_form_app/core/migrations/utils.dart';

void main() {
  group('Migrations0001EquipmentModel', () {
    final registry = MigrationRegistry([Migrations0001EquipmentModel()]);

    final okCases = {
      'Dell Latitude 7420': ['Dell', 'Latitude', '7420'],
      'Latitude-7420': ['Dell', 'Latitude', '7420'],
      'Latitude_7420': ['Dell', 'Latitude', '7420'],
      'Lat 7420': ['Dell', 'Latitude', '7420'],
      'Latitude E7470': ['Dell', 'Latitude', 'E7470'],
      'ThinkPad T480': ['Lenovo', 'ThinkPad', 'T480'],
      'HP EliteBook 840 G5': ['HP', 'EliteBook', '840 G5'],
      'ProBook-450 G9': ['HP', 'ProBook', '450 G9'],
      'XPS 13 9310': ['Dell', 'XPS', '13 9310'],
    };

    okCases.forEach((input, expected) {
      test('migrates "$input"', () {
        final Map<String, dynamic> payload = {
          'equipment': <String, dynamic>{
            'makeModel': input,
          },
        };

        registry.runAll(
          payload,
          currentVersion: kCurrentSchemaVersion,
        );

        final equipment = payload['equipment'] as Map<String, dynamic>;
        expect(equipment.containsKey('makeModel'), isFalse);
        expect(equipment['make'], expected[0]);
        expect(equipment['family'], expected[1]);
        expect(equipment['modelNumber'], expected[2]);
        expect(getSchemaVersion(payload), kCurrentSchemaVersion);
      });
    });

    test('handles list of equipment maps', () {
      final Map<String, dynamic> payload = {
        'equipment': <String, dynamic>{
          'items': [
            <String, dynamic>{'makeModel': 'Latitude 7420'},
            <String, dynamic>{'makeModel': 'ThinkPad T480'},
          ],
        },
      };

      registry.runAll(
        payload,
        currentVersion: kCurrentSchemaVersion,
      );

      final items =
          ((payload['equipment'] as Map<String, dynamic>)['items'] as List)
              .cast<Map<String, dynamic>>();
      expect(items[0]['make'], 'Dell');
      expect(items[0]['family'], 'Latitude');
      expect(items[0]['modelNumber'], '7420');
      expect(items[1]['make'], 'Lenovo');
      expect(items[1]['family'], 'ThinkPad');
      expect(items[1]['modelNumber'], 'T480');
    });

    test('leaves makeModel intact on parse failure but bumps version', () {
      final longModel = List.filled(120, 'X').join();
      final Map<String, dynamic> payload = {
        'equipment': <String, dynamic>{
          'makeModel': longModel,
        },
      };

      registry.runAll(
        payload,
        currentVersion: kCurrentSchemaVersion,
      );

      final equipment = payload['equipment'] as Map<String, dynamic>;
      expect(equipment['makeModel'], longModel);
      expect(equipment.containsKey('make'), isFalse);
      expect(getSchemaVersion(payload), kCurrentSchemaVersion);
    });

    test('idempotent across multiple runs', () {
      final Map<String, dynamic> payload = {
        'equipment': <String, dynamic>{
          'makeModel': 'Dell Latitude 7420',
        },
      };

      registry.runAll(
        payload,
        currentVersion: kCurrentSchemaVersion,
      );

      final first = jsonDecode(jsonEncode(payload)) as Map<String, dynamic>;

      registry.runAll(
        payload,
        currentVersion: kCurrentSchemaVersion,
      );

      expect(payload, equals(first));
    });
  });
}
