import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../domain/session_models.dart';

enum PartyOcrConfidence { high, medium, low }

@immutable
class PartyOcrFieldSuggestion {
  PartyOcrFieldSuggestion({
    required this.value,
    required this.score,
    required this.evidence,
    required this.reason,
    this.highlight,
  }) : confidence = _confidenceFor(score);

  final String value;
  final double score;
  final String evidence;
  final String reason;
  final String? highlight;
  final PartyOcrConfidence confidence;

  static PartyOcrConfidence _confidenceFor(double score) {
    if (score >= 0.8) return PartyOcrConfidence.high;
    if (score >= 0.55) return PartyOcrConfidence.medium;
    return PartyOcrConfidence.low;
  }
}

@immutable
class PartyOcrAnalysis {
  const PartyOcrAnalysis({
    required this.rawText,
    required this.lines,
    required this.nameSuggestions,
    required this.departmentSuggestions,
    required this.titleSuggestions,
    required this.emailSuggestions,
  });

  final String rawText;
  final List<String> lines;
  final List<PartyOcrFieldSuggestion> nameSuggestions;
  final List<PartyOcrFieldSuggestion> departmentSuggestions;
  final List<PartyOcrFieldSuggestion> titleSuggestions;
  final List<PartyOcrFieldSuggestion> emailSuggestions;

  List<PartyOcrFieldSuggestion> suggestionsFor(PartyField field) {
    switch (field) {
      case PartyField.name:
        return nameSuggestions;
      case PartyField.department:
        return departmentSuggestions;
      case PartyField.email:
        return emailSuggestions;
    }
  }

  PartyOcrFieldSuggestion? primarySuggestionFor(PartyField field) {
    return suggestionsFor(field).firstOrNull;
  }
}

class _TitleExtraction {
  const _TitleExtraction({
    required this.suggestions,
    required this.consumedLineIndexes,
  });

  final List<PartyOcrFieldSuggestion> suggestions;
  final Set<int> consumedLineIndexes;
}

class _DepartmentCandidate {
  const _DepartmentCandidate({
    required this.value,
    required this.baseScore,
    required this.reason,
    this.highlight,
  });

  final String value;
  final double baseScore;
  final String reason;
  final String? highlight;
}

class PartyOcrAnalyzer {
  const PartyOcrAnalyzer();

  static final RegExp _nonLetters = RegExp(r'[^A-Za-z]');

  PartyOcrAnalysis analyze(Map<String, dynamic> fields) {
    final rawText = (fields['rawText'] as String?)?.trim() ?? '';
    final lineList = _deriveLines(fields, rawText);
    final emailSuggestions = _extractEmails(fields, lineList, rawText);
    final nameSuggestions = _extractNames(fields, lineList, emailSuggestions);
    final titleExtraction = _extractTitles(fields, lineList);
    final departmentSuggestions = _extractDepartments(
      fields,
      lineList,
      rawText,
      titleExtraction.consumedLineIndexes,
    );

    _reinforceEmailAnchoredName(nameSuggestions, emailSuggestions);
    _boostAgreement(nameSuggestions);
    _boostAgreement(departmentSuggestions);
    _boostAgreement(emailSuggestions);

    return PartyOcrAnalysis(
      rawText: rawText,
      lines: lineList,
      nameSuggestions: nameSuggestions,
      departmentSuggestions: departmentSuggestions,
      titleSuggestions: titleExtraction.suggestions,
      emailSuggestions: emailSuggestions,
    );
  }

  List<String> _deriveLines(Map<String, dynamic> fields, String rawText) {
    final provided = fields['lines'];
    if (provided is List) {
      return provided
          .whereType<String>()
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList(growable: false);
    }
    if (rawText.isEmpty) return const [];
    final normalized = rawText.replaceAll('\r', '');
    final split = normalized.split('\n');
    if (split.length == 1) {
      // Heuristic split on double spaces or commas when newline missing.
      return normalized
          .split(RegExp(r'\s{2,}|,'))
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList(growable: false);
    }
    return split
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
  }

