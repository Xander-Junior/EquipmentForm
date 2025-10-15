import 'package:flutter_test/flutter_test.dart';

import 'package:equipment_form_app/core/config/feature_flags.dart';
import 'package:equipment_form_app/core/equipment_model/label.dart';

void main() {
  group('EquipmentLabel', () {
    test('flag OFF returns legacy values', () {
      final input = {'makeModel': 'Latitude 7420', 'make': 'Dell'};
      final label = FeatureFlagsOverride.runWith(
        normalizedEquipmentModel: false,
        run: () => readLabelFromJson(input),
      );

      expect(label.isStructured, isFalse);
      expect(label.toDisplayUpper(), 'LATITUDE 7420');
      expect(label.toDisplayTitle(), 'Latitude 7420');
    });

    test('flag ON uses structured fields when present', () {
      final input = {
        'makeModel': '7420',
        'make': 'Dell',
        'family': 'Latitude',
        'modelNumber': '7420',
      };

      final label = FeatureFlagsOverride.runWith(
        normalizedEquipmentModel: true,
        run: () => readLabelFromJson(input),
      );

      expect(label.isStructured, isTrue);
      expect(label.toDisplayUpper(), 'DELL LATITUDE 7420');
      expect(label.toDisplayTitle(), 'Dell Latitude 7420');
    });

    test('flag ON falls back to legacy when structured missing', () {
      final input = {'makeModel': 'ThinkPad X1 Carbon'};

      final label = FeatureFlagsOverride.runWith(
        normalizedEquipmentModel: true,
        run: () => readLabelFromJson(input),
      );

      expect(label.isStructured, isFalse);
      expect(label.toDisplayUpper(), 'THINKPAD X1 CARBON');
    });

    test('readLabelFromJson does not mutate input', () {
      final input = {'makeModel': 'Latitude 7420'};
      FeatureFlagsOverride.runWith(
        normalizedEquipmentModel: true,
        run: () => readLabelFromJson(input),
      );
      expect(input, equals({'makeModel': 'Latitude 7420'}));
    });
  });
}
