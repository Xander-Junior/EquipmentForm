import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'ocr_service.freezed.dart';

@freezed
class OcrResult with _$OcrResult {
  const factory OcrResult({
    required Map<String, dynamic> fields,
    required double confidence,
    Duration? latency,
  }) = _OcrResult;
}

/// Abstraction over any OCR engine used in the app.
abstract class OcrService {
  String get engineId;
  String get engineVersion;
  /// Processes the provided [image] and returns structured data when possible.
  Future<OcrResult> analyze(File image, {Map<String, dynamic>? hints});
  Future<void> dispose() async {}
}

/// Temporary no-op implementation to unblock wiring for later milestones.
class NoopOcrService implements OcrService {
  const NoopOcrService();

  @override
  String get engineId => 'noop';

  @override
  String get engineVersion => '0.0.0';

  @override
  Future<OcrResult> analyze(File image, {Map<String, dynamic>? hints}) async {
    return const OcrResult(fields: <String, dynamic>{}, confidence: 0);
  }

  @override
  Future<void> dispose() async {}
}
