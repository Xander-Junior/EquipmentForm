import 'dart:convert';

import 'schema.dart';

int getSchemaVersion(Map<String, dynamic> json) {
  final value = json[kSchemaVersionKey];
  if (value is int) return value;
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

Map<String, dynamic> setSchemaVersion(Map<String, dynamic> json, int version) {
  json[kSchemaVersionKey] = version;
  return json;
}

Map<String, dynamic> deepCopy(Map<String, dynamic> json) {
  return jsonDecode(jsonEncode(json)) as Map<String, dynamic>;
}
