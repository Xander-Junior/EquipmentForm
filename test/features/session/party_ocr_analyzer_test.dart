import 'package:flutter_test/flutter_test.dart';

import 'package:equipment_form_app/features/session/domain/session_models.dart';
import 'package:equipment_form_app/features/session/ocr/party_ocr_analyzer.dart';

void main() {
  const analyzer = PartyOcrAnalyzer();

  test('hyphenated names normalise with proper casing', () {
    final analysis = analyzer.analyze({
      'rawText':
          'ANNE-MARIE O\'CONNOR\nSupply Chain Manager\nanne-marie.oconnor@tullowoil.com',
    });

    final nameSuggestion = analysis.primarySuggestionFor(PartyField.name)!;
    final allNames = analysis.nameSuggestions
        .map((s) => '${s.value}:${s.reason}:${s.score}')
        .toList();
    expect(
      nameSuggestion.value,
      equals('Anne-Marie O\'Connor'),
      reason: 'names=$allNames',
    );
  });

  test('supply chain inference prefers canonical labels', () {
    final analysis = analyzer.analyze({
      'rawText':
          'Anne-Marie O\'Connor\nSCM Manager\nanne-marie.oconnor@tullowoil.com',
    });

    final department =
        analysis.primarySuggestionFor(PartyField.department)!.value;
    expect(department, equals('Supply Chain Manager'));
  });

  test('email suggestions prefer tullowoil.com domain', () {
    final analysis = analyzer.analyze({
      'rawText':
          'Contact: anne-marie.oconnor@tullowoil.com / anne@contractor.net',
    });

    final email = analysis.primarySuggestionFor(PartyField.email)!.value;
    expect(email, equals('anne-marie.oconnor@tullowoil.com'));
  });

  test('supply chain without manager yields amber confidence', () {
    final analysis = analyzer.analyze({
      'rawText': 'OTUKO JOHN TEYE\nSupply Chain\notuko.teye@tullowoil.com',
      'lines': const [
        'OTUKO JOHN TEYE',
        'Supply Chain',
        'otuko.teye@tullowoil.com',
      ],
    });

    final suggestion = analysis.primarySuggestionFor(PartyField.department)!;
    expect(suggestion.value, equals('Supply Chain'));
    expect(suggestion.confidence, PartyOcrConfidence.medium);
  });

  test('email anchored name repair prefers email reconstruction', () {
    final analysis = analyzer.analyze({
      'rawText':
          'FRANCLS KWAKU NYARKO\nAPPLICATIONS\nDIGITAL & IT\nfrancis.nyarko@tullowoil.com',
      'lines': const [
        'FRANCLS KWAKU NYARKO',
        'APPLICATIONS',
        'DIGITAL & IT',
        'francis.nyarko@tullowoil.com',
      ],
      'name': 'FRANCLS KWAKU NYARKO',
      'email': 'francis.nyarko@tullowoil.com',
    });

    final name = analysis.primarySuggestionFor(PartyField.name)!;
    expect(
      name.value,
      equals('Francis Kwaku Nyarko'),
      reason: 'names=${analysis.nameSuggestions.map((s) => s.value).toList()}',
    );
    expect(name.confidence, PartyOcrConfidence.high);
  });

  test('title resolver separates applications from department', () {
    final analysis = analyzer.analyze({
      'rawText':
          'FRANCLS KWAKU NYARKO\nAPPLICATIONS\nDIGITAL & IT\nfrancis.nyarko@tullowoil.com',
      'lines': const [
        'FRANCLS KWAKU NYARKO',
        'APPLICATIONS',
        'DIGITAL & IT',
        'francis.nyarko@tullowoil.com',
      ],
    });

    final department =
        analysis.primarySuggestionFor(PartyField.department)!.value;
    expect(department, equals('Digital & IT'));
    expect(analysis.titleSuggestions.first.value, equals('Applications'));
  });

  test('confidence boosts when multiple sources agree', () {
    final analysis = analyzer.analyze({
      'rawText': 'Jane Doe\nDigital\njane.doe@tullowoil.com',
      'name': 'Jane Doe',
      'department': 'Digital',
      'email': 'jane.doe@tullowoil.com',
    });

    final email = analysis.primarySuggestionFor(PartyField.email)!;
    expect(email.confidence, PartyOcrConfidence.high);
    final department = analysis.primarySuggestionFor(PartyField.department)!;
    expect(department.value, equals('Digital'));
    expect(department.confidence,
        anyOf(PartyOcrConfidence.high, PartyOcrConfidence.medium));
  });
}
