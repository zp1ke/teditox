import 'package:flutter_test/flutter_test.dart';
import 'package:teditox/src/features/editor/presentation/text_delta.dart';

void main() {
  test(
    'diff and invert round-trip an insertion, deletion, and replacement',
    () {
      const cases = [
        ('', 'hello'),
        ('hello', ''),
        ('hello', 'hello!'),
        ('hello', 'hullo'),
        ('abcd', 'abXcd'),
        ('aaa', 'aaaa'),
        ('line\nline', 'line\nline\nline'),
      ];
      for (final (before, after) in cases) {
        final delta = diffText(before, after);
        expect(delta.apply(before), after, reason: '$before -> $after');
        expect(delta.invert().apply(after), before, reason: 'undo $after');
        expect(delta.payloadBytes, lessThan(before.length + after.length + 1));
      }
    },
  );
}
