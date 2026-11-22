/// One match of a find query.
class TextMatch {
  /// Creates a match covering [start] inclusive to [end] exclusive.
  const TextMatch(this.start, this.end);

  /// Start index in the buffer.
  final int start;

  /// End index in the buffer.
  final int end;

  /// Length of the matched text.
  int get length => end - start;
}

/// Options for [findMatches].
class FindQuery {
  /// Creates a query. An empty [text] matches nothing.
  const FindQuery({
    required this.text,
    this.caseSensitive = false,
    this.wholeWord = false,
  });

  /// Text to find.
  final String text;

  /// When false, matches ignore case.
  final bool caseSensitive;

  /// When true, the match must not sit inside a larger word.
  final bool wholeWord;
}

/// Finds [query] in [text].
List<TextMatch> findMatches(String text, FindQuery query) {
  if (query.text.isEmpty) return const [];
  final pattern = RegExp(
    RegExp.escape(query.text),
    caseSensitive: query.caseSensitive,
  );
  return [
    for (final match in pattern.allMatches(text))
      if (!query.wholeWord || _isWholeWord(text, match.start, match.end))
        TextMatch(match.start, match.end),
  ];
}

/// Index of the match at or after [cursor], or -1.
int nextMatchIndex(List<TextMatch> matches, int cursor) {
  for (var i = 0; i < matches.length; i++) {
    if (matches[i].start >= cursor) return i;
  }
  return matches.isEmpty ? -1 : 0;
}

/// Index of the match before [cursor], wrapping to the last match.
int previousMatchIndex(List<TextMatch> matches, int cursor) {
  for (var i = matches.length - 1; i >= 0; i--) {
    if (matches[i].start < cursor) return i;
  }
  return matches.isEmpty ? -1 : matches.length - 1;
}

/// Replaces every match, from the end so earlier indexes stay valid.
String replaceAllMatches(
  String text,
  List<TextMatch> matches,
  String replacement,
) {
  var result = text;
  for (final match in matches.reversed) {
    result = result.replaceRange(match.start, match.end, replacement);
  }
  return result;
}

bool _isWholeWord(String text, int start, int end) {
  final before = start == 0 || !_isWordChar(text.codeUnitAt(start - 1));
  final after = end >= text.length || !_isWordChar(text.codeUnitAt(end));
  return before && after;
}

bool _isWordChar(int codeUnit) {
  return (codeUnit >= 0x30 && codeUnit <= 0x39) ||
      (codeUnit >= 0x41 && codeUnit <= 0x5A) ||
      (codeUnit >= 0x61 && codeUnit <= 0x7A) ||
      codeUnit == 0x5F ||
      codeUnit > 0x7F;
}
