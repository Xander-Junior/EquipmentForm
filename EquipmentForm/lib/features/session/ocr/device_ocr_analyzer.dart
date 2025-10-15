import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../../shared/domain/normalizers.dart';

enum DeviceOcrConfidence { high, medium, low }

@immutable
class DeviceOcrFieldSuggestion {
  DeviceOcrFieldSuggestion({
    required this.value,
    required this.score,
    required this.evidence,
    required this.reason,
    this.highlight,
  }) : confidence = _confidenceFor(score);

  final String value;
  final double score;
  final String evidence;
  final String reason;
  final String? highlight;
  final DeviceOcrConfidence confidence;

  static DeviceOcrConfidence _confidenceFor(double score) {
    if (score >= 0.8) return DeviceOcrConfidence.high;
    if (score >= 0.55) return DeviceOcrConfidence.medium;
    return DeviceOcrConfidence.low;
  }
}

@immutable
class DeviceOcrAnalysis {
  const DeviceOcrAnalysis({
    required this.rawText,
    required this.lines,
    required this.assetTagSuggestions,
    required this.serviceTagSuggestions,
    required this.modelSuggestions,
    required this.warrantyExpirySuggestions,
  });

  final String rawText;
  final List<String> lines;
  final List<DeviceOcrFieldSuggestion> assetTagSuggestions;
  final List<DeviceOcrFieldSuggestion> serviceTagSuggestions;
  final List<DeviceOcrFieldSuggestion> modelSuggestions;
  final List<DeviceOcrFieldSuggestion> warrantyExpirySuggestions;

  List<DeviceOcrFieldSuggestion> suggestionsFor(String field) {
    switch (field) {
      case 'assetTag':
        return assetTagSuggestions;
      case 'serviceTag':
        return serviceTagSuggestions;
      case 'makeModel':
        return modelSuggestions;
      case 'warrantyExpiry':
        return warrantyExpirySuggestions;
      default:
        return [];
    }
  }

  DeviceOcrFieldSuggestion? primarySuggestionFor(String field) {
    return suggestionsFor(field).firstOrNull;
  }
}

class DeviceOcrAnalyzer {
  const DeviceOcrAnalyzer();

  DeviceOcrAnalysis analyze(Map<String, dynamic> fields) {
    final rawText = (fields['rawText'] as String?)?.trim() ?? '';
    final lineList = _deriveLines(fields, rawText);

    final assetTagSuggestions = _extractAssetTags(fields, lineList, rawText);
    final serviceTagSuggestions =
        _extractServiceTags(fields, lineList, rawText);
    final modelSuggestions = _extractModels(fields, lineList, rawText);
    final warrantyExpirySuggestions =
        _extractWarrantyExpiry(fields, lineList, rawText);

    return DeviceOcrAnalysis(
      rawText: rawText,
      lines: lineList,
      assetTagSuggestions: assetTagSuggestions,
      serviceTagSuggestions: serviceTagSuggestions,
      modelSuggestions: modelSuggestions,
      warrantyExpirySuggestions: warrantyExpirySuggestions,
    );
  }

  List<String> _deriveLines(Map<String, dynamic> fields, String rawText) {
    final provided = fields['lines'];
    if (provided is List) {
      return provided
          .whereType<String>()
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList(growable: false);
    }
    if (rawText.isEmpty) return const [];
    final normalized = rawText.replaceAll('\r', '');
    final split = normalized.split('\n');
    if (split.length == 1) {
      // Heuristic split on double spaces when newline missing.
      return normalized
          .split(RegExp(r'\s{2,}'))
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList(growable: false);
    }
    return split
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
  }

