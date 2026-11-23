import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teditox/src/core/services/content_uri_service.dart';
import 'package:teditox/src/core/services/encoding_service.dart';
import 'package:teditox/src/core/services/file_service.dart';
import 'package:teditox/src/core/services/preferences_service.dart';
import 'package:teditox/src/core/services/recent_files_service.dart';
import 'package:teditox/src/core/services/recovery_service.dart';
import 'package:teditox/src/core/utils/line_endings.dart';
import 'package:teditox/src/features/editor/presentation/editor_controller.dart';
import 'package:teditox/src/features/settings/presentation/settings_controller.dart';

class _FakeFileService extends FileService {
  _FakeFileService()
    : super(
        encodingService: EncodingService(),
        contentUriService: ContentUriService(logger: Logger()),
        logger: Logger(),
      );

  // path_provider has no implementation under `flutter test`; avoid touching
  // it.
  @override
  Future<Directory> getCacheDir() =>
      Directory.systemTemp.createTemp('teditox_fake_cache');
}

class _FakeRecent extends RecentFilesService {
  _FakeRecent() : super(prefs: PreferencesService());
  @override
  Future<void> addOrUpdate(RecentFileEntry entry, {int max = 10}) async {}
}

class _FakeRecovery extends RecoveryService {
  _FakeRecovery([this.snapshot]) : super(logger: Logger());

  final RecoverySnapshot? snapshot;

  @override
  Future<void> clear(FileService fileService) async {}

  @override
  Future<RecoverySnapshot?> loadSnapshot(FileService fileService) async =>
      snapshot;
}

class _FakeNamedFileService extends _FakeFileService {
  _FakeNamedFileService(this.name);

  final String name;

  @override
  Future<FileOpenResult?> openByPath({
    required String path,
    String? forcedEncoding,
    int? maxBytes,
  }) async => FileOpenResult(
    content: 'from content uri',
    path: path,
    encoding: 'utf-8',
    lineEndingStyle: LineEndingStyle.lf,
    bytes: const [1, 2, 3],
    isContentUri: true,
    contentUri: path,
    displayName: name,
  );
}

class _FakeSettings extends SettingsController {
  _FakeSettings() : super(prefs: PreferencesService());

  @override
  int get undoDepth => 5;
  @override
  int get maxFileSize => 1 << 20; // 1 MiB
  @override
  String get defaultEncoding => 'utf-8';
  @override
  bool get showWordCount => false;
}

class _CountingSettings extends _FakeSettings {
  @override
  bool get showWordCount => true;
}

class _RestoringSettings extends _FakeSettings {
  @override
  bool get restoreLastFile => true;
}

/// File service whose backend reports no display name (e.g. a content:// URI
/// whose metadata query failed).
class _FakeNamelessFileService extends _FakeFileService {
  @override
  Future<FileOpenResult?> openByPath({
    required String path,
    String? forcedEncoding,
    int? maxBytes,
  }) async => FileOpenResult(
    content: 'from content uri',
    path: path,
    encoding: 'utf-8',
    lineEndingStyle: LineEndingStyle.lf,
    bytes: const [1, 2, 3],
    isContentUri: true,
    contentUri: path,
  );
}

