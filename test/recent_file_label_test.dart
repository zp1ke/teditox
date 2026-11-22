import 'package:flutter_test/flutter_test.dart';
import 'package:teditox/src/core/services/recent_files_service.dart';
import 'package:teditox/src/features/recent/presentation/recent_file_label.dart';

RecentFileEntry _entry(String path, {String? name}) => RecentFileEntry(
  path: path,
  lastOpened: DateTime(2025),
  fileSize: 1,
  encoding: 'utf-8',
  lineEnding: 'lf',
  displayName: name,
);

void main() {
  test('titles use the stored name, never a content URI', () {
    expect(
      recentFileTitle(_entry('content://documents/14', name: 'notes.txt')),
      'notes.txt',
    );
    expect(recentFileTitle(_entry('/tmp/docs/notes.txt')), 'notes.txt');
    expect(recentFileTitle(_entry('content://documents/14')), isEmpty);
  });

  test('folder is the parent directory, not the full path', () {
    expect(recentFileFolder(_entry('/tmp/docs/notes.txt')), 'docs');
    expect(recentFileFolder(_entry('content://documents/14')), isNull);
  });
}