  List<DeviceOcrFieldSuggestion> _extractAssetTags(
    Map<String, dynamic> fields,
    List<String> lines,
    String rawText,
  ) {
    final suggestions = <DeviceOcrFieldSuggestion>[];
    final seen = <String>{};

    // Multiple patterns for asset tags - ordered by specificity
    final patterns = [
      RegExp(r'(?:asset\s*tag|property\s*id)[:\s-]+([A-Z0-9\-]{3,})',
          caseSensitive: false), // Asset tag with colon/space
      RegExp(r'\basset[:\s-]+([A-Z0-9\-]{3,})',
          caseSensitive: false), // Asset with colon/space
      RegExp(r'([0-9]{6,10})', caseSensitive: false), // Numeric asset tags (6-10 digits)
      RegExp(r'([A-Z]{2,3}[0-9]{3,6})',
          caseSensitive: false), // Common asset tag format
    ];

    void addSuggestion({
      required String value,
      required double score,
      required String evidence,
      String? highlight,
      required String reason,
    }) {
      final normalizedKey = value.trim().toUpperCase();
      if (normalizedKey.isEmpty || !seen.add(normalizedKey)) return;
      suggestions.add(
        DeviceOcrFieldSuggestion(
          value: normalizedKey,
          score: score.clamp(0, 1),
          evidence: evidence,
          highlight: highlight,
          reason: reason,
        ),
      );
    }

    // Check OCR field first
    final fieldAsset = fields['assetTag'];
    if (fieldAsset is String && fieldAsset.trim().isNotEmpty) {
      addSuggestion(
        value: fieldAsset.trim(),
        score: 0.88,
        evidence: fieldAsset,
        highlight: fieldAsset.trim(),
        reason: 'OCR engine asset tag field',
      );
    }

    // Search through lines with patterns
    for (var i = 0; i < patterns.length; i++) {
      final pattern = patterns[i];
      final baseScore = 0.85 - (i * 0.1); // Prefer earlier patterns

      for (final line in lines) {
        // Skip MAC addresses and country codes
        if (_isIgnorableIdentifier(line)) continue;

        for (final match in pattern.allMatches(line)) {
          final value =
              (match.groupCount > 0 ? match.group(1) : match.group(0)) ?? '';
          if (value.length >= 3 && !_isIgnorableIdentifier(value)) {
            addSuggestion(
              value: value,
              score: baseScore,
              evidence: line,
              highlight: match.group(0),
              reason: i == 0
                  ? 'Asset tag pattern match'
                  : 'Candidate asset identifier',
            );
          }
        }
      }
    }

    suggestions.sort((a, b) => b.score.compareTo(a.score));
    return suggestions;
  }

  List<DeviceOcrFieldSuggestion> _extractServiceTags(
    Map<String, dynamic> fields,
    List<String> lines,
    String rawText,
  ) {
    final suggestions = <DeviceOcrFieldSuggestion>[];
    final seen = <String>{};

    final patterns = [
      RegExp(r'(?:service\s*tag|svc\s*tag)[:\s-]+([A-Z0-9\-]{3,})',
          caseSensitive: false), // Service tag with colon/space
      RegExp(r'([A-Z0-9]{7,10})',
          caseSensitive: false), // Dell service tag format
      RegExp(r'([A-Z0-9]{3,10})',
          caseSensitive: false), // General alphanumeric service tags
    ];

    void addSuggestion({
      required String value,
      required double score,
      required String evidence,
      String? highlight,
      required String reason,
    }) {
      final normalizedKey = value.trim().toUpperCase();
      if (normalizedKey.isEmpty || !seen.add(normalizedKey)) return;
      suggestions.add(
        DeviceOcrFieldSuggestion(
          value: normalizedKey,
          score: score.clamp(0, 1),
          evidence: evidence,
          highlight: highlight,
          reason: reason,
        ),
      );
    }

    // Check OCR field first
    final fieldService = fields['serviceTag'];
    if (fieldService is String && fieldService.trim().isNotEmpty) {
      addSuggestion(
        value: fieldService.trim(),
        score: 0.88,
        evidence: fieldService,
        highlight: fieldService.trim(),
        reason: 'OCR engine service tag field',
      );
    }

    // Search through lines
    for (var i = 0; i < patterns.length; i++) {
      final pattern = patterns[i];
      final baseScore = 0.85 - (i * 0.1);

      for (final line in lines) {
        if (_isIgnorableIdentifier(line)) continue;

        for (final match in pattern.allMatches(line)) {
          final value =
              (match.groupCount > 0 ? match.group(1) : match.group(0)) ?? '';
          if (value.length >= 3 && !_isIgnorableIdentifier(value) && _isValidServiceTag(value, line)) {
            addSuggestion(
              value: value,
              score: baseScore,
              evidence: line,
              highlight: match.group(0),
              reason: i == 0
                  ? 'Service tag pattern match'
                  : 'Candidate service identifier',
            );
          }
        }
      }
    }

    suggestions.sort((a, b) => b.score.compareTo(a.score));
    return suggestions;
  }

