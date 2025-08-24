import 'dart:convert';
import 'dart:typed_data';

import 'package:charset_converter/charset_converter.dart';

/// Service for encoding and decoding text with various character sets.
class EncodingService {
  /// Ordered list for selection UI.
  final List<String> supported = [
    'utf-8',
    'utf-16le',
    'utf-16be',
    'iso-8859-1',
    'windows-1252',
    'us-ascii',
  ];

  /// Decode a list of bytes into a string using the specified encoding.
  /// If the encoding is not supported, fall back to UTF-8.
  Future<String> decode(List<int> bytes, {String? forcedEncoding}) async {
    final encoding = forcedEncoding ?? detectEncoding(bytes);
    try {
      return switch (encoding) {
        'utf-8' => utf8.decode(bytes, allowMalformed: true),
        String() => await CharsetConverter.decode(
          encoding,
          Uint8List.fromList(bytes),
        ),
      };
    } on Exception catch (_) {
      return utf8.decode(bytes, allowMalformed: true);
    }
  }

  /// Encode a string into a list of bytes using the specified encoding.
  /// If the encoding is not supported, fall back to UTF-8.
  Future<List<int>> encode(String text, String encoding) async {
    try {
      return switch (encoding) {
        'utf-8' => utf8.encode(text),
        String() => await CharsetConverter.encode(
          encoding,
          text,
        ),
      };
    } on Exception catch (_) {
      return utf8.encode(text);
    }
  }

  /// Detect the encoding of a list of bytes.
  String detectEncoding(List<int> bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      return 'utf-8';
    }
    if (bytes.length >= 2) {
      if (bytes[0] == 0xFF && bytes[1] == 0xFE) return 'utf-16le';
      if (bytes[0] == 0xFE && bytes[1] == 0xFF) return 'utf-16be';
    }
    return 'utf-8'; // heuristic default
  }
}
