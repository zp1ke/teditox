import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:teditox/src/core/di/service_locator.dart';
import 'package:teditox/src/core/localization/app_localizations.dart';
import 'package:teditox/src/core/services/intent_service.dart';
import 'package:teditox/src/core/services/share_service.dart';
import 'package:teditox/src/core/widgets/unsaved_changes_dialog.dart';
import 'package:teditox/src/features/editor/presentation/editor_controller.dart';
import 'package:teditox/src/features/editor/presentation/editor_layout.dart';
import 'package:teditox/src/features/editor/presentation/widgets/actions_menu.dart';
import 'package:teditox/src/features/editor/presentation/widgets/editor_text_area.dart';
import 'package:teditox/src/features/editor/presentation/widgets/find_bar.dart';
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
  final _findKey = GlobalKey<FindBarState>();
  var _findOpen = false;

  @override
  void initState() {
    super.initState();
    controller = sl<EditorController>();
    unawaited(_restoreAfterIntent());
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  Future<void> _restoreAfterIntent() async {
    await sl<IntentService>().whenReady;
    if (!mounted) return;
    await controller.restoreSession();
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent || !mounted) return false;
    if (ModalRoute.of(context)?.isCurrent != true) return false;
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final shortcut =
        pressed.contains(LogicalKeyboardKey.controlLeft) ||
        pressed.contains(LogicalKeyboardKey.controlRight) ||
        pressed.contains(LogicalKeyboardKey.metaLeft) ||
        pressed.contains(LogicalKeyboardKey.metaRight);
    final shift =
        pressed.contains(LogicalKeyboardKey.shiftLeft) ||
        pressed.contains(LogicalKeyboardKey.shiftRight);
    if (event.logicalKey == LogicalKeyboardKey.escape && _findOpen) {
      setState(() => _findOpen = false);
      return true;
    }
    if (!shortcut) return false;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.keyS:
        unawaited(
          shift ? controller.saveAs(context) : controller.save(context),
        );
      case LogicalKeyboardKey.keyO:
        unawaited(controller.openFile(context));
      case LogicalKeyboardKey.keyN:
        unawaited(controller.newFile(context));
      case LogicalKeyboardKey.keyF:
        _openFind();
      case LogicalKeyboardKey.keyZ:
        if (shift) {
          controller.redo();
        } else {
          controller.undo();
        }
      case LogicalKeyboardKey.keyY:
        controller.redo();
      default:
        return false;
    }
    return true;
  }

  void _openFind() {
    setState(() => _findOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _findKey.currentState?.focusQuery();
    });
  }

  Future<void> _share() async {
    final loc = AppLocalizations.of(context);
    final shared = await sl<ShareService>().shareText(
      text: controller.controller.text,
      fileName: controller.currentFileName ?? loc.new_file_name,
    );
    if (!mounted || shared) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(loc.share_copied)));
  }

  Future<bool> _handleBack() async {
    if (!controller.dirty) return true;

    final action = await UnsavedChangesDialog.show(context);
    if (!mounted) return false;

    switch (action) {
      case .save:
        return await controller.save(context);
      case .discard:
        return true;
      case .cancel:
      case null:
        return false;
    }
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
            final width = MediaQuery.sizeOf(context).width;
            final showPanel = editorShowsSidePanel(
              width: width,
              enabled: settings.showSidePanel,
            );
            final useDrawer = editorUsesDrawer(width);
            return Scaffold(
              drawer: useDrawer
                  ? const Drawer(child: SafeArea(child: SidePanel()))
                  : null,
              appBar: AppBar(
                title: Text(
                  '${loc.app_name}${ctl.dirty ? ' *' : ''}',
                  overflow: TextOverflow.ellipsis,
                ),
                actions: [
                  if (!useDrawer)
                    IconButton(
                      tooltip: showPanel
                          ? loc.hide_side_panel
                          : loc.show_side_panel,
                      icon: Icon(showPanel ? Icons.menu_open : Icons.menu),
                      onPressed: () {
                        unawaited(settings.setShowSidePanel(value: !showPanel));
                      },
                    ),
                  IconButton(
                    tooltip: loc.open,
                    icon: const Icon(Icons.folder_open),
                    onPressed: () => ctl.openFile(context),
                  ),
                  IconButton(
                    tooltip: loc.save,
                    icon: const Icon(Icons.save),
                    onPressed: () => ctl.save(context),
                  ),
                  IconButton(
                    tooltip: loc.find,
                    icon: const Icon(Icons.search),
                    onPressed: _openFind,
                  ),
                  IconButton(
                    tooltip: loc.share,
                    icon: const Icon(Icons.share),
                    onPressed: _share,
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
                  if (showPanel) const SizedBox(width: 220, child: SidePanel()),
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
                            child: Semantics(
                              header: true,
                              child: Text(
                                _fileTitle(ctl, loc),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: ctl.dirty
                                          ? Theme.of(context).colorScheme.error
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                        if (_findOpen)
                          FindBar(
                            key: _findKey,
                            controller: controller,
                            onClose: () => setState(() => _findOpen = false),
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

String _fileTitle(EditorController controller, AppLocalizations loc) {
  final name = controller.currentFileName ?? loc.new_file;
  if (!controller.dirty) return name;
  return '$name • ${loc.modified}';
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

    final label = items.join('  |  ');
    return Semantics(
      container: true,
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        child: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}
