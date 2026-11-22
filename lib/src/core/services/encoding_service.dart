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
        String() => await CharsetConverter.encode(encoding, text),
      };
    } on Exception catch (_) {
      return utf8.encode(text);
    }
  }

  /// Detect the encoding of a list of bytes.
  ///
  /// A BOM wins. Otherwise valid UTF-8 (including ASCII) stays UTF-8 so a
  /// normal text file is not labelled Latin-1. Invalid UTF-8 is scored as
  /// Windows-1252 when it contains bytes that encoding uses for punctuation,
  /// and ISO-8859-1 otherwise. UTF-16 without a BOM is recognised when one
  /// half of the sample is NULs.
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
    final utf16 = _utf16WithoutBom(bytes);
    if (utf16 != null) return utf16;
    if (_isStrictUtf8(bytes)) return 'utf-8';
    return _hasWindows1252Punctuation(bytes) ? 'windows-1252' : 'iso-8859-1';
  }
}

bool _isStrictUtf8(List<int> bytes) {
  try {
    utf8.decode(bytes);
    return true;
  } on FormatException {
    return false;
  }
}

/// Windows-1252 uses these for printable characters. ISO-8859-1 treats the
/// same bytes as controls, so their presence is a strong CP1252 signal.
const _windows1252Punctuation = <int>{
  0x80,
  0x82,
  0x83,
  0x84,
  0x85,
  0x86,
  0x87,
  0x88,
  0x89,
  0x8A,
  0x8B,
  0x8C,
  0x8E,
  0x91,
  0x92,
  0x93,
  0x94,
  0x95,
  0x96,
  0x97,
  0x98,
  0x99,
  0x9A,
  0x9B,
  0x9C,
  0x9E,
  0x9F,
};

bool _hasWindows1252Punctuation(List<int> bytes) {
  for (final byte in bytes) {
    if (_windows1252Punctuation.contains(byte)) return true;
  }
  return false;
}

/// Returns a UTF-16 encoding when one byte of each pair is NUL, or null.
String? _utf16WithoutBom(List<int> bytes) {
  if (bytes.length < 8 || bytes.length.isOdd) return null;
  final sample = bytes.length < 64 ? bytes.length : 64;
  var evenNulls = 0;
  var oddNulls = 0;
  for (var i = 0; i < sample; i++) {
    if (bytes[i] != 0) continue;
    if (i.isEven) {
      evenNulls++;
    } else {
      oddNulls++;
    }
  }
  final pairs = sample ~/ 2;
  if (oddNulls >= pairs * 3 ~/ 4 && evenNulls == 0) return 'utf-16le';
  if (evenNulls >= pairs * 3 ~/ 4 && oddNulls == 0) return 'utf-16be';
  return null;
}
