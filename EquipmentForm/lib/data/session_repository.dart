import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'models/session.dart';
import 'session/session_codec.dart';
import 'session_database.dart';

abstract class SecureStore {
  Future<void> write({required String key, required String value});
  Future<String?> read({required String key});
  Future<void> delete({required String key});
}

class FlutterSecureStore implements SecureStore {
  FlutterSecureStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> delete({required String key}) => _storage.delete(key: key);

  @override
  Future<String?> read({required String key}) => _storage.read(key: key);

  @override
  Future<void> write({required String key, required String value}) =>
      _storage.write(key: key, value: value);
}

class SessionRepository {
  SessionRepository({
    required SessionDatabase database,
    required SecureStore secureStore,
    SessionCodec? codec,
  })
      : _database = database,
        _secureStore = secureStore,
        _codec = codec ?? SessionCodec();

  final SessionDatabase _database;
  final SecureStore _secureStore;
  final SessionCodec _codec;

  static const String _latestSessionKey = 'latest_session_id';

  Future<void> save(Session session) async {
    final encodedPayload = _codec.encode(session.payload);
    final encodedSession = session.copyWith(payload: encodedPayload);

    await _database.upsertSession(encodedSession);
    await _secureStore.write(key: _latestSessionKey, value: session.id);
  }

  Future<Session?> loadLatest() async {
    final id = await _secureStore.read(key: _latestSessionKey);
    if (id == null) {
      return null;
    }
    final session = await _database.getSession(id);
    if (session == null) {
      await _secureStore.delete(key: _latestSessionKey);
      return null;
    }

    final decodedPayload = _codec.decode(session.payload);
    return session.copyWith(payload: decodedPayload);
  }

  Future<Session?> loadById(String id) async {
    final session = await _database.getSession(id);
    if (session == null) return null;
    final decodedPayload = _codec.decode(session.payload);
    return session.copyWith(payload: decodedPayload);
  }
}
