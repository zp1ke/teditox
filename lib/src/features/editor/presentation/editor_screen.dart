import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:teditox/src/core/di/service_locator.dart';
import 'package:teditox/src/core/localization/app_localizations.dart';
import 'package:teditox/src/features/editor/presentation/editor_controller.dart';
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
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () async {
              final ok = await controller.save();
              if (ok && context.mounted) {
                Navigator.pop(context, true);
              }
            },
            child: Text(loc.save),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
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
            Navigator.of(context).pop();
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
                    onPressed: () => ctl.openFile(),
                  ),
                  IconButton(
                    tooltip: loc.save,
                    icon: const Icon(Icons.save),
                    onPressed: () => ctl.save(),
                  ),
                  IconButton(
                    tooltip: loc.save_as,
                    icon: const Icon(Icons.save_as),
                    onPressed: () => ctl.saveAs(),
                  ),
                  IconButton(
                    tooltip: 'Undo',
                    onPressed: ctl.canUndo ? ctl.undo : null,
                    icon: const Icon(Icons.undo),
                  ),
                  IconButton(
                    tooltip: 'Redo',
                    onPressed: ctl.canRedo ? ctl.redo : null,
                    icon: const Icon(Icons.redo),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      switch (v) {
                        case 'settings':
                          context.go('/settings');
                        case 'recent':
                          context.go('/recent');
                        case 'about':
                          context.go('/about');
                        case 'new':
                          ctl.newFile();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'new',
                        child: Text(loc.new_file),
                      ),
                      PopupMenuItem(
                        value: 'recent',
                        child: Text(loc.recent_files),
                      ),
                      PopupMenuItem(
                        value: 'settings',
                        child: Text(loc.settings),
                      ),
                      const PopupMenuItem(
                        value: 'about',
                        child: Text('About'),
                      ),
                    ],
                  ),
                ],
              ),
              body: Row(
                children: [
                  if (MediaQuery.of(context).size.width >= 600)
                    SizedBox(
                      width: 250,
                      child: _SidePanel(),
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: _EditorTextArea(
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

class _EditorTextArea extends StatelessWidget {
  const _EditorTextArea({
    required this.showLineNumbers,
    required this.wrap,
  });

  final bool showLineNumbers;
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EditorController>();
    final textController = controller.controller;

    Widget textField = TextField(
      controller: textController,
      expands: true,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      style: TextStyle(
        fontFamily: DefaultTextStyle.of(context).style.fontFamily,
      ),
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      scrollPhysics: const BouncingScrollPhysics(),
    );

    if (!wrap) {
      textField = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 1000),
          child: textField,
        ),
      );
    }

    if (!showLineNumbers) {
      return textField;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.4),
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: textController,
            builder: (context, value, _) {
              final lines = value.text.isEmpty
                  ? 1
                  : '\n'.allMatches(value.text).length + 1;
              final children = List<Widget>.generate(
                lines,
                (index) => Text(
                  '${index + 1}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              );
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: children,
                ),
              );
            },
          ),
        ),
        Expanded(child: textField),
      ],
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
      if (ctl.currentPath != null) ctl.currentPath!.split('/').last,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.3),
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

class _SidePanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Placeholder: could show recent list or quick actions.
    final loc = AppLocalizations.of(context);
    final ctl = context.watch<EditorController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(loc.recent_files),
          onTap: () => context.go('/recent'),
        ),
        ListTile(
          title: Text(loc.settings),
          onTap: () => context.go('/settings'),
        ),
        ListTile(
          title: Text(loc.about),
          onTap: () => context.go('/about'),
        ),
        const Divider(),
        ListTile(
          title: Text(loc.new_file),
          onTap: ctl.newFile,
        ),
        ListTile(
          title: Text(loc.open),
          onTap: ctl.openFile,
        ),
        ListTile(
          title: Text(loc.save),
          onTap: ctl.save,
        ),
        ListTile(
          title: Text(loc.save_as),
          onTap: ctl.saveAs,
        ),
      ],
    );
  }
}
