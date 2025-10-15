import 'package:flutter_test/flutter_test.dart';

import 'package:equipment_form_app/core/config/feature_flags.dart';

void main() {
  test('FeatureFlagsOverride.runWith overrides normalizedEquipmentModel', () {
    final defaultValue = FeatureFlags.normalizedEquipmentModel;

    final toggled = FeatureFlagsOverride.runWith(
      normalizedEquipmentModel: !defaultValue,
      run: () => FeatureFlags.normalizedEquipmentModel,
    );

    expect(toggled, isNot(equals(defaultValue)));
    expect(FeatureFlags.normalizedEquipmentModel, defaultValue);
  });
}
