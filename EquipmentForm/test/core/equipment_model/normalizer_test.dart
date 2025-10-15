import 'package:flutter_test/flutter_test.dart';

import 'package:equipment_form_app/core/equipment_model/equipment_model.dart';
import 'package:equipment_form_app/core/equipment_model/normalizer.dart';
import 'package:equipment_form_app/core/equipment_model/telemetry.dart';

void main() {
  group('parseMakeModel', () {
    final okCases = <_Expectation>[
      _Expectation('Latitude 7420', ParseStatus.ok, 'Dell', 'Latitude', '7420'),
      _Expectation('Latitude-7420', ParseStatus.ok, 'Dell', 'Latitude', '7420'),
      _Expectation('Latitude_7420', ParseStatus.ok, 'Dell', 'Latitude', '7420'),
      _Expectation('Lat 7420', ParseStatus.ok, 'Dell', 'Latitude', '7420'),
      _Expectation(
          'Latitude E7470', ParseStatus.ok, 'Dell', 'Latitude', 'E7470'),
      _Expectation(
          'DELL PRECISION 5560', ParseStatus.ok, 'Dell', 'Precision', '5560'),
      _Expectation(
          'ThinkPad T480', ParseStatus.ok, 'Lenovo', 'ThinkPad', 'T480'),
      _Expectation(
          'LENOVO THINKPAD-X1', ParseStatus.ok, 'Lenovo', 'ThinkPad', 'X1'),
      _Expectation(
          'HP EliteBook 840 G5', ParseStatus.ok, 'HP', 'EliteBook', '840 G5'),
      _Expectation('ProBook-450 G9', ParseStatus.ok, 'HP', 'ProBook', '450 G9'),
      _Expectation('XPS 13 9310', ParseStatus.ok, 'Dell', 'XPS', '13 9310'),
      _Expectation('  dell   latitude   5540  ', ParseStatus.ok, 'Dell',
          'Latitude', '5540'),
      _Expectation(
          'thinkpad   t490', ParseStatus.ok, 'Lenovo', 'ThinkPad', 'T490'),
    ];

    for (final expectation in okCases) {
      test('returns OK for "${expectation.input}"', () {
        final result = parseMakeModel(expectation.input);
        expect(result.status, ParseStatus.ok);
        expect(result.value, isNotNull);
        expect(result.value!.make, expectation.make);
        expect(result.value!.family, expectation.family);
        expect(result.value!.modelNumber, expectation.modelNumber);
      });
    }

    final fallbackCases = <String, void Function(ParseResult)>{
      'Latitude': (result) {
        expect(result.value!.family, 'Latitude');
      },
      'Dell device 123': (result) {
        expect(result.value!.make, 'Dell');
        expect(result.value!.modelNumber, contains('123'));
      },
      '7420 only': (result) {
        expect(result.value!.modelNumber, '7420 ONLY');
      },
      'Unknown family model': (result) {
        expect(result.value!.make, 'Unknown');
      },
    };

    fallbackCases.forEach((input, verifier) {
      test('returns fallback for "$input"', () {
        final result = parseMakeModel(input);
        expect(result.status, ParseStatus.fallback);
        expect(result.value, isNotNull);
        verifier(result);
      });
    });

    final failCases = <String>[
      '',
      '   ',
      'This is a deliberately very long equipment string that should exceed eighty characters to force a failure case Latitude 7420 repeat',
    ];

    for (final input in failCases) {
      test('returns fail for "$input"', () {
        final result = parseMakeModel(input);
        expect(result.status, ParseStatus.fail);
        expect(result.value, isNull);
      });
    }

    test('round-trip normalization is consistent', () {
      const variants = ['Latitude 7420', 'latitude 7420', ' LATITUDE   7420 '];
      final parsed = variants.map(parseMakeModel).toList();
      for (final result in parsed) {
        expect(result.status, ParseStatus.ok);
        expect(result.value, isNotNull);
      }
      final first = parsed.first.value!;
      for (final result in parsed.skip(1)) {
        expect(result.value!.make, first.make);
        expect(result.value!.family, first.family);
        expect(result.value!.modelNumber, first.modelNumber);
      }
    });

    test('performance: 1000 parses under threshold', () {
      const iterations = 1000;
      final stopwatch = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        final input = okCases[i % okCases.length].input;
        parseMakeModel(input);
      }
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(200));
    });

    test('telemetry receives events', () {
      final telemetry = _TelemetryProbe();

      parseMakeModel('Latitude 7420', telemetry: telemetry);
      parseMakeModel('Latitude', telemetry: telemetry);
      parseMakeModel('', telemetry: telemetry);

      expect(telemetry.okCount, 1);
      expect(telemetry.fallbackCount, 1);
      expect(telemetry.failCount, 1);
      expect(telemetry.elapsedMsRecords.length, 3);
    });
  });
}

class _Expectation {
  const _Expectation(
      this.input, this.status, this.make, this.family, this.modelNumber);

  final String input;
  final ParseStatus status;
  final String make;
  final String family;
  final String modelNumber;
}

class _TelemetryProbe implements NormalizeTelemetry {
  int okCount = 0;
  int fallbackCount = 0;
  int failCount = 0;
  final elapsedMsRecords = <int>[];

  @override
  void ok(
      {required String raw,
      required EquipmentModel value,
      required int elapsedMs}) {
    okCount++;
    elapsedMsRecords.add(elapsedMs);
  }

  @override
  void fallback(
      {required String raw, EquipmentModel? value, required int elapsedMs}) {
    fallbackCount++;
    elapsedMsRecords.add(elapsedMs);
  }

  @override
  void fail({required String raw, required int elapsedMs}) {
    failCount++;
    elapsedMsRecords.add(elapsedMs);
  }
}
