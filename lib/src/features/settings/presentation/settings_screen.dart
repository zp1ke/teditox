import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:teditox/src/core/localization/app_localizations.dart';
import 'package:teditox/src/features/settings/presentation/settings_controller.dart';

/// Screen that displays application settings.
class SettingsScreen extends StatelessWidget {
  /// Creates a settings screen widget.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final settings = context.watch<SettingsController>();
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ThemeSection(settings: settings, loc: loc),
          const Divider(height: 32),
          _EditorSection(settings: settings, loc: loc),
          const Divider(height: 32),
          _AdvancedSection(settings: settings, loc: loc),
        ],
      ),
    );
  }
}

class _ThemeSection extends StatelessWidget {
  const _ThemeSection({required this.settings, required this.loc});
  final SettingsController settings;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.theme, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<ThemeMode>(
          segments: [
            ButtonSegment(value: ThemeMode.light, label: Text(loc.light)),
            ButtonSegment(value: ThemeMode.dark, label: Text(loc.dark)),
            ButtonSegment(value: ThemeMode.system, label: Text(loc.system)),
          ],
          selected: {settings.themeMode},
          onSelectionChanged: (s) => settings.setThemeMode(s.first),
        ),
        const SizedBox(height: 16),
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
      ],
    );
  }
}

class _EditorSection extends StatelessWidget {
  const _EditorSection({required this.settings, required this.loc});
  final SettingsController settings;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final fonts = ['system', 'JetBrains Mono', 'Fira Code', 'Source Code Pro'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.editor, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SwitchListTile(
          title: Text(loc.line_numbers),
          value: settings.showLineNumbers,
          onChanged: (value) => settings.setShowLineNumbers(value: value),
        ),
        SwitchListTile(
          title: Text(loc.wrap_lines),
          value: settings.wrapLines,
          onChanged: (value) => settings.setWrapLines(value: value),
        ),
        SwitchListTile(
          title: Text(loc.word_count),
          value: settings.showWordCount,
          onChanged: (value) => settings.setShowWordCount(value: value),
        ),
        DropdownButtonFormField<String>(
          initialValue: settings.currentFontFamily,
          decoration: InputDecoration(labelText: loc.font),
          items: fonts
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
        const SizedBox(height: 8),
        Text(
          '${loc.font_size}: ${settings.fontSize.toStringAsFixed(0)}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Slider(
          value: settings.fontSize,
          onChanged: settings.setFontSize,
          min: 10,
          max: 28,
          divisions: 18,
          label: settings.fontSize.toStringAsFixed(0),
        ),
        const SizedBox(height: 16),
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
            if (value != null) settings.setDefaultEncoding(encoding: value);
          },
        ),
      ],
    );
  }
}

class _AdvancedSection extends StatelessWidget {
  const _AdvancedSection({required this.settings, required this.loc});
  final SettingsController settings;
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
      children: [
        Text(loc.advanced, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
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
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          initialValue: settings.maxFileSize,
          decoration: InputDecoration(labelText: loc.max_file_size),
          items: maxSizes
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text('${s ~/ 1024} KB'),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) settings.setMaxFileSize(value: value);
          },
        ),
      ],
    );
  }
}
