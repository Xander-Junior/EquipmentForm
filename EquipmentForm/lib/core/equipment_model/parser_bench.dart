import 'dart:math';

import 'normalizer.dart';

final _samples = <String>[
  'Dell Latitude 7420',
  'Latitude-7420',
  'Latitude_7420',
  'Lat 7420',
  'Latitude E7470',
  'DELL PRECISION 5560',
  'ThinkPad T480',
  'LENOVO THINKPAD-X1',
  'HP EliteBook 840 G5',
  'ProBook-450 G9',
  'XPS 13 9310',
  'UnknownDevice 123',
  'device with    odd   spacing',
];

void main() {
  const iterations = 1000;
  final random = Random(42);
  final stopwatch = Stopwatch()..start();

  for (var i = 0; i < iterations; i++) {
    final sample = _samples[random.nextInt(_samples.length)];
    parseMakeModel(sample);
  }

  stopwatch.stop();
  final totalMs = stopwatch.elapsedMilliseconds;
  final opsPerSecond = iterations / (stopwatch.elapsedMicroseconds / 1e6);

  // ignore: avoid_print
  print(
    'equipment_model parser bench -> iterations=$iterations totalMs=$totalMs opsPerSecond=${opsPerSecond.toStringAsFixed(1)} avgMs=${(totalMs / iterations).toStringAsFixed(4)}',
  );
}
