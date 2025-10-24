import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:equipment_form_app/data/models/session.dart';
import 'package:equipment_form_app/features/profile/domain/user_profile.dart';
import 'package:equipment_form_app/features/session/controllers/session_controller.dart';
import 'package:equipment_form_app/features/session/domain/session_models.dart';
import 'package:equipment_form_app/app/di.dart';
import 'package:equipment_form_app/features/session/ocr/party_ocr_analyzer.dart';
import 'package:equipment_form_app/features/session/view/session_scope.dart';
import 'package:equipment_form_app/features/session/view/widgets/party_session_step.dart';
import 'package:equipment_form_app/features/session/view/widgets/section_capture_wizard.dart';
import 'package:equipment_form_app/features/ocr/services/ocr_service.dart';
import 'package:equipment_form_app/features/session/view/session_flow_screen.dart';
import 'ocr_test_utils.dart';

class _TestSectionCaptureWizard extends SectionCaptureWizard {
  _TestSectionCaptureWizard(
    super.ref,
    super.formType, {
    required this.fixedImage,
    super.presenter,
  });

  final File fixedImage;

  @override
  Future<PartyOcrWizardResult?> captureSection({
    required BuildContext context,
    required PartyRole role,
  }) {
    return processImage(context: context, role: role, image: fixedImage);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String valueFor(
          SessionController controller, PartyRole role, PartyField field) =>
      controller.state.party.members[role]!.fields[field]!.value;

  Future<void> scrollList(WidgetTester tester, double dy) async {
    await tester.drag(find.byType(ListView), Offset(0, dy));
    await tester.pumpAndSettle();
  }

  Future<void> toggleMirror(WidgetTester tester) async {
    await scrollList(tester, -400);
    await tester.tap(find.byKey(const Key('mirror-receivedBy')));
    await tester.pumpAndSettle();
  }

  Future<void> ensurePartyFieldVisible(
      WidgetTester tester, Finder finder) async {
    final scrollable = find.byType(ListView).first;
    await tester.dragUntilVisible(
      finder,
      scrollable,
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
  }

  Future<ProviderContainer> pumpPartySession(
    WidgetTester tester,
    SessionController controller, {
    SectionCaptureWizard Function(WidgetRef ref, FormType formType)?
        wizardBuilder,
    List<Override> overrides = const [],
  }) async {
    final formType = controller.state.workflow.formType;
    final container = ProviderContainer(
      overrides: [
        sessionControllerProvider(formType).overrideWith((ref) => controller),
        ...overrides,
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      SessionScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: PartySessionStep(
              formType: formType,
              sectionWizardBuilder: wizardBuilder,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('linking copies values and shows indicator', (tester) async {
    final controller = SessionController(
      formType: FormType.received,
      currentUser: demoUserProfile,
    );
    await pumpPartySession(tester, controller);
    expect(find.byType(ListView), findsOneWidget);

    const requestedNameKey = Key('party-requestedBy-name');
    const receivedNameKey = Key('party-receivedBy-name');

    await scrollList(tester, 400);
    await tester.enterText(find.byKey(requestedNameKey), 'Alice');
    await tester.pump();

    expect(
        valueFor(controller, PartyRole.receivedBy, PartyField.name), isEmpty);

    await toggleMirror(tester);

    expect(
        valueFor(controller, PartyRole.receivedBy, PartyField.name), 'Alice');
    expect(find.text('Linked to Requested By'), findsOneWidget);
    final receivedNameFieldWidget =
        tester.widget<TextField>(find.byKey(receivedNameKey));
    expect(receivedNameFieldWidget.controller!.text, 'Alice');

    await scrollList(tester, -400);
    await tester.enterText(find.byKey(receivedNameKey), 'Bea');
    await tester.pump();
    expect(valueFor(controller, PartyRole.requestedBy, PartyField.name), 'Bea');

    await toggleMirror(tester); // switch off
    expect(find.text('Linked to Requested By'), findsNothing);

    await scrollList(tester, 400);
    await tester.enterText(find.byKey(requestedNameKey), 'Cara');
    await tester.pump();
    expect(valueFor(controller, PartyRole.receivedBy, PartyField.name), 'Bea');
    final receivedNameAfterUnlink =
        tester.widget<TextField>(find.byKey(receivedNameKey));
    expect(receivedNameAfterUnlink.controller!.text, 'Bea');
  });

  testWidgets('linking before requested filled syncs later edits',
      (tester) async {
    final controller = SessionController(
      formType: FormType.received,
      currentUser: demoUserProfile,
    );

    await pumpPartySession(tester, controller);
    expect(find.byType(ListView), findsOneWidget);

    const requestedNameKey = Key('party-requestedBy-name');
    const receivedNameKey = Key('party-receivedBy-name');
    const requestedDeptKey = Key('party-requestedBy-department');
    const receivedDeptKey = Key('party-receivedBy-department');
    const requestedEmailKey = Key('party-requestedBy-email');
    const receivedEmailKey = Key('party-receivedBy-email');

    await scrollList(tester, -400);
    await tester.enterText(find.byKey(receivedNameKey), 'Bob');
    await tester.pump();

    await toggleMirror(tester);
    expect(valueFor(controller, PartyRole.requestedBy, PartyField.name), 'Bob');
    expect(
      tester.widget<TextField>(find.byKey(receivedNameKey)).controller!.text,
      'Bob',
    );

    await scrollList(tester, 400);
    await tester.enterText(find.byKey(requestedDeptKey), 'Applications');
    await tester.pump();
    expect(
      valueFor(controller, PartyRole.receivedBy, PartyField.department),
      'Applications',
    );
    await scrollList(tester, -400);
    expect(
      tester.widget<TextField>(find.byKey(receivedDeptKey)).controller!.text,
      'Applications',
    );

    await scrollList(tester, 400);
    await tester.enterText(find.byKey(requestedEmailKey), 'alice@example.com');
    await tester.pump();
    expect(
      valueFor(controller, PartyRole.receivedBy, PartyField.email),
      'alice@example.com',
    );
    await scrollList(tester, -400);
    expect(
      tester.widget<TextField>(find.byKey(receivedEmailKey)).controller!.text,
      'alice@example.com',
    );

    await scrollList(tester, 400);
    await tester.enterText(find.byKey(requestedNameKey), 'Charlie');
    await tester.pump();
    expect(
        valueFor(controller, PartyRole.receivedBy, PartyField.name), 'Charlie');
    await scrollList(tester, -400);
    expect(
      tester.widget<TextField>(find.byKey(receivedNameKey)).controller!.text,
      'Charlie',
    );
  });

  testWidgets('prefilled email selects all on first focus only once',
      (tester) async {
    final controller = SessionController(
      formType: FormType.received,
      currentUser: demoUserProfile,
    );

    await pumpPartySession(tester, controller);

    final emailField = find.byKey(const ValueKey('party-preparedBy-email'));
    final emailEditableFinder =
        find.descendant(of: emailField, matching: find.byType(EditableText));
    final emailState = tester.state<EditableTextState>(emailEditableFinder);
    final emailFocus = emailState.widget.focusNode;

    emailFocus.requestFocus();
    await tester.pump();
    await tester.pump();

    EditableText editable = tester.widget(emailEditableFinder);
    expect(editable.controller.selection.baseOffset, 0);
    expect(editable.controller.selection.extentOffset,
        editable.controller.text.length);

    await tester.enterText(emailField, 'preparer.tester@tullowoil.com');
    await tester.pump();

    final nameField = find.byKey(const ValueKey('party-preparedBy-name'));
    final nameEditableFinder =
        find.descendant(of: nameField, matching: find.byType(EditableText));
    final nameState = tester.state<EditableTextState>(nameEditableFinder);
    nameState.widget.focusNode.requestFocus();
    await tester.pump();

    emailFocus.requestFocus();
    await tester.pump();
    await tester.pump();

    editable = tester.widget(emailEditableFinder);
    expect(editable.controller.selection.baseOffset,
        editable.controller.selection.extentOffset);
    expect(editable.controller.selection.baseOffset,
        editable.controller.text.length);
  });

  testWidgets('tullowoil.com chip appears and applies on tap', (tester) async {
    final controller = SessionController(
      formType: FormType.received,
      currentUser: demoUserProfile,
    );

    await pumpPartySession(tester, controller);

    final emailField = find.byKey(const ValueKey('party-preparedBy-email'));
    await ensurePartyFieldVisible(tester, emailField);

    await tester.enterText(emailField, 'alice.smith@');
    await tester.pump();

    expect(find.text('tullowoil.com'), findsOneWidget);

    await tester.tap(find.text('tullowoil.com'));
    await tester.pump();

    expect(find.text('tullowoil.com'), findsNothing);
    expect(
      valueFor(controller, PartyRole.preparedBy, PartyField.email),
      'alice.smith@tullowoil.com',
    );
    expect(find.text('alice.smith@tullowoil.com'), findsOneWidget);
  });

  testWidgets(
      'blur with trailing @ appends tullowoil.com and validator updates',
      (tester) async {
    final controller = SessionController(
      formType: FormType.received,
      currentUser: demoUserProfile,
    );

    await pumpPartySession(tester, controller);

    final emailField = find.byKey(const ValueKey('party-preparedBy-email'));
    await ensurePartyFieldVisible(tester, emailField);

    await tester.enterText(emailField, 'invalid email');
    await tester.pump();
    expect(find.text('Enter a valid email address'), findsOneWidget);

    await tester.enterText(emailField, 'robert.king@');
    await tester.pump();
    expect(find.text('tullowoil.com'), findsOneWidget);
    expect(find.text('Enter a valid email address'), findsNothing);

    final context = tester.element(emailField);
    final focusNode = FocusNode();
    FocusScope.of(context).requestFocus(focusNode);
    await tester.pumpAndSettle();
    focusNode.dispose();

    final editable = tester.widget<EditableText>(
      find.descendant(of: emailField, matching: find.byType(EditableText)),
    );
    expect(editable.controller.text, 'robert.king@tullowoil.com');
    expect(
      valueFor(controller, PartyRole.preparedBy, PartyField.email),
      'robert.king@tullowoil.com',
    );
    expect(find.text('Enter a valid email address'), findsNothing);
  });

  testWidgets('party section wizard applies fixture and supports undo',
      (tester) async {
    late final OcrResult ocrResult;
    late final File image;

    await tester.runAsync(() async {
      final fixtureFile = File('test/fixtures/ocr/party/otuko_john_teye.json');
      final fixtureData =
          jsonDecode(await fixtureFile.readAsString()) as Map<String, dynamic>;
      ocrResult = OcrResult(
        fields: Map<String, dynamic>.from(fixtureData['fields'] as Map),
        confidence: (fixtureData['confidence'] as num).toDouble(),
      );
      image = await loadSampleImage(
        'samples/ocr/Eqpt_details/otuko_john_teye.JPG',
      );
    });

    presenter(
      BuildContext context,
      PartyOcrAnalysis analysis,
      Map<PartyField, TextEditingController> controllers,
      double confidence,
      bool imageWasPreprocessed,
      Map<PartyField, String> previousValues,
      Map<PartyField, PartyOcrFieldSuggestion?> initialSuggestions,
      double sharpness,
    ) async {
      final nameSuggestion = analysis.primarySuggestionFor(PartyField.name)!;
      final deptSuggestion =
          analysis.primarySuggestionFor(PartyField.department)!;
      final emailSuggestion = analysis.primarySuggestionFor(PartyField.email)!;

      controllers[PartyField.name]!.text = nameSuggestion.value;
      controllers[PartyField.department]!.text = deptSuggestion.value;
      controllers[PartyField.email]!.text = emailSuggestion.value;

      return PartyOcrReviewDecision(
        applied: true,
        values: {
          for (final entry in controllers.entries) entry.key: entry.value.text,
        },
      );
    }

    final controller = SessionController(
      formType: FormType.received,
      currentUser: demoUserProfile,
    );

    final container = await pumpPartySession(
      tester,
      controller,
      overrides: [
        ocrServiceProvider.overrideWithValue(FakeOcrService(ocrResult)),
        imageNormalizerProvider
            .overrideWith((ref) => FakeImageNormalizer(image)),
      ],
      wizardBuilder: (ref, formType) => _TestSectionCaptureWizard(
        ref,
        formType,
        fixedImage: image,
        presenter: presenter,
      ),
    );
    final formType = controller.state.workflow.formType;

    await tester.pumpWidget(
      SessionScope(
        container: container,
        child: MaterialApp(
          home: SessionFlowScreen(formType: formType),
        ),
      ),
    );
    await tester.pump();

    await tester.pumpWidget(
      SessionScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: PartySessionStep(
              formType: formType,
              sectionWizardBuilder: (ref, formType) =>
                  _TestSectionCaptureWizard(
                ref,
                formType,
                fixedImage: image,
                presenter: presenter,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final initialMember = container
        .read(sessionControllerProvider(FormType.received))
        .party
        .members[PartyRole.preparedBy]!;

    await tester.tap(find.text('Scan Section').at(1));
    await tester.pump();
    await tester.pumpAndSettle();

    final appliedMember = container
        .read(sessionControllerProvider(FormType.received))
        .party
        .members[PartyRole.preparedBy]!;
    final appliedMemberName = appliedMember.fields[PartyField.name]!.value;
    final appliedMemberDept =
        appliedMember.fields[PartyField.department]!.value;
    final appliedMemberEmail = appliedMember.fields[PartyField.email]!.value;
    final st = container.read(sessionControllerProvider(FormType.received));
    final appliedName =
        st.party.members[PartyRole.preparedBy]!.fields[PartyField.name]!.value;
    expect(appliedName, 'Otuko John Teye');
    expect(appliedMemberName, 'Otuko John Teye');
    expect(appliedMemberDept, 'Supply Chain Manager');
    expect(appliedMemberEmail, 'otuko.teye@tullowoil.com');
    expect(find.text('Applied OCR results to Prepared By.'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pump();
    await tester.pumpAndSettle();

    final revertedMember = container
        .read(sessionControllerProvider(FormType.received))
        .party
        .members[PartyRole.preparedBy]!;
    expect(revertedMember.fields[PartyField.name]!.value,
        initialMember.fields[PartyField.name]!.value);
    expect(revertedMember.fields[PartyField.department]!.value,
        initialMember.fields[PartyField.department]!.value);
    expect(revertedMember.fields[PartyField.email]!.value,
        initialMember.fields[PartyField.email]!.value);
  });

  testWidgets('party section wizard repairs Francis OCR data', (tester) async {
    late final OcrResult ocrResult;
    late final File image;

    await tester.runAsync(() async {
      final fixtureFile = File('test/fixtures/ocr/party/francis_nyarko.json');
      final fixtureData =
          jsonDecode(await fixtureFile.readAsString()) as Map<String, dynamic>;
      ocrResult = OcrResult(
        fields: Map<String, dynamic>.from(fixtureData['fields'] as Map),
        confidence: (fixtureData['confidence'] as num).toDouble(),
      );
      image = await loadSampleImage(
        'samples/ocr/Eqpt_details/francis_nyarko.JPG',
      );
    });

    presenter(
      BuildContext context,
      PartyOcrAnalysis analysis,
      Map<PartyField, TextEditingController> controllers,
      double confidence,
      bool imageWasPreprocessed,
      Map<PartyField, String> previousValues,
      Map<PartyField, PartyOcrFieldSuggestion?> initialSuggestions,
      double sharpness,
    ) async {
      for (final entry in controllers.entries) {
        final suggestion = analysis.primarySuggestionFor(entry.key) ??
            initialSuggestions[entry.key];
        if (suggestion != null) {
          entry.value.text = suggestion.value;
        }
      }

      return PartyOcrReviewDecision(
        applied: true,
        values: {
          for (final entry in controllers.entries) entry.key: entry.value.text,
        },
      );
    }

    final controller = SessionController(
      formType: FormType.received,
      currentUser: demoUserProfile,
    );

    final container = await pumpPartySession(
      tester,
      controller,
      overrides: [
        ocrServiceProvider.overrideWithValue(FakeOcrService(ocrResult)),
        imageNormalizerProvider
            .overrideWith((ref) => FakeImageNormalizer(image)),
      ],
      wizardBuilder: (ref, formType) => _TestSectionCaptureWizard(
        ref,
        formType,
        fixedImage: image,
        presenter: presenter,
      ),
    );

    await tester.tap(find.text('Scan Section').at(1));
    await tester.pump();
    await tester.pumpAndSettle();

    final appliedMember = container
        .read(sessionControllerProvider(FormType.received))
        .party
        .members[PartyRole.preparedBy]!;
    expect(appliedMember.fields[PartyField.name]!.value,
        equals('Francis Kwaku Nyarko'));
    expect(appliedMember.fields[PartyField.department]!.value,
        equals('Digital & IT'));
    expect(appliedMember.fields[PartyField.email]!.value,
        equals('francis.nyarko@tullowoil.com'));
    expect(find.text('Applied OCR results to Prepared By.'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pump();
    await tester.pumpAndSettle();

    final revertedMember = container
        .read(sessionControllerProvider(FormType.received))
        .party
        .members[PartyRole.preparedBy]!;
    expect(revertedMember.fields[PartyField.name]!.value,
        equals(demoUserProfile.name));
    expect(revertedMember.fields[PartyField.department]!.value,
        equals(demoUserProfile.department));
    expect(revertedMember.fields[PartyField.email]!.value,
        equals(demoUserProfile.email));
  });
}
