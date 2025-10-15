import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:equipment_form_app/app/router.dart';
import 'package:equipment_form_app/data/models/session.dart';
import 'package:equipment_form_app/features/profile/domain/user_profile.dart';
import 'package:equipment_form_app/features/profile/state/user_profile_provider.dart';
import 'package:equipment_form_app/features/session/view/session_flow_screen.dart';
import 'package:equipment_form_app/features/shared/view/form_type_select_screen.dart';

void main() {
  testWidgets('dirty session prompts before changing form type',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        currentUserProfileProvider.overrideWithValue(demoUserProfile),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/session',
      routes: [
        GoRoute(
          path: '/session',
          name: AppRoute.session.name,
          builder: (context, state) =>
              const SessionFlowScreen(formType: FormType.received),
        ),
        GoRoute(
          path: '/form-type',
          name: AppRoute.formTypeSelect.name,
          builder: (context, state) => const FormTypeSelectScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Edited');
    await tester.pump();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change Form Type'));
    await tester.pump();
    expect(find.text('Leave session?'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(ElevatedButton, 'Continue'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FormTypeSelectScreen), findsOneWidget);
  });

  testWidgets('change form type without edits navigates immediately',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        currentUserProfileProvider.overrideWithValue(demoUserProfile),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/session',
      routes: [
        GoRoute(
          path: '/session',
          name: AppRoute.session.name,
          builder: (context, state) =>
              const SessionFlowScreen(formType: FormType.received),
        ),
        GoRoute(
          path: '/form-type',
          name: AppRoute.formTypeSelect.name,
          builder: (context, state) => const FormTypeSelectScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change Form Type'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Leave session?'), findsNothing);
  });

  testWidgets('bottom actions respect keyboard insets', (tester) async {
    const mediaQueryData = MediaQueryData(
      size: Size(390, 844),
      viewInsets: EdgeInsets.only(bottom: 200),
    );

    final container = ProviderContainer(
      overrides: [
        currentUserProfileProvider.overrideWithValue(demoUserProfile),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MediaQuery(
          data: mediaQueryData,
          child: MaterialApp(
            home: SessionFlowScreen(formType: FormType.received),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollView = tester.widget<SingleChildScrollView>(
      find.byKey(const ValueKey('sessionFlowActionsScroll')),
    );

    final resolvedPadding = scrollView.padding?.resolve(TextDirection.ltr);
    expect(resolvedPadding?.bottom, 200 + 16);
  });
}
