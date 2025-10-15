import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:equipment_form_app/data/models/session.dart';
import 'package:equipment_form_app/features/session/domain/session_models.dart';
import 'package:equipment_form_app/features/shared/services/export_utils.dart';
import 'package:equipment_form_app/features/shared/state/export_diagnostics.dart';

void main() {
  group('export utils', () {
    test('buildExportFileName prefers asset tag', () {
      const state = AppSessionState(
        party: PartySessionState(members: {
          PartyRole.preparedBy: PartyMemberState(
            role: PartyRole.preparedBy,
            fields: {
              PartyField.name: PartyFieldState(value: 'Pat Prep'),
              PartyField.department: PartyFieldState(value: 'Digital'),
              PartyField.email: PartyFieldState(value: 'pat@tullowoil.com'),
            },
          ),
        }),
        equipment: EquipmentSessionState(primaries: [
          PrimaryDeviceState(
            id: '1',
            type: PrimaryDeviceType.laptop,
            makeModel: 'Dell',
            assetTag: 'ACC-LT-12345',
            serviceTag: 'SERV',
          ),
        ]),
        workflow: WorkflowSessionState(
            formType: FormType.received, location: LocationCode.acc),
      );

      final fileName =
          buildExportFileName(state, FormType.received, DateTime(2025, 1, 1));
      expect(fileName, 'ACC-LT-12345-RECEIVED-2025-01-01-v1.pdf');
    });

    test('buildExportFileName falls back to prepared name', () {
      const state = AppSessionState(
        party: PartySessionState(members: {
          PartyRole.preparedBy: PartyMemberState(
            role: PartyRole.preparedBy,
            fields: {
              PartyField.name:
                  PartyFieldState(value: 'Ada Lovelace-Smith'),
              PartyField.department:
                  PartyFieldState(value: 'Digital Engineering'),
              PartyField.email:
                  PartyFieldState(value: 'ada.love@tullowoil.com'),
            },
          ),
        }),
        equipment: EquipmentSessionState(primaries: [
          PrimaryDeviceState(
            id: '1',
            type: PrimaryDeviceType.laptop,
            makeModel: 'Dell',
          ),
        ]),
        workflow: WorkflowSessionState(
          formType: FormType.received,
          location: LocationCode.acc,
        ),
      );

      final fileName =
          buildExportFileName(state, FormType.received, DateTime(2025, 2, 2));
      expect(fileName, 'ADA-LOVELACE-SMITH-RECEIVED-2025-02-02-v1.pdf');
    });

    test('buildExportFileName uses session fallback when identifiers missing', () {
      const state = AppSessionState(
        party: PartySessionState(members: {
          PartyRole.preparedBy: PartyMemberState(
            role: PartyRole.preparedBy,
            fields: {
              PartyField.name: PartyFieldState(value: ''),
              PartyField.department: PartyFieldState(value: ''),
              PartyField.email: PartyFieldState(value: ''),
            },
          ),
        }),
        equipment: EquipmentSessionState(primaries: [
          PrimaryDeviceState(
            id: '1',
            type: PrimaryDeviceType.laptop,
            makeModel: 'Dell',
          ),
        ]),
        workflow: WorkflowSessionState(
          formType: FormType.received,
          location: LocationCode.acc,
        ),
      );

      final fileName =
          buildExportFileName(state, FormType.received, DateTime(2025, 3, 3));
      expect(fileName, 'SESSION-RECEIVED-2025-03-03-v1.pdf');
    });

    test('buildAuditPayload contains parties and devices', () {
      final session = Session(
        id: 'session-1',
        formType: FormType.received,
        payload: const {},
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1, 1),
      );
      const state = AppSessionState(
        party: PartySessionState(members: {
          PartyRole.requestedBy: PartyMemberState(
            role: PartyRole.requestedBy,
            fields: {
              PartyField.name: PartyFieldState(value: 'Requester'),
              PartyField.department: PartyFieldState(value: 'Ops'),
              PartyField.email: PartyFieldState(value: 'req@tullowoil.com'),
            },
          ),
        }),
        equipment: EquipmentSessionState(primaries: [
          PrimaryDeviceState(
            id: 'dev',
            type: PrimaryDeviceType.phone,
            makeModel: 'iPhone',
            assetTag: 'TAK-MB-54321',
            imei: '352099001761487',
            serialNumber: 'SN001',
            accessories: [
              AccessoryState(id: 'a', label: 'WITH CHARGER', selected: true)
            ],
          ),
        ]),
        workflow: WorkflowSessionState(
            formType: FormType.received, location: LocationCode.tak),
      );
      final diagnostics = ExportDiagnostics(
        timestamp: DateTime(2025, 1, 1, 12),
        formType: FormType.received,
        templateVersion: '2',
        engineId: 'engine',
        engineVersion: '1.0',
        device: 'macos',
        osVersion: '13.0',
        usedPreprocessing: true,
        confidence: 0.99,
        latencyMs: 840,
        pdfPath: '/tmp/test.pdf',
        fileName: 'TEST.pdf',
      );

      final payload = buildAuditPayload(
        session: session,
        state: state,
        diagnostics: diagnostics,
        templateVersion: '2',
        pdfPath: '/tmp/test.pdf',
      );

      expect(payload['parties'], contains('requestedBy'));
      expect(payload['canonicalDevices'], isA<List>());
      expect(jsonEncode(payload), contains('352099001761487'));
    });

    test('buildAuditPayload includes mandatory schema entries', () {
      final session = Session(
        id: 'session-schema',
        formType: FormType.replaced,
        payload: const {},
        createdAt: DateTime(2025, 4, 1),
        updatedAt: DateTime(2025, 4, 1, 12),
      );
      const state = AppSessionState(
        party: PartySessionState(members: {
          PartyRole.preparedBy: PartyMemberState(
            role: PartyRole.preparedBy,
            fields: {
              PartyField.name: PartyFieldState(value: 'Pat Prep'),
              PartyField.department: PartyFieldState(value: 'Digital'),
              PartyField.email: PartyFieldState(value: 'pat@tullowoil.com'),
            },
          ),
          PartyRole.requestedBy: PartyMemberState(
            role: PartyRole.requestedBy,
            fields: {
              PartyField.name: PartyFieldState(value: 'Requester'),
              PartyField.department: PartyFieldState(value: 'Ops'),
              PartyField.email: PartyFieldState(value: 'req@tullowoil.com'),
            },
          ),
        }),
        equipment: EquipmentSessionState(primaries: [
          PrimaryDeviceState(
            id: 'new',
            type: PrimaryDeviceType.laptop,
            makeModel: '7420',
            assetTag: 'ACC-LT-9999',
            serviceTag: 'SERV999',
          ),
        ]),
        workflow: WorkflowSessionState(
          formType: FormType.replaced,
          location: LocationCode.acc,
          dataHandlingConfirmed: true,
        ),
      );
      final diagnostics = ExportDiagnostics(
        timestamp: DateTime(2025, 4, 1, 12),
        formType: FormType.replaced,
        templateVersion: '3',
        engineId: 'ocr-test',
        engineVersion: '1.5.0',
        device: 'macos',
        osVersion: '14.4',
        usedPreprocessing: false,
        confidence: 0.92,
        latencyMs: 734,
        pdfPath: '/tmp/replaced.pdf',
        fileName: 'ACC-LT-9999-REPLACED-2025-04-01-v1.pdf',
      );

      final payload = buildAuditPayload(
        session: session,
        state: state,
        diagnostics: diagnostics,
        templateVersion: '3',
        pdfPath: '/tmp/replaced.pdf',
      );

      expect(payload, containsPair('timestamp', diagnostics.timestamp.toIso8601String()));
      expect(payload, containsPair('formType', 'replaced'));
      expect(payload, containsPair('templateVersion', '3'));
      expect(payload['parties'], isA<Map<String, dynamic>>());
      expect(payload['canonicalDevices'], isA<List>());
      expect(payload['ocr'], allOf(isA<Map<String, dynamic>>(), contains('engineVersion')));
      expect(payload['deviceInfo'], contains('hostname'));
      final pdf = payload['pdf'] as Map<String, dynamic>;
      expect(pdf['fileName'], diagnostics.fileName);
      expect(pdf['path'], diagnostics.pdfPath);
    });
  });
}
