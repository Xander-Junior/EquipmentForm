import 'package:flutter_test/flutter_test.dart';

import 'package:equipment_form_app/data/models/session.dart';

void main() {
  test('Session copyWith produces modified instance', () {
    final session = Session(
      id: 'abc',
      formType: FormType.received,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    );

    final updated = session.copyWith(
      payload: {'name': 'Jane'},
      updatedAt: DateTime(2025, 1, 2),
    );

    expect(updated.id, session.id);
    expect(updated.payload['name'], 'Jane');
    expect(updated.updatedAt, DateTime(2025, 1, 2));
  });

  test('Session JSON roundtrip preserves content', () {
    final session = Session(
      id: 'session-1',
      formType: FormType.replaced,
      payload: {'assetTag': 'AT123'},
      createdAt: DateTime(2025, 2, 1, 8),
      updatedAt: DateTime(2025, 2, 1, 9),
    );

    final json = session.toJson();
    final fromJson = Session.fromJson(json);

    expect(fromJson, session);
  });
}
