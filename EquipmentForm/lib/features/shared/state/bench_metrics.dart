import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BenchMetrics {
  const BenchMetrics({
    required this.runDate,
    required this.dataset,
    required this.engineId,
    required this.engineVersion,
    required this.device,
    required this.osVersion,
    required this.medianLatencyMs,
    required this.p95LatencyMs,
  });

  final DateTime runDate;
  final String dataset;
  final String engineId;
  final String engineVersion;
  final String device;
  final String osVersion;
  final int medianLatencyMs;
  final int p95LatencyMs;

  factory BenchMetrics.fromJson(Map<String, dynamic> json) {
    final latency = json['latency'] as Map<String, dynamic>? ?? const {};
    return BenchMetrics(
      runDate: DateTime.tryParse(json['runDate']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      dataset: json['dataset']?.toString() ?? 'unknown',
      engineId: json['engineId']?.toString() ?? 'unknown',
      engineVersion: json['engineVersion']?.toString() ?? 'unknown',
      device: json['device']?.toString() ?? 'unknown',
      osVersion: json['osVersion']?.toString() ?? 'unknown',
      medianLatencyMs:
          int.tryParse(latency['medianMs']?.toString() ?? '') ?? -1,
      p95LatencyMs: int.tryParse(latency['p95Ms']?.toString() ?? '') ?? -1,
    );
  }
}

final benchMetricsProvider = FutureProvider<BenchMetrics?>((ref) async {
  try {
    final raw =
        await rootBundle.loadString('assets/diagnostics/ocr_bench.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return BenchMetrics.fromJson(json);
  } catch (_) {
    return null;
  }
});
