import 'package:flutter_test/flutter_test.dart';

import 'package:equipment_form_app/core/config/feature_flags.dart';
import 'package:equipment_form_app/data/session/session_codec.dart';

void main() {
  group('SessionCodec', () {
    test('decode/encode pass through when flag OFF but still collect telemetry',
        () {
      final telemetryCalls = <String, Map<String, int>>{};
      final codec = SessionCodec(
        telemetryListener: (phase, telemetry) {
          telemetryCalls[phase] = {
            'applied': telemetry.migrationsApplied,
            'skipped': telemetry.migrationsSkipped,
            'failed': telemetry.migrationsFailed,
          };
        },
      );

      final raw = {
        'equipment': {'makeModel': 'Dell Latitude 7420'}
      };

      final decoded = codec.decode(raw);
      final encoded = codec.encode(raw);

      expect(decoded, equals(raw));
      expect(encoded, equals(raw));
      expect(telemetryCalls['decode[dryRun]']?['applied'],
          greaterThanOrEqualTo(0));
      expect(telemetryCalls['encode[dryRun]']?['applied'],
          greaterThanOrEqualTo(0));
      expect(telemetryCalls.containsKey('decode[apply]'), isFalse);
      expect(telemetryCalls.containsKey('encode[apply]'), isFalse);
      expect(raw['equipment'], equals({'makeModel': 'Dell Latitude 7420'}));
    });

    test('decode migrates when flag ON', () {
      FeatureFlagsOverride.runWith(
        normalizedEquipmentModel: true,
        run: () {
          final codec = SessionCodec();
          final raw = {
            'equipment': {'makeModel': 'Dell Latitude 7420'}
          };

          final decoded = codec.decode(raw);
          final equipment = decoded['equipment'] as Map<String, dynamic>;
          expect(equipment.containsKey('makeModel'), isFalse);
          expect(equipment['make'], 'Dell');
          expect(equipment['family'], 'Latitude');
          expect(equipment['modelNumber'], '7420');

          final second = codec.decode(decoded);
          expect(second, equals(decoded));
        },
      );
    });

    test('encode migrates when flag ON', () {
      FeatureFlagsOverride.runWith(
        normalizedEquipmentModel: true,
        run: () {
          final codec = SessionCodec();
          final raw = {
            'equipment': {'makeModel': 'Latitude-7420'}
          };

          final encoded = codec.encode(raw);
          final equipment = encoded['equipment'] as Map<String, dynamic>;
          expect(equipment.containsKey('makeModel'), isFalse);
          expect(equipment['family'], 'Latitude');

          final second = codec.encode(encoded);
          expect(second, equals(encoded));
        },
      );
    });

    test('arrays are migrated end-to-end', () {
      FeatureFlagsOverride.runWith(
        normalizedEquipmentModel: true,
        run: () {
          final codec = SessionCodec();
          final raw = {
            'equipment': {
              'items': [
                {'makeModel': 'Latitude 7420'},
                {'makeModel': 'ThinkPad T480'},
              ],
            },
          };

          final decoded = codec.decode(raw);
          final items = (decoded['equipment'] as Map<String, dynamic>)['items']
              as List<dynamic>;
          expect(items[0]['family'], 'Latitude');
          expect(items[1]['family'], 'ThinkPad');

          final encoded = codec.encode(raw);
          final encodedItems = (encoded['equipment']
              as Map<String, dynamic>)['items'] as List<dynamic>;
          expect(encodedItems[0]['family'], 'Latitude');
          expect(encodedItems[1]['family'], 'ThinkPad');
        },
      );
    });

    test('failure case keeps legacy field when flag ON', () {
      FeatureFlagsOverride.runWith(
        normalizedEquipmentModel: true,
        run: () {
          final codec = SessionCodec();
          final longModel = List.filled(120, 'X').join();
          final raw = {
            'equipment': {'makeModel': longModel}
          };

          final decoded = codec.decode(raw);
          final equipment = decoded['equipment'] as Map<String, dynamic>;
          expect(equipment['makeModel'], longModel);
          expect(equipment.containsKey('make'), isFalse);

          final encoded = codec.encode(raw);
          final equipmentEncoded = encoded['equipment'] as Map<String, dynamic>;
          expect(equipmentEncoded['makeModel'], longModel);
        },
      );
    });
  });
}
