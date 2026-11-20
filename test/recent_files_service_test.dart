import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teditox/src/core/services/preferences_service.dart';
import 'package:teditox/src/core/services/recent_files_service.dart';

RecentFileEntry _entry(String path, {DateTime? at, String? name}) =>
    RecentFileEntry(
      path: path,
      lastOpened: at ?? DateTime(2025),
      fileSize: 42,
      encoding: 'utf-8',
      lineEnding: 'lf',
      displayName: name,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('RecentFileEntry', () {
    test('toJson/fromJson round-trips', () {
      final entry = _entry(
        '/a.txt',
        at: DateTime(2025, 1, 2, 3, 4),
        name: 'a.txt',
      );
      final restored = RecentFileEntry.fromJson(entry.toJson());
      expect(restored.path, '/a.txt');
      expect(restored.lastOpened, entry.lastOpened);
      expect(restored.fileSize, 42);
      expect(restored.encoding, 'utf-8');
      expect(restored.lineEnding, 'lf');
      expect(restored.displayName, 'a.txt');
    });

    test('omits null displayName from JSON', () {
      final json = _entry('/a.txt').toJson();
      expect(json.containsKey('d'), isFalse);
      expect(RecentFileEntry.fromJson(json).displayName, isNull);
    });
  });

  group('RecentFilesService', () {
    late PreferencesService prefs;
    late RecentFilesService service;

    setUp(() async {
      prefs = PreferencesService();
      await prefs.init();
      service = RecentFilesService(prefs: prefs);
    });

    test('starts empty', () {
      expect(service.getAll(), isEmpty);
    });

    test('addOrUpdate inserts newest first', () async {
      await service.addOrUpdate(_entry('/old', at: DateTime(2025)));
      await service.addOrUpdate(_entry('/new', at: DateTime(2025, 3)));
      expect(service.getAll().map((e) => e.path), ['/new', '/old']);
    });

    test('re-adding the same path does not duplicate', () async {
      await service.addOrUpdate(_entry('/a', at: DateTime(2025)));
      await service.addOrUpdate(_entry('/b', at: DateTime(2025, 2)));
      await service.addOrUpdate(_entry('/a', at: DateTime(2025, 3)));
      final paths = service.getAll().map((e) => e.path).toList();
      expect(paths, ['/a', '/b']);
      expect(paths.where((p) => p == '/a').length, 1);
    });

    test('trims to the max length', () async {
      for (var i = 0; i < 5; i++) {
        await service.addOrUpdate(
          _entry('/f$i', at: DateTime(2025, 1, i + 1)),
          max: 2,
        );
      }
      expect(service.getAll(), hasLength(2));
      expect(service.getAll().map((e) => e.path), ['/f4', '/f3']);
    });

    test('remove deletes only the matching entry', () async {
      await service.addOrUpdate(_entry('/a'));
      await service.addOrUpdate(_entry('/b'));
      await service.remove('/a');
      expect(service.getAll().map((e) => e.path), ['/b']);
    });

    test('clearAll empties the list', () async {
      await service.addOrUpdate(_entry('/a'));
      await service.clearAll();
      expect(service.getAll(), isEmpty);
    });

    test('getAll sorts by lastOpened descending', () async {
      await service.addOrUpdate(_entry('/mid', at: DateTime(2025, 2)));
      await service.addOrUpdate(_entry('/old', at: DateTime(2025)));
      await service.addOrUpdate(_entry('/new', at: DateTime(2025, 3)));
      expect(service.getAll().map((e) => e.path), ['/new', '/mid', '/old']);
    });
  });

  group('PreferencesService defaults and persistence', () {
    test('defaults are sane', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = PreferencesService();
      await prefs.init();
      expect(prefs.themeMode, 'system');
      expect(prefs.locale, 'system');
      expect(prefs.editorFontSize, 14);
      expect(prefs.showLineNumbers, isTrue);
      expect(prefs.wrapLines, isTrue);
      expect(prefs.showWordCount, isFalse);
      expect(prefs.undoDepth, 5);
      expect(prefs.maxFileSize, 1024 * 1024);
      expect(prefs.defaultEncoding, 'utf-8');
      expect(prefs.recentFiles, isEmpty);
    });

    test('setters persist values', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = PreferencesService();
      await prefs.init();

      await prefs.setThemeMode('dark');
      await prefs.setLocale('es');
      await prefs.setEditorFontSize(18.5);
      await prefs.setShowLineNumbers(value: false);
      await prefs.setWrapLines(value: false);
      await prefs.setShowWordCount(value: true);
      await prefs.setUndoDepth(value: 20);
      await prefs.setMaxFileSize(value: 256);
      await prefs.setDefaultEncoding(encoding: 'utf-16le');

      expect(prefs.themeMode, 'dark');
      expect(prefs.locale, 'es');
      expect(prefs.editorFontSize, 18.5);
      expect(prefs.showLineNumbers, isFalse);
      expect(prefs.wrapLines, isFalse);
      expect(prefs.showWordCount, isTrue);
      expect(prefs.undoDepth, 20);
      expect(prefs.maxFileSize, 256);
      expect(prefs.defaultEncoding, 'utf-16le');
    });
  });
}
