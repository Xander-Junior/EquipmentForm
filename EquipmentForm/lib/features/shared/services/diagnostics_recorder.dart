import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../app/di.dart';

class DiagnosticsRecorder {
  DiagnosticsRecorder({required this.logger});

  final AppLogger logger;

  Future<void> capture({
    required File image,
    required Map<String, dynamic> metadata,
    required Map<String, dynamic> ocrFields,
  }) async {
    if (kReleaseMode) return;
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final diagnosticsDir = Directory(p.join(documentsDir.path, 'diagnostics'));
      await diagnosticsDir.create(recursive: true);

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final baseName = 'capture_$timestamp';

      final targetImage = File(p.join(diagnosticsDir.path, '$baseName.jpg'));
      await image.copy(targetImage.path);

      final payload = {
        'metadata': {
          ...metadata,
          'platform': Platform.operatingSystem,
          'platformVersion': Platform.operatingSystemVersion,
        },
        'ocr': ocrFields,
        'sourceImage': targetImage.path,
      };
      final jsonFile = File(p.join(diagnosticsDir.path, '$baseName.json'));
      await jsonFile.writeAsString(const JsonEncoder.withIndent('  ').convert(payload), flush: true);

      logger.info('Diagnostics saved to ${jsonFile.path}');
    } catch (error, stackTrace) {
      logger.error('Failed to record diagnostics', error: error, stackTrace: stackTrace);
    }
  }
}
