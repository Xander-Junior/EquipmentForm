import 'package:intl/intl.dart';

class AssetTag {
  AssetTag({required this.location, required this.deviceType, required this.number, required this.canonical});

  final String location;
  final String deviceType;
  final String number;
  final String canonical;
}

final _assetTagPattern =
    RegExp(r'^(ACC|TAK|LON)\s*-\s*(LT|MB)\s*-\s*(\d{4,6})$', caseSensitive: false);

AssetTag? parseAssetTag(String? input) {
  if (input == null || input.trim().isEmpty) {
    return null;
  }
  final match = _assetTagPattern.firstMatch(input.trim());
  if (match == null) {
    return null;
  }
  final location = match.group(1)!.toUpperCase();
  final deviceType = match.group(2)!.toUpperCase();
  final number = match.group(3)!;
  final canonical = '$location-$deviceType-$number';
  return AssetTag(
    location: location,
    deviceType: deviceType,
    number: number,
    canonical: canonical,
  );
}

String? normalizeAssetTag(String? input) => parseAssetTag(input)?.canonical;

String? validateAssetTag(String? input) {
  if (input == null || input.trim().isEmpty) {
    return 'Asset tag is required';
  }
  return parseAssetTag(input) == null ? 'Asset tag must match ACC-LT-12345 or TAK-MB-1234' : null;
}

String? normalizeImei(String? input) {
  if (input == null) return null;
  final digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) {
    return null;
  }
  return digits;
}

String? validateImei(String? input) {
  if (input == null || input.trim().isEmpty) {
    return 'IMEI is required';
  }
  final digits = normalizeImei(input);
  if (digits == null || digits.length != 15) {
    return 'IMEI must contain 15 digits';
  }
  return null;
}

DateFormat get _isoFormatter => DateFormat('yyyy-MM-dd');
final _displayFormatter = DateFormat('dd/MM/yyyy');

String? normalizeWarrantyExpiry(String? input) {
  if (input == null || input.trim().isEmpty) {
    return null;
  }
  final trimmed = input.trim();
  DateTime? parsed;
  final candidates = <DateFormat>[
    DateFormat('dd/MM/yyyy'),
    DateFormat('d/M/yyyy'),
    DateFormat('yyyy-MM-dd'),
  ];
  for (final format in candidates) {
    try {
      parsed = format.parseStrict(trimmed);
      break;
    } catch (_) {
      // continue
    }
  }
  return parsed == null ? null : _isoFormatter.format(parsed);
}

String? normalizeDellLatitudeModel(String? input) {
  if (input == null) return null;
  final trimmed = input.trim();
  if (trimmed.isEmpty) return '';
  var working = trimmed;
  final lower = working.toLowerCase();
  var matchedPrefix = false;
  if (lower.startsWith('dell')) {
    working = working.substring(4).trimLeft();
    matchedPrefix = true;
  }
  if (working.toLowerCase().startsWith('latitude')) {
    working = working.substring('latitude'.length).trimLeft();
    matchedPrefix = true;
  }
  if (!matchedPrefix) {
    return working;
  }
  working = working.replaceAll(RegExp(r'^[^A-Za-z0-9]+'), '');
  if (working.isEmpty) return '';
  return working.toUpperCase();
}

String formatWarrantyExpiryForDisplay(String? isoString) {
  if (isoString == null || isoString.isEmpty) return '';
  try {
    final parsed = DateTime.parse(isoString);
    return _displayFormatter.format(parsed);
  } catch (_) {
    return isoString;
  }
}

String? validateWarrantyExpiry(String? input) {
  if (input == null || input.trim().isEmpty) {
    return null;
  }
  return normalizeWarrantyExpiry(input) == null ? 'Warranty expiry must be a valid date (DD/MM/YYYY)' : null;
}