  List<PartyOcrFieldSuggestion> _extractEmails(
    Map<String, dynamic> fields,
    List<String> lines,
    String rawText,
  ) {
    final suggestions = <PartyOcrFieldSuggestion>[];
    final seen = <String>{};
    final emailRegex = RegExp(r'[^@\s]+@[^@\s]+\.[^@\s]+', caseSensitive: false);

    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      for (final match in emailRegex.allMatches(line)) {
        final value = match.group(0)!.toLowerCase();
        if (seen.add(value)) {
          suggestions.add(
            PartyOcrFieldSuggestion(
              value: value,
              score: _scoreEmail(value, fields),
              evidence: line,
              highlight: match.group(0),
              reason: value.endsWith('@tullowoil.com')
                  ? 'Matches company domain'
                  : 'Detected email address',
            ),
          );
        }
      }
    }

    if (suggestions.isEmpty && rawText.isNotEmpty) {
      final match = emailRegex.firstMatch(rawText);
      if (match != null) {
        final value = match.group(0)!.toLowerCase();
        suggestions.add(
          PartyOcrFieldSuggestion(
            value: value,
            score: _scoreEmail(value, fields),
            evidence: rawText,
            highlight: match.group(0),
            reason: 'Detected email address',
          ),
        );
      }
    }

    final fromFields = fields['email'];
    if (fromFields is String && seen.add(fromFields.toLowerCase())) {
      suggestions.add(
        PartyOcrFieldSuggestion(
          value: fromFields.toLowerCase(),
          score: _scoreEmail(fromFields, fields) + 0.05,
          evidence: fromFields,
          reason: 'OCR engine email field',
        ),
      );
    }

