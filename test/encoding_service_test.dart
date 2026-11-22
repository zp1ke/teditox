import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:teditox/src/core/services/encoding_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = EncodingService();

  group('detectEncoding', () {
    test('detects UTF-8 BOM', () {
      expect(service.detectEncoding([0xEF, 0xBB, 0xBF, 0x61]), 'utf-8');
    });

    test('detects UTF-16LE BOM', () {
      expect(service.detectEncoding([0xFF, 0xFE, 0x61, 0x00]), 'utf-16le');
    });

    test('detects UTF-16BE BOM', () {
      expect(service.detectEncoding([0xFE, 0xFF, 0x00, 0x61]), 'utf-16be');
    });

    test('keeps ASCII and valid UTF-8 as UTF-8', () {
      expect(service.detectEncoding(utf8.encode('plain ascii-ish')), 'utf-8');
      expect(service.detectEncoding(utf8.encode('café')), 'utf-8');
    });

    test('detects Windows-1252 punctuation that is invalid UTF-8', () {
      // 0x80 is the euro sign in Windows-1252 and illegal as UTF-8.
      expect(service.detectEncoding([0x50, 0x80, 0x31]), 'windows-1252');
    });

    test('detects ISO-8859-1 when high bytes are not CP1252 punctuation', () {
      // 0xE9 is é in ISO-8859-1 and a lone invalid UTF-8 lead byte.
      expect(service.detectEncoding([0x63, 0x61, 0x66, 0xE9]), 'iso-8859-1');
    });

    test('detects UTF-16LE without a BOM', () {
      expect(
        service.detectEncoding([
          0x61,
          0x00,
          0x62,
          0x00,
          0x63,
          0x00,
          0x64,
          0x00,
        ]),
        'utf-16le',
      );
    });
  });

  group('utf-8 paths (no platform channel)', () {
    test('decode/encode round-trips multi-byte text', () async {
      const text = 'Teditox — áéíóú 日本語 ✓';
      final bytes = await service.encode(text, 'utf-8');
      final decoded = await service.decode(bytes, forcedEncoding: 'utf-8');
      expect(decoded, text);
    });

    test('decode auto-detects and drops UTF-8 BOM bytes', () async {
      final bytes = Uint8List.fromList([
        0xEF,
        0xBB,
        0xBF,
        ...utf8.encode('hello'),
      ]);
      final decoded = await service.decode(bytes);
      // dart:convert's UTF-8 decoder strips a leading BOM.
      expect(decoded, 'hello');
    });

    test('decode tolerates malformed UTF-8 instead of throwing', () async {
      final decoded = await service.decode([
        0xC3,
        0x28,
        0xA0,
      ], forcedEncoding: 'utf-8');
      expect(decoded, isA<String>());
    });
  });

  // The non-UTF-8 charsets delegate to platform converters
  // (charset_converter). In unit tests the channel is missing, which must
  // exercise the graceful UTF-8 fallback below. Real conversion round-trips
  // are covered by on-device integration testing (see integration_test/).
  group('platform fallback (missing channel in unit test env)', () {
    test('decode of non-UTF-8 encoding falls back without throwing', () async {
      final bytes = utf8.encode('café');
      final decoded = await service.decode(
        bytes,
        forcedEncoding: 'windows-1252',
      );
      expect(decoded, isA<String>());
    });

    test('encode of non-UTF-8 encoding falls back to UTF-8 bytes', () async {
      final bytes = await service.encode('café', 'iso-8859-1');
      expect(utf8.decode(bytes), 'café');
    });
  });

  test('supported list matches README-documented order', () {
    expect(service.supported, [
      'utf-8',
      'utf-16le',
      'utf-16be',
      'iso-8859-1',
      'windows-1252',
      'us-ascii',
    ]);
  });
}
