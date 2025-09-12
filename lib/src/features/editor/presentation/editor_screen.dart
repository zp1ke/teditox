import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:teditox/src/core/di/service_locator.dart';
import 'package:teditox/src/core/localization/app_localizations.dart';
import 'package:teditox/src/features/editor/presentation/editor_controller.dart';
import 'package:teditox/src/features/editor/presentation/widgets/actions_menu.dart';
import 'package:teditox/src/features/editor/presentation/widgets/editor_text_area.dart';
import 'package:teditox/src/features/editor/presentation/widgets/side_panel.dart';
import 'package:teditox/src/features/settings/presentation/settings_controller.dart';

/// The main text editor screen widget.
///
/// This screen provides the primary text editing interface with features like
/// file operations, text editing, and integration with app settings.
class EditorScreen extends StatefulWidget {
  /// Creates an editor screen widget.
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final EditorController controller;

  @override
  void initState() {
    super.initState();
    controller = sl<EditorController>();
    controller.attemptRecovery();
  }

  Future<bool> _handleBack() async {
    if (!controller.dirty) return true;
    final loc = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.unsaved_changes),
        content: Text(loc.unsaved_changes_message),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () async {
              final ok = await controller.save();
              if (ok && context.mounted) {
                context.pop(true);
              }
            },
            child: Text(loc.save),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: Text(loc.discard),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final loc = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _handleBack();
          if (shouldPop && context.mounted) {
            await SystemNavigator.pop(animated: true);
          }
        }
      },
      child: ChangeNotifierProvider.value(
        value: controller,
        child: Consumer<EditorController>(
          builder: (context, ctl, _) {
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  '${loc.app_name}${ctl.dirty ? ' *' : ''}',
                ),
                actions: [
                  IconButton(
                    tooltip: loc.open,
                    icon: const Icon(Icons.folder_open),
                    onPressed: () => ctl.openFile(context),
                  ),
                  IconButton(
                    tooltip: loc.save,
                    icon: const Icon(Icons.save),
                    onPressed: () => ctl.save(),
                  ),
                  IconButton(
                    tooltip: loc.undo,
                    onPressed: ctl.canUndo ? ctl.undo : null,
                    icon: const Icon(Icons.undo),
                  ),
                  IconButton(
                    tooltip: loc.redo,
                    onPressed: ctl.canRedo ? ctl.redo : null,
                    icon: const Icon(Icons.redo),
                  ),
                  const ActionsMenu(),
                ],
              ),
              body: Row(
                children: [
                  if (MediaQuery.of(context).size.width >= 600)
                    const SizedBox(
                      width: 220,
                      child: SidePanel(),
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        // File name display between toolbar and editor
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerLow,
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outline.withValues(alpha: 0.2),
                                width: 0.95,
                              ),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              ctl.currentPath?.split('/').last ?? loc.new_file,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        Expanded(
                          child: EditorTextArea(
                            showLineNumbers: settings.showLineNumbers,
                            wrap: settings.wrapLines,
                          ),
                        ),
                        _StatusBar(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ctl = context.watch<EditorController>();
    final settings = context.watch<SettingsController>();
    final loc = AppLocalizations.of(context);

    final items = <String>[
      if (ctl.dirty) loc.modified else loc.saved,
      ctl.lineEnding.name.toUpperCase(),
      ctl.currentEncoding.toUpperCase(),
      if (settings.showWordCount)
        'W:${ctl.wordCount} C:${ctl.charCount} L:${ctl.lineCount}',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.labelSmall!,
        child: Row(
          children: [
            Expanded(
              child: Text(
                items.join('  |  '),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