/// Context stub for cases where [EditorController.openFileByPath] runs with
/// `skipConfirmation: true` and therefore never touches the context. Using a
/// plain `test` (not `testWidgets`) avoids the controller's periodic recovery
/// timer keeping the widget-test harness alive.
class _StubBuildContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Undo/redo ring buffer basic behavior', () {
    final controller = EditorController(
      fileService: _FakeFileService(),
      recentFiles: _FakeRecent(),
      recoveryService: _FakeRecovery(),
      settings: _FakeSettings(),
      logger: Logger(),
    );

    controller.controller.text = 'a';
    controller.controller.text = 'ab';
    controller.controller.text = 'abc';
    controller
      ..undo()
      ..undo();
    expect(controller.controller.text.length <= 3, true);
  });

  test(
    'opening a recent file sets the editor title to its file name',
    () async {
      final dir = await Directory.systemTemp.createTemp('teditox_ctrl_test');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/shopping-list.txt');
      await file.writeAsString('milk\neggs');

      final controller = EditorController(
        fileService: _FakeFileService(),
        recentFiles: _FakeRecent(),
        recoveryService: _FakeRecovery(),
        settings: _FakeSettings(),
        logger: Logger(),
      );

      addTearDown(controller.dispose);

      // Title starts as the unnamed-buffer state.
      expect(controller.currentFileName, isNull);

      final context = _StubBuildContext();

      final opened = await controller.openFileByPath(
        context,
        file.path,
        skipConfirmation: true,
      );

      expect(opened, isTrue);
      expect(controller.currentFileName, 'shopping-list.txt');
      expect(controller.controller.text, 'milk\neggs');
      expect(controller.dirty, isFalse);
    },
  );

  test('displayNameHint wins when the file reports no name', () async {
    final controller = EditorController(
      fileService: _FakeNamelessFileService(),
      recentFiles: _FakeRecent(),
      recoveryService: _FakeRecovery(),
      settings: _FakeSettings(),
      logger: Logger(),
    );

    addTearDown(controller.dispose);
    final context = _StubBuildContext();

    final opened = await controller.openFileByPath(
      context,
      'content://documents/14',
      skipConfirmation: true,
      displayNameHint: 'notes.txt',
    );

    expect(opened, isTrue);
    expect(controller.currentFileName, 'notes.txt');
  });

  test('displayNameHint wins over a document id from the resolver', () async {
    final controller = EditorController(
      fileService: _FakeNamedFileService('14'),
      recentFiles: _FakeRecent(),
      recoveryService: _FakeRecovery(),
      settings: _FakeSettings(),
      logger: Logger(),
    );
    addTearDown(controller.dispose);

    final opened = await controller.openFileByPath(
      _StubBuildContext(),
      'content://documents/14',
      skipConfirmation: true,
      displayNameHint: 'notes.txt',
    );

    expect(opened, isTrue);
    expect(controller.currentFileName, 'notes.txt');
  });

  test('blank names stay unnamed instead of a blank title', () async {
    final controller = EditorController(
      fileService: _FakeNamedFileService('   '),
      recentFiles: _FakeRecent(),
      recoveryService: _FakeRecovery(),
      settings: _FakeSettings(),
      logger: Logger(),
    );
    addTearDown(controller.dispose);

    final opened = await controller.openFileByPath(
      _StubBuildContext(),
      'content://documents/14',
      skipConfirmation: true,
      displayNameHint: '  ',
    );

    expect(opened, isTrue);
    expect(controller.currentFileName, isNull);
  });

  test(
    'crash recovery does not title a content URI with its document id',
    () async {
      final controller = EditorController(
        fileService: _FakeFileService(),
        recentFiles: _FakeRecent(),
        recoveryService: _FakeRecovery(
          RecoverySnapshot(
            content: 'recovered',
            path: 'content://documents/14',
            dirty: true,
            timestamp: DateTime(2025),
            encoding: 'utf-8',
            lineEnding: LineEndingStyle.lf,
          ),
        ),
        settings: _FakeSettings(),
        logger: Logger(),
      );
      addTearDown(controller.dispose);

      await controller.attemptRecovery();

      expect(controller.controller.text, 'recovered');
      expect(controller.currentFileName, isNull);
    },
  );

  test('undo and redo restore text without copying a large buffer', () async {
    final controller = EditorController(
      fileService: _FakeFileService(),
      recentFiles: _FakeRecent(),
      recoveryService: _FakeRecovery(),
      settings: _FakeSettings(),
      logger: Logger(),
    );
    addTearDown(controller.dispose);
    final base = 'a' * 200000;
    controller.controller.text = base;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    controller.controller.text = '$base!';
    await Future<void>.delayed(const Duration(milliseconds: 500));

    // One base buffer plus the changed span, not a copy per undo level.
    expect(controller.undoPayloadBytes, lessThan(base.length * 2));
    controller.undo();
    expect(controller.controller.text, base);
    controller.redo();
    expect(controller.controller.text, '$base!');
  });

  test('word count is cached and not recomputed during build', () async {
    final controller = EditorController(
      fileService: _FakeFileService(),
      recentFiles: _FakeRecent(),
      recoveryService: _FakeRecovery(),
      settings: _CountingSettings(),
      logger: Logger(),
    );
    addTearDown(controller.dispose);
    controller.controller.text = 'one two three';
    expect(controller.wordCount, 0);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(controller.wordCount, 3);
    expect(controller.charCount, 'one two three'.length);
    expect(controller.lineCount, 1);
  });

  test('restoreSession reopens the most recent file', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = PreferencesService();
    await prefs.init();
    final recent = RecentFilesService(prefs: prefs);
    final dir = await Directory.systemTemp.createTemp('teditox_restore');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/notes.txt');
    await file.writeAsString('restored text');
    await recent.addOrUpdate(
      RecentFileEntry(
        path: file.path,
        lastOpened: DateTime(2025),
        fileSize: 13,
        encoding: 'utf-8',
        lineEnding: 'lf',
        displayName: 'notes.txt',
      ),
    );

    final controller = EditorController(
      fileService: _FakeFileService(),
      recentFiles: recent,
      recoveryService: _FakeRecovery(),
      settings: _RestoringSettings(),
      logger: Logger(),
    );
    addTearDown(controller.dispose);

    await controller.restoreSession();

    expect(controller.controller.text, 'restored text');
    expect(controller.currentFileName, 'notes.txt');
    expect(controller.currentEncoding, 'utf-8');
  });

  test(
    'restoreSession does not replace a file opened from another app',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = PreferencesService();
      await prefs.init();
      final recent = RecentFilesService(prefs: prefs);
      final dir = await Directory.systemTemp.createTemp(
        'teditox_restore_intent',
      );
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/notes.txt');
      await file.writeAsString('restored text');
      await recent.addOrUpdate(
        RecentFileEntry(
          path: file.path,
          lastOpened: DateTime(2025),
          fileSize: 13,
          encoding: 'utf-8',
          lineEnding: 'lf',
          displayName: 'notes.txt',
        ),
      );

      final controller = EditorController(
        fileService: _FakeFileService(),
        recentFiles: recent,
        recoveryService: _FakeRecovery(),
        settings: _RestoringSettings(),
        logger: Logger(),
      );
      addTearDown(controller.dispose);
      controller.claimExternalOpen();
      controller.controller.text = 'from the file manager';

      await controller.restoreSession();

      expect(controller.controller.text, 'from the file manager');
    },
  );

  test('Line ending default', () {
    final controller = EditorController(
      fileService: _FakeFileService(),
      recentFiles: _FakeRecent(),
      recoveryService: _FakeRecovery(),
      settings: _FakeSettings(),
      logger: Logger(),
    );
    expect(controller.lineEnding, LineEndingStyle.lf);
  });
}
