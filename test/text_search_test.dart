import 'package:flutter_test/flutter_test.dart';
import 'package:teditox/src/features/editor/presentation/text_search.dart';

void main() {
  const text = 'Cat cat catalog cat';

  test('finds case-insensitive matches and wraps next/previous', () {
    final matches = findMatches(text, const FindQuery(text: 'cat'));
    expect(matches.map((m) => m.start), [0, 4, 8, 16]);
    expect(nextMatchIndex(matches, 5), 2);
    expect(nextMatchIndex(matches, 20), 0);
    expect(previousMatchIndex(matches, 4), 0);
    expect(previousMatchIndex(matches, 0), 3);
  });

  test('whole word skips matches inside a larger word', () {
    final matches = findMatches(
      text,
      const FindQuery(text: 'cat', wholeWord: true),
    );
    expect(matches.map((m) => m.start), [0, 4, 16]);
    expect(matches.any((m) => m.start == 8), isFalse);
  });

  test('replace all is one string and keeps earlier indexes valid', () {
    final matches = findMatches(
      'a a',
      const FindQuery(text: 'a', caseSensitive: true),
    );
    expect(replaceAllMatches('a a', matches, 'bb'), 'bb bb');
  });
}
