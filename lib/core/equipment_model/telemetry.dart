import 'equipment_model.dart';

abstract class NormalizeTelemetry {
  void ok(
      {required String raw,
      required EquipmentModel value,
      required int elapsedMs});
  void fallback(
      {required String raw, EquipmentModel? value, required int elapsedMs});
  void fail({required String raw, required int elapsedMs});
}

class DevNormalizeTelemetry implements NormalizeTelemetry {
  @override
  void ok(
      {required String raw,
      required EquipmentModel value,
      required int elapsedMs}) {
    _total++;
    _ok++;
    _totalElapsedMs += elapsedMs;
    _maybeLog('OK', raw, elapsedMs);
  }

  @override
  void fallback(
      {required String raw, EquipmentModel? value, required int elapsedMs}) {
    _total++;
    _fallback++;
    _totalElapsedMs += elapsedMs;
    _maybeLog('FALLBACK', raw, elapsedMs);
  }

  @override
  void fail({required String raw, required int elapsedMs}) {
    _total++;
    _fail++;
    _totalElapsedMs += elapsedMs;
    _maybeLog('FAIL', raw, elapsedMs);
  }

  int _total = 0;
  int _ok = 0;
  int _fallback = 0;
  int _fail = 0;
  int _totalElapsedMs = 0;

  double get okRate => _total == 0 ? 0 : _ok / _total;
  double get fallbackRate => _total == 0 ? 0 : _fallback / _total;
  double get failRate => _total == 0 ? 0 : _fail / _total;
  double get averageParseMs => _total == 0 ? 0 : _totalElapsedMs / _total;

  void reset() {
    _total = 0;
    _ok = 0;
    _fallback = 0;
    _fail = 0;
    _totalElapsedMs = 0;
  }

  void _maybeLog(String label, String raw, int elapsedMs) {
    assert(() {
      if (_total % _logEvery == 0) {
        final printable = raw.length > 40 ? '${raw.substring(0, 37)}...' : raw;
        final message = [
          'equipment_model_parser',
          'event=$label',
          'input="$printable"',
          'elapsed=${elapsedMs}ms',
          'total=$_total',
          'okRate=${okRate.toStringAsFixed(3)}',
          'fallbackRate=${fallbackRate.toStringAsFixed(3)}',
          'failRate=${failRate.toStringAsFixed(3)}',
          'avgMs=${averageParseMs.toStringAsFixed(2)}',
        ].join(' ');
        // ignore: avoid_print
        print(message);
      }
      return true;
    }());
  }

  static const int _logEvery = 50;
}
