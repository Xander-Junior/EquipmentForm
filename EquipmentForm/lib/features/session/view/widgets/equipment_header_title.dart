import 'package:flutter/material.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../core/equipment_model/label.dart';
import '../../domain/session_models.dart';

class EquipmentHeaderTitle extends StatelessWidget {
  const EquipmentHeaderTitle({
    super.key,
    required this.type,
    required this.fallbackLabel,
    this.structuredLabel,
  });

  final PrimaryDeviceType type;
  final String fallbackLabel;
  final EquipmentLabel? structuredLabel;

  @override
  Widget build(BuildContext context) {
    final structured = structuredLabel;
    final display = FeatureFlags.normalizedEquipmentModel &&
            structured != null &&
            structured.isStructured
        ? structured.toDisplayUpper()
        : fallbackLabel;

    return Text(
      '${type.label} $display',
      style: Theme.of(context).textTheme.titleMedium,
    );
  }
}
