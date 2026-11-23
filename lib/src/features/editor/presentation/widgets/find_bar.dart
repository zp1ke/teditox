import 'package:material_ui/material_ui.dart';
import 'package:teditox/src/core/localization/app_localizations.dart';
import 'package:teditox/src/features/editor/presentation/editor_controller.dart';
import 'package:teditox/src/features/editor/presentation/text_search.dart';

/// Find and replace bar for the editor buffer.
class FindBar extends StatefulWidget {
  /// Creates a find bar bound to [controller].
  const FindBar({required this.controller, required this.onClose, super.key});

  /// Editor whose buffer is searched.
  final EditorController controller;

  /// Called when the user dismisses the bar.
  final VoidCallback onClose;

  @override
  State<FindBar> createState() => FindBarState();
}

/// State for [FindBar], exposed so the editor can focus the query field.
class FindBarState extends State<FindBar> {
  final _queryController = TextEditingController();
  final _replaceController = TextEditingController();
  final _queryFocus = FocusNode();
  var _caseSensitive = false;
  var _wholeWord = false;
  var _showReplace = false;
  var _selected = -1;

  @override
  void initState() {
    super.initState();
    _queryController.addListener(_onQueryChanged);
    widget.controller.controller.addListener(_onBufferChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _queryFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    widget.controller.controller.removeListener(_onBufferChanged);
    widget.controller.setSearchHighlight(const [], -1);
    _queryController.dispose();
    _replaceController.dispose();
    _queryFocus.dispose();
    super.dispose();
  }

  /// Focuses the query field. Used by the find shortcut.
  void focusQuery() => _queryFocus.requestFocus();

  FindQuery get _query => FindQuery(
    text: _queryController.text,
    caseSensitive: _caseSensitive,
    wholeWord: _wholeWord,
  );

  List<TextMatch> get _matches =>
      findMatches(widget.controller.controller.text, _query);

  void _onQueryChanged() {
    setState(() => _selected = -1);
    _publish();
  }

  void _onBufferChanged() {
    _publish();
    if (mounted) setState(() {});
  }

  void _publish() {
    final matches = _matches;
    final selected = _selected >= 0 && _selected < matches.length
        ? _selected
        : -1;
    widget.controller.setSearchHighlight(matches, selected);
  }

  void _go(int index) {
    final matches = _matches;
    if (matches.isEmpty) {
      setState(() => _selected = -1);
      return;
    }
    final wrapped = index % matches.length;
    final match = matches[wrapped];
    widget.controller.selectRange(match.start, match.end);
    setState(() => _selected = wrapped);
    _publish();
  }

  void _next() {
    final matches = _matches;
    final cursor = widget.controller.controller.selection.extentOffset;
    final start = _selected >= 0
        ? _selected + 1
        : nextMatchIndex(matches, cursor);
    _go(start < 0 ? 0 : start);
  }

  void _previous() {
    final matches = _matches;
    final cursor = widget.controller.controller.selection.start;
    final index = _selected >= 0
        ? _selected - 1
        : previousMatchIndex(matches, cursor);
    _go(index < 0 ? matches.length - 1 : index);
  }

  void _replaceOne() {
    final matches = _matches;
    if (matches.isEmpty) return;
    final index = _selected >= 0 && _selected < matches.length
        ? _selected
        : nextMatchIndex(
            matches,
            widget.controller.controller.selection.extentOffset,
          );
    if (index < 0) return;
    final match = matches[index];
    widget.controller.replaceRange(
      match.start,
      match.end,
      _replaceController.text,
    );
    setState(() => _selected = -1);
    _next();
  }

  void _replaceAll() {
    final matches = _matches;
    if (matches.isEmpty) return;
    widget.controller.replaceAll(matches, _replaceController.text);
    setState(() => _selected = -1);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final matches = _matches;
    final count = matches.isEmpty
        ? loc.find_no_matches
        : loc.find_match_count(
            _selected < 0 ? 0 : _selected + 1,
            matches.length,
          );
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 600;
            final query = TextField(
              controller: _queryController,
              focusNode: _queryFocus,
              decoration: InputDecoration(
                isDense: true,
                hintText: loc.find_hint,
                suffixText: count,
              ),
              onSubmitted: (_) => _next(),
            );
            final actions = _actionButtons(loc, matches.isEmpty);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (narrow) ...[
                  query,
                  actions,
                ] else
                  Row(
                    children: [
                      Expanded(child: query),
                      actions,
                    ],
                  ),
                if (_showReplace) _replaceRow(loc, matches.isEmpty, narrow),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _actionButtons(AppLocalizations loc, bool noMatches) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          tooltip: loc.find_previous,
          onPressed: noMatches ? null : _previous,
          icon: const Icon(Icons.keyboard_arrow_up),
        ),
        IconButton(
          tooltip: loc.find_next,
          onPressed: noMatches ? null : _next,
          icon: const Icon(Icons.keyboard_arrow_down),
        ),
        _filterButton(
          tooltip: loc.find_match_case,
          selected: _caseSensitive,
          onPressed: () {
            setState(() => _caseSensitive = !_caseSensitive);
            _publish();
          },
          icon: Icons.text_fields,
        ),
        _filterButton(
          tooltip: loc.find_whole_word,
          selected: _wholeWord,
          onPressed: () {
            setState(() => _wholeWord = !_wholeWord);
            _publish();
          },
          icon: Icons.spellcheck,
        ),
        _filterButton(
          tooltip: loc.replace,
          selected: _showReplace,
          onPressed: () => setState(() => _showReplace = !_showReplace),
          icon: Icons.find_replace,
        ),
        IconButton(
          tooltip: loc.close,
          onPressed: widget.onClose,
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _filterButton({
    required String tooltip,
    required bool selected,
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      isSelected: selected,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: selected ? scheme.secondaryContainer : null,
        foregroundColor: selected ? scheme.onSecondaryContainer : null,
      ),
      icon: Icon(icon),
    );
  }

  Widget _replaceRow(AppLocalizations loc, bool noMatches, bool narrow) {
    final field = TextField(
      controller: _replaceController,
      decoration: InputDecoration(isDense: true, hintText: loc.replace_hint),
    );
    final buttons = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: noMatches ? null : _replaceOne,
          child: Text(loc.replace),
        ),
        TextButton(
          onPressed: noMatches ? null : _replaceAll,
          child: Text(loc.replace_all),
        ),
      ],
    );
    if (narrow) {
      return Column(mainAxisSize: MainAxisSize.min, children: [field, buttons]);
    }
    return Row(
      children: [
        Expanded(child: field),
        buttons,
      ],
    );
  }
}
