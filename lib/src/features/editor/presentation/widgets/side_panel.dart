import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:teditox/src/app/router.dart';
import 'package:teditox/src/core/localization/app_localizations.dart';
import 'package:teditox/src/features/editor/presentation/editor_controller.dart';

/// Side panel widget that displays navigation options and file operations.
class SidePanel extends StatelessWidget {
  /// Creates a side panel widget.
  const SidePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final ctl = context.watch<EditorController>();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Navigation section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                loc.navigation,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(loc.recent_files),
              onTap: () => context.go(recentsRoute),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(loc.settings),
              onTap: () => context.go(settingsRoute),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(loc.about),
              onTap: () => context.go(aboutRoute),
            ),
            const Divider(),

            // File operations section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                loc.file_operations,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: Text(loc.new_file),
              onTap: () => ctl.newFile(context),
            ),
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: Text(loc.open),
              onTap: () => ctl.openFile(context),
            ),
            ListTile(
              leading: const Icon(Icons.save),
              title: Text(loc.save),
              onTap: ctl.save,
              enabled: ctl.dirty,
            ),
            ListTile(
              leading: const Icon(Icons.save_as),
              title: Text(loc.save_as),
              onTap: ctl.saveAs,
            ),
          ],
        ),
      ),
    );
  }
}
