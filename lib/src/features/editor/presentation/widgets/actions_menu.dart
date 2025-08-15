import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:teditox/src/core/localization/app_localizations.dart';
import 'package:teditox/src/features/editor/presentation/editor_controller.dart';

/// Actions menu widget that provides a popup menu with various editor actions.
class ActionsMenu extends StatelessWidget {
  /// Creates an actions menu widget.
  const ActionsMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final ctl = context.watch<EditorController>();

    return PopupMenuButton<String>(
      tooltip: 'More actions',
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        switch (value) {
          case 'new':
            ctl.newFile();
          case 'recent':
            context.go('/recent');
          case 'settings':
            context.go('/settings');
          case 'about':
            context.go('/about');
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'new',
          child: Row(
            children: [
              const Icon(Icons.add),
              const SizedBox(width: 12),
              Text(loc.new_file),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'recent',
          child: Row(
            children: [
              const Icon(Icons.history),
              const SizedBox(width: 12),
              Text(loc.recent_files),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              const Icon(Icons.settings),
              const SizedBox(width: 12),
              Text(loc.settings),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'about',
          child: Row(
            children: [
              const Icon(Icons.info_outline),
              const SizedBox(width: 12),
              Text(loc.about),
            ],
          ),
        ),
      ],
    );
  }
}
