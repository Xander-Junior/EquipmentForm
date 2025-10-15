import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../ocr/state/ocr_controller.dart';
import '../../pdf/services/pdf_renderer.dart';
import '../state/bench_metrics.dart';
import '../state/export_diagnostics.dart';

class DiagnosticsScreen extends ConsumerWidget {
  const DiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ocrService = ref.watch(ocrServiceProvider);
    final legibilityEnabled = ref.watch(legibilityPreferenceProvider);
    final thresholds = {
      'asset/service/serial': '≥ 98%',
      'name/department/email': '≥ 97%',
      'latency median': '≤ 900 ms',
      'latency p95': '≤ 1500 ms',
    };
    final diagnostics = ref.watch(exportDiagnosticsProvider);
    final benchMetricsAsync = ref.watch(benchMetricsProvider);
    final benchMetrics = benchMetricsAsync.asData?.value;

    Map<String, dynamic> diagnosticsPayload(
      ExportDiagnostics? snapshot,
      BenchMetrics? bench,
    ) {
      return {
        'templateVersion': PdfRenderer.templateVersion,
        'device': {
          'hostname': Platform.localHostname,
          'os': Platform.operatingSystem,
          'osVersion': Platform.operatingSystemVersion,
        },
        'legibilityPreprocessingEnabled': legibilityEnabled,
        'ocrEngine': {
          'engineId': ocrService.engineId,
          'engineVersion': ocrService.engineVersion,
        },
        'bench': bench == null
            ? null
            : {
                'runDate': bench.runDate.toIso8601String(),
                'dataset': bench.dataset,
                'engineId': bench.engineId,
                'engineVersion': bench.engineVersion,
                'device': bench.device,
                'osVersion': bench.osVersion,
                'medianLatencyMs': bench.medianLatencyMs,
                'p95LatencyMs': bench.p95LatencyMs,
              },
        'lastExport': snapshot == null
            ? null
            : {
                'timestamp': snapshot.timestamp.toIso8601String(),
                'formType': snapshot.formType.name,
                'templateVersion': snapshot.templateVersion,
                'confidence': snapshot.confidence,
                'latencyMs': snapshot.latencyMs,
                'usedPreprocessing': snapshot.usedPreprocessing,
                'fileName': snapshot.fileName,
                'pdfPath': snapshot.pdfPath,
                'device': snapshot.device,
                'osVersion': snapshot.osVersion,
              },
        'thresholds': thresholds,
      };
    }

    const jsonEncoder = JsonEncoder.withIndent('  ');
    String diagnosticsJsonString() =>
        jsonEncoder.convert(diagnosticsPayload(diagnostics, benchMetrics));
    final diagnosticsJson = diagnosticsJsonString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy diagnostics',
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: diagnosticsJsonString()),
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Diagnostics copied to clipboard')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoTile(
              title: 'Template Version', value: PdfRenderer.templateVersion),
          _InfoTile(title: 'Device', value: Platform.localHostname),
          _InfoTile(title: 'OS', value: Platform.operatingSystem),
          _InfoTile(
              title: 'OS Version', value: Platform.operatingSystemVersion),
          const Divider(),
          _InfoTile(title: 'OCR Engine', value: ocrService.engineId),
          _InfoTile(title: 'OCR Version', value: ocrService.engineVersion),
          _InfoTile(
            title: 'Low confidence threshold',
            value:
                '${(OcrController.lowConfidenceThreshold * 100).toStringAsFixed(0)}%',
          ),
          _InfoTile(
            title: 'Legibility preprocessing',
            value: legibilityEnabled ? 'Enabled' : 'Disabled',
          ),
          const Divider(),
          const Text('Last Export',
              style: TextStyle(fontWeight: FontWeight.bold)),
          if (diagnostics != null) ...[
            _InfoTile(
                title: 'Form Type',
                value: diagnostics.formType.name.toUpperCase()),
            _InfoTile(
                title: 'Template Version', value: diagnostics.templateVersion),
            _InfoTile(
                title: 'Preprocessing Used',
                value: diagnostics.usedPreprocessing ? 'Yes' : 'No'),
            _InfoTile(
                title: 'Confidence',
                value: diagnostics.confidence?.toStringAsFixed(3) ?? 'n/a'),
            _InfoTile(
                title: 'Latency (ms)',
                value: diagnostics.latencyMs?.toString() ?? 'n/a'),
            _InfoTile(
                title: 'Exported File',
                value: diagnostics.fileName ?? diagnostics.pdfPath ?? 'n/a'),
          ] else
            const _InfoTile(title: 'Status', value: 'No export recorded'),
          const Divider(),
          const Text('Benchmark',
              style: TextStyle(fontWeight: FontWeight.bold)),
          benchMetricsAsync.when(
            data: (metrics) {
              if (metrics == null) {
                return const _InfoTile(
                    title: 'Status', value: 'No benchmark report');
              }
              final median = metrics.medianLatencyMs >= 0
                  ? '${metrics.medianLatencyMs}'
                  : 'n/a';
              final p95 =
                  metrics.p95LatencyMs >= 0 ? '${metrics.p95LatencyMs}' : 'n/a';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _InfoTile(
                      title: 'Run Date',
                      value: metrics.runDate.toIso8601String()),
                  _InfoTile(
                    title: 'Bench Engine',
                    value: '${metrics.engineId} (${metrics.engineVersion})',
                  ),
                  _InfoTile(
                    title: 'Bench Device',
                    value: '${metrics.device} ${metrics.osVersion}',
                  ),
                  _InfoTile(title: 'Median Latency (ms)', value: median),
                  _InfoTile(title: 'p95 Latency (ms)', value: p95),
                  _InfoTile(title: 'Dataset', value: metrics.dataset),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            ),
            error: (_, __) =>
                const _InfoTile(title: 'Benchmark', value: 'Failed to load'),
          ),
          const Divider(),
          const Text('CI Thresholds',
              style: TextStyle(fontWeight: FontWeight.bold)),
          ...thresholds.entries
              .map((entry) => _InfoTile(title: entry.key, value: entry.value)),
          const Divider(),
          const Text('Diagnostics JSON',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              diagnosticsJson,
              style: const TextStyle(fontFamily: 'RobotoMono', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
              child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
          const SizedBox(width: 12),
          Expanded(child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
