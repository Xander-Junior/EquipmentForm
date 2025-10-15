import 'dart:io';
import 'dart:math';

import 'package:equipment_form_app/data/models/session.dart';
import 'package:equipment_form_app/features/pdf/services/pdf_renderer.dart';
import 'package:equipment_form_app/features/session/domain/session_models.dart';

Future<void> main() async {
  final renderer = PdfRenderer();
  final now = DateTime(2025, 1, 1);
  final baseSession = Session(
    id: 'session-${Random().nextInt(99999)}',
    formType: FormType.received,
    payload: const {},
    createdAt: now,
    updatedAt: now,
  );

  Future<void> write(String name, Session session, AppSessionState state) async {
    final bytes = await renderer.render(session: session, state: state, generatedAt: now);
    final file = File('test/goldens/pdf/$name');
    await file.writeAsBytes(bytes, flush: true);
  }

  final receivedState = AppSessionState(
    party: PartySessionState(members: {
      PartyRole.requestedBy: PartyMemberState(
        role: PartyRole.requestedBy,
        fields: {
          PartyField.name: PartyFieldState(value: 'Alex Requestor'),
          PartyField.department: PartyFieldState(value: 'Digital'),
          PartyField.email: PartyFieldState(value: 'alex.req@tullowoil.com'),
        },
      ),
      PartyRole.preparedBy: PartyMemberState(
        role: PartyRole.preparedBy,
        fields: {
          PartyField.name: PartyFieldState(value: 'Pat Preparer'),
          PartyField.department: PartyFieldState(value: 'Digital'),
          PartyField.email: PartyFieldState(value: 'pat.prep@tullowoil.com'),
        },
      ),
      PartyRole.receivedBy: PartyMemberState(
        role: PartyRole.receivedBy,
        fields: {
          PartyField.name: PartyFieldState(value: 'Riley Receiver'),
          PartyField.department: PartyFieldState(value: 'Finance'),
          PartyField.email: PartyFieldState(value: 'riley.recv@tullowoil.com'),
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
          AccessoryState(id: 'a1', label: 'With Adapter', selected: true),
          AccessoryState(id: 'a2', label: 'With Bag', selected: true),
        ],
      ),
    ]),
    workflow: WorkflowSessionState(
      formType: FormType.received,
      location: LocationCode.acc,
      dateReceived: DateTime(2025, 1, 10),
    ),
  );

  await write(
    'received_laptop.pdf',
    baseSession.copyWith(formType: FormType.received),
    receivedState,
  );

  final returnedState = AppSessionState(
    party: const PartySessionState(members: {
      PartyRole.returnedBy: PartyMemberState(
        role: PartyRole.returnedBy,
        fields: {
          PartyField.name: PartyFieldState(value: 'Kelly Returner'),
          PartyField.department: PartyFieldState(value: 'Ops'),
          PartyField.email: PartyFieldState(value: 'kelly.return@tullowoil.com'),
        },
      ),
      PartyRole.preparedBy: PartyMemberState(
        role: PartyRole.preparedBy,
        fields: {
          PartyField.name: PartyFieldState(value: 'Pat Preparer'),
          PartyField.department: PartyFieldState(value: 'Digital'),
          PartyField.email: PartyFieldState(value: 'pat.prep@tullowoil.com'),
        },
      ),
      PartyRole.receivedBy: PartyMemberState(
        role: PartyRole.receivedBy,
        fields: {
          PartyField.name: PartyFieldState(value: 'Riley Receiver'),
          PartyField.department: PartyFieldState(value: 'Finance'),
          PartyField.email: PartyFieldState(value: 'riley.recv@tullowoil.com'),
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
        accessories: [AccessoryState(id: 'c1', label: 'WITH CHARGER', selected: true)],
      ),
    ]),
    workflow: WorkflowSessionState(
      formType: FormType.returned,
      location: LocationCode.tak,
      dateReturned: DateTime(2025, 2, 5),
      dataHandlingConfirmed: true,
    ),
  );

  await write(
    'returned_phone.pdf',
    baseSession.copyWith(formType: FormType.returned),
    returnedState,
  );

  final replacedState = AppSessionState(
    party: const PartySessionState(members: {
      PartyRole.requestedBy: PartyMemberState(
        role: PartyRole.requestedBy,
        fields: {
          PartyField.name: PartyFieldState(value: 'Dana Requestor'),
          PartyField.department: PartyFieldState(value: 'Digital'),
          PartyField.email: PartyFieldState(value: 'dana.req@tullowoil.com'),
        },
      ),
      PartyRole.preparedBy: PartyMemberState(
        role: PartyRole.preparedBy,
        fields: {
          PartyField.name: PartyFieldState(value: 'Pat Preparer'),
          PartyField.department: PartyFieldState(value: 'Digital'),
          PartyField.email: PartyFieldState(value: 'pat.prep@tullowoil.com'),
        },
      ),
      PartyRole.receivedBy: PartyMemberState(
        role: PartyRole.receivedBy,
        fields: {
          PartyField.name: PartyFieldState(value: 'Riley Receiver'),
          PartyField.department: PartyFieldState(value: 'Finance'),
          PartyField.email: PartyFieldState(value: 'riley.recv@tullowoil.com'),
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
          AccessoryState(id: 'an1', label: 'WITH DOCKING STATION', selected: true),
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
      dateReceived: DateTime(2025, 3, 1),
      dateReturned: DateTime(2025, 3, 1),
      dataHandlingConfirmed: true,
    ),
  );

  await write(
    'replaced_laptop.pdf',
    baseSession.copyWith(formType: FormType.replaced),
    replacedState,
  );
}
