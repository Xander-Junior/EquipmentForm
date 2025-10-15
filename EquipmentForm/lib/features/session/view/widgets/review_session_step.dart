import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../app/di.dart';
import '../../../../data/models/session.dart';
import '../../controllers/session_controller.dart';
import '../../domain/session_models.dart';
import '../../../shared/state/export_diagnostics.dart';
import '../../../shared/services/export_utils.dart';
import '../../../ocr/state/ocr_controller.dart';
import '../../../shared/domain/normalizers.dart';
import '../../../pdf/services/pdf_renderer.dart';
import 'equipment_row_simulator.dart';

final reviewStepActionProvider = Provider.autoDispose
    .family<_ReviewStepActionBridge, FormType>((ref, formType) {
  final bridge = _ReviewStepActionBridge(ref, formType);
  ref.onDispose(bridge.dispose);
  return bridge;
});

class _ReviewStepActionBridge {
  _ReviewStepActionBridge(this.ref, this.formType);

  final Ref ref;
  final FormType formType;
  VoidCallback? _exportCallback;

  void register(VoidCallback callback) => _exportCallback = callback;
  void unregister(VoidCallback callback) {
    if (identical(_exportCallback, callback)) {
      _exportCallback = null;
    }
  }

  void export() => _exportCallback?.call();

  void dispose() {
    _exportCallback = null;
  }
}

class ReviewSessionStep extends ConsumerStatefulWidget {
  const ReviewSessionStep({super.key, required this.formType});

  final FormType formType;

  @override
  ConsumerState<ReviewSessionStep> createState() => _ReviewSessionStepState();
}

class _ReviewSessionStepState extends ConsumerState<ReviewSessionStep> {
  bool _isExporting = false;
  String? _lastExportPath;
  late final _ReviewStepActionBridge _bridge;

  @override
  void initState() {
    super.initState();
    _bridge = ref.read(reviewStepActionProvider(widget.formType));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bridge.register(_handleExport);
  }

  @override
  void dispose() {
    _bridge.unregister(_handleExport);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionControllerProvider(widget.formType));
    final party = sessionState.party;
    final equipment = sessionState.equipment;
    final workflow = sessionState.workflow;
    final validationMessages = _collectValidationMessages(sessionState);
    final canExport = !_isExporting && validationMessages.isEmpty;

