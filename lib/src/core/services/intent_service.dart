import 'dart:async';

import 'package:logger/logger.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// Service for handling incoming file intents from Android.
class IntentService {
  /// Creates an intent service with the required logger.
  IntentService({required this.logger});

  /// Logger instance for debugging.
  final Logger logger;

  StreamSubscription<List<SharedMediaFile>>? _intentDataStreamSubscription;

  /// Initializes the intent service and sets up listeners for incoming files.
  void initialize({
    required void Function(String filePath) onFileReceived,
  }) {
    // Listen for files shared while the app is already running
    _intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(
          (List<SharedMediaFile> value) {
            logger.i('Received files while app running: ${value.length}');
            _handleSharedFiles(value, onFileReceived);
          },
          onError: (dynamic err) {
            logger.e('Error receiving shared files: $err');
          },
        );

    // Get files shared when the app was launched from a closed state
    unawaited(
      ReceiveSharingIntent.instance
          .getInitialMedia()
          .then((List<SharedMediaFile> value) {
            logger.i('Received files on app launch: ${value.length}');
            _handleSharedFiles(value, onFileReceived);
          })
          .catchError((dynamic err) {
            logger.e('Error getting initial shared files: $err');
          }),
    );
  }

  /// Handles the received shared files and filters for text files.
  void _handleSharedFiles(
    List<SharedMediaFile> files,
    void Function(String filePath) onFileReceived,
  ) {
    for (final file in files) {
      final path = file.path;
      logger.d('Shared file path: $path');

      // Check if it's a text file based on the path or MIME type
      if (_isTextFile(path) || _isTextMimeType(file.mimeType)) {
        logger.i('Opening text file: $path (type: ${file.mimeType})');
        onFileReceived(path);
        break; // Only open the first text file
      } else {
        logger.w('Skipping non-text file: $path (type: ${file.mimeType})');
      }
    }
  }

  /// Checks if the MIME type indicates a text file.
  bool _isTextMimeType(String? mimeType) {
    if (mimeType == null) return false;
    return mimeType.startsWith('text/') ||
        mimeType == 'application/json' ||
        mimeType == 'application/xml' ||
        mimeType == 'application/javascript' ||
        mimeType == 'application/x-sh';
  }

  /// Checks if the file is a text file based on its extension.
  bool _isTextFile(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    const textExtensions = [
      'txt',
      'text',
      'log',
      'md',
      'markdown',
      'json',
      'xml',
      'csv',
      'js',
      'ts',
      'dart',
      'java',
      'kt',
      'py',
      'cpp',
      'c',
      'h',
      'html',
      'css',
      'php',
      'rb',
      'go',
      'rs',
      'swift',
      'sh',
      'bat',
      'ps1',
      'yaml',
      'yml',
      'toml',
      'ini',
      'cfg',
      'conf',
    ];
    return textExtensions.contains(extension);
  }

  /// Disposes the intent service and cancels subscriptions.
  void dispose() {
    unawaited(_intentDataStreamSubscription?.cancel());
  }
}
