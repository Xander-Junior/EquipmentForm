import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:equipment_form_app/data/models/session.dart';
import 'package:equipment_form_app/features/pdf/services/pdf_renderer.dart';
import 'package:equipment_form_app/features/session/domain/session_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final renderer = PdfRenderer();
  final baseSession = Session(
    id: 'session-golden',
    formType: FormType.received,
    payload: const {},
    createdAt: DateTime.utc(2025, 1, 1),
    updatedAt: DateTime.utc(2025, 1, 1, 12),
  );
  final generatedAt = DateTime.utc(2025, 1, 2, 8, 30);
  final updateMode = Platform.environment['UPDATE_PDF_GOLDENS'] == '1';

  String normalizePdf(Uint8List bytes) {
    final raw = latin1.decode(bytes, allowInvalid: true);
    final normalizedId = raw.replaceAll(
      RegExp(r'<</ID\[[^\]]+\]'),
      '<</ID[<normalized-id><normalized-id>]>',
    );
    return normalizedId;
  }

  Future<void> verifyPdf(String name, Uint8List bytes) async {
    if (updateMode) {
      final outputPath = p.join('test', 'goldens', 'pdf', name);
      final file = File(outputPath);
      await file.create(recursive: true);
      // Emit a short trace to make update progress visible when regenerating goldens.
      // ignore: avoid_print
      print('Updating golden → $outputPath');
      await file.writeAsBytes(bytes, flush: true);
    } else {
      final goldenPath = p.join('test', 'goldens', 'pdf', name);
      final goldenFile = File(goldenPath);
      expect(goldenFile.existsSync(), isTrue,
          reason: 'Missing golden: $goldenPath');
      final expected = await goldenFile.readAsBytes();
      expect(
        normalizePdf(bytes),
        normalizePdf(expected),
        reason: 'PDF drift detected for $name',
      );
    }
  }

  group('PDF renderer goldens', () {
    test('received laptop with accessories', () async {
      final session = baseSession.copyWith(formType: FormType.received);
      final state = AppSessionState(
        party: const PartySessionState(members: {
          PartyRole.requestedBy: PartyMemberState(
            role: PartyRole.requestedBy,
            fields: {
              PartyField.name: PartyFieldState(value: 'Alex Requestor'),
              PartyField.department: PartyFieldState(value: 'Digital'),
              PartyField.email:
                  PartyFieldState(value: 'alex.req@tullowoil.com'),
            },
          ),
          PartyRole.preparedBy: PartyMemberState(
            role: PartyRole.preparedBy,
            fields: {
              PartyField.name: PartyFieldState(value: 'Pat Preparer'),
              PartyField.department: PartyFieldState(value: 'Digital'),
              PartyField.email:
                  PartyFieldState(value: 'pat.prep@tullowoil.com'),
            },
          ),
          PartyRole.receivedBy: PartyMemberState(
            role: PartyRole.receivedBy,
            fields: {
              PartyField.name: PartyFieldState(value: 'Riley Receiver'),
              PartyField.department: PartyFieldState(value: 'Finance'),
              PartyField.email:
                  PartyFieldState(value: 'riley.recv@tullowoil.com'),
            },
          ),
        }),
        equipment: const EquipmentSessionState(primaries: [
          PrimaryDeviceState(
            id: 'l1',
            type: PrimaryDeviceType.laptop,
            makeModel: '7420',
            assetTag: 'ACC-LT-12345',
            serviceTag: '9K8C7M3',
            warrantyExpiry: '2026-02-01',
            accessories: [
              AccessoryState(id: 'a1', label: 'WITH ADAPTER', selected: true),
              AccessoryState(id: 'a2', label: 'WITH BAG', selected: true),
            ],
          ),
        ]),
        workflow: WorkflowSessionState(
          formType: FormType.received,
          location: LocationCode.acc,
          dateReceived: DateTime.utc(2025, 1, 10),
        ),
      );

      final bytes = await renderer.render(
        session: session,
        state: state,
        generatedAt: generatedAt,
      );
      await verifyPdf('received_laptop.pdf', bytes);
    });

    test('returned phone with imei and handling', () async {
      final session = baseSession.copyWith(formType: FormType.returned);
      final state = AppSessionState(
        party: const PartySessionState(members: {
          PartyRole.returnedBy: PartyMemberState(
            role: PartyRole.returnedBy,
            fields: {
              PartyField.name: PartyFieldState(value: 'Kelly Returner'),
              PartyField.department: PartyFieldState(value: 'Ops'),
              PartyField.email:
                  PartyFieldState(value: 'kelly.return@tullowoil.com'),
            },
          ),
          PartyRole.preparedBy: PartyMemberState(
            role: PartyRole.preparedBy,
            fields: {
              PartyField.name: PartyFieldState(value: 'Pat Preparer'),
              PartyField.department: PartyFieldState(value: 'Digital'),
              PartyField.email:
                  PartyFieldState(value: 'pat.prep@tullowoil.com'),
            },
          ),
          PartyRole.receivedBy: PartyMemberState(
            role: PartyRole.receivedBy,
            fields: {
              PartyField.name: PartyFieldState(value: 'Riley Receiver'),
              PartyField.department: PartyFieldState(value: 'Finance'),
              PartyField.email:
                  PartyFieldState(value: 'riley.recv@tullowoil.com'),
            },
          ),
        }),
        equipment: const EquipmentSessionState(primaries: [
          PrimaryDeviceState(
            id: 'p1',
            type: PrimaryDeviceType.phone,
            makeModel: 'iPhone 13',
            assetTag: 'TAK-MB-54321',
            imei: '352099001761487',
            serialNumber: 'SN123456789',
            accessories: [
              AccessoryState(id: 'c1', label: 'WITH CHARGER', selected: true),
            ],
          ),
        ]),
        workflow: WorkflowSessionState(
          formType: FormType.returned,
          location: LocationCode.tak,
          dateReturned: DateTime.utc(2025, 2, 5),
          dataHandlingConfirmed: true,
        ),
      );

      final bytes = await renderer.render(
        session: session,
        state: state,
        generatedAt: generatedAt,
      );
      await verifyPdf('returned_phone.pdf', bytes);
    });

    test('replaced laptop with photo frames', () async {
      final session = baseSession.copyWith(formType: FormType.replaced);
      final state = AppSessionState(
        party: const PartySessionState(members: {
          PartyRole.requestedBy: PartyMemberState(
            role: PartyRole.requestedBy,
            fields: {
              PartyField.name: PartyFieldState(value: 'Dana Requestor'),
              PartyField.department: PartyFieldState(value: 'Digital'),
              PartyField.email:
                  PartyFieldState(value: 'dana.req@tullowoil.com'),
            },
          ),
          PartyRole.preparedBy: PartyMemberState(
            role: PartyRole.preparedBy,
            fields: {
              PartyField.name: PartyFieldState(value: 'Pat Preparer'),
              PartyField.department: PartyFieldState(value: 'Digital'),
              PartyField.email:
                  PartyFieldState(value: 'pat.prep@tullowoil.com'),
            },
          ),
          PartyRole.receivedBy: PartyMemberState(
            role: PartyRole.receivedBy,
            fields: {
              PartyField.name: PartyFieldState(value: 'Riley Receiver'),
              PartyField.department: PartyFieldState(value: 'Finance'),
              PartyField.email:
                  PartyFieldState(value: 'riley.recv@tullowoil.com'),
            },
          ),
        }),
        equipment: const EquipmentSessionState(primaries: [
          PrimaryDeviceState(
            id: 'new',
            type: PrimaryDeviceType.laptop,
            makeModel: '7440',
            assetTag: 'LON-LT-77777',
            serviceTag: 'NEW123',
            warrantyExpiry: '2027-03-15',
            accessories: [
              AccessoryState(
                  id: 'an1', label: 'WITH DOCKING STATION', selected: true),
            ],
            isReplacementOld: false,
          ),
          PrimaryDeviceState(
            id: 'old',
            type: PrimaryDeviceType.laptop,
            makeModel: '7420',
            assetTag: 'LON-LT-11111',
            serviceTag: 'OLD456',
            warrantyExpiry: '2025-08-01',
            isReplacementOld: true,
          ),
        ]),
        workflow: WorkflowSessionState(
          formType: FormType.replaced,
          location: LocationCode.lon,
          dateReceived: DateTime.utc(2025, 3, 1),
          dateReturned: DateTime.utc(2025, 3, 1),
          dataHandlingConfirmed: true,
        ),
      );

      final bytes = await renderer.render(
        session: session,
        state: state,
        generatedAt: generatedAt,
      );
      await verifyPdf('replaced_laptop.pdf', bytes);
    });

    test('replaced mixed device kinds', () async {
      final session = baseSession.copyWith(formType: FormType.replaced);
      final state = AppSessionState(
        party: const PartySessionState(members: {
          PartyRole.preparedBy: PartyMemberState(
            role: PartyRole.preparedBy,
            fields: {
              PartyField.name: PartyFieldState(value: 'Sam Prep'),
              PartyField.department: PartyFieldState(value: 'Digital'),
              PartyField.email:
                  PartyFieldState(value: 'sam.prep@tullowoil.com'),
            },
          ),
          PartyRole.receivedBy: PartyMemberState(
            role: PartyRole.receivedBy,
            fields: {
              PartyField.name: PartyFieldState(value: 'Casey Receiver'),
              PartyField.department: PartyFieldState(value: 'Ops'),
              PartyField.email:
                  PartyFieldState(value: 'casey.recv@tullowoil.com'),
            },
          ),
          PartyRole.returnedBy: PartyMemberState(
            role: PartyRole.returnedBy,
            fields: {
              PartyField.name: PartyFieldState(value: 'Taylor Returner'),
              PartyField.department: PartyFieldState(value: 'Ops'),
              PartyField.email:
                  PartyFieldState(value: 'taylor.return@tullowoil.com'),
            },
          ),
        }),
        equipment: const EquipmentSessionState(primaries: [
          PrimaryDeviceState(
            id: 'new-phone',
            type: PrimaryDeviceType.phone,
            makeModel: 'iPhone 14 Pro',
            assetTag: 'ACC-PH-90001',
            imei: '352099001761999',
            serialNumber: 'SN-PHONE-77',
            accessories: [
              AccessoryState(id: 'case', label: 'Case', selected: true),
            ],
            isReplacementOld: false,
          ),
          PrimaryDeviceState(
            id: 'old-laptop',
            type: PrimaryDeviceType.laptop,
            makeModel: '7410',
            assetTag: 'ACC-LT-80002',
            serviceTag: 'OLD990',
            warrantyExpiry: '2024-12-01',
            isReplacementOld: true,
          ),
        ]),
        workflow: WorkflowSessionState(
          formType: FormType.replaced,
          location: LocationCode.acc,
          dateReceived: DateTime.utc(2025, 4, 12),
          dateReturned: DateTime.utc(2025, 4, 12),
          dataHandlingConfirmed: true,
        ),
      );

      final bytes = await renderer.render(
        session: session,
        state: state,
        generatedAt: generatedAt,
      );
      await verifyPdf('replaced_mixed.pdf', bytes);
    });
  });
}
