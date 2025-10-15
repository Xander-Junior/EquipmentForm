import 'dart:math';

import 'equipment_model.dart';
import 'telemetry.dart';
import 'vendor_map.dart';

ParseResult parseMakeModel(String raw, {NormalizeTelemetry? telemetry}) {
  final stopwatch = Stopwatch()..start();
  final sanitized = _sanitize(raw);
  if (sanitized.isEmpty) {
    return _finalize(
      status: ParseStatus.fail,
      raw: sanitized,
      value: null,
      telemetry: telemetry,
      elapsed: stopwatch.elapsed,
      originalRaw: raw,
    );
  }

  if (sanitized.length > _maxLength) {
    return _finalize(
      status: ParseStatus.fail,
      raw: sanitized.substring(0, _maxLength),
      value: null,
      telemetry: telemetry,
      elapsed: stopwatch.elapsed,
      originalRaw: raw,
    );
  }

  final fast = _fastPath(sanitized);
  if (fast != null) {
    return _finalize(
      status: fast.status,
      raw: fast.raw,
      value: fast.value,
      telemetry: telemetry,
      elapsed: stopwatch.elapsed,
      originalRaw: raw,
    );
  }

  final tokens = _tokenize(sanitized);
  if (tokens.isEmpty) {
    return _finalize(
      status: ParseStatus.fail,
      raw: sanitized,
      value: null,
      telemetry: telemetry,
      elapsed: stopwatch.elapsed,
      originalRaw: raw,
    );
  }

  final familyIndex = _findFamilyIndex(tokens);
  final canonicalFamily =
      familyIndex != null ? canonicalFamilyForToken(tokens[familyIndex]) : null;

  final vendor = inferVendorFromTokens(tokens) ??
      vendorForFamily(canonicalFamily) ??
      unknownVendor;

  if (canonicalFamily != null) {
    final modelTokens = tokens.sublist(familyIndex! + 1);
    if (modelTokens.isNotEmpty) {
      final modelNumber = _formatModelNumber(modelTokens);
      final model = EquipmentModel(
        make: vendor,
        family: canonicalFamily,
        modelNumber: modelNumber,
        raw: sanitized,
      );
      return _finalize(
        status: ParseStatus.ok,
        raw: sanitized,
        value: model,
        telemetry: telemetry,
        elapsed: stopwatch.elapsed,
        originalRaw: raw,
      );
    }

    final fallbackModel = EquipmentModel(
      make: vendor,
      family: canonicalFamily,
      modelNumber: _bestEffortModel(tokens, exclude: {familyIndex}),
      raw: sanitized,
    );
    return _finalize(
      status: ParseStatus.fallback,
      raw: sanitized,
      value: fallbackModel,
      telemetry: telemetry,
      elapsed: stopwatch.elapsed,
      originalRaw: raw,
    );
  }

  if (vendor != unknownVendor) {
    final fallbackModel = EquipmentModel(
      make: vendor,
      family: 'Unknown',
      modelNumber: _bestEffortModel(tokens, excludeVendor: vendor),
      raw: sanitized,
    );
    return _finalize(
      status: ParseStatus.fallback,
      raw: sanitized,
      value: fallbackModel,
      telemetry: telemetry,
      elapsed: stopwatch.elapsed,
      originalRaw: raw,
    );
  }

  if (sanitized.isNotEmpty) {
    final fallbackModel = EquipmentModel(
      make: unknownVendor,
      family: 'Unknown',
      modelNumber: sanitized.toUpperCase(),
      raw: sanitized,
    );
    return _finalize(
      status: ParseStatus.fallback,
      raw: sanitized,
      value: fallbackModel,
      telemetry: telemetry,
      elapsed: stopwatch.elapsed,
      originalRaw: raw,
    );
  }

  return _finalize(
    status: ParseStatus.fail,
    raw: sanitized,
    value: null,
    telemetry: telemetry,
    elapsed: stopwatch.elapsed,
    originalRaw: raw,
  );
}

const int _maxLength = 80;

ParseResult _finalize({
  required ParseStatus status,
  required String raw,
  required EquipmentModel? value,
  required NormalizeTelemetry? telemetry,
  required Duration elapsed,
  required String originalRaw,
}) {
  final elapsedMs = max(0, elapsed.inMicroseconds ~/ 1000);
  if (telemetry != null) {
    switch (status) {
      case ParseStatus.ok:
        telemetry.ok(raw: originalRaw, value: value!, elapsedMs: elapsedMs);
        break;
      case ParseStatus.fallback:
        telemetry.fallback(
            raw: originalRaw, value: value, elapsedMs: elapsedMs);
        break;
      case ParseStatus.fail:
        telemetry.fail(raw: originalRaw, elapsedMs: elapsedMs);
        break;
    }
  }
  return ParseResult(
    status: status,
    value: value,
    raw: raw,
    elapsed: elapsed,
  );
}

