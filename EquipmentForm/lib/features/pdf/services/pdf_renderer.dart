import 'dart:collection';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:yaml/yaml.dart';

import '../../../data/models/session.dart';
import '../../session/domain/session_models.dart';

String _formatAccessoryLabel(String label) {
  final cleaned = label.trim();
  final normalized = cleaned.toUpperCase().replaceFirst(RegExp(r'^WITH\s+'), '');
  if (normalized.isEmpty) return 'WITH';
  return 'WITH $normalized';
}

class PdfTypography {
  PdfTypography({required this.regular, required this.bold});

  final pw.Font regular;
  final pw.Font bold;

  pw.TextStyle titleLarge() => pw.TextStyle(font: bold, fontSize: 22);
  pw.TextStyle titleMedium() => pw.TextStyle(font: bold, fontSize: 16);
  pw.TextStyle bodyMedium({bool boldWeight = false}) =>
      pw.TextStyle(font: boldWeight ? bold : regular, fontSize: 11, height: 1.2);
  pw.TextStyle bodySmall({bool boldWeight = false}) =>
      pw.TextStyle(font: boldWeight ? bold : regular, fontSize: 10, height: 1.2);
}

class PdfMeta {
  const PdfMeta({
    required this.title,
    required this.author,
    required this.subject,
    this.keywords = const <String>[],
  });

  final String title;
  final String author;
  final String subject;
  final List<String> keywords;
}

class PdfRenderer {
  static PdfTypography? _typography;
  static Map<String, dynamic>? _fieldMap;
  static String? _templateVersion;

  static String get templateVersion => _templateVersion ?? '0';

  Future<void> _ensureAssets() async {
    if (_typography == null) {
      final regularData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
      _typography = PdfTypography(
        regular: pw.Font.ttf(regularData),
        bold: pw.Font.ttf(boldData),
      );
    }
    if (_fieldMap == null) {
      final yamlString = await rootBundle.loadString('EquipmentForm/eqpt_template_ref/field_map.yaml');
      final yaml = loadYaml(yamlString) as YamlMap;
      _fieldMap = jsonDecode(jsonEncode(yaml)) as Map<String, dynamic>;
      _templateVersion = ((_fieldMap?['version']) ?? '0').toString();
    }
  }

  Future<Uint8List> render({
    required Session session,
    required AppSessionState state,
    DateTime? generatedAt,
    PdfMeta? meta,
  }) async {
    await _ensureAssets();
    final typography = _typography!;
    final theme = pw.ThemeData.withFont(
      base: typography.regular,
      bold: typography.bold,
    );
    final doc = pw.Document(
      theme: theme,
      title: meta?.title,
      author: meta?.author,
      subject: meta?.subject,
      keywords: meta?.keywords.join(', '),
    );
    final generated = generatedAt ?? DateTime.now();
    final config = _fieldMap?[session.formType.name] as Map<String, dynamic>? ?? const {};
    switch (session.formType) {
      case FormType.received:
        _buildReceived(doc, session, state, config, generated, typography);
        break;
      case FormType.returned:
        _buildReturned(doc, session, state, config, generated, typography);
        break;
      case FormType.replaced:
        _buildReplaced(doc, session, state, config, generated, typography);
        break;
    }

    return doc.save();
  }

