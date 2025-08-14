import 'package:flutter/material.dart';

import 'package:teditox/src/core/di/service_locator.dart';
import 'package:teditox/src/core/localization/app_localizations.dart';
import 'package:teditox/src/core/services/recent_files_service.dart';
import 'package:teditox/src/core/utils/byte_size_formatter.dart';

/// Screen that displays recently opened files.
///
/// Shows a list of recently opened files with options to reopen them
/// or remove them from the recent files list.
class RecentScreen extends StatefulWidget {
  /// Creates a recent files screen.
  const RecentScreen({super.key});

  @override
  State<RecentScreen> createState() => _RecentScreenState();
}

class _RecentScreenState extends State<RecentScreen> {
  late final RecentFilesService recentService;
  late List<RecentFileEntry> entries;

  @override
  void initState() {
    super.initState();
    recentService = sl<RecentFilesService>();
    entries = recentService.getAll();
  }

  Future<void> _remove(String path) async {
    await recentService.remove(path);
    setState(() {
      entries = recentService.getAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.recent_files)),
      body: ListView.builder(
        itemCount: entries.length,
        itemBuilder: (context, i) {
          final e = entries[i];
          return Dismissible(
            key: ValueKey(e.path),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => _remove(e.path),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: ListTile(
              title: Text(e.path.split('/').last),
              subtitle: Text(e.path),
              trailing: Text(formatBytes(e.fileSize)),
              onTap: () {
                // TODO(dev): Implement direct file opening with controller.
              },
            ),
          );
        },
      ),
    );
  }
}
