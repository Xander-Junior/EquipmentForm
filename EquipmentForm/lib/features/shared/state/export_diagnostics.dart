import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/session.dart' show FormType;

class ExportDiagnostics {
  const ExportDiagnostics({
    required this.timestamp,
    required this.formType,
    required this.templateVersion,
    required this.engineId,
    required this.engineVersion,
    required this.device,
    required this.osVersion,
    required this.usedPreprocessing,
    this.confidence,
    this.latencyMs,
    this.pdfPath,
    this.fileName,
  });

  final DateTime timestamp;
  final FormType formType;
  final String templateVersion;
  final String engineId;
  final String engineVersion;
  final String device;
  final String osVersion;
  final bool usedPreprocessing;
  final double? confidence;
  final int? latencyMs;
  final String? pdfPath;
  final String? fileName;
}

final exportDiagnosticsProvider = StateProvider<ExportDiagnostics?>((ref) => null);
