import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

/// A failed read of a content URI.
class ContentUriReadException implements Exception {
  /// Creates a read failure.
  const ContentUriReadException(this.message, {required this.missing});

  /// Platform message.
  final String message;

  /// True when the document no longer exists (ENOENT / not found).
  final bool missing;

  @override
  String toString() => 'ContentUriReadException($message, missing: $missing)';
}

/// Whether a platform read error means the document is gone.
bool contentUriIsMissing(String? message) {
  final text = message?.toLowerCase() ?? '';
  return text.contains('enoent') ||
      text.contains('no such file') ||
      text.contains('not found');
}

/// Service for handling Android content URIs via platform channel.
///
/// This service allows reading from and writing to content URIs directly,
/// which is necessary for proper file handling on Android with scoped storage.
class ContentUriService {
  /// Creates a new instance of [ContentUriService].
  ContentUriService({required this.logger});

  /// The logger used for logging events and errors.
  final Logger logger;

  static const _channel = MethodChannel('org.zp1ke.teditox/content_uri');

  /// Opens a file picker to select a file for reading.
  ///
  /// Returns a map with 'uri' and 'displayName', or null if cancelled.
  Future<Map<String, String>?> pickFile() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'pickFile',
      );
      if (result == null) return null;

      final uri = result['uri'] as String?;
      final displayName = result['displayName'] as String?;

      if (uri == null) return null;

      logger.d('Picked file: $uri (displayName: $displayName)');
      return {'uri': uri, 'displayName': displayName ?? 'unknown'};
    } on PlatformException catch (e) {
      logger.e('Failed to pick file: ${e.message}');
      return null;
    }
  }

  /// Opens a file picker to create/save a file.
  ///
  /// Returns a map with 'uri' and 'displayName', or null if cancelled.
  Future<Map<String, String>?> createFile(String fileName) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'createFile',
        {'fileName': fileName},
      );
      if (result == null) return null;

      final uri = result['uri'] as String?;
      final displayName = result['displayName'] as String?;

      if (uri == null) return null;

      logger.d('Created file: $uri (displayName: $displayName)');
      return {'uri': uri, 'displayName': displayName ?? fileName};
    } on PlatformException catch (e) {
      logger.e('Failed to create file: ${e.message}');
      return null;
    }
  }

  /// Reads bytes from a content URI.
  ///
  /// Throws [ContentUriReadException] when the platform cannot read [uri].
  /// [ContentUriReadException.missing] is true when the document is gone.
  Future<Uint8List?> readFromUri(String uri) async {
    try {
      final result = await _channel.invokeMethod<Uint8List>('readFromUri', {
        'uri': uri,
      });
      logger.d('Read ${result?.length ?? 0} bytes from URI: $uri');
      if (result == null) {
        throw const ContentUriReadException('empty read', missing: false);
      }
      return result;
    } on PlatformException catch (e) {
      logger.e('Failed to read from URI $uri: ${e.message}');
      throw ContentUriReadException(
        e.message ?? 'read failed',
        missing: contentUriIsMissing(e.message),
      );
    }
  }

  /// Writes bytes to a content URI.
  ///
  /// Returns true if the write was successful, false otherwise.
  Future<bool> writeToUri(String uri, Uint8List bytes) async {
    try {
      final result = await _channel.invokeMethod<bool>('writeToUri', {
        'uri': uri,
        'bytes': bytes,
      });
      logger.d('Wrote ${bytes.length} bytes to URI: $uri');
      return result ?? false;
    } on PlatformException catch (e) {
      logger.e('Failed to write to URI $uri: ${e.message}');
      return false;
    }
  }

  /// Gets the display name (filename) from a content URI.
  ///
  /// Returns null if the name cannot be retrieved.
  Future<String?> getDisplayName(String uri) async {
    try {
      final result = await _channel.invokeMethod<String>('getDisplayName', {
        'uri': uri,
      });
      logger.d('Display name for $uri: $result');
      return result;
    } on PlatformException catch (e) {
      logger.e('Failed to get display name for URI $uri: ${e.message}');
      return null;
    }
  }

  /// Takes persistable URI permission for long-term access.
  ///
  /// This should be called after picking a file to maintain access to it.
  /// Returns true if permission was granted successfully.
  Future<bool> takePersistableUriPermission(String uri) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'takePersistableUriPermission',
        {'uri': uri},
      );
      logger.d('Took persistable permission for URI: $uri (success: $result)');
      return result ?? false;
    } on PlatformException catch (e) {
      logger.e(
        'Failed to take persistable permission for URI $uri: ${e.message}',
      );
      return false;
    }
  }
}
