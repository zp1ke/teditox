import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:teditox/src/core/services/file_service.dart'
    show fileAllowedExtensions;

/// A file handed to the app from another Android app.
class IncomingFile {
  /// Creates an incoming file.
  const IncomingFile(this.path, {this.displayName});

  /// Content URI or filesystem path.
  final String path;

  /// Name from the content resolver, when it had one.
  final String? displayName;
}

/// Whether [path] from an external open should be loaded into the editor.
bool shouldOpenIncoming(String path, String? mimeType) {
  final mime = mimeType?.toLowerCase();
  if (mime != null &&
      (mime.startsWith('image/') ||
          mime.startsWith('video/') ||
          mime.startsWith('audio/'))) {
    return false;
  }
  if (mime != null &&
      (mime.startsWith('text/') ||
          mime == 'application/json' ||
          mime == 'application/xml' ||
          mime == 'application/javascript' ||
          mime == 'application/x-sh' ||
          mime == 'application/octet-stream')) {
    return true;
  }
  final extension = path.toLowerCase().split('.').last;
  if (fileAllowedExtensions.contains(extension)) return true;
  return path.startsWith('content://') && mime == null;
}

/// Service for handling incoming file intents from Android.
///
/// The underlying plugin is Android-only. On other platforms (Linux desktop,
/// tests, web) [initialize] is a no-op instead of throwing
/// `MissingPluginException`.
class IntentService {
  /// Creates an intent service with the required logger.
  IntentService({required this.logger});

  /// Logger instance for debugging.
  final Logger logger;

  static const _channel = MethodChannel('org.zp1ke.teditox/content_uri');

  StreamSubscription<List<SharedMediaFile>>? _intentDataStreamSubscription;
  Future<void> _ready = Future<void>.value();

  /// Completes after the cold-start file intent has been delivered, if any.
  ///
  /// Session restore must wait for this. Otherwise it replaces the file the
  /// user just opened from another app.
  Future<void> get whenReady => _ready;

  /// Whether incoming-intent handling is available on this platform.
  static bool get isSupported => !kIsWeb && Platform.isAndroid;

  /// Initializes the intent service and sets up listeners for incoming files.
  ///
  /// No-op on platforms where `receive_sharing_intent` has no implementation.
  void initialize({required void Function(IncomingFile file) onFileReceived}) {
    if (!isSupported) {
      logger.d('Intent handling is unsupported on this platform; skipping.');
      return;
    }

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onIncomingFile') {
        _emitMap(call.arguments, onFileReceived);
      }
    });
    _ready = _consumeInitial(onFileReceived);

    // Listen for files shared while the app is already running
    _intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(
          (value) {
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
          .then((value) {
            logger.i('Received files on app launch: ${value.length}');
            _handleSharedFiles(value, onFileReceived);
          })
          .catchError((dynamic err) {
            logger.e('Error getting initial shared files: $err');
          }),
    );
  }

  /// Handles the received shared files and filters for text files.
  Future<void> _consumeInitial(
    void Function(IncomingFile file) onFileReceived,
  ) async {
    try {
      final raw = await _channel.invokeMethod<dynamic>('takeIncomingFile');
      _emitMap(raw, onFileReceived);
    } on PlatformException catch (e) {
      logger.e('Failed to read the launch file intent: ${e.message}');
    }
  }

  void _emitMap(dynamic raw, void Function(IncomingFile file) onFileReceived) {
    if (raw is! Map) return;
    final path = raw['uri'] as String?;
    if (path == null || path.isEmpty) return;
    final mime = raw['mimeType'] as String?;
    if (!shouldOpenIncoming(path, mime)) {
      logger.w('Skipping non-text incoming file: $path ($mime)');
      return;
    }
    final name = raw['displayName'] as String?;
    logger.i('Opening incoming file: $path ($name)');
    onFileReceived(IncomingFile(path, displayName: name));
  }

  void _handleSharedFiles(
    List<SharedMediaFile> files,
    void Function(IncomingFile file) onFileReceived,
  ) {
    for (final file in files) {
      final path = file.path;
      logger.d('Shared file path: $path');

      if (shouldOpenIncoming(path, file.mimeType)) {
        logger.i('Opening text file: $path (type: ${file.mimeType})');
        onFileReceived(IncomingFile(path));
        break;
      } else {
        logger.w('Skipping non-text file: $path (type: ${file.mimeType})');
      }
    }
  }

  /// Disposes the intent service and cancels subscriptions.
  void dispose() {
    unawaited(_intentDataStreamSubscription?.cancel());
  }
}