String _sanitize(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return '';
  final collapsed = trimmed.replaceAll(_multiWhitespace, ' ');
  return collapsed;
}

final RegExp _multiWhitespace = RegExp(r'\s+');
final RegExp _tokenSeparator = RegExp(r'[\s_\-]+');

List<String> _tokenize(String value) {
  return value
      .split(_tokenSeparator)
      .where((token) => token.isNotEmpty)
      .map((token) => token.toLowerCase())
      .toList();
}

int? _findFamilyIndex(List<String> tokens) {
  for (var i = 0; i < tokens.length; i++) {
    if (canonicalFamilyForToken(tokens[i]) != null) {
      return i;
    }
  }
  return null;
}

String _formatModelNumber(List<String> tokens) {
  return tokens.map((token) => token.toUpperCase()).join(' ');
}

String _bestEffortModel(List<String> tokens,
    {Set<int>? exclude, String? excludeVendor}) {
  final buffer = <String>[];
  for (var i = 0; i < tokens.length; i++) {
    if (exclude != null && exclude.contains(i)) continue;
    final token = tokens[i];
    if (excludeVendor != null &&
        token.toLowerCase() == excludeVendor.toLowerCase()) {
      continue;
    }
    final family = canonicalFamilyForToken(token);
    if (family != null) continue;
    buffer.add(token.toUpperCase());
  }
  if (buffer.isEmpty) {
    return tokens.map((token) => token.toUpperCase()).join(' ');
  }
  return buffer.join(' ');
}

class _FastPathResult {
  _FastPathResult({
    required this.status,
    required this.value,
    required this.raw,
  });

  final ParseStatus status;
  final EquipmentModel? value;
  final String raw;
}

class _FastPattern {
  _FastPattern(this.family, String pattern)
      : vendor = vendorForFamily(family),
        regex = RegExp(pattern, caseSensitive: false);

  final String family;
  final String? vendor;
  final RegExp regex;
}

final List<_FastPattern> _fastPatterns = [
  _FastPattern('Latitude', r'^(?:dell\s+)?(?:lat|latitude)[\s_\-]+(.+)$'),
  _FastPattern('Precision', r'^(?:dell\s+)?precision[\s_\-]+(.+)$'),
  _FastPattern('XPS', r'^(?:dell\s+)?xps[\s_\-]+(.+)$'),
  _FastPattern('ThinkPad', r'^(?:lenovo\s+)?thinkpad[\s_\-]+(.+)$'),
  _FastPattern('IdeaPad', r'^(?:lenovo\s+)?ideapad[\s_\-]+(.+)$'),
  _FastPattern('EliteBook', r'^(?:hp\s+)?elitebook[\s_\-]+(.+)$'),
  _FastPattern('ProBook', r'^(?:hp\s+)?probook[\s_\-]+(.+)$'),
];

_FastPathResult? _fastPath(String sanitized) {
  for (final pattern in _fastPatterns) {
    final match = pattern.regex.firstMatch(sanitized);
    if (match != null) {
      final tail = match.group(1)?.trim();
      if (tail == null || tail.isEmpty) {
        final fallbackModel = EquipmentModel(
          make: pattern.vendor ?? unknownVendor,
          family: pattern.family,
          modelNumber: '',
          raw: sanitized,
        );
        return _FastPathResult(
          status: ParseStatus.fallback,
          value: fallbackModel,
          raw: sanitized,
        );
      }
      final tokens = _tokenize(tail);
      if (tokens.isEmpty) {
        final fallbackModel = EquipmentModel(
          make: pattern.vendor ?? unknownVendor,
          family: pattern.family,
          modelNumber: '',
          raw: sanitized,
        );
        return _FastPathResult(
          status: ParseStatus.fallback,
          value: fallbackModel,
          raw: sanitized,
        );
      }
      final modelNumber = _formatModelNumber(tokens);
      final model = EquipmentModel(
        make: pattern.vendor ?? unknownVendor,
        family: pattern.family,
        modelNumber: modelNumber,
        raw: sanitized,
      );
      return _FastPathResult(
        status: ParseStatus.ok,
        value: model,
        raw: sanitized,
      );
    }
  }
  return null;
}
