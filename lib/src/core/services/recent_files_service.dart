import 'dart:convert';

import 'package:teditox/src/core/services/preferences_service.dart';

/// Represents a single entry in the recent files list.
class RecentFileEntry {
  /// Creates a new recent file entry.
  RecentFileEntry({
    required this.path,
    required this.lastOpened,
    required this.fileSize,
    required this.encoding,
    required this.lineEnding,
  });

  /// Creates a new recent file entry from a JSON map.
  factory RecentFileEntry.fromJson(Map<String, dynamic> json) =>
      RecentFileEntry(
        path: json['p'] as String,
        lastOpened: DateTime.parse(json['o'] as String),
        fileSize: json['s'] as int,
        encoding: json['e'] as String,
        lineEnding: json['l'] as String,
      );

  /// The file path of the recent file.
  final String path;

  /// The last opened timestamp of the recent file.
  final DateTime lastOpened;

  /// The file size of the recent file.
  final int fileSize;

  /// The encoding of the recent file.
  final String encoding;

  /// The line ending style of the recent file.
  final String lineEnding;

  /// Converts the recent file entry to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'p': path,
    'o': lastOpened.toIso8601String(),
    's': fileSize,
    'e': encoding,
    'l': lineEnding,
  };
}

/// Service for managing recent files.
class RecentFilesService {
  /// Creates a new instance of [RecentFilesService].
  RecentFilesService({required this.prefs});

  /// The preferences service used by this service.
  final PreferencesService prefs;

  static const _maxDefault = 10;

  /// Retrieves all recent file entries.
  List<RecentFileEntry> getAll() {
    final list = prefs.recentFiles;
    return list
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .map(RecentFileEntry.fromJson)
        .toList()
      ..sort((a, b) => b.lastOpened.compareTo(a.lastOpened));
  }

  /// Adds a new recent file entry or updates an existing one.
  Future<void> addOrUpdate(
    RecentFileEntry entry, {
    int max = _maxDefault,
  }) async {
    final all = getAll();
    final filtered = all.where((e) => e.path != entry.path).toList()
      ..insert(0, entry);
    if (filtered.length > max) filtered.removeRange(max, filtered.length);
    final store = filtered
        .map((e) => jsonEncode(e.toJson()))
        .toList(growable: false);
    await prefs.setRecentFiles(store);
  }

  /// Removes a recent file entry.
  Future<void> remove(String path) async {
    final updated = getAll()
        .where((element) => element.path != path)
        .map((e) => e.toJson());
    await prefs.setRecentFiles(
      updated.map(jsonEncode).toList(growable: false),
    );
  }

  /// Clears all recent file entries.
  Future<void> clearAll() async {
    await prefs.setRecentFiles([]);
  }

  /// Prunes invalid recent file entries.
  Future<void> pruneInvalid() async {
    // Deferred: implement existence check; placeholder.
  }
}
