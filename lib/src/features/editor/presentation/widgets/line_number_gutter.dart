import 'package:material_ui/material_ui.dart';
import 'package:teditox/src/features/editor/presentation/line_number_layout.dart';

/// Paints only the line numbers that intersect the editor viewport.
///
/// The previous gutter built one widget per logical line on every keystroke.
class LineNumberGutter extends StatefulWidget {
  /// Creates a gutter synced to [textController] and [scrollController].
  const LineNumberGutter({
    required this.textController,
    required this.scrollController,
    required this.textStyle,
    required this.wrap,
    required this.contentPadding,
    required this.textMaxWidth,
    super.key,
  });

  /// Editor text. Listened to for line-count changes.
  final TextEditingController textController;

  /// Vertical scroll of the text field.
  final ScrollController scrollController;

  /// Style used by the text field, so line height matches.
  final TextStyle textStyle;

  /// Whether the editor wraps long lines.
  final bool wrap;

  /// Padding above the first line, matching the text field.
  final EdgeInsets contentPadding;

  /// Width the text field wraps at, excluding its own horizontal padding.
  final double textMaxWidth;

  @override
  State<LineNumberGutter> createState() => _LineNumberGutterState();
}

class _LineNumberGutterState extends State<LineNumberGutter> {
  String _cachedText = '';
  double _cachedWidth = -1;
  List<double>? _heights;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    final scaler = MediaQuery.textScalerOf(context);
    final numberStyle = widget.textStyle.copyWith(
      fontSize: (widget.textStyle.fontSize ?? 14) * 0.85,
      color: color,
    );
    final lineHeight = _measureLineHeight(scaler);
    final lineCount = LineNumberLayout.countLines(widget.textController.text);
    final width = _gutterWidth(lineCount, numberStyle, scaler);

    return SizedBox(
      width: width,
      child: ListenableBuilder(
        listenable: Listenable.merge([
          widget.textController,
          widget.scrollController,
        ]),
        builder: (context, _) {
          final text = widget.textController.text;
          final layout = widget.wrap
              ? LineNumberLayout.variable(_wrapped(text, lineHeight, scaler))
              : LineNumberLayout.uniform(
                  lineCount: LineNumberLayout.countLines(text),
                  lineHeight: lineHeight,
                );
          final offset = widget.scrollController.hasClients
              ? widget.scrollController.offset
              : 0.0;
          return CustomPaint(
            painter: _GutterPainter(
              layout: layout,
              scrollOffset: offset,
              paddingTop: widget.contentPadding.top,
              style: numberStyle,
              color: color,
              textScaler: scaler,
              textIdentity: Object.hash(text.length, text.hashCode),
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }

  double _measureLineHeight(TextScaler scaler) {
    final sample = TextPainter(
      text: TextSpan(text: 'A', style: widget.textStyle),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final height = sample.height;
    sample.dispose();
    return height;
  }

  double _gutterWidth(int lineCount, TextStyle style, TextScaler scaler) {
    final probe = TextPainter(
      text: TextSpan(text: '0' * lineCount.toString().length, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final width = probe.width + 16;
    probe.dispose();
    return width;
  }

  List<double> _wrapped(String text, double lineHeight, TextScaler scaler) {
    if (text == _cachedText &&
        widget.textMaxWidth == _cachedWidth &&
        _heights != null) {
      return _heights!;
    }
    _heights = wrappedLineHeights(
      text: text,
      maxWidth: widget.textMaxWidth,
      style: widget.textStyle,
      textScaler: scaler,
      minLineHeight: lineHeight,
    );
    _cachedText = text;
    _cachedWidth = widget.textMaxWidth;
    return _heights!;
  }
}

class _GutterPainter extends CustomPainter {
  _GutterPainter({
    required this.layout,
    required this.scrollOffset,
    required this.paddingTop,
    required this.style,
    required this.color,
    required this.textScaler,
    required this.textIdentity,
  });

  final LineNumberLayout layout;
  final double scrollOffset;
  final double paddingTop;
  final TextStyle style;
  final Color color;
  final TextScaler textScaler;
  final int textIdentity;

  @override
  void paint(Canvas canvas, Size size) {
    final window = layout.visible(
      scrollOffset: scrollOffset - paddingTop,
      viewportHeight: size.height,
    );
    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    );
    for (var line = window.start; line < window.end; line++) {
      painter
        ..text = TextSpan(
          text: '${line + 1}',
          style: style.copyWith(color: color),
        )
        ..layout();
      final y = paddingTop + layout.topOf(line) - scrollOffset;
      painter.paint(canvas, Offset(size.width - painter.width - 8, y));
    }
    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant _GutterPainter oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.textIdentity != textIdentity ||
        oldDelegate.layout.lineCount != layout.lineCount ||
        oldDelegate.paddingTop != paddingTop ||
        oldDelegate.color != color;
  }
}
