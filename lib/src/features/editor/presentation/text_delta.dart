/// A single replacement inside a string.
///
/// Undo history stores these instead of a full copy of the buffer once the
/// document is large.
class TextDelta {
  /// Creates a replacement of [removed] with [inserted] at [start].
  const TextDelta({
    required this.start,
    required this.removed,
    required this.inserted,
  });

  /// Index in the previous text where the change begins.
  final int start;

  /// Text that was removed from the previous version.
  final String removed;

  /// Text that replaced [removed].
  final String inserted;

  /// Bytes kept by this step (the changed span, not the whole document).
  int get payloadBytes => removed.length + inserted.length;

  /// Applies this change to [text].
  String apply(String text) {
    final end = start + removed.length;
    if (start < 0 || end > text.length) return text;
    return text.replaceRange(start, end, inserted);
  }

  /// The inverse change, suitable for undo.
  TextDelta invert() =>
      TextDelta(start: start, removed: inserted, inserted: removed);
}

/// Diffs [before] and [after] as one prefix/suffix-aligned replacement.
TextDelta diffText(String before, String after) {
  var start = 0;
  final minLength = before.length < after.length ? before.length : after.length;
  while (start < minLength &&
      before.codeUnitAt(start) == after.codeUnitAt(start)) {
    start++;
  }

  var beforeEnd = before.length;
  var afterEnd = after.length;
  while (beforeEnd > start &&
      afterEnd > start &&
      before.codeUnitAt(beforeEnd - 1) == after.codeUnitAt(afterEnd - 1)) {
    beforeEnd--;
    afterEnd--;
  }

  return TextDelta(
    start: start,
    removed: before.substring(start, beforeEnd),
    inserted: after.substring(start, afterEnd),
  );
}
