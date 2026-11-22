import 'package:flutter_test/flutter_test.dart';
import 'package:teditox/src/features/editor/presentation/line_number_layout.dart';

void main() {
  test(
    'countLines treats empty text as one line and counts a trailing newline',
    () {
      expect(LineNumberLayout.countLines(''), 1);
      expect(LineNumberLayout.countLines('a'), 1);
      expect(LineNumberLayout.countLines('a\nb'), 2);
      expect(LineNumberLayout.countLines('a\n'), 2);
    },
  );

  test('uniform layout paints only the visible window', () {
    final layout = LineNumberLayout.uniform(lineCount: 5000, lineHeight: 20);
    final window = layout.visible(scrollOffset: 1000, viewportHeight: 200);
    expect(window.start, 50);
    expect(window.end, 61);
    expect(window.end - window.start, lessThan(20));
  });

  test('variable layout finds the line at a wrapped offset', () {
    final layout = LineNumberLayout.variable([10, 30, 10]);
    expect(layout.lineAt(0), 0);
    expect(layout.lineAt(10), 1);
    expect(layout.lineAt(39), 1);
    expect(layout.lineAt(40), 2);
    final window = layout.visible(scrollOffset: 10, viewportHeight: 30);
    expect(window.start, 1);
    // Includes the line that starts on the viewport's bottom edge.
    expect(window.end, 3);
  });
}