  List<DeviceOcrFieldSuggestion> _extractModels(
    Map<String, dynamic> fields,
    List<String> lines,
    String rawText,
  ) {
    final suggestions = <DeviceOcrFieldSuggestion>[];
    final seen = <String>{};

    // Common manufacturer patterns
    final manufacturers = [
      'Dell',
      'HP',
      'Lenovo',
      'Apple',
      'Microsoft',
      'ASUS',
      'Acer',
      'Samsung'
    ];
    final modelPatterns = [
      RegExp(r'(?:model|make)[:\s-]*([A-Z0-9\s\-]{3,25})',
          caseSensitive: false),
      RegExp(r'(Dell\s+\w+(?:\s+\w+)?)', caseSensitive: false),
      RegExp(r'(HP\s+\w+(?:\s+\w+)?)', caseSensitive: false),
      RegExp(r'(Lenovo\s+\w+(?:\s+\w+)?)', caseSensitive: false),
      RegExp(r'(MacBook\s+\w+(?:\s+\w+)?)', caseSensitive: false),
      RegExp(r'(Surface\s+\w+(?:\s+\w+)?)', caseSensitive: false),
    ];

    void addSuggestion({
      required String value,
      required double score,
      required String evidence,
      String? highlight,
      required String reason,
    }) {
      final normalizedValue = _normalizeModelValue(value.trim());
      final normalizedKey = normalizedValue.toLowerCase();
      if (normalizedKey.isEmpty ||
          normalizedKey.length < 3 ||
          !seen.add(normalizedKey)) return;
      suggestions.add(
        DeviceOcrFieldSuggestion(
          value: normalizedValue,
          score: score.clamp(0, 1),
          evidence: evidence,
          highlight: highlight,
          reason: reason,
        ),
      );
    }

    // Check OCR field first
    final fieldModel = fields['makeModel'];
    if (fieldModel is String && fieldModel.trim().isNotEmpty) {
      addSuggestion(
        value: fieldModel.trim(),
        score: 0.88,
        evidence: fieldModel,
        highlight: fieldModel.trim(),
        reason: 'OCR engine model field',
      );
    }

    // Search with manufacturer-specific patterns
    for (var i = 0; i < modelPatterns.length; i++) {
      final pattern = modelPatterns[i];
      final baseScore =
          i == 0 ? 0.85 : 0.90; // Manufacturer patterns score higher

      for (final line in lines) {
        for (final match in pattern.allMatches(line)) {
          final value =
              (match.groupCount > 0 ? match.group(1) : match.group(0)) ?? '';
          if (value.length >= 3) {
            addSuggestion(
              value: value,
              score: baseScore,
              evidence: line,
              highlight: match.group(0),
              reason: i == 0
                  ? 'Model pattern match'
                  : 'Manufacturer model detected',
            );
          }
        }
      }
    }

    // Look for lines that start with known manufacturers
    for (final line in lines) {
      for (final manufacturer in manufacturers) {
        if (line.toLowerCase().startsWith(manufacturer.toLowerCase())) {
          final words = line.split(RegExp(r'\s+'));
          if (words.length >= 2) {
            addSuggestion(
              value: line,
              score: 0.75,
              evidence: line,
              highlight: line,
              reason: 'Manufacturer line detected',
            );
          }
          break;
        }
      }
    }

    suggestions.sort((a, b) => b.score.compareTo(a.score));
    return suggestions;
  }

  List<DeviceOcrFieldSuggestion> _extractWarrantyExpiry(
    Map<String, dynamic> fields,
    List<String> lines,
    String rawText,
  ) {
    final suggestions = <DeviceOcrFieldSuggestion>[];
    final seen = <String>{};

    final patterns = [
      RegExp(
          r'(?:warranty\s*expiry|w\.?e\.?|warranty|expires?)[:\s-]*(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})',
          caseSensitive: false),
      RegExp(r'(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})',
          caseSensitive: false), // Any date pattern
      RegExp(r'(?:exp|expiry)[:\s-]*(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})',
          caseSensitive: false),
    ];

    void addSuggestion({
      required String value,
      required double score,
      required String evidence,
      String? highlight,
      required String reason,
    }) {
      final normalizedKey = value.trim();
      if (normalizedKey.isEmpty || !seen.add(normalizedKey)) return;
      suggestions.add(
        DeviceOcrFieldSuggestion(
          value: _normalizeDate(normalizedKey),
          score: score.clamp(0, 1),
          evidence: evidence,
          highlight: highlight,
          reason: reason,
        ),
      );
    }

    // Check OCR field first
    final fieldWE = fields['warrantyExpiry'];
    if (fieldWE is String && fieldWE.trim().isNotEmpty) {
      addSuggestion(
        value: fieldWE.trim(),
        score: 0.88,
        evidence: fieldWE,
        highlight: fieldWE.trim(),
        reason: 'OCR engine warranty expiry field',
      );
    }

    // Search through lines
    for (var i = 0; i < patterns.length; i++) {
      final pattern = patterns[i];
      final baseScore = 0.85 - (i * 0.1);

      for (final line in lines) {
        for (final match in pattern.allMatches(line)) {
          final value =
              (match.groupCount > 0 ? match.group(1) : match.group(0)) ?? '';
          if (_looksLikeDate(value)) {
            addSuggestion(
              value: value,
              score: baseScore,
              evidence: line,
              highlight: match.group(0),
              reason: i == 0
                  ? 'Warranty expiry pattern match'
                  : 'Date pattern detected',
            );
          }
        }
      }
    }

    suggestions.sort((a, b) => b.score.compareTo(a.score));
    return suggestions;
  }

