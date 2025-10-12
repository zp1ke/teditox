import 'dart:io';
import 'dart:typed_data';

import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:teditox/src/core/services/content_uri_service.dart';
import 'package:teditox/src/core/services/encoding_service.dart';
import 'package:teditox/src/core/utils/line_endings.dart';

/// Allowed file extensions for opening and saving files.
const fileAllowedExtensions = ['txt', 'text', 'log', 'md', 'json', 'csv', ''];

/// Result of a file open operation.
class FileOpenResult {
  /// Creates a new instance of [FileOpenResult].
  FileOpenResult({
    required this.content,
    required this.path,
    required this.encoding,
    required this.lineEndingStyle,
    required this.bytes,
    this.isContentUri = false,
    this.contentUri,
    this.displayName,
  });

  /// The content of the file.
  final String content;

  /// The path to the file (may be a cache path on Android).
  final String path;

  /// The encoding used to read the file.
  final String encoding;

  /// The line ending style used in the file.
  final LineEndingStyle lineEndingStyle;

  /// The raw bytes of the file.
  final List<int> bytes;

  /// Whether this file was opened from a content:// URI.
  final bool isContentUri;

  /// The actual content URI if this was opened from SAF (Android).
  final String? contentUri;

  /// The display name of the file from the content provider.
  final String? displayName;
}

/// Result of a file save operation.
class FileSaveResult {
  /// Creates a new instance of [FileSaveResult].
  FileSaveResult({
    required this.path,
    required this.isContentUri,
    this.contentUri,
    this.displayName,
  });

  /// The path to the saved file (may be a document identifier on Android).
  final String path;

  /// Whether this is a content URI that requires "Save As" for future saves.
  final bool isContentUri;

  /// The actual content URI if saved via SAF (Android).
  final String? contentUri;

  /// The display name of the saved file.
  final String? displayName;
}

/// Service for handling file operations.
class FileService {
  /// Creates a new instance of [FileService].
  FileService({
    required this.encodingService,
    required this.contentUriService,
    required this.logger,
  });

  /// The encoding service used for text encoding and decoding.
  final EncodingService encodingService;

  /// The content URI service for Android SAF operations.
  final ContentUriService contentUriService;

  /// The logger used for logging events and errors.
  final Logger logger;

  /// Picks a file and opens it for reading.
  Future<FileOpenResult?> pickAndOpen({
    String? forcedEncoding,
    int? maxBytes,
  }) async {
    // Use our custom content URI service instead of file_picker
    final result = await contentUriService.pickFile();
    if (result == null) {
      return null; // User cancelled
    }

    final uri = result['uri']!;
    final displayName = result['displayName']!;

    // Read the file content using content URI service
    final uriBytes = await contentUriService.readFromUri(uri);
    if (uriBytes == null) {
      throw const FileSystemException('Failed to read from content URI');
    }

    if (maxBytes != null && uriBytes.length > maxBytes) {
      throw const FileSystemException('File exceeds size threshold');
    }

    final content = await encodingService.decode(
      uriBytes,
      forcedEncoding: forcedEncoding,
    );
    final le = detectLineEndings(content);

    logger.d(
      'Opened file: $uri (displayName: $displayName, size: ${uriBytes.length})',
    );

    return FileOpenResult(
      content: content,
      path: uri,
      encoding: forcedEncoding ?? encodingService.detectEncoding(uriBytes),
      lineEndingStyle: le,
      bytes: uriBytes,
      isContentUri: true,
      contentUri: uri,
      displayName: displayName,
    );
  }

  /// Opens a file directly by its path.
  /// Supports both regular file paths and Android content:// URIs.
  Future<FileOpenResult?> openByPath({
    required String path,
    String? forcedEncoding,
    int? maxBytes,
  }) async {
    try {
      List<int> bytes;
      String? contentUri;
      String? displayName;
      final isContentUri = path.startsWith('content://');

      if (isContentUri) {
        // Use content URI service to read directly
        contentUri = path;
        final uriBytes = await contentUriService.readFromUri(path);
        if (uriBytes == null) {
          throw FileSystemException('Failed to read from content URI', path);
        }
        bytes = uriBytes;

        // Try to take persistable permission
        await contentUriService.takePersistableUriPermission(path);

        // Get display name
        displayName = await contentUriService.getDisplayName(path);

        logger.d('Opened content URI: $path (displayName: $displayName)');
      } else {
        // Regular file path
        final file = File(path);
        if (!file.existsSync()) {
          throw FileSystemException('File does not exist', path);
        }
        bytes = await file.readAsBytes();
      }

      if (maxBytes != null && bytes.length > maxBytes) {
        throw const FileSystemException('File exceeds size threshold');
      }

      final content = await encodingService.decode(
        bytes,
        forcedEncoding: forcedEncoding,
      );
      final le = detectLineEndings(content);

      return FileOpenResult(
        content: content,
        path: path,
        encoding: forcedEncoding ?? encodingService.detectEncoding(bytes),
        lineEndingStyle: le,
        bytes: bytes,
        isContentUri: isContentUri,
        contentUri: contentUri,
        displayName: displayName,
      );
    } catch (e) {
      logger.e('Failed to open file at path $path: $e');
      rethrow;
    }
  }

  /// Saves a new file with the specified content and encoding.
  ///
  /// Returns null if the user cancels, otherwise returns a FileSaveResult
  /// with the path and content URI information.
  Future<FileSaveResult?> saveNew({
    required String initialName,
    required String content,
    required String encoding,
    required LineEndingStyle lineEndingStyle,
  }) async {
    final bytes = await _bytes(
      content: content,
      lineEndingStyle: lineEndingStyle,
      encoding: encoding,
    );

    // Use our custom content URI service instead of file_picker
    final result = await contentUriService.createFile(initialName);
    if (result == null) {
      return null; // User cancelled
    }

    final uri = result['uri']!;
    final displayName = result['displayName']!;

    // Write the bytes to the content URI
    final success = await contentUriService.writeToUri(
      uri,
      Uint8List.fromList(bytes),
    );

    if (!success) {
      throw const FileSystemException('Failed to write to content URI');
    }

    logger.d(
      'Saved file: $uri (displayName: $displayName, size: ${bytes.length})',
    );

    return FileSaveResult(
      path: uri,
      isContentUri: true,
      contentUri: uri,
      displayName: displayName,
    );
  }

  /// Saves the content to the path with the given encoding and line ending.
  ///
  /// For content URIs, uses the ContentUriService to write directly.
  Future<String> saveToPath({
    required String path,
    required String content,
    required String encoding,
    required LineEndingStyle lineEndingStyle,
  }) async {
    final bytes = await _bytes(
      content: content,
      lineEndingStyle: lineEndingStyle,
      encoding: encoding,
    );

    if (path.startsWith('content://')) {
      // Use content URI service for direct write
      final success = await contentUriService.writeToUri(
        path,
        Uint8List.fromList(bytes),
      );
      if (!success) {
        throw FileSystemException('Failed to write to content URI', path);
      }
      logger.d('Wrote ${bytes.length} bytes to content URI: $path');
    } else {
      // Regular file path
      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);
    }

    return path;
  }

  Future<List<int>> _bytes({
    required String content,
    required LineEndingStyle lineEndingStyle,
    required String encoding,
  }) async {
    // Prepare the content with proper line endings and encoding
    final normalized = normalizeLineEndings(content, lineEndingStyle);
    return encodingService.encode(normalized, encoding);
  }

  /// Gets the directory for caching files.
  Future<Directory> getCacheDir() async => getTemporaryDirectory();
}
