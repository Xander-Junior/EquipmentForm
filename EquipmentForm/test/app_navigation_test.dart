import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:equipment_form_app/app/di.dart';
import 'package:equipment_form_app/data/models/session.dart';
import 'package:equipment_form_app/data/session_database.dart';
import 'package:equipment_form_app/data/session_repository.dart';
import 'package:equipment_form_app/main.dart';

class InMemorySecureStore implements SecureStore {
  final Map<String, String> _store = {};

  @override
  Future<void> delete({required String key}) async {
    _store.remove(key);
  }

  @override
  Future<String?> read({required String key}) async => _store[key];

  @override
  Future<void> write({required String key, required String value}) async {
    _store[key] = value;
  }
}

void main() {
  testWidgets('App navigates through core route flow', (tester) async {
    final database = SessionDatabase.memory();
    final secureStore = InMemorySecureStore();

    final container = ProviderContainer(
      overrides: [
        sessionDatabaseProvider.overrideWithValue(database),
        secureStoreProvider.overrideWithValue(secureStore),
      ],
    );
    addTearDown(() {
      container.dispose();
      database.close();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const EquipmentFormApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Start New Session'), findsOneWidget);

    await tester.tap(find.text('Start New Session'));
    await tester.pumpAndSettle();

    expect(find.text('Choose Form Type'), findsOneWidget);

    await tester.tap(find.text(FormType.received.name.toUpperCase()));
    await tester.pumpAndSettle();

    expect(find.text('Parties'), findsWidgets);
    expect(find.text('Requested By'), findsOneWidget);

    // Additional assertions handled in specialized tests; smoke test stops on party session.
  });
}