  bool _isIgnorableIdentifier(String text) {
    final upper = text.toUpperCase();
    // MAC address patterns
    if (RegExp(
            r'^[0-9A-F]{2}[:-][0-9A-F]{2}[:-][0-9A-F]{2}[:-][0-9A-F]{2}[:-][0-9A-F]{2}[:-][0-9A-F]{2}$')
        .hasMatch(upper)) {
      return true;
    }
    // Country codes and common non-identifiers
    const ignorable = ['US', 'USA', 'UK', 'CA', 'FCC', 'IC', 'CE', 'RoHS'];
    if (ignorable.contains(upper)) {
      return true;
    }
    return false;
  }

  String _normalizeModelValue(String input) {
    final normalized = normalizeDellLatitudeModel(input);
    if (normalized != null && normalized.isNotEmpty && normalized != input) {
      return normalized.trim();
    }
    return _capitalizeModel(input);
  }

  String _capitalizeModel(String input) {
    return input.split(' ').map((word) {
      if (word.isEmpty) return word;
      // Keep known tech acronyms uppercase (but not brand names)
      final upper = word.toUpperCase();
      if ([
        'HP',
        'ASUS',
        'MSI',
        'USB',
        'SSD',
        'HDD',
        'RAM',
        'CPU',
        'GPU'
      ].contains(upper)) {
        return upper;
      }
      // Special handling for common brands to preserve proper casing
      final lower = word.toLowerCase();
      if (lower == 'dell') return 'Dell';
      if (lower == 'optiplex') return 'OptiPlex';
      if (lower == 'thinkpad') return 'ThinkPad';
      if (lower == 'macbook') return 'MacBook';
      if (lower == 'probook') return 'ProBook';
      
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String _normalizeDate(String input) {
    // Convert various date formats to DD/MM/YYYY
    final parts = input.split(RegExp(r'[\/\-]'));
    if (parts.length == 3) {
      var day = parts[0].padLeft(2, '0');
      var month = parts[1].padLeft(2, '0');
      var year = parts[2];

      // Handle 2-digit years
      if (year.length == 2) {
        final currentYear = DateTime.now().year;
        final currentCentury = (currentYear ~/ 100) * 100;
        final twoDigitYear = int.tryParse(year) ?? 0;

        // If year is less than current year % 100 + 10, assume next century
        // Otherwise assume current century
        if (twoDigitYear < (currentYear % 100) + 10) {
          year = (currentCentury + 100 + twoDigitYear).toString();
        } else {
          year = (currentCentury + twoDigitYear).toString();
        }
      }

      return '$day/$month/$year';
    }
    return input;
  }

  bool _looksLikeDate(String value) {
    // Basic date validation - should have 2-3 parts separated by / or -
    final parts = value.split(RegExp(r'[\/\-]'));
    if (parts.length != 3) return false;

    // Each part should be numeric
    for (final part in parts) {
      if (int.tryParse(part) == null) return false;
    }

    // Basic range checks
    final nums = parts.map(int.parse).toList();
    return nums.every((n) => n >= 1 && n <= 9999); // Very loose validation
  }

  bool _isValidServiceTag(String value, String line) {
    // Avoid matching descriptive words
    final lowerValue = value.toLowerCase();
    const invalidWords = {
      'service', 'tag', 'express', 'expresscode', 'code', 'dell', 'inc', 'model', 'laptop', 'desktop'
    };
    
    if (invalidWords.contains(lowerValue)) return false;
    
    // Service tags should be alphanumeric combinations
    if (!RegExp(r'^[A-Z0-9]+$', caseSensitive: false).hasMatch(value)) return false;
    
    // Should have a mix of letters and numbers (not all letters or all numbers unless 7+ chars)
    final hasLetters = RegExp(r'[A-Z]', caseSensitive: false).hasMatch(value);
    final hasNumbers = RegExp(r'[0-9]').hasMatch(value);
    
    // Dell style service tags are typically 7 chars with mix of letters/numbers
    if (value.length == 7 && hasLetters && hasNumbers) return true;
    
    // Other valid combinations
    if (value.length >= 3 && value.length <= 10 && (hasLetters || hasNumbers)) {
      // If it's on its own line or after a colon, it's more likely to be valid
      final trimmedLine = line.trim();
      if (trimmedLine == value || trimmedLine.endsWith(': $value') || trimmedLine.endsWith(':$value')) {
        return true;
      }
    }
    
    return false;
  }
}
