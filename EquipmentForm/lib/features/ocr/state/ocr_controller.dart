import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../services/ocr_service.dart';
import '../utils/text_normalizer.dart';
import '../../shared/domain/normalizers.dart';
import 'ocr_state.dart';

class OcrController extends StateNotifier<OcrState> {
  OcrController(this._service, this._normalizer, this._logger) : super(const OcrState());

  final OcrService _service;
  final TextNormalizer _normalizer;
  final AppLogger _logger;

  static const double lowConfidenceThreshold = 0.9;

  Future<void> analyze(
    File image, {
    bool usedPreprocessing = false,
  }) async {
    if (!image.existsSync()) {
      state = state.copyWith(errorMessage: 'Image not found: ${image.path}');
      return;
    }

    state = state.copyWith(isProcessing: true, errorMessage: null);
    final result = await _service.analyze(image, hints: {
      'expectedFields': ['name', 'department', 'email', 'assetTag', 'serviceTag', 'serial'],
      'preprocessed': usedPreprocessing,
    });

    // Apply normalization to numeric identifiers and names.
    final normalized = Map<String, dynamic>.from(result.fields);
    if (normalized['assetTag'] is String) {
      final canonical = normalizeAssetTag(normalized['assetTag'] as String);
      if (canonical != null) {
        normalized['assetTag'] = canonical;
      }
    }
    if (normalized['serviceTag'] is String) {
      normalized['serviceTag'] = _normalizer.normalizeIdentifier(normalized['serviceTag'] as String);
    }
    if (normalized['serial'] is String) {
      normalized['serial'] = _normalizer.normalizeIdentifier(normalized['serial'] as String);
    }
    if (normalized['imei'] is String) {
      normalized['imei'] = normalizeImei(normalized['imei'] as String);
    }
    if (normalized['warrantyExpiry'] is String) {
      final normalizedWe = normalizeWarrantyExpiry(normalized['warrantyExpiry'] as String);
      if (normalizedWe != null) {
        normalized['warrantyExpiry'] = normalizedWe;
      }
    }
    if (normalized['name'] is String) {
      normalized['name'] = _normalizer.normalizeName(normalized['name'] as String);
    }
    if (normalized['department'] is String) {
      normalized['department'] = _normalizer.normalizeName(normalized['department'] as String);
    }

    state = state.copyWith(
      isProcessing: false,
      result: result.copyWith(fields: normalized),
      lastUsedPreprocessing: usedPreprocessing,
    );

    if (result.confidence < lowConfidenceThreshold) {
      _logger.info('Low OCR confidence (${result.confidence}) for ${image.path}');
    }
  }

  void reset() {
    state = const OcrState();
  }
}

final ocrControllerProvider = StateNotifierProvider<OcrController, OcrState>((ref) {
  return OcrController(
    ref.watch(ocrServiceProvider),
    const TextNormalizer(),
    ref.watch(appLoggerProvider),
  );
});
