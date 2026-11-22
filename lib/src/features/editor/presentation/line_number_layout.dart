import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Inclusive-exclusive range of line numbers that intersect the viewport.
class LineWindow {
  /// Creates a window from [start] inclusive to [end] exclusive.
  const LineWindow({required this.start, required this.end});

  /// First visible line, zero-based.
  final int start;

  /// First line below the viewport.
  final int end;
}

/// Positions of logical lines in the gutter.
class LineNumberLayout {
  /// Every line has the same [lineHeight]. Used when wrapping is off.
  LineNumberLayout.uniform({required this.lineCount, required this.lineHeight})
    : _prefix = null;

  /// Each logical line may be taller than one visual line. Used when wrapping.
  LineNumberLayout.variable(List<double> heights)
    : lineCount = heights.length,
      lineHeight = heights.isEmpty ? 0 : heights.first,
      _prefix = _prefixSums(heights);

  /// Number of logical lines. Empty documents count as one.
  final int lineCount;

  /// Height of a single unwrapped line, or of the first line when variable.
  final double lineHeight;

  final List<double>? _prefix;

  /// Logical line count of [text].
  ///
  /// A trailing newline counts as an extra line.
  static int countLines(String text) {
    if (text.isEmpty) return 1;
    var count = 1;
    for (var i = 0; i < text.length; i++) {
      if (text.codeUnitAt(i) == 0x0A) count++;
    }
    return count;
  }

  /// Y offset of the top of [line], relative to the document start.
  double topOf(int line) {
    if (_prefix == null) return line * lineHeight;
    return _prefix[line.clamp(0, lineCount)];
  }

  /// Line whose body contains [y], clamped to the document.
  int lineAt(double y) {
    if (lineCount == 0) return 0;
    if (_prefix == null) {
      if (lineHeight <= 0) return 0;
      return (y / lineHeight).floor().clamp(0, lineCount - 1);
    }
    var low = 0;
    var high = lineCount;
    while (low < high) {
      final mid = (low + high) ~/ 2;
      if (_prefix[mid + 1] <= y) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low.clamp(0, lineCount - 1);
  }

  /// Lines that intersect the viewport at [scrollOffset].
  LineWindow visible({
    required double scrollOffset,
    required double viewportHeight,
  }) {
    if (lineCount == 0) return const LineWindow(start: 0, end: 0);
    final start = lineAt(math.max(0, scrollOffset));
    final endLine = lineAt(scrollOffset + math.max(0, viewportHeight));
    final end = math.min(lineCount, math.max(start + 1, endLine + 1));
    return LineWindow(start: start, end: end);
  }
}

List<double> _prefixSums(List<double> heights) {
  final prefix = List<double>.filled(heights.length + 1, 0);
  for (var i = 0; i < heights.length; i++) {
    prefix[i + 1] = prefix[i] + heights[i];
  }
  return prefix;
}

/// Per-logical-line heights for wrapped text.
///
/// [maxWidth] is the width the editor field wraps at. Empty lines keep
/// [minLineHeight] so the gutter still has a row.
List<double> wrappedLineHeights({
  required String text,
  required double maxWidth,
  required TextStyle style,
  required TextScaler textScaler,
  required double minLineHeight,
}) {
  final lines = text.isEmpty ? const [''] : text.split('\n');
  if (maxWidth <= 0) {
    return List<double>.filled(lines.length, minLineHeight);
  }
  return [
    for (final line in lines)
      _lineHeight(
        line,
        maxWidth: maxWidth,
        style: style,
        textScaler: textScaler,
        minLineHeight: minLineHeight,
      ),
  ];
}

double _lineHeight(
  String line, {
  required double maxWidth,
  required TextStyle style,
  required TextScaler textScaler,
  required double minLineHeight,
}) {
  final painter = TextPainter(
    text: TextSpan(text: line.isEmpty ? ' ' : line, style: style),
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
  )..layout(maxWidth: maxWidth);
  final height = painter.height;
  painter.dispose();
  return height < minLineHeight ? minLineHeight : height;
}
