import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:teditox/src/core/services/file_service.dart';

/// Shares the current buffer with another app.
///
/// Android sends a cache file via `ACTION_SEND`. Other platforms copy the
/// text to the clipboard, because there is no share sheet.
class ShareService {
  /// Creates a share service.
  ShareService({required this.fileService, required this.logger});

  /// Used to locate the cache directory.
  final FileService fileService;

  /// Logger for share failures.
  final Logger logger;

  static const _channel = MethodChannel('org.zp1ke.teditox/content_uri');

  /// Shares [text] under [fileName]. Returns false when the platform cannot.
  Future<bool> shareText({
    required String text,
    required String fileName,
  }) async {
    final safeName = fileName.replaceAll(RegExp(r'[\\/]'), '_');
    try {
      final cache = await fileService.getCacheDir();
      final file = File('${cache.path}/$safeName');
      await file.writeAsString(text, flush: true);
      if (!kIsWeb && Platform.isAndroid) {
        await _channel.invokeMethod<void>('shareFile', {
          'path': file.path,
          'text': text,
        });
        return true;
      }
      await Clipboard.setData(ClipboardData(text: text));
      return false;
    } on Exception catch (e) {
      logger.e('Share failed: $e');
      return false;
    }
  }
}
