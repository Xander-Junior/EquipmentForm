abstract class MigrationTelemetry {
  void applied({required String id});
  void skipped({required String id, String? reason});
  void failed({required String id, required String error});
}

class DebugMigrationTelemetry implements MigrationTelemetry {
  int migrationsApplied = 0;
  int migrationsSkipped = 0;
  int migrationsFailed = 0;

  final List<String> _events = [];

  List<String> get events => List.unmodifiable(_events);

  @override
  void applied({required String id}) {
    migrationsApplied++;
    _record('applied', id);
  }

  @override
  void skipped({required String id, String? reason}) {
    migrationsSkipped++;
    _record('skipped', id, reason: reason);
  }

  @override
  void failed({required String id, required String error}) {
    migrationsFailed++;
    _record('failed', id, reason: error);
  }

  void reset() {
    migrationsApplied = 0;
    migrationsSkipped = 0;
    migrationsFailed = 0;
    _events.clear();
  }

  void _record(String label, String id, {String? reason}) {
    assert(() {
      final description =
          '[migrate] $label:$id${reason != null ? '($reason)' : ''}';
      // ignore: avoid_print
      print(description);
      return true;
    }());
    if (reason != null) {
      _events.add('$label:$id:$reason');
    } else {
      _events.add('$label:$id');
    }
  }
}
