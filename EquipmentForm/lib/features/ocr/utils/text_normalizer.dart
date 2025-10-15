/// Utilities for normalizing OCR text into canonical formats.
class TextNormalizer {
  const TextNormalizer();

  /// Normalizes an asset/service/serial tag by stripping whitespace,
  /// uppercasing letters, and replacing lookalike characters.
  String normalizeIdentifier(String input) {
    final trimmed = input.trim().toUpperCase();
    final buffer = StringBuffer();
    for (final rune in trimmed.runes) {
      final char = String.fromCharCode(rune);
      switch (char) {
        case 'O':
          buffer.write('0');
          break;
        case 'I':
        case 'L':
          buffer.write('1');
          break;
        case 'S':
          buffer.write('5');
          break;
        case '-':
        case ' ':
        case '_':
          // skip separators
          break;
        default:
          buffer.write(char);
      }
    }
    return buffer.toString();
  }

  /// Normalizes a person name by trimming, collapsing multiple spaces,
  /// and capitalizing each word.
  String normalizeName(String input) {
    final segments = input.trim().split(RegExp(r'\s+'));
    return segments
        .where((segment) => segment.isNotEmpty)
        .map((segment) => segment[0].toUpperCase() + segment.substring(1).toLowerCase())
        .join(' ');
  }
}
