import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teditox/src/core/theme/app_theme.dart';
import 'package:teditox/src/features/editor/presentation/editor_controller.dart';
import 'package:teditox/src/features/settings/presentation/settings_controller.dart';

/// A text area widget with optional line numbers and wrapping.
///
/// This widget provides a customizable text editing area that can display
/// line numbers and supports text wrapping. It uses a [TextField] for text
/// input and manages scrolling for both the text area and line numbers.
class EditorTextArea extends StatefulWidget {
  /// Creates an editor text area widget.
  ///
  /// The [showLineNumbers] parameter controls whether line numbers are
  /// displayed.
  /// The [wrap] parameter controls whether text wrapping is enabled.
  const EditorTextArea({
    required this.showLineNumbers,
    required this.wrap,
    super.key,
  });

  /// Whether to show line numbers alongside the text area.
  ////
  /// If true, line numbers will be displayed; otherwise, they will be hidden.
  final bool showLineNumbers;

  /// Whether to enable text wrapping in the text area.
  ////
  /// If true, text will wrap within the visible area; otherwise, horizontal
  /// scrolling will be enabled.
  final bool wrap;

  @override
  State<EditorTextArea> createState() => _EditorTextAreaState();
}

class _EditorTextAreaState extends State<EditorTextArea> {
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _lineNumberScrollController = ScrollController();
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    // Synchronize line numbers scroll with text field scroll
    _verticalScrollController.addListener(_syncLineNumbers);
  }

  void _syncLineNumbers() {
    if (_isSyncing) return;
    _isSyncing = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_lineNumberScrollController.hasClients &&
          _verticalScrollController.hasClients) {
        _lineNumberScrollController.jumpTo(_verticalScrollController.offset);
      }
      _isSyncing = false;
    });
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
      autofocus: true,
      showCursor: true,
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
              final lines = text.split('\n');

              // Create a TextPainter with the exact same style as the TextField
              final textPainter = TextPainter(
                text: TextSpan(text: 'A', style: textStyle),
                textDirection: TextDirection.ltr,
                textScaler: MediaQuery.textScalerOf(context),
              )..layout();

              // Get the exact line height that Flutter uses
              final lineHeight = textPainter.height;

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
                      lines.length,
                      (index) => SizedBox(
                        height: lineHeight,
                        width: double.infinity,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontFamily: textStyle.fontFamily,
                                fontSize: textStyle.fontSize! * 0.85,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                height: textStyle.height,
                              ),
                              textAlign: TextAlign.right,
                              textScaler: MediaQuery.textScalerOf(context),
                            ),
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
