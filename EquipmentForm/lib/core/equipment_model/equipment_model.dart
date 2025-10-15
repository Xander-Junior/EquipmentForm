class EquipmentModel {
  const EquipmentModel({
    required this.make,
    required this.family,
    required this.modelNumber,
    this.raw,
  });

  final String make;
  final String family;
  final String modelNumber;
  final String? raw;

  EquipmentModel copyWith({
    String? make,
    String? family,
    String? modelNumber,
    String? raw,
  }) {
    return EquipmentModel(
      make: make ?? this.make,
      family: family ?? this.family,
      modelNumber: modelNumber ?? this.modelNumber,
      raw: raw ?? this.raw,
    );
  }

  @override
  String toString() => '$make $family $modelNumber';

  @override
  bool operator ==(Object other) {
    return other is EquipmentModel &&
        other.make == make &&
        other.family == family &&
        other.modelNumber == modelNumber &&
        other.raw == raw;
  }

  @override
  int get hashCode => Object.hash(make, family, modelNumber, raw);
}

enum ParseStatus { ok, fallback, fail }

class ParseResult {
  const ParseResult({
    required this.status,
    this.value,
    required this.raw,
    required this.elapsed,
  });

  final ParseStatus status;
  final EquipmentModel? value;
  final String raw;
  final Duration elapsed;
}
