import 'dart:convert';
import 'dart:io';

import 'package:logger/logger.dart';

import 'package:teditox/src/core/services/file_service.dart';
import 'package:teditox/src/core/utils/line_endings.dart';

/// Represents a snapshot of the editor state for recovery purposes.
///
/// This class contains all the necessary information to restore the editor
/// to a previous state, including content, file path, and settings.
class RecoverySnapshot {
  /// Creates a new recovery snapshot.
  RecoverySnapshot({
    required this.content,
    required this.path,
    required this.dirty,
    required this.timestamp,
    required this.encoding,
    required this.lineEnding,
  });

  /// Creates a recovery snapshot from JSON data.
  factory RecoverySnapshot.fromJson(Map<String, dynamic> json) =>
      RecoverySnapshot(
        content: json['c'] as String,
        path: json['p'] as String?,
        dirty: json['d'] as bool,
        timestamp: DateTime.parse(json['t'] as String),
        encoding: json['e'] as String,
        lineEnding: LineEndingStyle.values.firstWhere(
          (e) => e.name == json['l'],
          orElse: () => LineEndingStyle.lf,
        ),
      );

  /// The text content of the file.
  final String content;

  /// The file path, null for new/unsaved files.
  final String? path;

  /// Whether the content has unsaved changes.
  final bool dirty;

  /// When this snapshot was created.
  final DateTime timestamp;

  /// The text encoding used for the file.
  final String encoding;

  /// The line ending style used in the file.
  final LineEndingStyle lineEnding;

  /// Converts this snapshot to a JSON representation.
  Map<String, dynamic> toJson() => {
        'c': content,
        'p': path,
        'd': dirty,
        't': timestamp.toIso8601String(),
        'e': encoding,
        'l': lineEnding.name,
      };
}

/// Service for managing editor state recovery functionality.
///
/// This service handles saving and loading editor snapshots to prevent
/// data loss in case of unexpected application termination.
class RecoveryService {
  /// Creates a new recovery service with the given logger.
  RecoveryService({required this.logger});

  /// Logger instance for error reporting.
  final Logger logger;

  static const _fileName = 'teditox_recovery.json';

  /// Gets the recovery file path.
  Future<File> _file(FileService fileService) async {
    final dir = await fileService.getCacheDir();
    return File('${dir.path}/$_fileName');
  }

  /// Saves a recovery snapshot to disk.
  ///
  /// The snapshot is serialized to JSON and written to the recovery file.
  /// If saving fails, a warning is logged but no exception is thrown.
  Future<void> saveSnapshot(
    FileService fileService,
    RecoverySnapshot snap,
  ) async {
    try {
      final f = await _file(fileService);
      await f.writeAsString(jsonEncode(snap.toJson()), flush: true);
    } on Exception catch (e) {
      logger.w('Recovery write failed: $e');
    }
  }

  /// Loads a recovery snapshot from disk.
  ///
  /// Returns the most recent snapshot if available, or null if no recovery
  /// file exists or if loading fails. Errors are logged as warnings.
  Future<RecoverySnapshot?> loadSnapshot(FileService fileService) async {
    try {
      final f = await _file(fileService);
      if (!f.existsSync()) return null;
      final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      return RecoverySnapshot.fromJson(data);
    } on Exception catch (e) {
      logger.w('Recovery load failed: $e');
      return null;
    }
  }

  /// Clears the recovery file from disk.
  ///
  /// This should be called when the user explicitly saves their work
  /// or when recovery is no longer needed. Errors are logged as warnings.
  Future<void> clear(FileService fileService) async {
    try {
      final f = await _file(fileService);
      if (f.existsSync()) await f.delete();
    } on Exception catch (e) {
      logger.w('Recovery clear failed: $e');
    }
  }
}
