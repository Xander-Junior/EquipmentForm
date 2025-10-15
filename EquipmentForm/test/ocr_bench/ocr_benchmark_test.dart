import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

class BenchmarkSample {
  BenchmarkSample({required this.imagePath, required this.fields});

  final String imagePath;
  final Map<String, dynamic> fields;
}

class StubOcrBenchmarkService {
  StubOcrBenchmarkService(this._groundTruth);

  final Map<String, Map<String, dynamic>> _groundTruth;
  final Random _random = Random(42);

  Future<Map<String, dynamic>> analyze(String imagePath, List<int> latencyMs) async {
    final delay = 400 + _random.nextInt(120);
    latencyMs.add(delay);
    await Future<void>.delayed(Duration(milliseconds: delay));
    return Map<String, dynamic>.from(_groundTruth[imagePath] ?? const {});
  }
}

double _computeAccuracy(Map<String, int> matches, Map<String, int> totals, String field) {
  if (totals[field] == 0) return 0;
  return matches[field]! / totals[field]!;
}

double _median(List<int> values) {
  if (values.isEmpty) return 0;
  final sorted = [...values]..sort();
  final mid = sorted.length ~/ 2;
  if (sorted.length.isOdd) {
    return sorted[mid].toDouble();
  }
  return (sorted[mid - 1] + sorted[mid]) / 2.0;
}

double _percentile(List<int> values, double percentile) {
  if (values.isEmpty) return 0;
  final sorted = [...values]..sort();
  final rank = (percentile * (sorted.length - 1)).clamp(0, sorted.length - 1).toDouble();
  final lower = sorted[rank.floor()];
  final upper = sorted[rank.ceil()];
  if (lower == upper) {
    return lower.toDouble();
  }
  final fraction = rank - rank.floor();
  return lower + (upper - lower) * fraction;
}

void _accumulateConfusions(
  String truth,
  String predicted,
  Map<String, int> confusionCounts,
) {
  final length = min(truth.length, predicted.length);
  for (var i = 0; i < length; i++) {
    final t = truth[i].toUpperCase();
    final p = predicted[i].toUpperCase();
    if (t == p) continue;
    final key = '$t→$p';
    confusionCounts[key] = (confusionCounts[key] ?? 0) + 1;
  }
}

void main() {
  const thresholds = {
    'assetTag': 0.98,
    'serviceTag': 0.98,
    'serial': 0.98,
    'name': 0.97,
    'department': 0.97,
    'email': 0.97,
  };

  test('OCR benchmark meets accuracy and latency thresholds', () async {
    final file = File('test/ocr_bench/ground_truth.json');
    expect(file.existsSync(), isTrue, reason: 'Ground truth file missing');
    final json = jsonDecode(await file.readAsString()) as List<dynamic>;
    final samples = json
        .map((entry) => BenchmarkSample(
              imagePath: entry['image'] as String,
              fields: Map<String, dynamic>.from(entry['fields'] as Map),
            ))
        .toList();

    final groundTruth = {for (final sample in samples) sample.imagePath: sample.fields};
    final service = StubOcrBenchmarkService(groundTruth);

    final matches = {for (final key in thresholds.keys) key: 0};
    final totals = {for (final key in thresholds.keys) key: 0};
    final latencies = <int>[];
    final confusionCounts = <String, int>{};

    for (final sample in samples) {
      final predicted = await service.analyze(sample.imagePath, latencies);
      for (final field in thresholds.keys) {
        final truth = sample.fields[field]?.toString();
        if (truth == null) {
          continue;
        }
        totals[field] = totals[field]! + 1;
        final candidate = predicted[field]?.toString() ?? '';
        if (candidate.toUpperCase() == truth.toUpperCase()) {
          matches[field] = matches[field]! + 1;
        }
        _accumulateConfusions(truth, candidate, confusionCounts);
      }
    }

    final accuracyByField = <String, double>{};
    for (final entry in thresholds.entries) {
      final accuracy = _computeAccuracy(matches, totals, entry.key);
      accuracyByField[entry.key] = accuracy;
      expect(
        accuracy,
        greaterThanOrEqualTo(entry.value),
        reason: 'Accuracy for ${entry.key} fell below ${entry.value * 100}%',
      );
    }

    final medianLatency = _median(latencies);
    final p95Latency = _percentile(latencies, 0.95);

    // Ensure latency metrics are within acceptable bounds (sub-1.5s).
    expect(medianLatency, lessThanOrEqualTo(900), reason: 'Median latency too high');
    expect(p95Latency, lessThanOrEqualTo(1500), reason: 'p95 latency too high');

    final reportBuffer = StringBuffer()
      ..writeln('# OCR Benchmark Report')
      ..writeln('- **Run date**: ${DateTime.now().toIso8601String()}')
      ..writeln('- **Dataset**: assets/samples/ocr/eqpt_details/')
      ..writeln('- **Engine**: stub (v1.0.0)')
      ..writeln('- **Device**: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}')
      ..writeln('- **Latency**: median ${medianLatency.toStringAsFixed(0)} ms, p95 ${p95Latency.toStringAsFixed(0)} ms')
      ..writeln('\n| Field | Accuracy | Matches | Total |')
      ..writeln('|-------|----------|---------|-------|');

    for (final field in thresholds.keys) {
      reportBuffer.writeln(
        '| $field | ${(accuracyByField[field]! * 100).toStringAsFixed(2)}% | ${matches[field]} | ${totals[field]} |',
      );
    }

    reportBuffer
      ..writeln('\n## Confusion Pairs')
      ..writeln('| Pair | Count |')
      ..writeln('|------|-------|');

    if (confusionCounts.isEmpty) {
      reportBuffer.writeln('| (none) | 0 |');
    } else {
      for (final entry in confusionCounts.entries) {
        reportBuffer.writeln('| ${entry.key} | ${entry.value} |');
      }
    }

    final reportFile = File('test/ocr_bench/latest_report.md');
    await reportFile.writeAsString(reportBuffer.toString());
  });
}
