import 'dart:io';

import 'package:intl/intl.dart';

import '../../../data/models/session.dart';
import '../../session/domain/session_models.dart';
import '../state/export_diagnostics.dart';

String _sanitizeComponent(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return 'SESSION';
  return trimmed
      .replaceAll(RegExp(r'[^A-Za-z0-9\-]'), '-')
      .replaceAll(RegExp(r'-{2,}'), '-')
      .toUpperCase();
}

String deriveExportBaseName(AppSessionState state) {
  for (final device in state.equipment.primaries) {
    final assetTag = device.assetTag;
    if (assetTag != null && assetTag.trim().isNotEmpty) {
      return _sanitizeComponent(assetTag);
    }
  }

  final prepared = state.party.members[PartyRole.preparedBy];
  final name = prepared?.fields[PartyField.name]?.value;
  if (name != null && name.trim().isNotEmpty) {
    return _sanitizeComponent(name);
  }

  final requested = state.party.members[PartyRole.requestedBy];
  final reqName = requested?.fields[PartyField.name]?.value;
  if (reqName != null && reqName.trim().isNotEmpty) {
    return _sanitizeComponent(reqName);
  }

  return 'SESSION';
}

String buildExportFileName(
    AppSessionState state, FormType formType, DateTime timestamp) {
  final base = deriveExportBaseName(state);
  final date = DateFormat('yyyy-MM-dd').format(timestamp);
  final formLabel = formType.name.toUpperCase();
  return '$base-$formLabel-$date-v1.pdf';
}

Map<String, dynamic> buildAuditPayload({
  required Session session,
  required AppSessionState state,
  required ExportDiagnostics diagnostics,
  required String templateVersion,
  required String pdfPath,
}) {
  final parties = <String, Map<String, String>>{};
  state.party.members.forEach((role, member) {
    parties[role.name] = {
      for (final entry in member.fields.entries)
        entry.key.name: entry.value.value,
    };
  });

  final devices = state.equipment.primaries.map((device) {
    return {
      'id': device.id,
      'type': device.type.name,
      'makeModel': device.makeModel,
      'assetTag': device.assetTag,
      'serviceTag': device.serviceTag,
      'warrantyExpiry': device.warrantyExpiry,
      'imei': device.imei,
      'serialNumber': device.serialNumber,
      'isReplacementOld': device.isReplacementOld,
      'accessories': device.accessories
          .where((a) => a.selected)
          .map((a) => a.label)
          .toList(),
    };
  }).toList();

  return {
    'timestamp': diagnostics.timestamp.toIso8601String(),
    'formType': session.formType.name,
    'templateVersion': templateVersion,
    'pdf': {
      'fileName': diagnostics.fileName,
      'path': pdfPath,
    },
    'parties': parties,
    'canonicalDevices': devices,
    'workflow': {
      'location': state.workflow.location?.label,
      'dateReceived': state.workflow.dateReceived?.toIso8601String(),
      'dateReturned': state.workflow.dateReturned?.toIso8601String(),
      'dataHandlingConfirmed': state.workflow.dataHandlingConfirmed,
    },
    'ocr': {
      'engineId': diagnostics.engineId,
      'engineVersion': diagnostics.engineVersion,
      'confidence': diagnostics.confidence,
      'latencyMs': diagnostics.latencyMs,
      'usedPreprocessing': diagnostics.usedPreprocessing,
    },
    'deviceInfo': {
      'hostname': Platform.localHostname,
      'os': diagnostics.device,
      'osVersion': diagnostics.osVersion,
    },
    'source': {
      'app': 'EquipmentForm',
      'version': '1.0.0',
    },
  };
}