    suggestions.sort((a, b) => b.score.compareTo(a.score));
    return suggestions;
  }

  double _scoreEmail(String email, Map<String, dynamic> fields) {
    double score = 0.6;
    final lower = email.toLowerCase();
    if (lower.endsWith('@tullowoil.com')) {
      score += 0.3;
    }
    final seed = fields['email'];
    if (seed is String && seed.toLowerCase() == lower) {
      score += 0.1;
    }
    return score.clamp(0, 1);
  }

  List<PartyOcrFieldSuggestion> _extractNames(
    Map<String, dynamic> fields,
    List<String> lines,
    List<PartyOcrFieldSuggestion> emailSuggestions,
  ) {
    final suggestions = <PartyOcrFieldSuggestion>[];
    final seen = <String>{};
    final uppercaseNamePattern = RegExp(r"^[A-Z][A-Z\-'\s]+$");

    void addSuggestion({
      required String value,
      required double score,
      required String evidence,
      String? highlight,
      required String reason,
    }) {
      final normalizedKey = value.trim().toLowerCase();
      if (normalizedKey.isEmpty || !seen.add(normalizedKey)) return;
      suggestions.add(
        PartyOcrFieldSuggestion(
          value: value,
          score: score.clamp(0, 1),
          evidence: evidence,
          highlight: highlight,
          reason: reason,
        ),
      );
    }

    final fieldName = fields['name'];
    if (fieldName is String && fieldName.trim().isNotEmpty) {
      final normalized = _normalizeName(fieldName);
      addSuggestion(
        value: normalized,
        score: 0.88,
        evidence: fieldName,
        highlight: fieldName.trim(),
        reason: 'OCR engine name field',
      );
    }

    if (emailSuggestions.isNotEmpty) {
      final topEmail = emailSuggestions.first.value;
      final localPart = topEmail.split('@').first;
      final segments =
          localPart.split(RegExp(r'[._]')).where((segment) => segment.isNotEmpty);
      if (segments.length >= 2) {
        final reconstructed =
            segments.map(_normalizeHyphenatedSegment).join(' ');
        if (reconstructed.trim().length >= 3) {
          addSuggestion(
            value: reconstructed,
            score: topEmail.endsWith('@tullowoil.com') ? 0.82 : 0.68,
            evidence: topEmail,
            highlight: localPart,
            reason: 'Derived from email username',
          );
        }
      }

      final emailLineIndex = _lineIndexContaining(lines, topEmail);
      if (emailLineIndex != null && emailLineIndex > 0) {
        final preceding = lines[emailLineIndex - 1];
        if (!_looksLikeDepartment(preceding)) {
          final normalized = _normalizeName(preceding);
          if (normalized.split(' ').length >= 2) {
            addSuggestion(
              value: normalized,
              score: topEmail.endsWith('@tullowoil.com') ? 0.86 : 0.74,
              evidence: preceding,
              highlight: preceding.trim(),
              reason: 'Line preceding email address',
            );
          }
        }
      }
    }

    for (final line in lines) {
      if (line.contains('@')) continue;
      final words = line.split(RegExp(r'\s+'));
      if (words.length >= 2 && words.length <= 4) {
        final normalized = _normalizeName(line);
        final isUppercaseCandidate = uppercaseNamePattern.hasMatch(line);
        if (normalized.split(' ').length >= 2) {
          addSuggestion(
            value: normalized,
            score: isUppercaseCandidate ? 0.9 : 0.6,
            evidence: line,
            highlight: line.trim(),
            reason: isUppercaseCandidate
                ? 'Uppercase display name'
                : 'Candidate full name line',
          );
        }
      }
    }

    suggestions.sort((a, b) => b.score.compareTo(a.score));
    return suggestions;
  }

  _TitleExtraction _extractTitles(
    Map<String, dynamic> fields,
    List<String> lines,
  ) {
    final suggestions = <PartyOcrFieldSuggestion>[];
    final consumed = <int>{};
    final seen = <String>{};

    void addSuggestion({
      required String value,
      required double score,
      required String evidence,
      required String reason,
      String? highlight,
      int? index,
    }) {
      final key = value.trim().toLowerCase();
      if (key.isEmpty || !seen.add(key)) return;
      if (index != null) {
        consumed.add(index);
      }
      suggestions.add(
        PartyOcrFieldSuggestion(
          value: value,
          score: score.clamp(0, 1),
          evidence: evidence,
          highlight: highlight,
          reason: reason,
        ),
      );
    }

    final fieldTitle = fields['title'];
    if (fieldTitle is String && fieldTitle.trim().isNotEmpty) {
      final normalized = _normalizeTitle(fieldTitle);
      addSuggestion(
        value: normalized,
        score: 0.8,
        evidence: fieldTitle,
        reason: 'OCR engine title field',
        highlight: fieldTitle.trim(),
      );
    }

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (!_isLikelyTitleLine(line)) continue;
      final normalized = _normalizeTitle(line);
      final score = _scoreTitle(normalized);
      addSuggestion(
        value: normalized,
        score: score,
        evidence: line,
        reason: 'Likely job title',
        highlight: _extractHighlight(line, normalized) ?? line.trim(),
        index: i,
      );
    }

    suggestions.sort((a, b) => b.score.compareTo(a.score));
    return _TitleExtraction(suggestions: suggestions, consumedLineIndexes: consumed);
  }

  List<PartyOcrFieldSuggestion> _extractDepartments(
    Map<String, dynamic> fields,
    List<String> lines,
    String rawText,
    Set<int> skipIndexes,
  ) {
    final suggestions = <PartyOcrFieldSuggestion>[];
    final seen = <String>{};

    void addSuggestion({
      required String value,
      required double score,
      required String evidence,
      String? highlight,
      required String reason,
    }) {
      final key = value.trim().toLowerCase();
      if (key.isEmpty || !seen.add(key)) return;
      suggestions.add(
        PartyOcrFieldSuggestion(
          value: value,
          score: score.clamp(0, 1),
          evidence: evidence,
          highlight: highlight,
          reason: reason,
        ),
      );
    }

    final fieldDept = fields['department'];
    if (fieldDept is String && fieldDept.trim().isNotEmpty) {
      final normalized = _canonicalDepartment(fieldDept) ?? _normalizeDepartment(fieldDept);
      addSuggestion(
        value: normalized,
        score: 0.84,
        evidence: fieldDept,
        highlight: fieldDept.trim(),
        reason: 'OCR engine department field',
      );
    }

    for (var i = 0; i < lines.length; i++) {
      if (skipIndexes.contains(i)) continue;
      final candidate = _departmentCandidateFromLine(lines[i]);
      if (candidate != null) {
        addSuggestion(
          value: candidate.value,
          score: candidate.baseScore,
          evidence: lines[i],
          highlight: candidate.highlight,
          reason: candidate.reason,
        );
      }
    }

    if (rawText.isNotEmpty && suggestions.isEmpty) {
      final inferred = _departmentCandidateFromLine(rawText);
      if (inferred != null) {
        addSuggestion(
          value: inferred.value,
          score: inferred.baseScore,
          evidence: rawText,
          highlight: inferred.highlight,
          reason: inferred.reason,
        );
      }
    }

    suggestions.sort((a, b) => b.score.compareTo(a.score));
    return suggestions;
  }

  String _normalizeName(String input) {
    final cleaned = input.replaceAll(RegExp(r"[^A-Za-z\s'\-]"), ' ');
    final parts = cleaned.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final normalized = parts
        .map((segment) => segment.contains('-')
            ? segment.split('-').map(_normalizeHyphenatedSegment).join('-')
            : _normalizeHyphenatedSegment(segment))
        .join(' ');
    return normalized;
  }

  String _normalizeHyphenatedSegment(String segment) {
    if (segment.isEmpty) return segment;
    final buffer = StringBuffer();
    var capitalizeNext = true;
    for (final rune in segment.runes) {
      final char = String.fromCharCode(rune);
      if (char == '\'' || char == '’') {
        buffer.write(char);
        capitalizeNext = true;
        continue;
      }
      if (char == '-' || char == '‐') {
        buffer.write('-');
        capitalizeNext = true;
        continue;
      }
      if (capitalizeNext) {
        buffer.write(char.toUpperCase());
        capitalizeNext = false;
      } else {
        buffer.write(char.toLowerCase());
      }
    }
    return buffer.toString();
  }

  String _normalizeTitle(String input) => _normalizeDepartment(input);

  double _scoreTitle(String normalized) {
    final lower = normalized.toLowerCase();
    double score = 0.58;
    if (lower.contains('manager')) score += 0.12;
    if (lower.contains('lead') || lower.contains('head')) score += 0.08;
    if (lower.contains('applications')) score += 0.06;
    if (lower.contains('analyst') || lower.contains('specialist')) score += 0.04;
    return score.clamp(0.58, 0.9);
  }

  _DepartmentCandidate? _departmentCandidateFromLine(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    final supply = _inferSupplyChain(trimmed);
    if (supply != null) {
      final base = supply == 'Supply Chain'
          ? 0.72
          : (supply == 'Supply Chain Manager' ? 0.9 : 0.85);
      return _DepartmentCandidate(
        value: supply,
        baseScore: base,
        reason: 'Supply Chain reference',
        highlight: _extractHighlight(trimmed, supply),
      );
    }

    final canonical = _canonicalDepartment(trimmed);
    if (canonical != null) {
      final lower = canonical.toLowerCase();
      double base = 0.8;
      if (lower.contains('digital') && lower.contains('it')) {
        base = 0.86;
      } else if (lower.contains('information technology')) {
        base = 0.82;
      }
      return _DepartmentCandidate(
        value: canonical,
        baseScore: base,
        reason: 'Department synonym',
        highlight: _extractHighlight(trimmed, canonical),
      );
    }

    if (!_looksLikeDepartment(trimmed)) {
      return null;
    }

    final normalized = _normalizeDepartment(trimmed);
    return _DepartmentCandidate(
      value: normalized,
      baseScore: 0.64,
      reason: 'Likely department line',
      highlight: trimmed,
    );
  }

  String _normalizeDepartment(String input) {
    final replaced = input
        .replaceAll(RegExp(r'[\\/]'), ' & ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (replaced.isEmpty) return replaced;
    final canonical = _canonicalDepartment(replaced);
    if (canonical != null) {
      return canonical;
    }
    return replaced.split(' ').map((word) {
      if (word.isEmpty) return word;
      final lowerWord = word.toLowerCase();
      if (lowerWord.length == 1) {
        return lowerWord.toUpperCase();
      }
      return lowerWord[0].toUpperCase() + lowerWord.substring(1);
    }).join(' ');
  }

  String? _canonicalDepartment(String input) {
    final normalized = input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9&\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) return null;
    if (normalized == 'digital') {
      return 'Digital';
    }
    if (normalized == 'it' || normalized == 'information technology') {
      return 'Information Technology';
    }
    if (normalized.contains('digital') && normalized.contains('it')) {
      return 'Digital & IT';
    }
    if (normalized == 'scm' || normalized.contains('supply chain management')) {
      return 'Supply Chain Management';
    }
    if (normalized.contains('supply chain manager')) {
      return 'Supply Chain Manager';
    }
    if (normalized.contains('supply chain')) {
      return 'Supply Chain';
    }
    return null;
  }

  String? _inferSupplyChain(String text) {
    final lower = text.toLowerCase();
    if (!lower.contains('supply') && !lower.contains('scm')) {
      return null;
    }
    if (lower.contains('manager')) {
      return 'Supply Chain Manager';
    }
    if (lower.contains('management') || lower.contains('scm')) {
      return 'Supply Chain Management';
    }
    return 'Supply Chain';
  }

  bool _looksLikeDepartment(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('@')) return false;
    if (_isLikelyTitleLine(text)) return false;
    if (lower.contains('department') || lower.contains('division')) return true;
    if (lower.contains('team') || lower.contains('unit')) return true;
    final words = text.trim().split(RegExp(r'\s+'));
    if (words.length == 1) {
      return lower == 'digital' || lower == 'security' || lower == 'operations';
    }
    final keywords = {
      'supply',
      'chain',
      'digital',
      'operations',
      'manager',
      'management',
      'team',
      'department',
      'services',
      'information',
      'technology',
      'it',
      'applications',
    };
    final looksLikeName = words.length >= 2 &&
        words.every((token) =>
            RegExp(r"^[A-Za-z][A-Za-z\-']*").hasMatch(token.trim())) &&
        words.every((token) => !keywords.contains(token.toLowerCase()));
    if (looksLikeName) return false;
    return words.length <= 4;
  }

  bool _isLikelyTitleLine(String text) {
    final lower = text.toLowerCase().trim();
    if (lower.isEmpty) return false;
    if (lower.contains('@')) return false;
    if (lower.contains('department') || lower.contains('division')) return false;
    final keywords = {
      'applications',
      'manager',
      'lead',
      'analyst',
      'engineer',
      'specialist',
      'officer',
      'coordinator',
      'administrator',
    };
    final words = lower.split(RegExp(r'\s+'));
    if (words.length > 4) return false;
    return words.any(keywords.contains);
  }

  String? _extractHighlight(String text, String inferred) {
    final lowerText = text.toLowerCase();
    final lowerInferred = inferred.toLowerCase();
    if (lowerText.contains(lowerInferred)) {
      final start = lowerText.indexOf(lowerInferred);
      return text.substring(start, start + inferred.length);
    }
    if (lowerText.contains('supply chain')) {
      return text.substring(
        lowerText.indexOf('supply chain'),
        lowerText.indexOf('supply chain') + 'Supply Chain'.length,
      );
    }
    if (lowerText.contains('scm')) {
      return text.substring(lowerText.indexOf('scm'), lowerText.indexOf('scm') + 3);
    }
    if (lowerInferred.contains('digital') && lowerText.contains('digital')) {
      final start = lowerText.indexOf('digital');
      final length = lowerInferred.contains('it') ? 'Digital & IT'.length : 'Digital'.length;
      return text.substring(start, math.min(start + length, text.length));
    }
    if (lowerInferred.contains('information technology') &&
        lowerText.contains('information technology')) {
      final start = lowerText.indexOf('information technology');
      return text.substring(start, math.min(start + 'Information Technology'.length, text.length));
    }
    return null;
  }

  void _reinforceEmailAnchoredName(
    List<PartyOcrFieldSuggestion> nameSuggestions,
    List<PartyOcrFieldSuggestion> emailSuggestions,
  ) {
    if (nameSuggestions.isEmpty || emailSuggestions.isEmpty) return;
    final emailDerived = nameSuggestions.firstWhereOrNull(
      (s) => s.reason == 'Derived from email username',
    );
    final anchor = emailDerived ?? nameSuggestions.first;

    for (final candidate in nameSuggestions) {
      if (identical(candidate, anchor)) continue;
      final mergedValue = _mergeName(anchor.value, candidate.value);
      if (mergedValue == anchor.value && mergedValue == candidate.value) {
        continue;
      }
      final boostedScore = math.max(anchor.score, candidate.score) + 0.06;
      final repaired = PartyOcrFieldSuggestion(
        value: mergedValue,
        score: boostedScore.clamp(0, 1),
        evidence: '${anchor.evidence} • ${candidate.evidence}',
        highlight: candidate.highlight ?? anchor.highlight,
        reason: 'Email and OCR text align',
      );
      nameSuggestions
        ..remove(anchor)
        ..add(repaired);
      nameSuggestions.sort((a, b) => b.score.compareTo(a.score));
      return;
    }
  }

  void _boostAgreement(List<PartyOcrFieldSuggestion> suggestions) {
    if (suggestions.length <= 1) return;
    final grouped = <String, List<PartyOcrFieldSuggestion>>{};
    for (final suggestion in suggestions) {
      final key = suggestion.value.trim().toLowerCase();
      grouped.putIfAbsent(key, () => []).add(suggestion);
    }

    final updated = <PartyOcrFieldSuggestion>[];
    var modified = false;
    for (final entry in grouped.entries) {
      final group = entry.value;
      group.sort((a, b) => b.score.compareTo(a.score));
      final top = group.first;
      if (group.length > 1) {
        final boost = (0.05 * (group.length - 1)).clamp(0, 0.12);
        updated.add(
          PartyOcrFieldSuggestion(
            value: top.value,
            score: (top.score + boost).clamp(0, 1),
            evidence: group.map((s) => s.evidence).toSet().join(' • '),
            highlight: top.highlight,
            reason: '${top.reason}; corroborated',
          ),
        );
        modified = true;
        updated.addAll(group.skip(1));
      } else {
        updated.add(top);
      }
    }

    if (modified) {
      suggestions
        ..clear()
        ..addAll(updated)
        ..sort((a, b) => b.score.compareTo(a.score));
    }
  }

  String _mergeName(String emailValue, String candidateValue) {
    final emailTokens =
        emailValue.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    final candidateTokens = candidateValue
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (candidateTokens.isEmpty) return emailValue;
    if (emailTokens.isEmpty) return candidateValue;

    final usedEmailIndexes = <int>{};
    final merged = <String>[];

    for (final candidateToken in candidateTokens) {
      final plainCandidate =
          candidateToken.replaceAll(_nonLetters, '').toLowerCase();
      var bestIndex = -1;
      var bestDistance = 1 << 30;
      for (var i = 0; i < emailTokens.length; i++) {
        if (usedEmailIndexes.contains(i)) continue;
        final emailToken = emailTokens[i];
        final plainEmail =
            emailToken.replaceAll(_nonLetters, '').toLowerCase();
        if (plainEmail.isEmpty || plainCandidate.isEmpty) continue;
        if (plainEmail[0] != plainCandidate[0]) continue;
        final distance = _levenshteinDistance(plainEmail, plainCandidate);
        if (distance < bestDistance) {
          bestDistance = distance;
          bestIndex = i;
        }
      }

      if (bestIndex != -1) {
        usedEmailIndexes.add(bestIndex);
        merged.add(_mergeToken(
          emailTokens[bestIndex],
          candidateToken,
          bestDistance,
        ));
      } else {
        merged.add(_normalizeName(candidateToken));
      }
    }

    for (var i = 0; i < emailTokens.length; i++) {
      if (!usedEmailIndexes.contains(i)) {
        merged.add(_normalizeName(emailTokens[i]));
      }
    }

    return merged.join(' ').trim();
  }

  String _mergeToken(String emailToken, String candidateToken, int distance) {
    final plainEmail = emailToken.replaceAll(_nonLetters, '').toLowerCase();
    final plainCandidate =
        candidateToken.replaceAll(_nonLetters, '').toLowerCase();

    if (plainEmail == plainCandidate) {
      return _normalizeName(candidateToken);
    }

    if (distance <= 1 && plainEmail.length >= plainCandidate.length) {
      return _normalizeName(emailToken);
    }

    if (distance <= 1 && plainCandidate.length > plainEmail.length) {
      return _normalizeName(candidateToken);
    }

    return plainEmail.isNotEmpty
        ? _normalizeName(emailToken)
        : _normalizeName(candidateToken);
  }

  int _levenshteinDistance(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final previous = List<int>.generate(b.length + 1, (index) => index);
    final current = List<int>.filled(b.length + 1, 0);

    for (var i = 0; i < a.length; i++) {
      current[0] = i + 1;
      for (var j = 0; j < b.length; j++) {
        final cost = a[i] == b[j] ? 0 : 1;
        current[j + 1] = math.min(
          math.min(current[j] + 1, previous[j + 1] + 1),
          previous[j] + cost,
        );
      }
      previous.setAll(0, current);
    }

    return current[b.length];
  }

  int? _lineIndexContaining(List<String> lines, String value) {
    if (value.isEmpty) return null;
    final lower = value.toLowerCase();
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].toLowerCase().contains(lower)) {
        return i;
      }
    }
    return null;
  }
}
