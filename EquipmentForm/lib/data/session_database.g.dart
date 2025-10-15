// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_database.dart';

// ignore_for_file: type=lint
class $SessionRecordsTable extends SessionRecords
    with TableInfo<$SessionRecordsTable, SessionRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _formTypeMeta =
      const VerificationMeta('formType');
  @override
  late final GeneratedColumn<String> formType = GeneratedColumn<String>(
      'form_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, formType, payload, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_records';
  @override
  VerificationContext validateIntegrity(Insertable<SessionRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('form_type')) {
      context.handle(_formTypeMeta,
          formType.isAcceptableOrUnknown(data['form_type']!, _formTypeMeta));
    } else if (isInserting) {
      context.missing(_formTypeMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      formType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}form_type'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SessionRecordsTable createAlias(String alias) {
    return $SessionRecordsTable(attachedDatabase, alias);
  }
}

class SessionRecord extends DataClass implements Insertable<SessionRecord> {
  final String id;
  final String formType;
  final String payload;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SessionRecord(
      {required this.id,
      required this.formType,
      required this.payload,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['form_type'] = Variable<String>(formType);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SessionRecordsCompanion toCompanion(bool nullToAbsent) {
    return SessionRecordsCompanion(
      id: Value(id),
      formType: Value(formType),
      payload: Value(payload),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SessionRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionRecord(
      id: serializer.fromJson<String>(json['id']),
      formType: serializer.fromJson<String>(json['formType']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'formType': serializer.toJson<String>(formType),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SessionRecord copyWith(
          {String? id,
          String? formType,
          String? payload,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      SessionRecord(
        id: id ?? this.id,
        formType: formType ?? this.formType,
        payload: payload ?? this.payload,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SessionRecord copyWithCompanion(SessionRecordsCompanion data) {
    return SessionRecord(
      id: data.id.present ? data.id.value : this.id,
      formType: data.formType.present ? data.formType.value : this.formType,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionRecord(')
          ..write('id: $id, ')
          ..write('formType: $formType, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, formType, payload, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionRecord &&
          other.id == this.id &&
          other.formType == this.formType &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SessionRecordsCompanion extends UpdateCompanion<SessionRecord> {
  final Value<String> id;
  final Value<String> formType;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SessionRecordsCompanion({
    this.id = const Value.absent(),
    this.formType = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionRecordsCompanion.insert({
    required String id,
    required String formType,
    required String payload,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        formType = Value(formType),
        payload = Value(payload),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<SessionRecord> custom({
    Expression<String>? id,
    Expression<String>? formType,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (formType != null) 'form_type': formType,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionRecordsCompanion copyWith(
      {Value<String>? id,
      Value<String>? formType,
      Value<String>? payload,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return SessionRecordsCompanion(
      id: id ?? this.id,
      formType: formType ?? this.formType,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (formType.present) {
      map['form_type'] = Variable<String>(formType.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionRecordsCompanion(')
          ..write('id: $id, ')
          ..write('formType: $formType, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$SessionDatabase extends GeneratedDatabase {
  _$SessionDatabase(QueryExecutor e) : super(e);
  $SessionDatabaseManager get managers => $SessionDatabaseManager(this);
  late final $SessionRecordsTable sessionRecords = $SessionRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [sessionRecords];
}

typedef $$SessionRecordsTableCreateCompanionBuilder = SessionRecordsCompanion
    Function({
  required String id,
  required String formType,
  required String payload,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$SessionRecordsTableUpdateCompanionBuilder = SessionRecordsCompanion
    Function({
  Value<String> id,
  Value<String> formType,
  Value<String> payload,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$SessionRecordsTableFilterComposer
    extends Composer<_$SessionDatabase, $SessionRecordsTable> {
  $$SessionRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get formType => $composableBuilder(
      column: $table.formType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$SessionRecordsTableOrderingComposer
    extends Composer<_$SessionDatabase, $SessionRecordsTable> {
  $$SessionRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get formType => $composableBuilder(
      column: $table.formType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SessionRecordsTableAnnotationComposer
    extends Composer<_$SessionDatabase, $SessionRecordsTable> {
  $$SessionRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get formType =>
      $composableBuilder(column: $table.formType, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SessionRecordsTableTableManager extends RootTableManager<
    _$SessionDatabase,
    $SessionRecordsTable,
    SessionRecord,
    $$SessionRecordsTableFilterComposer,
    $$SessionRecordsTableOrderingComposer,
    $$SessionRecordsTableAnnotationComposer,
    $$SessionRecordsTableCreateCompanionBuilder,
    $$SessionRecordsTableUpdateCompanionBuilder,
    (
      SessionRecord,
      BaseReferences<_$SessionDatabase, $SessionRecordsTable, SessionRecord>
    ),
    SessionRecord,
    PrefetchHooks Function()> {
  $$SessionRecordsTableTableManager(
      _$SessionDatabase db, $SessionRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> formType = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SessionRecordsCompanion(
            id: id,
            formType: formType,
            payload: payload,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String formType,
            required String payload,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SessionRecordsCompanion.insert(
            id: id,
            formType: formType,
            payload: payload,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SessionRecordsTableProcessedTableManager = ProcessedTableManager<
    _$SessionDatabase,
    $SessionRecordsTable,
    SessionRecord,
    $$SessionRecordsTableFilterComposer,
    $$SessionRecordsTableOrderingComposer,
    $$SessionRecordsTableAnnotationComposer,
    $$SessionRecordsTableCreateCompanionBuilder,
    $$SessionRecordsTableUpdateCompanionBuilder,
    (
      SessionRecord,
      BaseReferences<_$SessionDatabase, $SessionRecordsTable, SessionRecord>
    ),
    SessionRecord,
    PrefetchHooks Function()>;

class $SessionDatabaseManager {
  final _$SessionDatabase _db;
  $SessionDatabaseManager(this._db);
  $$SessionRecordsTableTableManager get sessionRecords =>
      $$SessionRecordsTableTableManager(_db, _db.sessionRecords);
}
