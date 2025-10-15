import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:equipment_form_app/app/di.dart';
import 'package:equipment_form_app/data/session_database.dart';
import 'package:equipment_form_app/data/session_repository.dart';
import 'package:equipment_form_app/main.dart';

class TestSecureStore implements SecureStore {
  final Map<String, String> _store = {};

  @override
  Future<void> delete({required String key}) async => _store.remove(key);

  @override
  Future<String?> read({required String key}) async => _store[key];

  @override
  Future<void> write({required String key, required String value}) async =>
      _store[key] = value;
}

void main() {
  testWidgets('home screen renders and navigates to form selection', (tester) async {
    final database = SessionDatabase.memory();
    final secureStore = TestSecureStore();

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
  });
}
