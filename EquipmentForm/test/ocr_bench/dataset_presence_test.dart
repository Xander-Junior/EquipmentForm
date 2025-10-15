import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ocr sample dataset directory is present with files', () {
    final datasetDir = Directory('assets/samples/ocr/eqpt_details');
    expect(datasetDir.existsSync(), isTrue,
        reason: 'Expected assets/samples/ocr/eqpt_details directory to exist for OCR bench');

    final entries = datasetDir.listSync(recursive: true).whereType<File>().toList();
    expect(entries, isNotEmpty,
        reason: 'OCR benchmark dataset should contain at least one image file');
  });
}
