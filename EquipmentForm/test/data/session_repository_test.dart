import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:equipment_form_app/data/models/session.dart';
import 'package:equipment_form_app/data/session_database.dart';
import 'package:equipment_form_app/data/session_repository.dart';

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
  late Directory tempDir;
  late File dbFile;
  late InMemorySecureStore secureStore;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('session_repo_test');
    dbFile = File(p.join(tempDir.path, 'session.sqlite'));
    secureStore = InMemorySecureStore();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('save/load roundtrip persists across database instances', () async {
    final session = Session(
      id: 'session-123',
      formType: FormType.received,
      payload: {'field': 'value'},
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1, 12),
    );

    final db1 = SessionDatabase.forTesting(NativeDatabase(dbFile));
    final repo1 = SessionRepository(database: db1, secureStore: secureStore);

    await repo1.save(session);
    await db1.close();

    final db2 = SessionDatabase.forTesting(NativeDatabase(dbFile));
    final repo2 = SessionRepository(database: db2, secureStore: secureStore);

    final loaded = await repo2.loadLatest();
    expect(loaded, isNotNull);
    expect(loaded!.id, equals(session.id));
    expect(loaded.formType, equals(session.formType));
    expect(loaded.payload['field'], equals('value'));

    await db2.close();
  });

  test('missing session clears secure pointer', () async {
    final db = SessionDatabase.memory();
    final repo = SessionRepository(database: db, secureStore: secureStore);

    await secureStore.write(key: 'latest_session_id', value: 'missing');

    final loaded = await repo.loadLatest();
    expect(loaded, isNull);

    final pointer = await secureStore.read(key: 'latest_session_id');
    expect(pointer, isNull);

    await db.close();
  });
}
