import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teditox/src/core/di/service_locator.dart';
import 'package:teditox/src/core/localization/app_localizations.dart';
import 'package:teditox/src/core/theme/app_theme.dart';
import 'package:teditox/src/features/editor/presentation/editor_controller.dart';
import 'package:teditox/src/features/editor/presentation/widgets/actions_menu.dart';
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

class _EditorTextArea extends StatefulWidget {
  const _EditorTextArea({
    required this.showLineNumbers,
    required this.wrap,
  });

  final bool showLineNumbers;
  final bool wrap;

  @override
  State<_EditorTextArea> createState() => _EditorTextAreaState();
}

class _EditorTextAreaState extends State<_EditorTextArea> {
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _lineNumberScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Synchronize line numbers scroll with text field scroll
    _verticalScrollController.addListener(_syncLineNumbers);
  }

  void _syncLineNumbers() {
    if (_lineNumberScrollController.hasClients &&
        _verticalScrollController.hasClients) {
      _lineNumberScrollController.jumpTo(_verticalScrollController.offset);
    }
  }

  @override
  void dispose() {
    _verticalScrollController
      ..removeListener(_syncLineNumbers)
      ..dispose();
    _horizontalScrollController.dispose();
    _lineNumberScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EditorController>();
    final textController = controller.controller;
    final settings = context.watch<SettingsController>();

    final textStyle = getTextStyle(
      settings.editorFontFamily,
      fontSize: settings.editorFontSize,
      height: 1.4, // Match TextField's default line height
    );

    // TextField's content padding
    const textFieldPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 8);

    Widget textField = TextField(
      controller: textController,
      scrollController: _verticalScrollController,
      expands: true,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      style: textStyle,
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: textFieldPadding,
        isDense: true,
      ),
      scrollPhysics: const BouncingScrollPhysics(),
    );

    if (!widget.wrap) {
      textField = SingleChildScrollView(
        controller: _horizontalScrollController,
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 1000),
          child: textField,
        ),
      );
    }

    if (!widget.showLineNumbers) {
      return textField;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 50,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            border: Border(
              right: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
          ),
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: textController,
            builder: (context, value, _) {
              final text = value.text.isEmpty ? '\n' : value.text;
              final lines = text.split('\n').length;

              // Create a text painter to measure exact line heights
              final textPainter = TextPainter(
                text: TextSpan(text: text, style: textStyle),
                textDirection: TextDirection.ltr,
              )..layout();

              // Calculate the exact height each line should have
              final totalTextHeight = textPainter.height;
              final averageLineHeight = totalTextHeight / lines;

              return SingleChildScrollView(
                controller: _lineNumberScrollController,
                physics: const NeverScrollableScrollPhysics(),
                child: Container(
                  padding: EdgeInsets.only(
                    top: textFieldPadding.top,
                    bottom: textFieldPadding.bottom,
                  ),
                  child: Column(
                    children: List<Widget>.generate(
                      lines,
                      (index) => SizedBox(
                        height: averageLineHeight,
                        width: double.infinity,
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontFamily: textStyle.fontFamily,
                              fontSize: textStyle.fontSize! * 0.85,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              height: 1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
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
