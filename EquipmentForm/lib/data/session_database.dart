import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'models/session.dart';

part 'session_database.g.dart';

class SessionRecords extends Table {
  TextColumn get id => text()();
  TextColumn get formType => text()();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [SessionRecords])
class SessionDatabase extends _$SessionDatabase {
  SessionDatabase._internal() : super(_openConnection());

  SessionDatabase.forTesting(super.executor);

  factory SessionDatabase() => SessionDatabase._internal();

  factory SessionDatabase.memory() => SessionDatabase.forTesting(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  Future<void> upsertSession(Session session) async {
    final companion = SessionRecordsCompanion(
      id: Value(session.id),
      formType: Value(session.formType.name),
      payload: Value(jsonEncode(session.payload)),
      createdAt: Value(session.createdAt),
      updatedAt: Value(session.updatedAt),
    );

    await into(sessionRecords).insertOnConflictUpdate(companion);
  }

  Future<Session?> getSession(String id) async {
    final record = await (select(sessionRecords)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (record == null) {
      return null;
    }

    final Map<String, dynamic> payload =
        jsonDecode(record.payload) as Map<String, dynamic>;
    return Session(
      id: record.id,
      formType: FormType.values.byName(record.formType),
      payload: payload,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'session.sqlite')); // TODO: add SQLCipher in later milestone.
    return NativeDatabase(file);
  });
}
