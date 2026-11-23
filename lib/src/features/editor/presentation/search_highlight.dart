import 'package:flutter/rendering.dart';
import 'package:teditox/src/features/editor/presentation/text_search.dart';

/// Paints find matches behind the editor text.
class SearchHighlightPainter extends RenderEditablePainter {
  /// Creates a painter with no matches.
  SearchHighlightPainter();

  /// Matches to paint. Indexes are into the editor buffer.
  List<TextMatch> matches = const [];

  /// Index of the current match, or -1.
  int activeIndex = -1;

  /// Color for every match except the current one.
  Color color = const Color(0x66FFF59D);

  /// Color for [activeIndex].
  Color activeColor = const Color(0x99FFB74D);

  /// Replaces the painted matches and repaints when they changed.
  void update({
    required List<TextMatch> matches,
    required int activeIndex,
    required Color color,
    required Color activeColor,
  }) {
    if (activeIndex == this.activeIndex &&
        color == this.color &&
        activeColor == this.activeColor &&
        _same(matches, this.matches)) {
      return;
    }
    this.matches = matches;
    this.activeIndex = activeIndex;
    this.color = color;
    this.activeColor = activeColor;
    notifyListeners();
  }

  @override
  void paint(Canvas canvas, Size size, RenderEditable renderEditable) {
    if (matches.isEmpty) return;
    final textLength = renderEditable.plainText.length;
    final paint = Paint();
    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];
      if (match.start < 0 ||
          match.end > textLength ||
          match.end <= match.start) {
        continue;
      }
      paint.color = i == activeIndex ? activeColor : color;
      final boxes = renderEditable.getBoxesForSelection(
        TextSelection(baseOffset: match.start, extentOffset: match.end),
      );
      for (final box in boxes) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(box.toRect(), const Radius.circular(2)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(RenderEditablePainter? oldDelegate) => true;

  static bool _same(List<TextMatch> a, List<TextMatch> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].start != b[i].start || a[i].end != b[i].end) return false;
    }
    return true;
  }
}
