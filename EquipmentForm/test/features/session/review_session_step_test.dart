import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:equipment_form_app/data/models/session.dart';
import 'package:equipment_form_app/features/profile/domain/user_profile.dart';
import 'package:equipment_form_app/features/session/controllers/session_controller.dart';
import 'package:equipment_form_app/features/session/domain/session_models.dart';
import 'package:equipment_form_app/features/session/view/widgets/review_session_step.dart';

SessionController _buildController(FormType formType) {
  final controller =
      SessionController(formType: formType, currentUser: demoUserProfile);
  final updatedMembers = <PartyRole, PartyMemberState>{};
  controller.state.party.members.forEach((role, member) {
    final populatedFields = <PartyField, PartyFieldState>{};
    member.fields.forEach((field, fieldState) {
      final value = fieldState.value.isNotEmpty
          ? fieldState.value
          : '${role.label} ${field.label}';
      populatedFields[field] = fieldState.copyWith(value: value);
    });
    updatedMembers[role] =
        member.copyWith(fields: populatedFields, mirrorsRequested: false);
  });
  controller.state = controller.state.copyWith(
    party: controller.state.party.copyWith(members: updatedMembers),
  );
  return controller;
}

Future<List<ElevatedButton>> _pumpReview(
  WidgetTester tester,
  SessionController controller,
) async {
  final container = ProviderContainer(
    overrides: [
      sessionControllerProvider(controller.state.workflow.formType)
          .overrideWith((ref) => controller),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 1200,
            child:
                ReviewSessionStep(formType: controller.state.workflow.formType),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final listViewFinder = find.byType(ListView);
  final buttonFinder = find.byWidgetPredicate(
    (widget) => widget is ElevatedButton,
    skipOffstage: false,
  );
  for (var i = 0; i < 6 && buttonFinder.evaluate().isEmpty; i++) {
    if (listViewFinder.evaluate().isEmpty) {
      break;
    }
    await tester.drag(listViewFinder, const Offset(0, -400));
    await tester.pumpAndSettle();
  }
  return tester
      .widgetList<ElevatedButton>(
        buttonFinder,
      )
      .toList();
}

void main() {
  testWidgets('export button disabled when validation fails (missing make)',
      (tester) async {
    final controller = _buildController(FormType.received);
    controller.state = controller.state.copyWith(
      equipment: const EquipmentSessionState(primaries: [
        PrimaryDeviceState(
          id: '1',
          type: PrimaryDeviceType.laptop,
          makeModel: '',
          assetTag: 'ACC-LT-12345',
          serviceTag: 'SERV123',
        ),
      ]),
    );

    final buttons = await _pumpReview(tester, controller);
    expect(buttons, isNotEmpty);
    expect(buttons.every((button) => button.onPressed == null), isTrue);
  });

  testWidgets('export disabled when asset tag invalid', (tester) async {
    final controller = _buildController(FormType.received);
    controller.state = controller.state.copyWith(
      equipment: const EquipmentSessionState(primaries: [
        PrimaryDeviceState(
          id: 'asset-invalid',
          type: PrimaryDeviceType.laptop,
          makeModel: '7420',
          assetTag: 'INVALID',
          serviceTag: 'SERV123',
        ),
      ]),
    );

    final buttons = await _pumpReview(tester, controller);
    expect(buttons, isNotEmpty);
    expect(buttons.every((button) => button.onPressed == null), isTrue);
  });

  testWidgets('export disabled when IMEI invalid', (tester) async {
    final controller = _buildController(FormType.returned);
    controller.state = controller.state.copyWith(
      equipment: const EquipmentSessionState(primaries: [
        PrimaryDeviceState(
          id: 'phone-invalid',
          type: PrimaryDeviceType.phone,
          makeModel: 'iPhone 13',
          imei: '12345',
          assetTag: 'TAK-MB-54321',
        ),
      ]),
      workflow: controller.state.workflow.copyWith(dataHandlingConfirmed: true),
    );

    final buttons = await _pumpReview(tester, controller);
    expect(buttons, isNotEmpty);
    expect(buttons.every((button) => button.onPressed == null), isTrue);
  });

  testWidgets('export disabled when warranty expiry invalid', (tester) async {
    final controller = _buildController(FormType.received);
    controller.state = controller.state.copyWith(
      equipment: const EquipmentSessionState(primaries: [
        PrimaryDeviceState(
          id: 'warranty-invalid',
          type: PrimaryDeviceType.laptop,
          makeModel: '7420',
          assetTag: 'ACC-LT-54321',
          serviceTag: 'SERV321',
          warrantyExpiry: '99/99/2025',
        ),
      ]),
    );

    final buttons = await _pumpReview(tester, controller);
    expect(buttons, isNotEmpty);
    expect(buttons.every((button) => button.onPressed == null), isTrue);
  });
}
