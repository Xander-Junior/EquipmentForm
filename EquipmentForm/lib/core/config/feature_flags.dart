import 'dart:async';

class FeatureFlags {
  static const bool _normalizedEquipmentModelDefault = bool.fromEnvironment(
      'FF_NORMALIZED_EQUIPMENT_MODEL',
      defaultValue: false);

  static bool get normalizedEquipmentModel =>
      FeatureFlagsOverride._normalizedEquipmentModelOverride ??
      _normalizedEquipmentModelDefault;
}

class FeatureFlagsOverride {
  static const _normalizedKey = #normalizedEquipmentModelOverride;

  static bool? get _normalizedEquipmentModelOverride {
    final value = Zone.current[_normalizedKey];
    return value is bool ? value : null;
  }

  static T runWith<T>({
    bool? normalizedEquipmentModel,
    required T Function() run,
  }) {
    if (normalizedEquipmentModel == null) {
      return run();
    }
    return runZoned(
      run,
      zoneValues: {_normalizedKey: normalizedEquipmentModel},
    );
  }
}
