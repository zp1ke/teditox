import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  Future<void> _clearAll() async {
    final loc = AppLocalizations.of(context);
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.clear_recent_files),
        content: Text(loc.clear_recent_files_confirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(loc.clear),
          ),
        ],
      ),
    );

    if (shouldClear ?? false) {
      await recentService.clearAll();
      setState(() {
        entries = recentService.getAll();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.recent_files),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/');
            }
          },
        ),
        actions: [
          if (entries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: loc.clear_recent_files,
              onPressed: _clearAll,
            ),
        ],
      ),
      body: entries.isEmpty
          ? Center(
              child: Text(
                'No recent files',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : ListView.builder(
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
                      // TODO(dev): Implement file opening with controller.
                    },
                  ),
                );
              },
            ),
    );
  }
}
