import 'package:flutter/material.dart';
import 'package:teditox/src/core/services/preferences_service.dart';

/// Controller for managing application settings and preferences.
///
/// Provides access to user preferences with reactive updates through
/// ChangeNotifier. Acts as a bridge between the UI and preferences service.
class SettingsController extends ChangeNotifier {
  /// Creates a settings controller with the given preferences service.
  SettingsController({required this.prefs});

  /// The underlying preferences service for persistence.
  final PreferencesService prefs;

  /// Gets the current theme mode setting.
  ///
  /// Converts the string preference to a ThemeMode enum value.
  /// Returns ThemeMode.system if the preference is invalid.
  ThemeMode get themeMode {
    final v = prefs.themeMode;
    switch (v) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Gets the current locale setting.
  ///
  /// Returns null for system locale, or a Locale object for specific locales.
  Locale? get locale {
    final v = prefs.locale;
    if (v == 'system') return null;
    return Locale(v);
  }

  /// Gets the current font family setting.
  String get currentFontFamily => prefs.fontFamily;

  /// Returns the editor font family.
  String get editorFontFamily => prefs.editorFontFamily;

  /// Gets the editor font size setting in points.
  double get editorFontSize => prefs.editorFontSize;

  /// Gets whether line numbers should be displayed in the editor.
  bool get showLineNumbers => prefs.showLineNumbers;

  /// Gets whether long lines should be wrapped in the editor.
  bool get wrapLines => prefs.wrapLines;

  /// Gets whether the word count should be displayed.
  bool get showWordCount => prefs.showWordCount;

  /// Gets the maximum number of undo operations to keep.
  int get undoDepth => prefs.undoDepth;

  /// Gets the maximum file size limit in bytes.
  int get maxFileSize => prefs.maxFileSize;

  /// Gets the default text encoding for file operations.
  String get defaultEncoding => prefs.defaultEncoding;

  /// Loads settings from preferences.
  ///
  /// Currently a placeholder as settings are loaded synchronously.
  Future<void> load() async {
    // Already loaded; placeholders for async fetching if needed.
  }

  /// Sets the theme mode preference.
  ///
  /// Converts the ThemeMode enum to a string and saves it to preferences.
  /// Notifies listeners of the change.
  Future<void> setThemeMode(ThemeMode mode) async {
    await prefs.setThemeMode(
      mode == ThemeMode.system
          ? 'system'
          : (mode == ThemeMode.dark ? 'dark' : 'light'),
    );
    notifyListeners();
  }

  /// Sets the locale preference.
  ///
  /// Updates the locale setting and notifies listeners of the change.
  Future<void> setLocale(String locale) async {
    await prefs.setLocale(locale);
    notifyListeners();
  }

  /// Sets the font family preference.
  ///
  /// Updates the font family setting and notifies listeners of the change.
  Future<void> setFontFamily(String family) async {
    await prefs.setFontFamily(family);
    notifyListeners();
  }

  /// Sets the editor font family preference.
  ///
  /// Updates the editor font family and notifies listeners of the change.
  Future<void> setEditorFontFamily(String family) async {
    await prefs.setEditorFontFamily(family);
    notifyListeners();
  }

  /// Sets the font size preference.
  ///
  /// Updates the editor font size setting and notifies listeners of the change.
  Future<void> setEditorFontSize(double size) async {
    await prefs.setEditorFontSize(size);
    notifyListeners();
  }

  /// Sets whether line numbers should be displayed in the editor.
  ///
  /// Updates the line numbers visibility setting and notifies listeners.
  Future<void> setShowLineNumbers({required bool value}) async {
    await prefs.setShowLineNumbers(value: value);
    notifyListeners();
  }

  /// Sets whether long lines should be wrapped in the editor.
  ///
  /// Updates the line wrapping setting and notifies listeners.
  Future<void> setWrapLines({required bool value}) async {
    await prefs.setWrapLines(value: value);
    notifyListeners();
  }

  /// Sets whether the word count should be displayed.
  ///
  /// Updates the word count visibility setting and notifies listeners.
  Future<void> setShowWordCount({required bool value}) async {
    await prefs.setShowWordCount(value: value);
    notifyListeners();
  }

  /// Sets the maximum number of undo operations to keep.
  ///
  /// Updates the undo depth limit and notifies listeners.
  Future<void> setUndoDepth({required int value}) async {
    await prefs.setUndoDepth(value: value);
    notifyListeners();
  }

  /// Sets the maximum file size limit in bytes.
  ///
  /// Updates the file size limit and notifies listeners.
  Future<void> setMaxFileSize({required int value}) async {
    await prefs.setMaxFileSize(value: value);
    notifyListeners();
  }

  /// Sets the default text encoding for file operations.
  ///
  /// Updates the default encoding setting and notifies listeners.
  Future<void> setDefaultEncoding({required String encoding}) async {
    await prefs.setDefaultEncoding(encoding: encoding);
    notifyListeners();
  }
}
