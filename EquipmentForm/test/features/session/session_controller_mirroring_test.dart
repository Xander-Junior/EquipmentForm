import 'package:flutter_test/flutter_test.dart';

import 'package:equipment_form_app/data/models/session.dart';
import 'package:equipment_form_app/features/profile/domain/user_profile.dart';
import 'package:equipment_form_app/features/session/controllers/session_controller.dart';
import 'package:equipment_form_app/features/session/domain/session_models.dart';

void main() {
  SessionController buildController() => SessionController(
      formType: FormType.received, currentUser: demoUserProfile);

  String valueFor(
          SessionController controller, PartyRole role, PartyField field) =>
      controller.state.party.members[role]!.fields[field]!.value;

  test('enabling mirror copies existing values', () {
    final controller = buildController();
    controller.updatePartyField(
        PartyRole.requestedBy, PartyField.name, 'Alice');
    controller.updatePartyField(
        PartyRole.requestedBy, PartyField.department, 'Ops');
    controller.updatePartyField(
        PartyRole.requestedBy, PartyField.email, 'alice@tullowoil.com');
    controller.updatePartyField(
        PartyRole.receivedBy, PartyField.name, 'Placeholder');

    controller.setMirrorFromRequested(PartyRole.receivedBy, true);

    expect(
        valueFor(controller, PartyRole.receivedBy, PartyField.name), 'Alice');
    expect(valueFor(controller, PartyRole.receivedBy, PartyField.department),
        'Ops');
    expect(valueFor(controller, PartyRole.receivedBy, PartyField.email),
        'alice@tullowoil.com');
  });

  test('mirroring propagates when requested filled later', () {
    final controller = buildController();
    controller.updatePartyField(PartyRole.receivedBy, PartyField.name, 'Bob');

    controller.setMirrorFromRequested(PartyRole.receivedBy, true);

    expect(valueFor(controller, PartyRole.requestedBy, PartyField.name), 'Bob');

    controller.updatePartyField(
        PartyRole.requestedBy, PartyField.name, 'Charlie');

    expect(
        valueFor(controller, PartyRole.receivedBy, PartyField.name), 'Charlie');
  });

  test('edits propagate bi-directionally while mirrored', () {
    final controller = buildController();
    controller.setMirrorFromRequested(PartyRole.receivedBy, true);

    controller.updatePartyField(
        PartyRole.receivedBy, PartyField.department, 'Finance');
    expect(valueFor(controller, PartyRole.requestedBy, PartyField.department),
        'Finance');

    controller.updatePartyField(
        PartyRole.requestedBy, PartyField.department, 'IT');
    expect(valueFor(controller, PartyRole.receivedBy, PartyField.department),
        'IT');
  });

  test('disabling mirror stops propagation', () {
    final controller = buildController();
    controller.setMirrorFromRequested(PartyRole.receivedBy, true);
    controller.updatePartyField(
        PartyRole.requestedBy, PartyField.email, 'one@tullowoil.com');

    controller.setMirrorFromRequested(PartyRole.receivedBy, false);
    controller.updatePartyField(
        PartyRole.requestedBy, PartyField.email, 'two@tullowoil.com');

    expect(valueFor(controller, PartyRole.receivedBy, PartyField.email),
        'one@tullowoil.com');
  });

  test('controller dirty flag reflects mirroring changes', () {
    final controller = buildController();
    expect(controller.isDirty, isFalse);
    controller.setMirrorFromRequested(PartyRole.receivedBy, true);
    expect(controller.isDirty, isTrue);
  });
}
