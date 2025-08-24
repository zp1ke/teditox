import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teditox/src/core/localization/app_localizations.dart';
import 'package:teditox/src/core/theme/app_theme.dart';
import 'package:teditox/src/core/utils/byte_size_formatter.dart';
import 'package:teditox/src/core/utils/context.dart';
import 'package:teditox/src/features/settings/presentation/settings_controller.dart';

/// Screen that displays application settings.
class SettingsScreen extends StatelessWidget {
  /// Creates a settings screen widget.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: context.navigateBack,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ThemeSection(loc: loc),
          const Divider(height: 32),
          _EditorSection(loc: loc),
          const Divider(height: 32),
          _AdvancedSection(loc: loc),
        ],
      ),
    );
  }
}

class _ThemeSection extends StatelessWidget {
  const _ThemeSection({required this.loc});
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(loc.theme, style: Theme.of(context).textTheme.titleMedium),
        Consumer<SettingsController>(
          builder: (context, settings, child) => SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(value: ThemeMode.light, label: Text(loc.light)),
              ButtonSegment(value: ThemeMode.dark, label: Text(loc.dark)),
              ButtonSegment(value: ThemeMode.system, label: Text(loc.system)),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (s) => settings.setThemeMode(s.first),
          ),
        ),
        Consumer<SettingsController>(
          builder: (context, settings, child) =>
              DropdownButtonFormField<String>(
                initialValue: settings.locale?.languageCode ?? 'system',
                decoration: InputDecoration(labelText: loc.language),
                items: [
                  DropdownMenuItem(value: 'system', child: Text(loc.system)),
                  DropdownMenuItem(value: 'en', child: Text(loc.english)),
                  DropdownMenuItem(value: 'es', child: Text(loc.spanish)),
                ],
                onChanged: (v) {
                  if (v != null) settings.setLocale(v);
                },
              ),
        ),
        Consumer<SettingsController>(
          builder: (context, settings, child) =>
              DropdownButtonFormField<String>(
                initialValue: settings.currentFontFamily,
                decoration: InputDecoration(labelText: loc.font),
                items: appFonts
                    .map(
                      (font) => DropdownMenuItem(
                        value: font,
                        child: Text(font.capitalize),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) settings.setFontFamily(v);
                },
              ),
        ),
      ],
    );
  }
}

class _EditorSection extends StatelessWidget {
  const _EditorSection({required this.loc});
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(loc.editor, style: Theme.of(context).textTheme.titleMedium),
        Consumer<SettingsController>(
          builder: (context, settings, child) => SwitchListTile(
            title: Text(loc.line_numbers),
            value: settings.showLineNumbers,
            onChanged: (value) => settings.setShowLineNumbers(value: value),
          ),
        ),
        Consumer<SettingsController>(
          builder: (context, settings, child) => SwitchListTile(
            title: Text(loc.wrap_lines),
            value: settings.wrapLines,
            onChanged: (value) => settings.setWrapLines(value: value),
          ),
        ),
        Consumer<SettingsController>(
          builder: (context, settings, child) => SwitchListTile(
            title: Text(loc.word_count),
            value: settings.showWordCount,
            onChanged: (value) => settings.setShowWordCount(value: value),
          ),
        ),
        Consumer<SettingsController>(
          builder: (context, settings, child) =>
              DropdownButtonFormField<String>(
                initialValue: settings.editorFontFamily,
                decoration: InputDecoration(labelText: loc.font),
                items: editorFonts
                    .map(
                      (font) => DropdownMenuItem(
                        value: font,
                        child: Text(font.capitalize),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) settings.setEditorFontFamily(v);
                },
              ),
        ),
        Consumer<SettingsController>(
          builder: (context, settings, child) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${loc.editor_font_size}: ${settings.editorFontSize}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Slider(
                value: settings.editorFontSize,
                onChanged: settings.setEditorFontSize,
                min: 10,
                max: 28,
                divisions: 18,
                label: settings.editorFontSize.toStringAsFixed(0),
              ),
            ],
          ),
        ),
        Consumer<SettingsController>(
          builder: (context, settings, child) =>
              DropdownButtonFormField<String>(
                initialValue: settings.defaultEncoding,
                decoration: InputDecoration(labelText: loc.encoding),
                items: const [
                  DropdownMenuItem(value: 'utf-8', child: Text('UTF-8')),
                  DropdownMenuItem(value: 'utf-16le', child: Text('UTF-16 LE')),
                  DropdownMenuItem(value: 'utf-16be', child: Text('UTF-16 BE')),
                  DropdownMenuItem(
                    value: 'iso-8859-1',
                    child: Text('ISO-8859-1'),
                  ),
                  DropdownMenuItem(
                    value: 'windows-1252',
                    child: Text('Windows-1252'),
                  ),
                  DropdownMenuItem(value: 'us-ascii', child: Text('US-ASCII')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    settings.setDefaultEncoding(encoding: value);
                  }
                },
              ),
        ),
      ],
    );
  }
}

class _AdvancedSection extends StatelessWidget {
  const _AdvancedSection({required this.loc});
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final maxSizes = <int>[
      256 * 1024,
      512 * 1024,
      1024 * 1024,
      2 * 1024 * 1024,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(loc.advanced, style: Theme.of(context).textTheme.titleMedium),
        Consumer<SettingsController>(
          builder: (context, settings, child) => DropdownButtonFormField<int>(
            initialValue: settings.undoDepth,
            decoration: InputDecoration(labelText: loc.undo_depth),
            items: [5, 10, 20]
                .map(
                  (d) => DropdownMenuItem(
                    value: d,
                    child: Text(d.toStringAsFixed(0)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) settings.setUndoDepth(value: value);
            },
          ),
        ),
        Consumer<SettingsController>(
          builder: (context, settings, child) => DropdownButtonFormField<int>(
            initialValue: settings.maxFileSize,
            decoration: InputDecoration(labelText: loc.max_file_size),
            items: maxSizes
                .map(
                  (size) => DropdownMenuItem(
                    value: size,
                    child: Text(formatBytes(size)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) settings.setMaxFileSize(value: value);
            },
          ),
        ),
      ],
    );
  }
}
