import 'package:flutter/material.dart';
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
      appBar: AppBar(title: Text(loc.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ThemeSection(settings: settings),
          const Divider(),
          _EditorSection(settings: settings, loc: loc),
          const Divider(),
          _AdvancedSection(settings: settings),
        ],
      ),
    );
  }
}

class _ThemeSection extends StatelessWidget {
  const _ThemeSection({required this.settings});
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Theme', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(value: ThemeMode.light, label: Text('Light')),
            ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
            ButtonSegment(value: ThemeMode.system, label: Text('System')),
          ],
          selected: {settings.themeMode},
          onSelectionChanged: (s) => settings.setThemeMode(s.first),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: settings.locale?.languageCode ?? 'system',
          decoration: const InputDecoration(labelText: 'Language'),
          items: const [
            DropdownMenuItem(value: 'system', child: Text('System')),
            DropdownMenuItem(value: 'en', child: Text('English')),
            DropdownMenuItem(value: 'es', child: Text('Español')),
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
              .map((f) => DropdownMenuItem(value: f, child: Text(f)))
              .toList(),
          onChanged: (v) {
            if (v != null) settings.setFontFamily(v);
          },
        ),
        Slider(
          value: settings.fontSize,
          onChanged: settings.setFontSize,
          min: 10,
          max: 28,
          divisions: 18,
          label: settings.fontSize.toStringAsFixed(0),
        ),
        Row(
          children: [
            Expanded(child: Text(loc.encoding)),
            DropdownButton<String>(
              value: settings.defaultEncoding,
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
        ),
      ],
    );
  }
}

class _AdvancedSection extends StatelessWidget {
  const _AdvancedSection({required this.settings});
  final SettingsController settings;

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
        Text('Advanced', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            const Expanded(child: Text('Undo depth')),
            DropdownButton<int>(
              value: settings.undoDepth,
              items: [5, 10, 20]
                  .map((d) => DropdownMenuItem(value: d, child: Text('$d')))
                  .toList(),
              onChanged: (value) {
                if (value != null) settings.setUndoDepth(value: value);
              },
            ),
          ],
        ),
        Row(
          children: [
            const Expanded(child: Text('Max file size')),
            DropdownButton<int>(
              value: settings.maxFileSize,
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
        ),
      ],
    );
  }
}
