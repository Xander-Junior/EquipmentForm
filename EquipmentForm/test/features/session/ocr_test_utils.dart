import 'dart:io';

import 'package:equipment_form_app/app/di.dart';
import 'package:equipment_form_app/features/ocr/services/ocr_service.dart';
import 'package:equipment_form_app/features/shared/services/image_normalizer.dart';
Future<File> loadSampleImage(String relativePath) async {
  final source = File(relativePath);
  if (!await source.exists()) {
    throw Exception('Sample image not found: $relativePath');
  }
  final directory = await Directory.systemTemp.createTemp('ocr_samples');
  final target = File('${directory.path}/${relativePath.split('/').last}');
  return source.copy(target.path);
}

class FakeOcrService implements OcrService {
  FakeOcrService(this.result);

  final OcrResult result;

  @override
  String get engineId => 'fake';

  @override
  String get engineVersion => '0.0.0';

  @override
  Future<OcrResult> analyze(File image, {Map<String, dynamic>? hints}) async {
    return result;
  }

  @override
  Future<void> dispose() async {}
}

class FakeImageNormalizer extends ImageNormalizer {
  FakeImageNormalizer(this.fixedFile) : super(logger: AppLogger());

  final File fixedFile;

  @override
  Future<NormalizedImage> normalize(
    File input, {
    required bool improveLegibility,
    ImageCropPreset? cropPreset,
  }) async {
    return NormalizedImage(
      file: fixedFile,
      legibilityApplied: improveLegibility,
      sharpness: 120,
      brightness: 128,
    );
  }
}
