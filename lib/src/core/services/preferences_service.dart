import 'package:shared_preferences/shared_preferences.dart';
import 'package:teditox/src/core/theme/app_theme.dart';

/// Service for managing application preferences and settings.
///
/// This service provides a centralized way to store and retrieve user
/// preferences such as theme settings, editor configuration, and recent files.
class PreferencesService {
  static const _keyThemeMode = 'theme_mode';
  static const _keyLocale = 'locale';
  static const _keyFontFamily = 'font_family';
  static const _keyEditorFontFamily = 'editor_font_family';
  static const _keyEditorFontSize = 'editor_font_size';
  static const _keyShowLineNumbers = 'show_line_numbers';
  static const _keyWrapLines = 'wrap_lines';
  static const _keyWordCount = 'word_count';
  static const _keyUndoDepth = 'undo_depth';
  static const _keyMaxFileSize = 'max_file_size';
  static const _keyRecentFiles = 'recent_files';
  static const _keyEncoding = 'default_encoding';

  late SharedPreferences _prefs;

  /// Initializes the preferences service.
  ///
  /// This method must be called before accessing any preferences.
  /// It loads the shared preferences instance.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Gets the undo depth limit for text editing operations.
  ///
  /// Returns the maximum number of undo operations to keep in memory.
  /// Defaults to 5 if not set.
  int get undoDepth => _prefs.getInt(_keyUndoDepth) ?? 5;

  /// Sets the undo depth limit for text editing operations.
  Future<void> setUndoDepth({required int value}) =>
      _prefs.setInt(_keyUndoDepth, value);

  /// Gets the maximum file size limit in bytes.
  ///
  /// Returns the maximum allowed file size for opening/editing.
  /// Defaults to 1MB (1024 * 1024 bytes) if not set.
  int get maxFileSize => _prefs.getInt(_keyMaxFileSize) ?? (1024 * 1024);

  /// Sets the maximum file size limit in bytes.
  Future<void> setMaxFileSize({required int value}) =>
      _prefs.setInt(_keyMaxFileSize, value);

  /// Gets the current theme mode setting.
  ///
  /// Returns the theme mode preference: 'light', 'dark', or 'system'.
  /// Defaults to 'system' if not set.
  String get themeMode => _prefs.getString(_keyThemeMode) ?? 'system';

  /// Sets the theme mode preference.
  Future<void> setThemeMode(String mode) =>
      _prefs.setString(_keyThemeMode, mode);

  /// Gets the current locale setting.
  ///
  /// Returns the locale preference (e.g., 'en', 'es') or 'system' to use
  /// the system locale. Defaults to 'system' if not set.
  String get locale => _prefs.getString(_keyLocale) ?? 'system';

  /// Sets the locale preference.
  Future<void> setLocale(String locale) => _prefs.setString(_keyLocale, locale);

  /// Gets the current font family setting.
  ///
  /// Returns the font family preference or 'system' to use the system
  /// default font. Defaults to first option if not set.
  String get fontFamily => _prefs.getString(_keyFontFamily) ?? appFonts.first;

  /// Sets the font family preference.
  Future<void> setFontFamily(String family) =>
      _prefs.setString(_keyFontFamily, family);

  /// Gets the current editor font family setting.
  String get editorFontFamily =>
      _prefs.getString(_keyEditorFontFamily) ?? editorFonts.first;

  /// Sets the editor font family preference.
  Future<void> setEditorFontFamily(String family) =>
      _prefs.setString(_keyEditorFontFamily, family);

  /// Gets the current font size setting.
  ///
  /// Returns the font size in points. Defaults to 14.0 if not set.
  double get editorFontSize => _prefs.getDouble(_keyEditorFontSize) ?? 14;

  /// Sets the font size preference.
  Future<void> setEditorFontSize(double size) =>
      _prefs.setDouble(_keyEditorFontSize, size);

  /// Gets whether line numbers should be displayed in the editor.
  ///
  /// Returns true if line numbers should be shown, false otherwise.
  /// Defaults to true if not set.
  bool get showLineNumbers => _prefs.getBool(_keyShowLineNumbers) ?? true;

  /// Sets whether to display line numbers in the editor.
  Future<void> setShowLineNumbers({required bool value}) =>
      _prefs.setBool(_keyShowLineNumbers, value);

  /// Gets whether lines should be wrapped in the editor.
  ///
  /// Returns true if long lines should wrap to the next line, false otherwise.
  /// Defaults to true if not set.
  bool get wrapLines => _prefs.getBool(_keyWrapLines) ?? true;

  /// Sets whether to wrap long lines in the editor.
  Future<void> setWrapLines({required bool value}) =>
      _prefs.setBool(_keyWrapLines, value);

  /// Gets whether the word count should be displayed.
  ///
  /// Returns true if the word count should be shown in the UI, false otherwise.
  /// Defaults to false if not set.
  bool get showWordCount => _prefs.getBool(_keyWordCount) ?? false;

  /// Sets whether to display the word count in the UI.
  Future<void> setShowWordCount({required bool value}) =>
      _prefs.setBool(_keyWordCount, value);

  /// Gets the default text encoding for file operations.
  ///
  /// Returns the default encoding to use when opening/saving files.
  /// Defaults to 'utf-8' if not set.
  String get defaultEncoding => _prefs.getString(_keyEncoding) ?? 'utf-8';

  /// Sets the default text encoding for file operations.
  Future<void> setDefaultEncoding({required String encoding}) =>
      _prefs.setString(_keyEncoding, encoding);

  /// Gets the list of recently opened files.
  ///
  /// Returns a list of file paths that were recently opened by the user.
  /// Returns an empty list if no recent files are stored.
  List<String> get recentFiles =>
      _prefs.getStringList(_keyRecentFiles) ?? <String>[];

  /// Sets the list of recently opened files.
  Future<void> setRecentFiles(List<String> list) =>
      _prefs.setStringList(_keyRecentFiles, list);
}
