import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../../app/di.dart';
import 'ocr_service.dart';

class OcrServiceMlKit implements OcrService {
  OcrServiceMlKit({required this.logger})
      : _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  final AppLogger logger;
  final TextRecognizer _textRecognizer;

  @override
  String get engineId => 'google_mlkit_text_recognition';

  @override
  String get engineVersion => '0.13.1';

  @override
  Future<OcrResult> analyze(File image, {Map<String, dynamic>? hints}) async {
    final stopwatch = Stopwatch()..start();
    try {
      final inputImage = InputImage.fromFile(image);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      stopwatch.stop();
      final fields = _extractFields(recognizedText.text);
      final confidence = _estimateConfidence(recognizedText);
      return OcrResult(
        fields: fields,
        confidence: confidence,
        latency: stopwatch.elapsed,
      );
    } catch (error, stackTrace) {
      stopwatch.stop();
      logger.error('OCR processing failed',
          error: error, stackTrace: stackTrace);
      return OcrResult(
          fields: const {}, confidence: 0, latency: stopwatch.elapsed);
    }
  }

  Map<String, dynamic> _extractFields(String rawText) {
    final lineList = rawText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final joined = rawText.replaceAll('\n', ' ');
    final lines = lineList;
    final result = <String, dynamic>{
      'rawText': joined.trim(),
    };

    final emailRegex = RegExp(r'[^@\s]+@tullowoil\.com', caseSensitive: false);
    final serialRegex =
        RegExp(r'(?:serial|sn)[:\s-]*([A-Z0-9]{5,})', caseSensitive: false);
    final assetRegex = RegExp(r'(?:asset|laptop)[:\s-]*([A-Z0-9\-]{3,})',
        caseSensitive: false);
    final serviceRegex = RegExp(
        r'(?:service|svc|svc tag)[:\s-]*([A-Z0-9\-]{3,})',
        caseSensitive: false);

    // Enhanced patterns for device sticker OCR
    final modelRegex = RegExp(r'(?:model|make)[:\s-]*([A-Z0-9\s\-]{3,25})',
        caseSensitive: false);
    final manufacturerRegex = RegExp(
        r'(Dell|HP|Lenovo|Apple|Microsoft|ASUS|Acer|Samsung)\s+([A-Za-z0-9\s\-]{2,20})',
        caseSensitive: false);
    final warrantyRegex = RegExp(
        r'(?:warranty\s*expiry|w\.?e\.?|warranty|expires?)[:\s-]*(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})',
        caseSensitive: false);
    final dateRegex =
        RegExp(r'(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})', caseSensitive: false);

    final emailMatch = emailRegex.firstMatch(joined);
    if (emailMatch != null) {
      result['email'] = emailMatch.group(0)!.toLowerCase();
    }

    // Extract device identifiers and model information
    for (final line in lines) {
      // Skip MAC addresses and country codes
      if (_isIgnorableIdentifier(line)) continue;

      if (!result.containsKey('assetTag')) {
        final match = assetRegex.firstMatch(line);
        if (match != null) {
          result['assetTag'] = match.group(1) ?? '';
          continue;
        }
      }

      if (!result.containsKey('serviceTag')) {
        final match = serviceRegex.firstMatch(line);
        if (match != null) {
          result['serviceTag'] = match.group(1) ?? '';
          continue;
        }
      }

      if (!result.containsKey('serial')) {
        final match = serialRegex.firstMatch(line);
        if (match != null) {
          result['serial'] = match.group(1) ?? '';
          continue;
        }
      }

      // Extract model information
      if (!result.containsKey('makeModel')) {
        // Try manufacturer-specific pattern first
        final manufacturerMatch = manufacturerRegex.firstMatch(line);
        if (manufacturerMatch != null) {
          final manufacturer = manufacturerMatch.group(1) ?? '';
          final model = manufacturerMatch.group(2) ?? '';
          result['makeModel'] = '$manufacturer $model'.trim();
          continue;
        }

        // Try generic model pattern
        final modelMatch = modelRegex.firstMatch(line);
        if (modelMatch != null) {
          result['makeModel'] = (modelMatch.group(1) ?? '').trim();
          continue;
        }
      }

      // Extract warranty expiry
      if (!result.containsKey('warrantyExpiry')) {
        final warrantyMatch = warrantyRegex.firstMatch(line);
        if (warrantyMatch != null) {
          result['warrantyExpiry'] =
              _normalizeDate(warrantyMatch.group(1) ?? '');
          continue;
        }

        // Look for any date pattern as potential warranty date
        final dateMatch = dateRegex.firstMatch(line);
        if (dateMatch != null && _looksLikeWarrantyDate(line)) {
          result['warrantyExpiry'] = _normalizeDate(dateMatch.group(1) ?? '');
          continue;
        }
      }
    }

    // Estimate name and department by taking lines preceding email, if present.
    if (emailMatch != null) {
      final prefix = joined.substring(0, emailMatch.start).trim();
      final segments = prefix.split(RegExp(r'\s{2,}|,'));
      if (segments.isNotEmpty) {
        final candidate = segments.last.trim();
        if (candidate.split(' ').length >= 2) {
          result['name'] = candidate;
        }
      }
      if (segments.length >= 2) {
        result['department'] = segments[segments.length - 2].trim();
      }
    } else {
      final iterator = lines.iterator;
      if (iterator.moveNext()) {
        result['name'] = iterator.current;
        if (iterator.moveNext()) {
          result['department'] = iterator.current;
        }
      }
    }

    result['lines'] = lineList;
    return result;
  }

  double _estimateConfidence(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) {
      return 0;
    }
    final scores = <double>[];
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final averageConfidence = line.elements.fold<double>(
                0, (sum, element) => sum + (element.confidence ?? 0)) /
            (line.elements.isNotEmpty ? line.elements.length : 1);
        if (!averageConfidence.isNaN && averageConfidence > 0) {
          scores.add(averageConfidence);
        }
      }
    }
    if (scores.isEmpty) {
      return 0.5;
    }
    scores.sort();
    return scores[scores.length ~/ 2];
  }

  @override
  Future<void> dispose() async {
    await _textRecognizer.close();
  }

  bool _isIgnorableIdentifier(String text) {
    final upper = text.toUpperCase();
    // MAC address patterns
    if (RegExp(
            r'^[0-9A-F]{2}[:-][0-9A-F]{2}[:-][0-9A-F]{2}[:-][0-9A-F]{2}[:-][0-9A-F]{2}[:-][0-9A-F]{2}\$')
        .hasMatch(upper)) {
      return true;
    }
    // Country codes and common non-identifiers
    const ignorable = [
      'US',
      'USA',
      'UK',
      'CA',
      'FCC',
      'IC',
      'CE',
      'RoHS',
      'COUNTRY',
      'MADE IN'
    ];
    for (final ignore in ignorable) {
      if (upper.contains(ignore)) return true;
    }
    return false;
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

  bool _looksLikeWarrantyDate(String line) {
    final lower = line.toLowerCase();
    return lower.contains('warranty') ||
        lower.contains('expiry') ||
        lower.contains('expires') ||
        lower.contains('w.e') ||
        lower.contains('valid');
  }
}
