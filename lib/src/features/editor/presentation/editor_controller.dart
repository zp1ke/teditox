import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:teditox/src/core/services/file_service.dart';
import 'package:teditox/src/core/services/recent_files_service.dart';
import 'package:teditox/src/core/services/recovery_service.dart';
import 'package:teditox/src/core/utils/line_endings.dart';
import 'package:teditox/src/features/settings/presentation/settings_controller.dart';

/// Represents a single undo/redo state entry.
///
/// Contains both the text content and cursor selection position
/// for a specific point in the editing history.
class UndoEntry {
  /// Creates an undo entry with the given text and selection.
  UndoEntry(this.text, this.selection);

  /// The text content at this point in history.
  final String text;

  /// The cursor selection position at this point in history.
  final TextSelection selection;
}

/// Controller for managing text editor state and operations.
///
/// This controller handles all editor functionality including file operations,
/// undo/redo management, text editing, and automatic recovery features.
class EditorController extends ChangeNotifier {
  /// Creates an editor controller with the required services.
  EditorController({
    required this.fileService,
    required this.recentFiles,
    required this.recoveryService,
    required this.settings,
    required this.logger,
  }) {
    _controller.addListener(_onTextChanged);
    _recoveryTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _maybeSnapshot();
    });
  }

  /// Service for file operations (open, save, etc.).
  final FileService fileService;

  /// Service for managing recently opened files.
  final RecentFilesService recentFiles;

  /// Service for automatic recovery functionality.
  final RecoveryService recoveryService;

  /// Controller for accessing user settings and preferences.
  final SettingsController settings;

  /// Logger for error reporting and debugging.
  final Logger logger;

  final TextEditingController _controller = TextEditingController();

  /// The underlying text editing controller.
  ///
  /// Provides access to the text content and cursor position.
  TextEditingController get controller => _controller;

  /// The current file path, null for new/unsaved files.
  String? currentPath;

  /// The text encoding of the current file.
  String currentEncoding = 'utf-8';

  /// The line ending style of the current file.
  LineEndingStyle lineEnding = LineEndingStyle.lf;

  /// Whether the current content has unsaved changes.
  bool dirty = false;

  // Undo/Redo
  final List<UndoEntry> _undoStack = [];
  final List<UndoEntry> _redoStack = [];

  /// Gets the maximum undo depth from user settings.
  int get undoDepth => settings.undoDepth;

  Timer? _debounce;
  Timer? _recoveryTimer;

  void _onTextChanged() {
    dirty = true;
    _scheduleCoalescedPush();
    notifyListeners();
  }

  void _scheduleCoalescedPush() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _pushUndo);
  }

  void _pushInitial(UndoEntry entry) {
    _undoStack.clear();
    _redoStack.clear();
    _undoStack.add(entry);
  }

  void _pushUndo() {
    final entry = UndoEntry(_controller.text, _controller.selection);
    if (_undoStack.isEmpty || _undoStack.last.text != entry.text) {
      _undoStack.add(entry);
      if (_undoStack.length > undoDepth) {
        _undoStack.removeAt(0);
      }
      _redoStack.clear();
    }
  }

  /// Whether undo operation is available.
  /// Returns true if there are previous states to undo to.
  bool get canUndo => _undoStack.length > 1;

  /// Whether redo operation is available.
  /// Returns true if there are undone operations that can be redone.
  bool get canRedo => _redoStack.isNotEmpty;

  /// Undoes the last operation, restoring the previous text state.
  /// Only performs undo if [canUndo] is true.
  void undo() {
    if (!canUndo) return;
    final last = _undoStack.removeLast();
    _redoStack.add(last);
    final prev = _undoStack.last;
    _applyUndoEntry(prev);
  }

  /// Redoes the last undone operation, restoring the previously undone state.
  /// Only performs redo if [canRedo] is true.
  void redo() {
    if (!canRedo) return;
    final entry = _redoStack.removeLast();
    _undoStack.add(entry);
    _applyUndoEntry(entry);
  }

  void _applyUndoEntry(UndoEntry entry, {bool markDirty = true}) {
    _controller
      ..text = entry.text
      ..selection = entry.selection;
    if (markDirty) {
      dirty = true;
    }
    notifyListeners();
  }

  /// Creates a new file, clearing the current content and resetting state.
  /// Shows a confirmation dialog if there are unsaved changes.
  Future<void> newFile() async {
    if (!await _confirmDiscardIfNeeded()) return;
    currentPath = null;
    currentEncoding = settings.defaultEncoding;
    lineEnding = LineEndingStyle.lf;
    _controller.clear();
    dirty = false;
    _pushInitial(UndoEntry('', const TextSelection.collapsed(offset: 0)));
    await recoveryService.clear(fileService);
    notifyListeners();
  }

  Future<bool> _confirmDiscardIfNeeded() async {
    // UI-level confirmation handled externally; assume yes for core logic.
    return true;
  }

  /// Opens a file using the file picker dialog.
  /// Returns true if a file was successfully opened, false if cancelled or
  /// on error. Automatically detects encoding and line endings from the
  /// opened file.
  Future<bool> openFile() async {
    try {
      final res = await fileService.pickAndOpen(
        maxBytes: settings.maxFileSize,
      );
      if (res == null) return false;
      currentPath = res.path;
      currentEncoding = res.encoding;
      lineEnding = res.lineEndingStyle;
      _controller.text = res.content;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
      dirty = false;
      _pushInitial(UndoEntry(_controller.text, _controller.selection));
      await recentFiles.addOrUpdate(
        RecentFileEntry(
          path: res.path,
          lastOpened: DateTime.now(),
          fileSize: res.bytes.length,
          encoding: currentEncoding,
          lineEnding: lineEnding.name,
        ),
      );
      await recoveryService.clear(fileService);
      notifyListeners();
      return true;
    } on FileSystemException {
      // propagate UI message
      return false;
    } on Exception catch (e) {
      logger.e('Open failed: $e');
      return false;
    }
  }

  /// Saves the current content to the existing file path.
  /// Returns true if the save was successful, false otherwise.
  /// Updates the recent files list and clears the dirty flag on success.
  Future<bool> save() async {
    if (currentPath == null) {
      return saveAs();
    }
    try {
      await fileService.saveToPath(
        path: currentPath!,
        content: _controller.text,
        encoding: currentEncoding,
        lineEndingStyle: lineEnding,
      );

      // Get actual file size after saving
      final file = File(currentPath!);
      final actualFileSize = await file.length();

      dirty = false;
      _pushInitial(
        UndoEntry(_controller.text, _controller.selection),
      ); // reset baseline

      await recentFiles.addOrUpdate(
        RecentFileEntry(
          path: currentPath!,
          lastOpened: DateTime.now(),
          fileSize: actualFileSize, // Use actual file size from disk
          encoding: currentEncoding,
          lineEnding: lineEnding.name,
        ),
      );
      await recoveryService.clear(fileService);
      notifyListeners();
      return true;
    } on Exception catch (e) {
      logger.e('Save failed: $e');
      return false;
    }
  }

  /// Saves the current content to a new file using the file picker dialog.
  /// Returns true if the save was successful, false otherwise.
  /// Updates the current file path, recent files list, and clears the dirty
  /// flag on success.
  Future<bool> saveAs() async {
    try {
      final path = await fileService.saveNew(
        content: _controller.text,
        encoding: currentEncoding,
        lineEndingStyle: lineEnding,
      );
      if (path == null) return false;

      // Verify the file was actually created and get its actual size
      final file = File(path);
      if (!file.existsSync()) {
        logger.w('File was not created successfully: $path');
        return false;
      }

      final actualFileSize = await file.length();

      currentPath = path;
      dirty = false;
      _pushInitial(
        UndoEntry(_controller.text, _controller.selection),
      );

      // Only add to recent files if the file was actually saved successfully
      await recentFiles.addOrUpdate(
        RecentFileEntry(
          path: path,
          lastOpened: DateTime.now(),
          fileSize: actualFileSize, // Use actual file size from disk
          encoding: currentEncoding,
          lineEnding: lineEnding.name,
        ),
      );

      await recoveryService.clear(fileService);
      notifyListeners();
      return true;
    } on Exception catch (e) {
      logger.e('SaveAs failed: $e');
      return false;
    }
  }

  /// The number of words in the current text.
  /// Returns 0 for empty text, otherwise counts whitespace-separated words.
  int get wordCount {
    final text = _controller.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  /// The total number of characters in the current text.
  int get charCount => _controller.text.length;

  /// The total number of lines in the current text.
  /// Returns 1 for empty text, otherwise counts newline characters plus 1.
  int get lineCount => _controller.text.isEmpty
      ? 1
      : '\n'.allMatches(_controller.text).length + 1;

  /// Attempts to recover content from a previously saved recovery snapshot.
  /// Loads the most recent snapshot and restores the text content and
  /// file path.
  Future<void> attemptRecovery() async {
    final snap = await recoveryService.loadSnapshot(fileService);
    if (snap == null) return;
    // Simple heuristic: if snapshot is newer than nothing.
    _controller.text = snap.content;
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    currentPath = snap.path;
    currentEncoding = snap.encoding;
    lineEnding = snap.lineEnding;
    dirty = snap.dirty;
    _pushInitial(UndoEntry(_controller.text, _controller.selection));
    notifyListeners();
  }

  void _maybeSnapshot() {
    if (!dirty) return;
    final snap = RecoverySnapshot(
      content: _controller.text,
      path: currentPath,
      dirty: dirty,
      timestamp: DateTime.now(),
      encoding: currentEncoding,
      lineEnding: lineEnding,
    );
    recoveryService.saveSnapshot(fileService, snap);
  }

  /// Disposes of resources used by the controller.
  /// Cancels timers and disposes of the text controller.
  @override
  void dispose() {
    _debounce?.cancel();
    _recoveryTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }
}
