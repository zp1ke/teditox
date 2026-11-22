import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:teditox/src/core/services/content_uri_service.dart';
import 'package:teditox/src/core/services/encoding_service.dart';
import 'package:teditox/src/core/services/file_service.dart';
import 'package:teditox/src/core/services/recovery_service.dart';
import 'package:teditox/src/core/utils/line_endings.dart';

class _CacheFileService extends FileService {
  _CacheFileService(this.cache)
    : super(
        encodingService: EncodingService(),
        contentUriService: ContentUriService(logger: Logger(level: Level.off)),
        logger: Logger(level: Level.off),
      );

  final Directory cache;

  @override
  Future<Directory> getCacheDir() async => cache;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'saveSnapshot replaces the file atomically and stays readable',
    () async {
      final dir = await Directory.systemTemp.createTemp('teditox_recovery');
      addTearDown(() => dir.delete(recursive: true));
      final service = RecoveryService(logger: Logger(level: Level.off));
      final files = _CacheFileService(dir);

      Future<RecoverySnapshot> snap(String content) => Future.value(
        RecoverySnapshot(
          content: content,
          path: '/tmp/notes.txt',
          dirty: true,
          timestamp: DateTime(2025),
          encoding: 'utf-8',
          lineEnding: LineEndingStyle.lf,
        ),
      );

      await service.saveSnapshot(files, await snap('first'));
      await service.saveSnapshot(files, await snap('second'));

      final loaded = await service.loadSnapshot(files);
      expect(loaded?.content, 'second');
      expect(
        File('${dir.path}/teditox_recovery.json.tmp').existsSync(),
        isFalse,
      );
    },
  );
}
