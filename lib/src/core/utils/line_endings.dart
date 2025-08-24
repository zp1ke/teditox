/// Represents different line ending styles used in text files.
///
/// Different operating systems use different line ending conventions:
/// - [lf]: Unix/Linux/macOS style (line feed only)
/// - [crlf]: Windows style (carriage return + line feed)
/// - [cr]: Classic Mac style (carriage return only)
enum LineEndingStyle {
  /// Unix/Linux/macOS line endings (\n)
  lf,

  /// Windows line endings (\r\n)
  crlf,

  /// Classic Mac line endings (\r)
  cr,
}

/// Detects the most common line ending style in the given text.
///
/// Analyzes the text content and returns the line ending style that
/// appears most frequently. If no line endings are found, defaults to
/// [LineEndingStyle.lf].
///
/// Returns:
/// - [LineEndingStyle.crlf] if Windows-style endings are most common
/// - [LineEndingStyle.lf] if Unix-style endings are most common
/// - [LineEndingStyle.cr] if classic Mac endings are most common
/// - [LineEndingStyle.lf] as default for single-line text
LineEndingStyle detectLineEndings(String text) {
  final crlfCount = RegExp(r'\r\n').allMatches(text).length;
  final crCount = RegExp(r'\r(?!\n)').allMatches(text).length;
  final lfCount = RegExp(r'(?<!\r)\n').allMatches(text).length;
  if (crlfCount >= lfCount && crlfCount >= crCount && crlfCount > 0) {
    return LineEndingStyle.crlf;
  }
  if (lfCount >= crCount && lfCount > 0) {
    return LineEndingStyle.lf;
  }
  if (crCount > 0) return LineEndingStyle.cr;
  return LineEndingStyle.lf; // default when single line
}

/// Normalizes line endings in text to the specified style.
///
/// Takes input text with mixed or unknown line endings and converts
/// all line endings to the specified [style].
///
/// The process:
/// 1. Unifies all line endings to LF (\n) format
/// 2. Converts to the target line ending style
///
/// [text]: The input text to normalize
/// [style]: The desired line ending style
///
/// Returns the text with consistent line endings of the specified style.
String normalizeLineEndings(String text, LineEndingStyle style) {
  final unified = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  return switch (style) {
    LineEndingStyle.lf => unified,
    LineEndingStyle.crlf => unified.replaceAll('\n', '\r\n'),
    LineEndingStyle.cr => unified.replaceAll('\n', '\r'),
  };
}
