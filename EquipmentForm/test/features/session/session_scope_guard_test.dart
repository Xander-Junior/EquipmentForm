import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:equipment_form_app/data/models/session.dart';
import 'package:equipment_form_app/features/session/view/session_flow_screen.dart';

void main() {
  testWidgets('session subtree uses a single container', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: SessionFlowScreen(formType: FormType.received),
        ),
      ),
    );

    expect(find.byType(ProviderScope), findsNothing);
  });
}