    return ListView(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      children: [
        Text('Review & Export', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        _SummaryCard(
          title: 'Parties',
          child: Column(
            children: party.members.values.map((member) {
              final lowConfidence = PartyField.values.any(
                  (field) => (member.fields[field]?.confidence ?? 1) < 0.85);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(member.role.label),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.fields[PartyField.name]?.value ?? ''),
                    Text(member.fields[PartyField.department]?.value ?? ''),
                    Text(member.fields[PartyField.email]?.value ?? ''),
                    if (lowConfidence)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Low OCR confidence — please verify',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        _SummaryCard(
          title: 'Equipment Rows',
          child: EquipmentRowSimulator(
            devices: equipment.primaries,
            formType: widget.formType,
            workflow: workflow,
          ),
        ),
        const SizedBox(height: 16),
        _SummaryCard(
          title: 'Workflow',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Location: ${workflow.location?.label ?? '—'}'),
              if (workflow.dateReceived != null)
                Text('Date Received: ${_format(workflow.dateReceived!)}'),
              if (workflow.dateReturned != null)
                Text('Date Returned: ${_format(workflow.dateReturned!)}'),
              if (widget.formType != FormType.received)
                Text(
                    'Data Handling Confirmed: ${workflow.dataHandlingConfirmed ? 'Yes' : 'No'}'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (validationMessages.isNotEmpty) ...[
          MaterialBanner(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: validationMessages.map(Text.new).toList(),
            ),
            actions: const [SizedBox.shrink()],
          ),
          const SizedBox(height: 16),
        ],
        if (_isExporting)
          const Center(child: CircularProgressIndicator())
        else
          ElevatedButton.icon(
            onPressed: canExport ? _handleExport : null,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Export PDF'),
          ),
        if (_lastExportPath != null) ...[
          const SizedBox(height: 12),
          Text('Saved to $_lastExportPath'),
        ],
      ],
    );
  }

  Future<void> _handleExport() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final sessionState = ref.read(sessionControllerProvider(widget.formType));
      final repository = ref.read(sessionRepositoryProvider);
      final renderer = ref.read(pdfRendererProvider);
      final now = DateTime.now();
      final session = Session(
        id: 'session-${now.millisecondsSinceEpoch}-${Random().nextInt(9999)}',
        formType: widget.formType,
        payload: sessionState.toJson(),
        createdAt: now,
        updatedAt: now,
      );
      await repository.save(session);

      final fileName = buildExportFileName(sessionState, widget.formType, now);
      final directory = await getApplicationDocumentsDirectory();
      final pdfPath = p.join(directory.path, fileName);

      final meta = PdfMeta(
        title: 'Equipment ${widget.formType.name.toUpperCase()} Form',
        author: 'EquipmentForm App',
        subject: 'Equipment ${widget.formType.name} export',
        keywords: ['equipment', widget.formType.name, 'pdf'],
      );

      final pdfBytes = await renderer.render(
        session: session,
        state: sessionState,
        generatedAt: now,
        meta: meta,
      );

      final file = File(pdfPath);
      await file.writeAsBytes(pdfBytes, flush: true);

      final ocrState = ref.read(ocrControllerProvider);
      final ocrService = ref.read(ocrServiceProvider);
      final diagnostics = ExportDiagnostics(
        timestamp: now,
        formType: widget.formType,
        templateVersion: PdfRenderer.templateVersion,
        engineId: ocrService.engineId,
        engineVersion: ocrService.engineVersion,
        device: Platform.operatingSystem,
        osVersion: Platform.operatingSystemVersion,
        usedPreprocessing: ocrState.lastUsedPreprocessing,
        confidence: ocrState.result?.confidence,
        latencyMs: ocrState.result?.latency?.inMilliseconds,
        pdfPath: pdfPath,
        fileName: fileName,
      );
      ref.read(exportDiagnosticsProvider.notifier).state = diagnostics;

      final auditPayload = buildAuditPayload(
        session: session,
        state: sessionState,
        diagnostics: diagnostics,
        templateVersion: PdfRenderer.templateVersion,
        pdfPath: pdfPath,
      );
      final auditFile = File(p.setExtension(pdfPath, '.audit.json'));
      await auditFile.writeAsString(
          const JsonEncoder.withIndent('  ').convert(auditPayload),
          flush: true);

      if (!mounted) return;
      setState(() => _lastExportPath = pdfPath);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF exported to $pdfPath')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  String _format(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  List<String> _collectValidationMessages(AppSessionState state) {
    final messages = <String>[];
    state.party.members.forEach((role, member) {
      for (final entry in member.fields.entries) {
        if (entry.value.value.trim().isEmpty) {
          messages.add('${role.label}: ${entry.key.label} is required');
        }
      }
    });

    for (final device in state.equipment.primaries) {
      final deviceLabel = device.displayMakeModel.isNotEmpty
          ? device.displayMakeModel
          : device.type.name.toUpperCase();
      if (device.makeModel.trim().isEmpty) {
        messages.add('$deviceLabel: Make / Model is required');
      }
      if (device.type == PrimaryDeviceType.laptop) {
        final assetError = validateAssetTag(device.assetTag);
        if (assetError != null) {
          messages.add('$deviceLabel: $assetError');
        }
        if ((device.serviceTag ?? '').trim().isEmpty) {
          messages.add('$deviceLabel: Service tag is required');
        }
      }
      if (device.type == PrimaryDeviceType.phone) {
        final imeiError = validateImei(device.imei);
        if (imeiError != null) {
          messages.add('$deviceLabel: $imeiError');
        }
      }
      if (device.warrantyExpiry != null &&
          normalizeWarrantyExpiry(device.warrantyExpiry) == null) {
        messages.add(
            '$deviceLabel: Warranty expiry must be DD/MM/YYYY or ISO date');
      }
    }

    if (widget.formType == FormType.returned ||
        widget.formType == FormType.replaced) {
      if (!state.workflow.dataHandlingConfirmed) {
        messages.add('Data handling confirmation is required');
      }
    }

    return messages;
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
