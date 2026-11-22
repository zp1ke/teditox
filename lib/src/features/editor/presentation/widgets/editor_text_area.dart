import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:teditox/src/core/theme/app_theme.dart';
import 'package:teditox/src/features/editor/presentation/editor_controller.dart';
import 'package:teditox/src/features/editor/presentation/line_number_layout.dart';
import 'package:teditox/src/features/editor/presentation/widgets/line_number_gutter.dart';
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

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final lineCount = LineNumberLayout.countLines(textController.text);
        final digits = lineCount.toString().length;
        // Enough for the widest digit run plus the gutter's inner padding.
        final gutterWidth = 8.0 * digits + 16;
        final textMaxWidth =
            (constraints.maxWidth - gutterWidth) - textFieldPadding.horizontal;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
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
              child: ExcludeSemantics(
                child: LineNumberGutter(
                  textController: textController,
                  scrollController: _verticalScrollController,
                  textStyle: textStyle,
                  wrap: widget.wrap,
                  contentPadding: textFieldPadding,
                  textMaxWidth: textMaxWidth,
                ),
              ),
            ),
            Expanded(child: textField),
          ],
        );
      },
    );
  }
}
