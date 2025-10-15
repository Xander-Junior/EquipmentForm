import '../config/feature_flags.dart';

class EquipmentLabel {
  const EquipmentLabel({
    this.make,
    this.family,
    this.modelNumber,
    required this.rawMakeModel,
  });

  final String? make;
  final String? family;
  final String? modelNumber;
  final String rawMakeModel;

  bool get isStructured =>
      _isNotEmpty(make) || _isNotEmpty(family) || _isNotEmpty(modelNumber);

  String toDisplayUpper() {
    final parts = _structuredParts();
    if (parts.isNotEmpty) {
      return parts.map((part) => part.toUpperCase()).join(' ');
    }
    final raw = rawMakeModel.trim();
    return raw.isEmpty ? '' : raw.toUpperCase();
  }

  String toDisplayTitle() {
    final parts = _structuredParts();
    if (parts.isNotEmpty) {
      return parts.map(_titleCase).join(' ');
    }
    final raw = rawMakeModel.trim();
    return raw.isEmpty ? '' : _titleCase(raw);
  }

  List<String> _structuredParts() {
    return [
      if (_isNotEmpty(make)) make!.trim(),
      if (_isNotEmpty(family)) family!.trim(),
      if (_isNotEmpty(modelNumber)) modelNumber!.trim(),
    ];
  }

  static bool _isNotEmpty(String? value) =>
      value != null && value.trim().isNotEmpty;

  String _titleCase(String input) {
    final words = input.split(RegExp(r'\\s+'));
    final transformed = <String>[];
    for (final word in words) {
      if (word.isEmpty) continue;
      if (word.toUpperCase() == word && word.length <= 3) {
        transformed.add(word.toUpperCase());
      } else if (word.length == 1) {
        transformed.add(word.toUpperCase());
      } else {
        transformed
            .add('${word[0].toUpperCase()}${word.substring(1).toLowerCase()}');
      }
    }
    return transformed.join(' ');
  }
}

EquipmentLabel readLabelFromJson(Map<String, dynamic> equipJson) {
  final raw = (equipJson['makeModel'] as String?)?.trim() ?? '';

  if (!FeatureFlags.normalizedEquipmentModel) {
    return EquipmentLabel(rawMakeModel: raw);
  }

  String? make;
  String? family;
  String? modelNumber;

  String? readValue(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  make = readValue(equipJson['make']);
  family = readValue(equipJson['family']);
  modelNumber = readValue(equipJson['modelNumber']);

  final modelMap = equipJson['model'];
  if (modelMap is Map) {
    make ??= readValue(modelMap['make']);
    family ??= readValue(modelMap['family']);
    modelNumber ??= readValue(modelMap['modelNumber']);
  }

  return EquipmentLabel(
    make: make,
    family: family,
    modelNumber: modelNumber,
    rawMakeModel: raw,
  );
}
