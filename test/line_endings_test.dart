import 'package:flutter_test/flutter_test.dart';
import 'package:teditox/src/core/utils/line_endings.dart';

void main() {
  group('detectLineEndings', () {
    test('empty / single-line text defaults to LF', () {
      expect(detectLineEndings(''), LineEndingStyle.lf);
      expect(detectLineEndings('no newlines here'), LineEndingStyle.lf);
    });

    test('detects LF', () {
      expect(detectLineEndings('a\nb\nc'), LineEndingStyle.lf);
    });

    test('detects CRLF', () {
      expect(detectLineEndings('a\r\nb\r\nc'), LineEndingStyle.crlf);
    });

    test('detects CR', () {
      expect(detectLineEndings('a\rb\rc'), LineEndingStyle.cr);
    });

    test('picks the most frequent style when mixed', () {
      // 2 CRLF vs 1 LF -> CRLF
      expect(detectLineEndings('a\r\nb\r\nc\nd'), LineEndingStyle.crlf);
      // 2 LF vs 1 CRLF -> LF
      expect(detectLineEndings('a\nb\nc\r\nd'), LineEndingStyle.lf);
      // 2 CR vs 1 LF -> CR
      expect(detectLineEndings('a\rb\rc\nd'), LineEndingStyle.cr);
    });

    test('CRLF is not double-counted as CR', () {
      expect(detectLineEndings('a\r\nb'), LineEndingStyle.crlf);
    });
  });

  group('normalizeLineEndings', () {
    test('LF target unifies CRLF and CR', () {
      expect(
        normalizeLineEndings('a\r\nb\rc\nd', LineEndingStyle.lf),
        'a\nb\nc\nd',
      );
    });

    test('CRLF target', () {
      expect(
        normalizeLineEndings('a\r\nb\rc\nd', LineEndingStyle.crlf),
        'a\r\nb\r\nc\r\nd',
      );
    });

    test('CR target', () {
      expect(normalizeLineEndings('a\r\nb\nc', LineEndingStyle.cr), 'a\rb\rc');
    });

    test('is idempotent', () {
      const input = 'a\r\nb\rc\n';
      final once = normalizeLineEndings(input, LineEndingStyle.crlf);
      expect(normalizeLineEndings(once, LineEndingStyle.crlf), once);
    });

    test('preserves text without line endings', () {
      expect(normalizeLineEndings('abc', LineEndingStyle.crlf), 'abc');
    });
  });
}
