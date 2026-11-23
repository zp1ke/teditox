import 'dart:async';

import 'package:logger/logger.dart';
import 'package:material_ui/material_ui.dart';
import 'package:teditox/src/core/localization/app_localizations.dart';
import 'package:teditox/src/core/services/file_service.dart';
import 'package:teditox/src/core/services/recent_files_service.dart';
import 'package:teditox/src/core/services/recovery_service.dart';
import 'package:teditox/src/core/utils/line_endings.dart';
import 'package:teditox/src/core/widgets/file_open_error_dialog.dart';
import 'package:teditox/src/core/widgets/unsaved_changes_dialog.dart';
import 'package:teditox/src/features/editor/presentation/text_delta.dart';
import 'package:teditox/src/features/editor/presentation/text_search.dart';
import 'package:teditox/src/features/settings/presentation/settings_controller.dart';

final _whitespace = RegExp(r'\s+');

bool _sameMatches(List<TextMatch> a, List<TextMatch> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].start != b[i].start || a[i].end != b[i].end) return false;
  }
  return true;
}

/// Non-blank trimmed name, or null.
String? _usableName(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

/// Represents a single undo/redo state entry.
///
/// Contains both the text content and cursor selection position
/// for a specific point in the editing history.
class UndoEntry {
  /// Creates a base entry holding the full [text].
  UndoEntry(this.text, this.selection) : delta = null;

  /// Creates an entry that transforms the previous text by [delta].
  UndoEntry.delta(this.delta, this.selection) : text = null;

  /// Full text, set only on the base entry and after the stack is folded.
  final String? text;

  /// Change from the previous entry. Null on the base entry.
  final TextDelta? delta;

  /// Cursor selection after this step.
  final TextSelection selection;

  /// Characters retained by this step.
  int get payloadBytes => text?.length ?? delta?.payloadBytes ?? 0;
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
    _markSeen(_controller.text);
    _undoTip = _controller.text;
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
  int _seenFingerprint = 0;
  String _undoTip = '';
  int _wordCount = 0;
  int _charCount = 0;
  int _lineCount = 1;
  bool _countsStale = true;
  int? _lastSnapshotFingerprint;

  /// The underlying text editing controller.
  ///
  /// Provides access to the text content and cursor position.
  TextEditingController get controller => _controller;

  /// The current file path (content URI or real path).
  String? currentPath;

  /// The display name of the current file.
  String? _displayName;

  /// The current file name (display name from content provider or filename).
  String? get currentFileName => _displayName;

  /// The text encoding of the current file.
  String currentEncoding = 'utf-8';

  /// The line ending style of the current file.
  LineEndingStyle lineEnding = .lf;

  /// Whether the current content has unsaved changes.
  bool dirty = false;

  var _externalOpen = false;

  /// Marks that an external app is opening a file, so session restore does
  /// not replace it.
  void claimExternalOpen() {
    _externalOpen = true;
  }

  /// Find matches to paint in the editor. Empty when find is closed.
  List<TextMatch> searchMatches = const [];

  /// Index into [searchMatches] of the current match, or -1.
  int searchActiveIndex = -1;

  /// Updates the painted find matches. No-ops when nothing changed.
  void setSearchHighlight(List<TextMatch> matches, int activeIndex) {
    if (activeIndex == searchActiveIndex &&
        _sameMatches(searchMatches, matches)) {
      return;
    }
    searchMatches = matches;
    searchActiveIndex = activeIndex;
    notifyListeners();
  }

  // Undo/Redo
  final List<UndoEntry> _undoStack = [];
  final List<UndoEntry> _redoStack = [];

  /// Gets the maximum undo depth from user settings.
  int get undoDepth => settings.undoDepth;

  Timer? _debounce;
  Timer? _countsTimer;
  Timer? _recoveryTimer;

  void _onTextChanged() {
    // Selection and focus also notify the controller. A fingerprint avoids
    // retaining a second copy of a large buffer just to detect a change.
    final text = _controller.text;
    final fingerprint = _fingerprint(text);
    if (fingerprint == _seenFingerprint) return;
    _seenFingerprint = fingerprint;
    _countsStale = true;
    _setDirty(true);
    _scheduleCoalescedPush();
    if (settings.showWordCount) _scheduleCounts();
    notifyListeners();
  }

  void _markSeen(String text) {
    _seenFingerprint = _fingerprint(text);
  }

  int _fingerprint(String text) {
    if (text.isEmpty) return 0;
    return Object.hash(
      text.length,
      text.hashCode,
      text.codeUnitAt(0),
      text.codeUnitAt(text.length ~/ 2),
      text.codeUnitAt(text.length - 1),
    );
  }

  void _setDirty(bool value) {
    dirty = value;
    if (value) {
      _recoveryTimer ??= Timer.periodic(const Duration(seconds: 10), (_) {
        _maybeSnapshot();
      });
    } else {
      _recoveryTimer?.cancel();
      _recoveryTimer = null;
      _lastSnapshotFingerprint = null;
    }
  }

  void _scheduleCoalescedPush() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _pushUndo);
  }

  void _pushInitial(UndoEntry entry) {
    _undoStack
      ..clear()
      ..add(entry);
    _redoStack.clear();
    _undoTip = entry.text ?? _controller.text;
  }

  void _pushUndo() {
    final current = _controller.text;
    if (current.length == _undoTip.length && current == _undoTip) return;
    _undoStack.add(
      UndoEntry.delta(diffText(_undoTip, current), _controller.selection),
    );
    _undoTip = current;
    _trimUndo();
    _redoStack.clear();
  }

  void _trimUndo() {
    while (_undoStack.length > undoDepth && _undoStack.length > 1) {
      final baseText = _undoStack.first.text;
      final next = _undoStack[1];
      final delta = next.delta;
      if (baseText == null || delta == null) {
        _undoStack.removeAt(0);
        continue;
      }
      _undoStack
        ..removeAt(0)
        ..removeAt(0)
        ..insert(0, UndoEntry(delta.apply(baseText), next.selection));
    }
  }

  /// Characters retained by the undo and redo stacks.
  ///
  /// Visible for tests. Large documents should stay near one buffer plus the
  /// changed spans, not one full copy per undo level.
  int get undoPayloadBytes {
    var total = 0;
    for (final entry in _undoStack) {
      total += entry.payloadBytes;
    }
    for (final entry in _redoStack) {
      total += entry.payloadBytes;
    }
    return total;
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
    final delta = last.delta;
    if (delta == null) return;
    _applyText(
      delta.invert().apply(_controller.text),
      _undoStack.last.selection,
    );
  }

  /// Redoes the last undone operation, restoring the previously undone state.
  /// Only performs redo if [canRedo] is true.
  void redo() {
    if (!canRedo) return;
    final entry = _redoStack.removeLast();
    final delta = entry.delta;
    if (delta == null) return;
    _undoStack.add(entry);
    _applyText(delta.apply(_controller.text), entry.selection);
  }

  void _applyText(String text, TextSelection selection) {
    final end = text.length;
    final clamped = TextSelection(
      baseOffset: selection.baseOffset.clamp(0, end),
      extentOffset: selection.extentOffset.clamp(0, end),
    );
    _markSeen(text);
    _undoTip = text;
    _controller.value = TextEditingValue(text: text, selection: clamped);
    _countsStale = true;
    _setDirty(true);
    if (settings.showWordCount) _scheduleCounts();
    notifyListeners();
  }

  /// Creates a new file, clearing the current content and resetting state.
  /// Shows a confirmation dialog if there are unsaved changes.
  Future<void> newFile(BuildContext context) async {
    if (!await _confirmDiscardIfNeeded(context)) return;
    currentPath = null;
    _displayName = null;
    currentEncoding = settings.defaultEncoding;
    lineEnding = .lf;
    _controller.clear();
    _markSeen('');
    _setDirty(false);
    _pushInitial(UndoEntry('', const TextSelection.collapsed(offset: 0)));
    await recoveryService.clear(fileService);
    notifyListeners();
  }

  Future<bool> _confirmDiscardIfNeeded(BuildContext context) async {
    if (!dirty) return true; // No unsaved changes, proceed

    // Show confirmation dialog for unsaved changes
    final action = await UnsavedChangesDialog.show(context);
    if (!context.mounted) return false;

    switch (action) {
      case .save:
        return await save(context);
      case .discard:
        return true;
      case .cancel:
      case null:
        return false;
    }
  }

  /// Opens a file using the file picker dialog.
  /// Shows a confirmation dialog if there are unsaved changes.
  /// Returns true if a file was successfully opened, false if cancelled or
  /// on error. Automatically detects encoding and line endings from the
  /// opened file.
  Future<bool> openFile(BuildContext context) async {
    // Check for unsaved changes before opening a new file
    if (!await _confirmDiscardIfNeeded(context)) return false;

    try {
      final res = await fileService.pickAndOpen(maxBytes: settings.maxFileSize);
      if (res == null) return false;
      currentPath = res.path;
      _displayName = res.displayName;
      // Track content URI status
      currentEncoding = res.encoding;
      lineEnding = res.lineEndingStyle;
      _markSeen(res.content);
      _controller.text = res.content;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
      _setDirty(false);
      _pushInitial(UndoEntry(_controller.text, _controller.selection));
      _countsStale = true;
      if (settings.showWordCount) _scheduleCounts();

      // Add to recent files with display name
      await recentFiles.addOrUpdate(
        RecentFileEntry(
          path: res.path,
          lastOpened: DateTime.now(),
          fileSize: res.bytes.length,
          encoding: currentEncoding,
          lineEnding: lineEnding.name,
          displayName: _displayName,
        ),
      );

      await recoveryService.clear(fileService);
      notifyListeners();
      return true;
    } on FileOpenException catch (e) {
      if (context.mounted) await _reportOpenFailure(context, e);
      return false;
    } on Exception catch (e) {
      logger.e('Open failed: $e');
      return false;
    }
  }

  /// Opens a file by its path directly.
  /// Shows a confirmation dialog if there are unsaved changes.
  /// Returns true if a file was successfully opened, false if cancelled or
  /// on error. Automatically detects encoding and line endings from the
  /// opened file.
  ///
  /// Set [skipConfirmation] to true to bypass the unsaved changes check.
  /// This is useful when opening files from external intents at app startup.
  ///
  /// [displayNameHint] is preferred over the name reported by the file when it
  /// is non-blank. The recent-files list passes the name the user already saw,
  /// which is more reliable than a later content-resolver query (that query can
  /// return a document id or an empty string).
  Future<bool> openFileByPath(
    BuildContext context,
    String path, {
    bool skipConfirmation = false,
    String? displayNameHint,
  }) async {
    // Check for unsaved changes before opening a new file
    if (!skipConfirmation && !await _confirmDiscardIfNeeded(context)) {
      return false;
    }

    try {
      final res = await fileService.openByPath(
        path: path,
        maxBytes: settings.maxFileSize,
      );
      if (res == null) return false;

      currentPath = res.path;
      _displayName =
          _usableName(displayNameHint) ?? _usableName(res.displayName);
      // Track content URI status
      currentEncoding = res.encoding;
      lineEnding = res.lineEndingStyle;
      _markSeen(res.content);
      _controller.text = res.content;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
      _setDirty(false);
      _pushInitial(UndoEntry(_controller.text, _controller.selection));
      _countsStale = true;
      if (settings.showWordCount) _scheduleCounts();

      // Add to recent files with display name
      await recentFiles.addOrUpdate(
        RecentFileEntry(
          path: res.path,
          lastOpened: DateTime.now(),
          fileSize: res.bytes.length,
          encoding: currentEncoding,
          lineEnding: lineEnding.name,
          displayName: _displayName,
        ),
      );

      await recoveryService.clear(fileService);
      notifyListeners();
      return true;
    } on FileOpenException catch (e) {
      if (e.failure == FileOpenFailure.notFound ||
          e.failure == FileOpenFailure.unreadable) {
        await recentFiles.remove(path);
      }
      if (context.mounted) await _reportOpenFailure(context, e);
      return false;
    } on Exception catch (e) {
      logger.e('Open by path failed: $e');
      return false;
    }
  }

  /// Reloads [currentPath] with [encoding].
  ///
  /// No-op when no file is open. Keeps the manual-save model: the reopened
  /// buffer is clean.
  Future<bool> reopenWithEncoding(BuildContext context, String encoding) async {
    final path = currentPath;
    if (path == null) return false;
    try {
      final res = await fileService.openByPath(
        path: path,
        forcedEncoding: encoding,
        maxBytes: settings.maxFileSize,
      );
      if (res == null) return false;
      await _acceptOpened(res, displayNameHint: _displayName);
      return true;
    } on FileOpenException catch (e) {
      if (context.mounted) await _reportOpenFailure(context, e);
      return false;
    } on Exception catch (e) {
      logger.e('Reopen with encoding failed: $e');
      return false;
    }
  }

  Future<void> _reportOpenFailure(
    BuildContext context,
    FileOpenException error,
  ) async {
    logger.w('Open failed: $error');
    if (!context.mounted) return;
    await showFileOpenError(context, error);
  }

  /// Saves the current content to the existing file path.
  /// Returns true if the save was successful, false otherwise.
  /// Updates the recent files list and clears the dirty flag on success.
  ///
  /// For files opened from content:// URIs, we can now save directly to them
  /// since we have persistable permissions.
  Future<bool> save(BuildContext context) async {
    // If no current path, use "Save As"
    if (currentPath == null) {
      return await saveAs(context);
    }

    try {
      await fileService.saveToPath(
        path: currentPath!,
        content: _controller.text,
        encoding: currentEncoding,
        lineEndingStyle: lineEnding,
      );

      _setDirty(false);
      _pushInitial(
        UndoEntry(_controller.text, _controller.selection),
      ); // reset baseline

      // For content URIs, we can't get file size easily, estimate it
      final fileSize = _controller.text.length;

      // Only add to recent files if we have a display name
      if (_displayName != null) {
        await recentFiles.addOrUpdate(
          RecentFileEntry(
            path: currentPath!,
            lastOpened: DateTime.now(),
            fileSize: fileSize,
            encoding: currentEncoding,
            lineEnding: lineEnding.name,
            displayName: _displayName,
          ),
        );
      }

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
  Future<bool> saveAs(BuildContext context) async {
    try {
      final result = await fileService.saveNew(
        initialName: AppLocalizations.of(context).new_file_name,
        content: _controller.text,
        encoding: currentEncoding,
        lineEndingStyle: lineEnding,
      );
      if (result == null) return false;

      // The file has been saved
      // Update our state to reflect the save
      currentPath = result.path;
      _displayName = result.displayName;
      _setDirty(false);
      _pushInitial(UndoEntry(_controller.text, _controller.selection));

      // Add to recent files with display name
      // Estimate file size from content length
      final fileSize = _controller.text.length;

      await recentFiles.addOrUpdate(
        RecentFileEntry(
          path: result.path,
          lastOpened: DateTime.now(),
          fileSize: fileSize,
          encoding: currentEncoding,
          lineEnding: lineEnding.name,
          displayName: _displayName,
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
  ///
  /// Cached and refreshed about 250 ms after the text changes, and only while
  /// the word-count setting is on.
  int get wordCount {
    _scheduleCountsIfNeeded();
    return _wordCount;
  }

  /// The total number of characters in the current text.
  int get charCount {
    _scheduleCountsIfNeeded();
    return _charCount;
  }

  /// The total number of lines in the current text.
  ///
  /// Empty text counts as one line.
  int get lineCount {
    _scheduleCountsIfNeeded();
    return _lineCount;
  }

  void _scheduleCountsIfNeeded() {
    if (!settings.showWordCount || !_countsStale || _countsTimer != null) {
      return;
    }
    _scheduleCounts();
  }

  void _scheduleCounts() {
    _countsTimer?.cancel();
    _countsTimer = Timer(const Duration(milliseconds: 250), _recomputeCounts);
  }

  void _recomputeCounts() {
    _countsTimer = null;
    final text = _controller.text;
    final trimmed = text.trim();
    final words = trimmed.isEmpty ? 0 : trimmed.split(_whitespace).length;
    final chars = text.length;
    final lines = text.isEmpty ? 1 : '\n'.allMatches(text).length + 1;
    _countsStale = false;
    if (words == _wordCount && chars == _charCount && lines == _lineCount) {
      return;
    }
    _wordCount = words;
    _charCount = chars;
    _lineCount = lines;
    notifyListeners();
  }

  /// Restores a crash snapshot, or the last file when that setting is on.
  Future<void> restoreSession() async {
    if (_externalOpen) return;
    if (await attemptRecovery()) return;
    if (_externalOpen || !settings.restoreLastFile) return;
    final recent = recentFiles.getAll();
    if (recent.isEmpty || _externalOpen) return;
    final entry = recent.first;
    try {
      final res = await fileService.openByPath(
        path: entry.path,
        forcedEncoding: entry.encoding,
        maxBytes: settings.maxFileSize,
      );
      if (res == null || _externalOpen) return;
      await _acceptOpened(res, displayNameHint: entry.displayName);
    } on FileOpenException catch (e) {
      if (e.failure == FileOpenFailure.notFound) {
        await recentFiles.remove(entry.path);
      }
      logger.w('Could not restore last file: $e');
    }
  }

  /// Attempts to recover content from a previously saved recovery snapshot.
  ///
  /// Returns true when a snapshot was applied.
  Future<bool> attemptRecovery() async {
    if (_externalOpen) return false;
    final snap = await recoveryService.loadSnapshot(fileService);
    if (snap == null || _externalOpen) return false;
    // Simple heuristic: if snapshot is newer than nothing.
    _markSeen(snap.content);
    _controller.text = snap.content;
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    currentPath = snap.path;
    _displayName = snap.path == null ? null : displayNameForPath(snap.path!);
    currentEncoding = snap.encoding;
    lineEnding = snap.lineEnding;
    _setDirty(snap.dirty);
    _pushInitial(UndoEntry(_controller.text, _controller.selection));
    _countsStale = true;
    notifyListeners();
    return true;
  }

  Future<void> _acceptOpened(
    FileOpenResult res, {
    String? displayNameHint,
  }) async {
    currentPath = res.path;
    _displayName = _usableName(displayNameHint) ?? _usableName(res.displayName);
    currentEncoding = res.encoding;
    lineEnding = res.lineEndingStyle;
    _markSeen(res.content);
    _controller.text = res.content;
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    _setDirty(false);
    _pushInitial(UndoEntry(_controller.text, _controller.selection));
    _countsStale = true;
    if (settings.showWordCount) _scheduleCounts();
    await recentFiles.addOrUpdate(
      RecentFileEntry(
        path: res.path,
        lastOpened: DateTime.now(),
        fileSize: res.bytes.length,
        encoding: currentEncoding,
        lineEnding: lineEnding.name,
        displayName: _displayName,
      ),
    );
    await recoveryService.clear(fileService);
    notifyListeners();
  }

  void _maybeSnapshot() {
    if (!dirty) return;
    final text = _controller.text;
    final fingerprint = Object.hash(
      text.length,
      text.hashCode,
      currentPath,
      currentEncoding,
      lineEnding.name,
    );
    if (fingerprint == _lastSnapshotFingerprint) return;
    _lastSnapshotFingerprint = fingerprint;
    final snap = RecoverySnapshot(
      content: text,
      path: currentPath,
      dirty: dirty,
      timestamp: DateTime.now(),
      encoding: currentEncoding,
      lineEnding: lineEnding,
    );
    unawaited(recoveryService.saveSnapshot(fileService, snap));
  }

  /// Selects [start] inclusive to [end] exclusive in the buffer.
  void selectRange(int start, int end) {
    final length = _controller.text.length;
    final clampedStart = start.clamp(0, length);
    final clampedEnd = end.clamp(0, length);
    _controller.selection = TextSelection(
      baseOffset: clampedStart,
      extentOffset: clampedEnd,
    );
  }

  /// Replaces one span and records a single undo step.
  void replaceRange(int start, int end, String replacement) {
    final next = _controller.text.replaceRange(start, end, replacement);
    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: start + replacement.length),
    );
    commitEdit();
  }

  /// Replaces every [matches] span and records a single undo step.
  void replaceAll(List<TextMatch> matches, String replacement) {
    if (matches.isEmpty) return;
    _controller.text = replaceAllMatches(
      _controller.text,
      matches,
      replacement,
    );
    commitEdit();
  }

  /// Changes how the next save encodes the buffer.
  ///
  /// The in-memory text stays as-is. Line endings and charset are applied
  /// on save.
  void setSaveFormat({LineEndingStyle? endings, String? encoding}) {
    if (endings != null) lineEnding = endings;
    if (encoding != null) currentEncoding = encoding;
    notifyListeners();
  }

  /// Flushes the coalesced undo timer so the latest edit is one undo step.
  void commitEdit() {
    _debounce?.cancel();
    _pushUndo();
  }

  /// Disposes of resources used by the controller.
  /// Cancels timers and disposes of the text controller.
  @override
  void dispose() {
    _debounce?.cancel();
    _countsTimer?.cancel();
    _recoveryTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }
}
