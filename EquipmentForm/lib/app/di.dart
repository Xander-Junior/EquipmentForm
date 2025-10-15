import 'dart:developer';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/session_database.dart';
import '../data/session_repository.dart';
import '../features/ocr/services/ocr_service.dart';
import '../features/ocr/services/ocr_service_mlkit.dart';
import '../features/pdf/services/pdf_renderer.dart';
import '../features/shared/services/image_normalizer.dart';
import '../features/shared/services/diagnostics_recorder.dart';

class AppLogger {
  void info(String message, {Object? error, StackTrace? stackTrace}) {
    log(message, name: 'EquipmentForm', error: error, stackTrace: stackTrace);
  }

  void error(String message, {Object? error, StackTrace? stackTrace}) {
    log(message, name: 'EquipmentForm', level: 1000, error: error, stackTrace: stackTrace);
  }
}

final appLoggerProvider = Provider<AppLogger>((ref) => AppLogger());

final sessionDatabaseProvider = Provider<SessionDatabase>((ref) {
  final database = SessionDatabase();
  ref.onDispose(() {
    database.close();
  });
  return database;
});

final secureStoreProvider = Provider<SecureStore>((ref) {
  return FlutterSecureStore();
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(
    database: ref.watch(sessionDatabaseProvider),
    secureStore: ref.watch(secureStoreProvider),
  );
});

final ocrServiceProvider = Provider<OcrService>((ref) {
  final logger = ref.watch(appLoggerProvider);
  if (Platform.isAndroid || Platform.isIOS) {
    final service = OcrServiceMlKit(logger: logger);
    ref.onDispose(() => service.dispose());
    return service;
  }
  return const NoopOcrService();
});

final pdfRendererProvider = Provider<PdfRenderer>((ref) => PdfRenderer());

final legibilityPreferenceProvider = StateProvider<bool>((ref) => true);

final imageNormalizerProvider = Provider<ImageNormalizer>((ref) {
  final logger = ref.watch(appLoggerProvider);
  return ImageNormalizer(logger: logger);
});

final diagnosticsRecorderProvider = Provider<DiagnosticsRecorder>((ref) {
  final logger = ref.watch(appLoggerProvider);
  return DiagnosticsRecorder(logger: logger);
});
