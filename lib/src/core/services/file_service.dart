import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:teditox/src/core/services/encoding_service.dart';
import 'package:teditox/src/core/utils/line_endings.dart';

/// Result of a file open operation.
class FileOpenResult {
  /// Creates a new instance of [FileOpenResult].
  FileOpenResult({
    required this.content,
    required this.path,
    required this.encoding,
    required this.lineEndingStyle,
    required this.bytes,
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
      allowedExtensions: ['txt', 'text', 'log', 'md', 'csv', ''],
      withData: true,
    );
    if (res == null || res.files.isEmpty) return null;
    final file = res.files.first;
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
    return FileOpenResult(
      content: content,
      path: file.path!,
      encoding: forcedEncoding ?? encodingService.detectEncoding(bytes),
      lineEndingStyle: le,
      bytes: bytes,
    );
  }

  /// Saves a new file with the specified content and encoding.
  Future<String?> saveNew({
    required String content,
    required String encoding,
    required LineEndingStyle lineEndingStyle,
  }) async {
    // Prepare the content with proper line endings and encoding
    final normalized = normalizeLineEndings(content, lineEndingStyle);
    final bytes = await encodingService.encode(normalized, encoding);

    final path = await FilePicker.platform.saveFile(
      fileName: 'untitled.txt',
      type: FileType.custom,
      allowedExtensions: ['txt'],
      bytes: Uint8List.fromList(bytes), // Convert to Uint8List for Android/iOS
    );

    return path;
  }

  /// Saves the content to the path with the given encoding and line ending.
  Future<String> saveToPath({
    required String path,
    required String content,
    required String encoding,
    required LineEndingStyle lineEndingStyle,
  }) async {
    final normalized = normalizeLineEndings(content, lineEndingStyle);
    final bytes = await encodingService.encode(normalized, encoding);
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return path;
  }

  /// Gets the directory for caching files.
  Future<Directory> getCacheDir() async => getTemporaryDirectory();
}
