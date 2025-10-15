import 'package:flutter_test/flutter_test.dart';

import 'package:equipment_form_app/features/ocr/utils/text_normalizer.dart';

void main() {
  const normalizer = TextNormalizer();

  group('TextNormalizer.normalizeIdentifier', () {
    test('uppercases and strips separators', () {
      expect(normalizer.normalizeIdentifier(' ab-12 '), equals('AB12'));
    });

    test('replaces lookalike characters', () {
      expect(normalizer.normalizeIdentifier('O1LS'), equals('0115'));
    });
  });

  group('TextNormalizer.normalizeName', () {
    test('capitalizes each word and collapses spaces', () {
      expect(normalizer.normalizeName('  joHN   doE '), equals('John Doe'));
    });
  });
}
