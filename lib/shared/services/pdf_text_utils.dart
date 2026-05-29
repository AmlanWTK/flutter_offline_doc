/// Heuristic: embedded PDF text is usable when it has enough non-whitespace content.
bool isSubstantialEmbeddedText(String text) {
  final trimmed = text.trim();
  if (trimmed.length < 40) return false;

  final meaningful = trimmed.replaceAll(RegExp(r'\s+'), '');
  if (meaningful.length < 25) return false;

  // Reject pages that are mostly placeholder or garbled extraction.
  final replacementRatio =
      trimmed.split('').where((c) => c == '\uFFFD' || c == '?').length /
          trimmed.length;
  return replacementRatio < 0.3;
}
