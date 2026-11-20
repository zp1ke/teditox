import 'package:flutter_test/flutter_test.dart';
import 'package:teditox/src/core/utils/byte_size_formatter.dart';

void main() {
  group('formatBytes', () {
    test('bytes below 1 KB: 1 decimal only under 10', () {
      expect(formatBytes(0), '0.0 B');
      expect(formatBytes(1), '1.0 B');
      expect(formatBytes(9), '9.0 B');
      expect(formatBytes(512), '512 B');
      expect(formatBytes(1023), '1023 B');
    });

    test('kilobytes', () {
      expect(formatBytes(1024), '1.0 KB');
      expect(formatBytes(1536), '1.5 KB');
      expect(formatBytes(10240), '10 KB');
    });

    test('megabytes', () {
      expect(formatBytes(1024 * 1024), '1.0 MB');
      expect(formatBytes(1024 * 1024 * 2), '2.0 MB');
      expect(formatBytes(1024 * 1024 * 256), '256 MB');
    });
    test('gigabytes (upper bound)', () {
      expect(formatBytes(1024 * 1024 * 1024), '1.0 GB');
    });

    test('stops at GB for very large values', () {
      expect(formatBytes(1024 * 1024 * 1024 * 4096), contains('GB'));
    });
  });
}
