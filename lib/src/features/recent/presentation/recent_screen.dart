import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teditox/src/core/di/service_locator.dart';
import 'package:teditox/src/core/localization/app_localizations.dart';
import 'package:teditox/src/core/services/recent_files_service.dart';
import 'package:teditox/src/core/utils/byte_size_formatter.dart';
import 'package:teditox/src/core/utils/context.dart';
import 'package:teditox/src/core/utils/icons.dart';
import 'package:teditox/src/features/editor/presentation/editor_controller.dart';

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
            onPressed: () => context.pop(false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => context.pop(true),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.recent_files),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: context.navigateBack,
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
                loc.no_recent_files,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: entries.length,
              itemBuilder: (context, i) {
                final e = entries[i];
                return Dismissible(
                  key: ValueKey(e.path),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _remove(e.path),
                  background: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Icon(Icons.delete, color: colorScheme.onError),
                  ),
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    elevation: 2,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final controller = sl<EditorController>();
                        final success = await controller.openFileByPath(
                          context,
                          e.path,
                        );
                        if (context.mounted) {
                          if (success) {
                            context.navigate(.editor, cleanStack: true);
                          } else {
                            await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(loc.open_file_error),
                                content: Text(
                                  loc.open_file_error_message(e.path),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => context.pop(false),
                                    child: Text(loc.ok),
                                  ),
                                ],
                              ),
                            );
                          }
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              e.path.toIcon,
                              size: 40,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.displayName ?? e.path.split('/').last,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    e.path,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                          fontSize: 11,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatBytes(e.fileSize),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
