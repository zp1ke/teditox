import 'dart:io';

import 'package:teditox/src/core/services/file_service.dart';
import 'package:teditox/src/core/services/recent_files_service.dart';

/// Title for a recent-file row. Never a raw path or content URI.
String recentFileTitle(RecentFileEntry entry) {
  final stored = entry.displayName?.trim();
  if (stored != null && stored.isNotEmpty) return stored;
  return displayNameForPath(entry.path) ?? '';
}

/// Parent folder name for a filesystem path, or null for a content URI.
String? recentFileFolder(RecentFileEntry entry) {
  if (entry.path.startsWith('content://')) return null;
  final segments = File(
    entry.path,
  ).uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
  if (segments.length < 2) return null;
  return segments[segments.length - 2];
}
