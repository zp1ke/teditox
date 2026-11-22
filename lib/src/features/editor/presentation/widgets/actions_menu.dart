import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:teditox/src/app/router.dart';
import 'package:teditox/src/core/localization/app_localizations.dart';
import 'package:teditox/src/core/utils/context.dart';
import 'package:teditox/src/core/utils/line_endings.dart';
import 'package:teditox/src/features/editor/presentation/editor_controller.dart';

const _newAction = 'new';
const _saveAsAction = 'save_as';
const _reopenEncodingAction = 'reopen_encoding';
const _convertFormatAction = 'convert_format';

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

Future<void> _convertFormat(
  BuildContext context,
  EditorController controller,
) async {
  final loc = AppLocalizations.of(context);
  var endings = controller.lineEnding;
  var encoding = controller.currentEncoding;
  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(loc.convert_format),
      content: StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<LineEndingStyle>(
              isExpanded: true,
              value: endings,
              items: [
                for (final style in LineEndingStyle.values)
                  DropdownMenuItem(
                    value: style,
                    child: Text(style.name.toUpperCase()),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => endings = value);
              },
            ),
            DropdownButton<String>(
              isExpanded: true,
              value: encoding,
              items: [
                for (final name
                    in controller.fileService.encodingService.supported)
                  DropdownMenuItem(value: name, child: Text(name)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => encoding = value);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(loc.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(loc.ok),
        ),
      ],
    ),
  );
  if (saved != true || !context.mounted) return;
  controller.setSaveFormat(endings: endings, encoding: encoding);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        loc.convert_format_applied(endings.name.toUpperCase(), encoding),
      ),
    ),
  );
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
        } else if (value case _convertFormatAction) {
          unawaited(_convertFormat(context, ctl));
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
          value: _convertFormatAction,
          child: Row(
            spacing: 12,
            children: [const Icon(Icons.swap_horiz), Text(loc.convert_format)],
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
