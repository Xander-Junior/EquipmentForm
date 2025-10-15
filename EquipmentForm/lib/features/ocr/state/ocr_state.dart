import 'package:freezed_annotation/freezed_annotation.dart';

import '../services/ocr_service.dart';

part 'ocr_state.freezed.dart';

@freezed
class OcrState with _$OcrState {
  const factory OcrState({
    @Default(false) bool isProcessing,
    OcrResult? result,
    String? errorMessage,
    @Default(false) bool lastUsedPreprocessing,
  }) = _OcrState;
}
