import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:equipment_form_app/data/models/session.dart';
import 'package:equipment_form_app/features/device/view/device_capture_screen.dart';
import 'package:equipment_form_app/features/session/ocr/device_ocr_analyzer.dart';
import 'package:equipment_form_app/features/session/view/widgets/device_sticker_wizard.dart';
import 'package:equipment_form_app/app/di.dart';
import 'package:equipment_form_app/features/ocr/services/ocr_service.dart';

import '../session/ocr_test_utils.dart';

void main() {
  group('Device Sticker OCR Integration Tests', () {
    testWidgets('device sticker analyzer produces correct suggestions',
        (tester) async {
      // Test the analyzer with sample device sticker data
      const analyzer = DeviceOcrAnalyzer();

      final stickerData = {
        'rawText':
            'Dell OptiPlex 7090\nAsset Tag: AB123456\nService Tag: 7XYZ890\nWarranty Expiry: 15/12/2025',
        'lines': [
          'Dell OptiPlex 7090',
          'Asset Tag: AB123456',
          'Service Tag: 7XYZ890',
          'Warranty Expiry: 15/12/2025',
        ],
        'assetTag': 'AB123456',
        'serviceTag': '7XYZ890',
        'makeModel': 'Dell OptiPlex 7090',
        'warrantyExpiry': '15/12/2025',
      };

      final analysis = analyzer.analyze(stickerData);

      // Verify asset tag extraction
      final assetTag = analysis.primarySuggestionFor('assetTag');
      expect(assetTag?.value, equals('AB123456'));
      expect(assetTag?.confidence, equals(DeviceOcrConfidence.high));

      // Verify service tag extraction
      final serviceTag = analysis.primarySuggestionFor('serviceTag');
      expect(serviceTag?.value, equals('7XYZ890'));
      expect(serviceTag?.confidence, equals(DeviceOcrConfidence.high));

      // Verify model extraction
      final model = analysis.primarySuggestionFor('makeModel');
      expect(model?.value,
          equals('Dell OptiPlex 7090')); // Correct capitalization
      expect(model?.confidence, equals(DeviceOcrConfidence.high));

      // Verify warranty extraction
      final warranty = analysis.primarySuggestionFor('warrantyExpiry');
      expect(warranty?.value, equals('15/12/2025'));
      expect(warranty?.confidence, equals(DeviceOcrConfidence.high));

      // Verify evidence and highlighting - use just the value for simplicity
      expect(assetTag?.evidence, isNotEmpty);
      expect(serviceTag?.evidence, isNotEmpty);
      expect(model?.evidence, isNotEmpty);
      expect(warranty?.evidence, isNotEmpty);
    });

    testWidgets('device sticker analyzer handles various manufacturer patterns',
        (tester) async {
      const analyzer = DeviceOcrAnalyzer();

      // Test HP pattern
      final hpAnalysis = analyzer.analyze({
        'rawText': 'HP ProBook 450\nSerial: ABC123DEF',
      });
      expect(hpAnalysis.primarySuggestionFor('makeModel')?.value,
          equals('HP ProBook 450'));

      // Test Lenovo pattern
      final lenovoAnalysis = analyzer.analyze({
        'rawText': 'Lenovo ThinkPad X1\nCarbon Gen 9',
      });
      expect(lenovoAnalysis.primarySuggestionFor('makeModel')?.value,
          equals('Lenovo ThinkPad X1'));

      // Test MacBook pattern
      final macAnalysis = analyzer.analyze({
        'rawText': 'MacBook Pro 14-inch\nApple Inc.',
      });
      expect(macAnalysis.primarySuggestionFor('makeModel')?.value,
          equals('MacBook Pro 14'));

      // Test Surface pattern
      final surfaceAnalysis = analyzer.analyze({
        'rawText': 'Surface Laptop 4\nMicrosoft Corporation',
      });
      expect(surfaceAnalysis.primarySuggestionFor('makeModel')?.value,
          equals('Surface Laptop 4'));
    });

    testWidgets('device sticker analyzer handles low confidence appropriately',
        (tester) async {
      const analyzer = DeviceOcrAnalyzer();

      final lowConfidenceData = {
        'rawText': 'Blurry text Asset: A8123 Service: 7XYZ890',
        'assetTag': 'A8123', // This might be misread
        'serviceTag': '7XYZ890',
      };

      final analysis = analyzer.analyze(lowConfidenceData);

      // Verify confidence calculations
      expect(analysis.primarySuggestionFor('assetTag')?.confidence,
          anyOf(DeviceOcrConfidence.medium, DeviceOcrConfidence.high));
      expect(analysis.primarySuggestionFor('serviceTag')?.confidence,
          anyOf(DeviceOcrConfidence.high, DeviceOcrConfidence.medium));

      // Verify suggestions are still provided
      expect(analysis.primarySuggestionFor('assetTag')?.value, equals('A8123'));
      expect(analysis.primarySuggestionFor('serviceTag')?.value,
          equals('7XYZ890'));
    });

    testWidgets('full sticker wizard applies all suggested fields',
        (tester) async {
      await tester.runAsync(() async {
        final tempDir = await Directory.systemTemp.createTemp('sticker_full');
        final tempFile = File('${tempDir.path}/sticker.jpg');
        await tempFile.writeAsBytes(const [0]);

        final ocrResult = OcrResult(fields: {
          'rawText':
              'Dell Latitude 5440\nAsset Tag: TL-123456\nService Tag: ABCD123\nW.E.: 12/06/2026',
          'lines': const [
            'Dell Latitude 5440',
            'Asset Tag: TL-123456',
            'Service Tag: ABCD123',
            'W.E.: 12/06/2026',
          ],
        }, confidence: 0.91);

        final completer = Completer<DeviceStickerWizardResult?>();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ocrServiceProvider.overrideWithValue(FakeOcrService(ocrResult)),
              imageNormalizerProvider
                  .overrideWith((ref) => FakeImageNormalizer(tempFile)),
              legibilityPreferenceProvider.overrideWith((ref) => false),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    final wizard = DeviceStickerWizard(ref);
                    Future.microtask(() async {
                      final result = await wizard.processImage(
                        context: context,
                        image: tempFile,
                        currentValues: {
                          'assetTag': 'OLD123',
                          'serviceTag': 'OLD456',
                          'makeModel': 'Old Model',
                          'warrantyExpiry': '01/01/2020',
                        },
                      );
                      completer.complete(result);
                    });
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('Device Sticker OCR Results'), findsOneWidget);

        await tester.tap(find.text('Apply'));
        await tester.pumpAndSettle();

        final result = await completer.future;
        expect(result, isNotNull);
        expect(result!.appliedValues['assetTag'], equals('TL-123456'));
        expect(result.appliedValues['serviceTag'], equals('ABCD123'));
        expect(result.appliedValues['makeModel'], equals('Dell Latitude 5440'));
        expect(result.appliedValues['warrantyExpiry'], equals('12/06/2026'));
        expect(result.previousValues['assetTag'], equals('OLD123'));
        expect(result.previousValues['serviceTag'], equals('OLD456'));
      });
    });

    testWidgets('sticker wizard leaves untouched fields unchanged',
        (tester) async {
      await tester.runAsync(() async {
        final tempDir = await Directory.systemTemp.createTemp('sticker_partial');
        final tempFile = File('${tempDir.path}/sticker.jpg');
        await tempFile.writeAsBytes(const [0]);

        final ocrResult = OcrResult(fields: {
          'rawText': 'Service Tag: ZXCV123',
          'lines': const ['Service Tag: ZXCV123'],
          'assetTag': 'UNCHANGED-1',
        }, confidence: 0.82);

        final completer = Completer<DeviceStickerWizardResult?>();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ocrServiceProvider.overrideWithValue(FakeOcrService(ocrResult)),
              imageNormalizerProvider
                  .overrideWith((ref) => FakeImageNormalizer(tempFile)),
              legibilityPreferenceProvider.overrideWith((ref) => false),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    final wizard = DeviceStickerWizard(ref);
                    Future.microtask(() async {
                      final result = await wizard.processImage(
                        context: context,
                        image: tempFile,
                        currentValues: {
                          'assetTag': 'UNCHANGED-1',
                          'serviceTag': 'OLD-SERVICE',
                          'makeModel': 'Existing Model',
                        },
                      );
                      completer.complete(result);
                    });
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('Device Sticker OCR Results'), findsOneWidget);

        await tester.tap(find.text('Apply'));
        await tester.pumpAndSettle();

        final result = await completer.future;
        expect(result, isNotNull);
        expect(result!.appliedValues['assetTag'], equals('UNCHANGED-1'));
        expect(result.appliedValues['serviceTag'], equals('ZXCV123'));
        expect(result.previousValues['assetTag'], equals('UNCHANGED-1'));
      });
    });
  });
}
