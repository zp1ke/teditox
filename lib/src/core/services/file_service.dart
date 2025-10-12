import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
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
  });

  /// The content of the file.
  final String content;

  /// The path to the file.
  final String path;

  /// The encoding used to read the file.
  final String encoding;

  /// The line ending style used in the file.
  final LineEndingStyle lineEndingStyle;

  /// The raw bytes of the file.
  final List<int> bytes;

  /// Whether this file was opened from a content:// URI (temporary access).
  /// These files should use "Save As" instead of direct save.
  final bool isContentUri;
}

/// Service for handling file operations.
class FileService {
  /// Creates a new instance of [FileService].
  FileService({
    required this.encodingService,
    required this.logger,
  });

  /// The encoding service used for text encoding and decoding.
  final EncodingService encodingService;

  /// The logger used for logging events and errors.
  final Logger logger;

  /// Picks a file and opens it for reading.
  Future<FileOpenResult?> pickAndOpen({
    String? forcedEncoding,
    int? maxBytes,
  }) async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: fileAllowedExtensions,
      withData: true,
    );
    if (res == null || res.files.isEmpty) {
      return null;
    }
    final file = res.files.single;
    final bytes =
        file.bytes ??
        await File(file.path!).readAsBytes(); // fallback for large
    if (maxBytes != null && bytes.length > maxBytes) {
      throw const FileSystemException('File exceeds size threshold');
    }
    final content = await encodingService.decode(
      bytes,
      forcedEncoding: forcedEncoding,
    );
    final le = detectLineEndings(content);

    // Check if the path is a content URI or temporary path
    // File picker on Android often returns content:// URIs or cache paths
    // that don't point to the actual file location
    final path = file.path ?? '';
    final isContentUri =
        path.startsWith('content://') ||
        path.contains('/cache/') ||
        path.contains('/tmp/');

    logger.d('Picked file path: $path (isContentUri: $isContentUri)');

    return FileOpenResult(
      content: content,
      path: path,
      encoding: forcedEncoding ?? encodingService.detectEncoding(bytes),
      lineEndingStyle: le,
      bytes: bytes,
      isContentUri: isContentUri, // Mark as content URI if temporary
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
      final bytes = <int>[];
      var finalPath = path;

      // Handle Android content:// URIs
      if (path.startsWith('content://')) {
        logger.d('Handling content URI: $path');

        // For content URIs, we need to read the file and copy it
        // to a temp location because we can't directly work with
        // content:// URIs as File paths
        final file = File(path);

        try {
          // Try to read the bytes directly - this works on Android
          final contentBytes = await file.readAsBytes();
          bytes.addAll(contentBytes);
          logger.d('Read ${bytes.length} bytes from content URI');
        } on FileSystemException catch (e) {
          logger.e('Failed to read from content URI: $e');
          rethrow;
        }

        // Extract filename from the content URI if possible
        final pathSegments = Uri.parse(path).pathSegments;
        final filename = pathSegments.isNotEmpty
            ? pathSegments.last
            : 'shared_file.txt';

        // Copy to a temporary file so we have a real path
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/$filename');
        await tempFile.writeAsBytes(bytes);
        finalPath = tempFile.path;
        logger.d('Copied content to temporary file: $finalPath');
      } else {
        // Regular file path
        final file = File(path);
        if (!file.existsSync()) {
          throw FileSystemException('File does not exist', path);
        }
        bytes.addAll(await file.readAsBytes());
        finalPath = path;
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
        path: finalPath,
        encoding: forcedEncoding ?? encodingService.detectEncoding(bytes),
        lineEndingStyle: le,
        bytes: bytes,
        isContentUri: path.startsWith('content://'), // Track content URI status
      );
    } catch (e) {
      logger.e('Failed to open file at path $path: $e');
      rethrow;
    }
  }

  /// Saves a new file with the specified content and encoding.
  Future<File?> saveNew({
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
    final filePath = await FilePicker.platform.saveFile(
      fileName: initialName,
      type: FileType.custom,
      allowedExtensions: fileAllowedExtensions,
      bytes: Uint8List.fromList(bytes),
    );
    // TODO: fix returned path different from actual saved file path on Android
    return filePath != null ? File(filePath) : null;
  }

  /// Saves the content to the path with the given encoding and line ending.
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
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return path;
  }

  Future<List<int>> _bytes({
    required String content,
    required LineEndingStyle lineEndingStyle,
    required String encoding,
  }) async {
    // Prepare the content with proper line endings and encoding
    final normalized = normalizeLineEndings(content, lineEndingStyle);
    return await encodingService.encode(normalized, encoding);
  }

  /// Gets the directory for caching files.
  Future<Directory> getCacheDir() async => getTemporaryDirectory();
}
