import 'label.dart';

extension EquipmentJsonX on Map<String, dynamic> {
  EquipmentLabel get equipmentLabel => readLabelFromJson(this);
}
