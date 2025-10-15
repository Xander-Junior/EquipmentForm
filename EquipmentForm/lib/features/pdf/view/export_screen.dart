import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../app/di.dart';
import '../../../data/models/session.dart';
import '../../session/domain/session_models.dart';
import '../../ocr/state/ocr_controller.dart';
import '../../pdf/services/pdf_renderer.dart';
import '../../shared/services/export_utils.dart';
import '../../shared/state/export_diagnostics.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key, this.formType, this.fields});

  final FormType? formType;
  final Map<String, dynamic>? fields;

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  bool _isExporting = false;
  String? _lastExportPath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = widget.formType?.name ?? 'unknown';

    return Scaffold(
      appBar: AppBar(title: Text('Export — ${label.toUpperCase()}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Finalize and export the ${label.toUpperCase()} form.',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            if (_isExporting) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 12),
              const Text('Generating PDF…'),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _handleExport,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Generate PDF'),
              ),
            ],
            if (_lastExportPath != null) ...[
              const SizedBox(height: 16),
              const Text('Last export saved to:'),
              Text(_lastExportPath!,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleExport() async {
    if (_isExporting) return;
    final payload = widget.fields ?? const <String, dynamic>{};
    final appState =
        _legacyStateFromPayload(payload, widget.formType ?? FormType.received);

    final now = DateTime.now();
    final session = Session(
      id: 'session-${now.millisecondsSinceEpoch}-${Random().nextInt(9999)}',
      formType: widget.formType ?? FormType.received,
      payload: payload,
      createdAt: now,
      updatedAt: now,
    );

    setState(() => _isExporting = true);
    try {
      final repository = ref.read(sessionRepositoryProvider);
      await repository.save(session);

      final renderer = ref.read(pdfRendererProvider);
      final meta = PdfMeta(
        title: 'Equipment ${session.formType.name.toUpperCase()} Form',
        author: 'EquipmentForm App',
        subject: 'Equipment ${session.formType.name} export',
        keywords: ['equipment', session.formType.name, 'pdf'],
      );
      final pdfBytes = await renderer.render(
        session: session,
        state: appState,
        generatedAt: now,
        meta: meta,
      );

      final directory = await getApplicationDocumentsDirectory();
      final filename = buildExportFileName(appState, session.formType, now);
      final file = File(p.join(directory.path, filename));
      await file.writeAsBytes(pdfBytes, flush: true);

      final ocrState = ref.read(ocrControllerProvider);
      final ocrService = ref.read(ocrServiceProvider);
      final diagnostics = ExportDiagnostics(
        timestamp: now,
        formType: session.formType,
        templateVersion: PdfRenderer.templateVersion,
        engineId: ocrService.engineId,
        engineVersion: ocrService.engineVersion,
        device: Platform.operatingSystem,
        osVersion: Platform.operatingSystemVersion,
        usedPreprocessing: ocrState.lastUsedPreprocessing,
        confidence: ocrState.result?.confidence,
        latencyMs: ocrState.result?.latency?.inMilliseconds,
        pdfPath: file.path,
        fileName: filename,
      );
      ref.read(exportDiagnosticsProvider.notifier).state = diagnostics;

      final auditPayload = buildAuditPayload(
        session: session,
        state: appState,
        diagnostics: diagnostics,
        templateVersion: PdfRenderer.templateVersion,
        pdfPath: file.path,
      );
      final auditFile = File(p.setExtension(file.path, '.audit.json'));
      await auditFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(auditPayload),
        flush: true,
      );

      if (!mounted) return;
      setState(() => _lastExportPath = file.path);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF exported to ${file.path}')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export PDF: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  AppSessionState _legacyStateFromPayload(
      Map<String, dynamic> payload, FormType formType) {
    final party = PartySessionState(members: {
      PartyRole.preparedBy: PartyMemberState(
        role: PartyRole.preparedBy,
        fields: {
          PartyField.name:
              PartyFieldState(value: payload['name']?.toString() ?? ''),
          PartyField.department:
              PartyFieldState(value: payload['department']?.toString() ?? ''),
          PartyField.email:
              PartyFieldState(value: payload['email']?.toString() ?? ''),
        },
      ),
      PartyRole.receivedBy: const PartyMemberState(
        role: PartyRole.receivedBy,
        fields: {
          PartyField.name: PartyFieldState(),
          PartyField.department: PartyFieldState(),
          PartyField.email: PartyFieldState(),
        },
      ),
    });

    final primary = PrimaryDeviceState(
      id: 'legacy-device',
      type: PrimaryDeviceType.laptop,
      makeModel: payload['makeModelDisplay']?.toString() ??
          payload['makeModel']?.toString() ??
          '',
      assetTag: payload['assetTag']?.toString(),
      serviceTag: payload['serviceTag']?.toString(),
      serialNumber: payload['serial']?.toString(),
      imei: payload['imei']?.toString(),
      warrantyExpiry: payload['warrantyExpiryDisplay']?.toString(),
      accessories: (payload['accessories'] as List?)
              ?.cast<String>()
              .map((label) =>
                  AccessoryState(id: label, label: label, selected: true))
              .toList() ??
          const [],
    );

    final equipment = EquipmentSessionState(primaries: [primary]);
    final workflow = WorkflowSessionState(
        formType: formType,
        location: LocationCode.acc,
        dateReceived: DateTime.now());
    return AppSessionState(
        party: party, equipment: equipment, workflow: workflow);
  }
}
