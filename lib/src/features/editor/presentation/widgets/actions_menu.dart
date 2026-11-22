import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:teditox/src/app/router.dart';
import 'package:teditox/src/core/localization/app_localizations.dart';
import 'package:teditox/src/core/utils/context.dart';
import 'package:teditox/src/features/editor/presentation/editor_controller.dart';

const _newAction = 'new';
const _saveAsAction = 'save_as';
const _reopenEncodingAction = 'reopen_encoding';

Future<void> _reopenWithEncoding(
  BuildContext context,
  EditorController controller,
) async {
  final loc = AppLocalizations.of(context);
  final encoding = await showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(loc.reopen_with_encoding),
      children: [
        for (final name in controller.fileService.encodingService.supported)
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(name),
            child: Text(name),
          ),
      ],
    ),
  );
  if (encoding == null || !context.mounted) return;
  await controller.reopenWithEncoding(context, encoding);
}

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
        if (value case _newAction) {
          unawaited(ctl.newFile(context));
        } else if (value case _saveAsAction) {
          unawaited(ctl.saveAs(context));
        } else if (value case _reopenEncodingAction) {
          unawaited(_reopenWithEncoding(context, ctl));
        } else {
          for (final route in AppRoute.values) {
            if (value == route.name) {
              context.navigate(route);
              break;
            }
          }
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _newAction,
          child: Row(
            spacing: 12,
            children: [const Icon(Icons.add), Text(loc.new_file)],
          ),
        ),
        PopupMenuItem(
          value: _saveAsAction,
          child: Row(
            spacing: 12,
            children: [const Icon(Icons.save_as_sharp), Text(loc.save_as)],
          ),
        ),
        PopupMenuItem(
          value: _reopenEncodingAction,
          enabled: ctl.currentPath != null,
          child: Row(
            spacing: 12,
            children: [
              const Icon(Icons.translate),
              Text(loc.reopen_with_encoding),
            ],
          ),
        ),
        const PopupMenuDivider(),
        ...AppRoute.values
            .where((route) => route.icon != null)
            .map(
              (route) => PopupMenuItem(
                value: route.name,
                child: Row(
                  spacing: 12,
                  children: [Icon(route.icon), Text(route.title(loc))],
                ),
              ),
            ),
      ],
    );
  }
}