  void _buildReceived(
    pw.Document doc,
    Session session,
    AppSessionState state,
    Map<String, dynamic> config,
    DateTime generated,
    PdfTypography typography,
  ) {
    final metadata = _metadataTable(session, generated, typography);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                config['title']?.toString() ?? 'EQUIPMENT RECEIVED FORM',
                style: typography.titleLarge(),
              ),
              pw.SizedBox(height: 16),
              metadata,
              pw.SizedBox(height: 16),
              _partySection(state.party, config['party'] as Map<String, dynamic>?, typography),
              pw.SizedBox(height: 16),
              _equipmentTable(state.equipment.primaries, config['table'] as Map<String, dynamic>?, typography),
              pw.SizedBox(height: 16),
              _workflowSection(session.formType, state.workflow, config['workflow'] as Map<String, dynamic>?, typography),
            ],
          );
        },
      ),
    );
  }

  void _buildReturned(
    pw.Document doc,
    Session session,
    AppSessionState state,
    Map<String, dynamic> config,
    DateTime generated,
    PdfTypography typography,
  ) {
    final metadata = _metadataTable(session, generated, typography);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                config['title']?.toString() ?? 'EQUIPMENT RETURNED FORM',
                style: typography.titleLarge(),
              ),
              pw.SizedBox(height: 16),
              metadata,
              pw.SizedBox(height: 16),
              _partySection(state.party, config['party'] as Map<String, dynamic>?, typography),
              pw.SizedBox(height: 16),
              _equipmentTable(state.equipment.primaries, config['table'] as Map<String, dynamic>?, typography),
              pw.SizedBox(height: 16),
              _workflowSection(session.formType, state.workflow, config['workflow'] as Map<String, dynamic>?, typography),
            ],
          );
        },
      ),
    );
  }

  void _buildReplaced(
    pw.Document doc,
    Session session,
    AppSessionState state,
    Map<String, dynamic> config,
    DateTime generated,
    PdfTypography typography,
  ) {
    final metadata = _metadataTable(session, generated, typography);
    final newDevices = state.equipment.primaries.where((d) => !d.isReplacementOld).toList();
    final oldDevices = state.equipment.primaries.where((d) => d.isReplacementOld).toList();
    final photosConfig = config['photos'] as Map<String, dynamic>?;
    final newPhotoLabel = photosConfig?['newLabel']?.toString();
    final oldPhotoLabel = photosConfig?['oldLabel']?.toString();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                config['title']?.toString() ?? 'EQUIPMENT REPLACED FORM',
                style: typography.titleLarge(),
              ),
              pw.SizedBox(height: 16),
              metadata,
              pw.SizedBox(height: 16),
              _partySection(state.party, config['party'] as Map<String, dynamic>?, typography),
              pw.SizedBox(height: 16),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(config['newLabel']?.toString() ?? 'NEW DEVICE', style: typography.titleMedium()),
                        pw.SizedBox(height: 8),
                        _equipmentTable(newDevices, config['table'] as Map<String, dynamic>?, typography),
                        if (newPhotoLabel != null) ...[
                          pw.SizedBox(height: 12),
                          _photoFrame(newPhotoLabel, typography),
                        ],
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(config['oldLabel']?.toString() ?? 'OLD DEVICE', style: typography.titleMedium()),
                        pw.SizedBox(height: 8),
                        _equipmentTable(oldDevices, config['table'] as Map<String, dynamic>?, typography),
                        if (oldPhotoLabel != null) ...[
                          pw.SizedBox(height: 12),
                          _photoFrame(oldPhotoLabel, typography),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              _workflowSection(session.formType, state.workflow, config['workflow'] as Map<String, dynamic>?, typography),
            ],
          );
        },
      ),
    );
  }

  pw.Widget _metadataTable(Session session, DateTime generated, PdfTypography typography) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final data = [
      ['Form Type', session.formType.name.toUpperCase()],
      ['Session ID', session.id],
      ['Generated', dateFormat.format(generated)],
    ];
    return pw.TableHelper.fromTextArray(
      data: data,
      border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.5),
      headerCount: 0,
      cellAlignment: pw.Alignment.centerLeft,
      cellStyle: typography.bodySmall(),
    );
  }

  pw.Widget _partySection(PartySessionState party, Map<String, dynamic>? config, PdfTypography typography) {
    final headers = ['Role', 'Name', 'Department', 'Email'];
    final rows = party.members.entries.map((entry) {
      final label = config?[entry.key.name]?.toString() ?? entry.key.label;
      final name = entry.value.fields[PartyField.name]?.value ?? '';
      final dept = entry.value.fields[PartyField.department]?.value ?? '';
      final email = entry.value.fields[PartyField.email]?.value ?? '';
      return [label, name, dept, email];
    }).toList();
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      headerStyle: typography.bodyMedium(boldWeight: true),
      cellAlignment: pw.Alignment.centerLeft,
      cellStyle: typography.bodySmall(),
    );
  }

  pw.Widget _equipmentTable(List<PrimaryDeviceState> devices, Map<String, dynamic>? config, PdfTypography typography) {
    final leftHeader = config?['leftHeader']?.toString() ?? 'Equipment Make / Model';
    final rightHeader = config?['rightHeader']?.toString() ?? 'Equipment Serial / Details';
    final rows = <List<String>>[];
    for (final device in devices) {
      final accessoryLines = LinkedHashSet<String>.from(
        device.accessories
            .where((a) => a.selected)
            .map((a) => _formatAccessoryLabel(a.label)),
      );
      final left = ([device.displayMakeModel, ...accessoryLines])
          .where((line) => line.trim().isNotEmpty)
          .join('\n');
      final right = _deviceDetails(device).join('\n');
      rows.add([left.isEmpty ? '—' : left, right.isEmpty ? '—' : right]);
    }
    if (rows.isEmpty) {
      rows.add(['—', '—']);
    }
    return pw.TableHelper.fromTextArray(
      headers: [leftHeader, rightHeader],
      data: rows,
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      headerStyle: typography.bodyMedium(boldWeight: true),
      cellAlignment: pw.Alignment.topLeft,
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(2),
      },
      cellStyle: typography.bodySmall(),
    );
  }

  List<String> _deviceDetails(PrimaryDeviceState device) {
    final details = <String>[];
    if (device.type == PrimaryDeviceType.laptop) {
      if ((device.assetTag ?? '').isNotEmpty) details.add('ASSET-TAG: ${device.assetTag}');
      if ((device.serviceTag ?? '').isNotEmpty) details.add('SERVICE TAG: ${device.serviceTag}');
      if ((device.warrantyExpiry ?? '').isNotEmpty) details.add('W.E.: ${device.warrantyExpiry}');
    } else {
      if ((device.imei ?? '').isNotEmpty) details.add('IMEI: ${device.imei}');
      if ((device.serialNumber ?? '').isNotEmpty) details.add('SERIAL: ${device.serialNumber}');
      if ((device.assetTag ?? '').isNotEmpty) details.add('ASSET-TAG: ${device.assetTag}');
    }
    return details;
  }

  pw.Widget _workflowSection(
    FormType formType,
    WorkflowSessionState workflow,
    Map<String, dynamic>? config,
    PdfTypography typography,
  ) {
    final rows = <List<String>>[];
    switch (formType) {
      case FormType.received:
        rows.add([
          config?['dateReceived']?.toString() ?? 'Date Received',
          workflow.dateReceived != null ? DateFormat('yyyy-MM-dd').format(workflow.dateReceived!) : '—',
        ]);
        break;
      case FormType.returned:
        rows.add([
          config?['dateReturned']?.toString() ?? 'Date Returned',
          workflow.dateReturned != null ? DateFormat('yyyy-MM-dd').format(workflow.dateReturned!) : '—',
        ]);
        rows.add([
          config?['dataHandling']?.toString() ?? 'Data Handling Confirmed',
          workflow.dataHandlingConfirmed ? '[x]' : '[ ]',
        ]);
        break;
      case FormType.replaced:
        rows.add([
          config?['newDate']?.toString() ?? 'New Device Received',
          workflow.dateReceived != null ? DateFormat('yyyy-MM-dd').format(workflow.dateReceived!) : '—',
        ]);
        rows.add([
          config?['oldDate']?.toString() ?? 'Old Device Returned',
          workflow.dateReturned != null ? DateFormat('yyyy-MM-dd').format(workflow.dateReturned!) : '—',
        ]);
        rows.add([
          config?['dataHandling']?.toString() ?? 'Data Handling Confirmed',
          workflow.dataHandlingConfirmed ? '[x]' : '[ ]',
        ]);
        break;
    }
    if (workflow.location != null) {
      rows.add([
        config?['location']?.toString() ?? 'Location',
        workflow.location!.label,
      ]);
    }
    return pw.TableHelper.fromTextArray(
      data: rows,
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      headerCount: 0,
      cellAlignment: pw.Alignment.centerLeft,
      cellStyle: typography.bodySmall(),
    );
  }

  pw.Widget _photoFrame(String label, PdfTypography typography) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: typography.bodySmall(boldWeight: true)),
        pw.SizedBox(height: 4),
        pw.Container(
          height: 120,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey500, width: 1),
          ),
          alignment: pw.Alignment.center,
          child: pw.Text('Photo'),
        ),
      ],
    );
  }
}
