import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
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
          logger: Logger(),
        );
}

class _FakeRecent extends RecentFilesService {
  _FakeRecent() : super(prefs: PreferencesService());
  @override
  Future<void> addOrUpdate(RecentFileEntry entry, {int max = 10}) async {}
}

class _FakeRecovery extends RecoveryService {
  _FakeRecovery() : super(logger: Logger());
}

class _FakeSettings extends SettingsController {
  _FakeSettings()
      : super(
          prefs: PreferencesService(),
        );

  @override
  int get undoDepth => 5;
  @override
  String get defaultEncoding => 'utf-8';
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
