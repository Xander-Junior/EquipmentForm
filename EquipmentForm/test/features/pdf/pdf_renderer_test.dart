// ignore_for_file: prefer_const_constructors

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:equipment_form_app/data/models/session.dart';
import 'package:equipment_form_app/features/pdf/services/pdf_renderer.dart';
import 'package:equipment_form_app/features/session/domain/session_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PdfRenderer embeds Noto fonts in received document', () async {
    final renderer = PdfRenderer();
    final session = Session(
      id: 'session-test',
      formType: FormType.received,
      payload: const {},
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1, 12),
    );

    final state = AppSessionState(
      party: PartySessionState(members: {
        PartyRole.preparedBy: PartyMemberState(
          role: PartyRole.preparedBy,
          fields: {
            PartyField.name: const PartyFieldState(value: 'Jane Doe'),
            PartyField.department: const PartyFieldState(value: 'Engineering'),
            PartyField.email: const PartyFieldState(value: 'jane.doe@tullowoil.com'),
          },
        ),
        PartyRole.receivedBy: PartyMemberState(
          role: PartyRole.receivedBy,
          fields: {
            PartyField.name: const PartyFieldState(value: 'Alex Receiver'),
            PartyField.department: const PartyFieldState(value: 'IT'),
            PartyField.email: const PartyFieldState(value: 'alex.receiver@tullowoil.com'),
          },
        ),
      }),
      equipment: EquipmentSessionState(primaries: [
        PrimaryDeviceState(
          id: 'test-device',
          type: PrimaryDeviceType.laptop,
          makeModel: '7420',
          assetTag: 'ACC-LT-12345',
          serviceTag: '9K8C7M3',
          serialNumber: 'SR-001',
          warrantyExpiry: '01/02/2026',
          accessories: const [
            AccessoryState(id: 'adapter', label: 'With Adapter', selected: true),
          ],
        ),
      ]),
      workflow: WorkflowSessionState(
        formType: FormType.received,
        location: LocationCode.acc,
        dateReceived: DateTime(2025, 1, 1),
      ),
    );

    final bytes = await renderer.render(
      session: session,
      state: state,
      generatedAt: DateTime.utc(2025, 1, 1, 12),
    );

    expect(bytes.length, greaterThan(1000));
    final text = utf8.decode(bytes, allowMalformed: true);
    expect(text, contains('NotoSans'));
  });
}
