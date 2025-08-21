import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:teditox/src/app/router.dart';
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
      tooltip: loc.more_actions,
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        switch (value) {
          case 'new':
            ctl.newFile(context);
          case recentsName:
            context.go(recentsRoute);
          case settingsName:
            context.go(settingsRoute);
          case aboutName:
            context.go(aboutRoute);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'new',
          child: Row(
            spacing: 12,
            children: [
              const Icon(Icons.add),
              Text(loc.new_file),
            ],
          ),
        ),
        PopupMenuItem(
          value: recentsName,
          child: Row(
            spacing: 12,
            children: [
              const Icon(Icons.history),
              Text(loc.recent_files),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: settingsName,
          child: Row(
            spacing: 12,
            children: [
              const Icon(Icons.settings),
              Text(loc.settings),
            ],
          ),
        ),
        PopupMenuItem(
          value: aboutName,
          child: Row(
            spacing: 12,
            children: [
              const Icon(Icons.info_outline),
              Text(loc.about),
            ],
          ),
        ),
      ],
    );
  }
}
