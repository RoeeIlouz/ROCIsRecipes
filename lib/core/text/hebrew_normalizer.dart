final RegExp _niqqud = RegExp('[֑-ׇ]');
final RegExp _punctuation = RegExp('["\'`´’“”׳״.,;:!?()]');
final RegExp _separators = RegExp(r'[-_\s]+');

const Map<String, String> _finalLetters = {
  'ך': 'כ',
  'ם': 'מ',
  'ן': 'נ',
  'ף': 'פ',
  'ץ': 'צ',
};

/// Normalizes Hebrew or English text for matching: strips niqqud and
/// punctuation, maps final letters to regular forms, lowercases Latin,
/// treats hyphens/underscores as spaces, and collapses whitespace.
String normalizeText(String input) {
  var s = input.replaceAll(_niqqud, '').replaceAll(_punctuation, '');
  s = s.replaceAll(_separators, ' ').trim().toLowerCase();
  final buffer = StringBuffer();
  for (final rune in s.runes) {
    final ch = String.fromCharCode(rune);
    buffer.write(_finalLetters[ch] ?? ch);
  }
  return buffer.toString();
}
