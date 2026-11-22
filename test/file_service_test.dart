import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:teditox/src/core/services/content_uri_service.dart';
import 'package:teditox/src/core/services/encoding_service.dart';
import 'package:teditox/src/core/services/file_service.dart';
import 'package:teditox/src/core/utils/line_endings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late FileService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('teditox_file_test');
    // These tests exercise expected failures. A default Logger prints them
    // as error boxes even when the test asserts the throw.
    final logger = Logger(level: Level.off);
    service = FileService(
      encodingService: EncodingService(),
      contentUriService: ContentUriService(logger: logger),
      logger: logger,
    );
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('displayNameForPath', () {
    test('uses the last path segment for a filesystem path', () {
      expect(displayNameForPath('/tmp/notes.txt'), 'notes.txt');
      expect(displayNameForPath('/tmp/dir/'), 'dir');
      expect(displayNameForPath('/'), isNull);
    });

    test('does not invent a name from a content URI', () {
      expect(
        displayNameForPath(
          'content://documents/document/primary%3ADownload%2Fnotes.txt',
        ),
        isNull,
      );
    });
  });

  group('openByPath', () {
    test(
      'reports the file name so the editor title is not "New File"',
      () async {
        final file = File('${tempDir.path}/notes.txt');
        await file.writeAsString('hello world');

        final result = await service.openByPath(path: file.path);

        expect(result, isNotNull);
        expect(result!.displayName, 'notes.txt');
        expect(result.path, file.path);
        expect(result.content, 'hello world');
        expect(result.isContentUri, isFalse);
      },
    );

    test('handles names with dots and no extension', () async {
      final dotted = File('${tempDir.path}/archive.tar.log');
      await dotted.writeAsString('x');
      expect(
        (await service.openByPath(path: dotted.path))!.displayName,
        'archive.tar.log',
      );

      final bare = File('${tempDir.path}/README');
      await bare.writeAsString('x');
      expect(
        (await service.openByPath(path: bare.path))!.displayName,
        'README',
      );
    });

    test('detects line endings of the opened content', () async {
      final file = File('${tempDir.path}/crlf.txt');
      await file.writeAsString('a\r\nb\r\nc');

      final result = await service.openByPath(path: file.path);

      expect(result!.lineEndingStyle, LineEndingStyle.crlf);
    });

    test('throws when the file does not exist', () async {
      expect(
        () => service.openByPath(path: '${tempDir.path}/nope.txt'),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('rejects files over the max size threshold', () async {
      final file = File('${tempDir.path}/big.txt');
      await file.writeAsString('x' * 2048);

      expect(
        () => service.openByPath(path: file.path, maxBytes: 1024),
        throwsA(isA<FileSystemException>()),
      );
    });
  });
}
