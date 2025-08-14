import 'package:flutter/material.dart';
import 'package:teditox/src/features/settings/presentation/settings_controller.dart';

/// Manages application theming with support for dynamic colors and settings.
///
/// This class provides theme generation capabilities with support for both
/// light and dark themes, dynamic color schemes, and user preferences.
class AppTheme {
  /// Creates an app theme instance.
  ///
  /// [lightDynamic] and [darkDynamic] are optional dynamic color schemes.
  /// [fallbackSeed] is used when dynamic colors are not available.
  /// [settings] provides access to user font preferences.
  AppTheme({
    required this.lightDynamic,
    required this.darkDynamic,
    required this.fallbackSeed,
    required this.settings,
  });

  /// Optional dynamic color scheme for light theme.
  ///
  /// When available, this provides system-generated colors that match
  /// the user's device theme preferences.
  final ColorScheme? lightDynamic;

  /// Optional dynamic color scheme for dark theme.
  ///
  /// When available, this provides system-generated colors that match
  /// the user's device theme preferences for dark mode.
  final ColorScheme? darkDynamic;

  /// Fallback seed color used when dynamic colors are not available.
  ///
  /// This color is used to generate a color scheme when the system
  /// doesn't provide dynamic colors.
  final Color fallbackSeed;

  /// Settings controller for accessing user font preferences.
  final SettingsController settings;

  /// Builds the light theme for the application.
  ///
  /// Uses dynamic colors if available, otherwise falls back to generating
  /// a color scheme from the fallback seed color. Includes user font
  /// preferences.
  ThemeData buildLightTheme() {
    final baseScheme =
        lightDynamic ?? ColorScheme.fromSeed(seedColor: fallbackSeed);
    return ThemeData(
      colorScheme: baseScheme,
      useMaterial3: true,
      fontFamily: settings.currentFontFamily,
    );
  }

  /// Builds the dark theme for the application.
  ///
  /// Uses dynamic colors if available, otherwise falls back to generating
  /// a dark color scheme from the fallback seed color. Includes user font
  /// preferences.
  ThemeData buildDarkTheme() {
    final baseScheme = darkDynamic ??
        ColorScheme.fromSeed(
          seedColor: fallbackSeed,
          brightness: Brightness.dark,
        );
    return ThemeData(
      colorScheme: baseScheme,
      useMaterial3: true,
      fontFamily: settings.currentFontFamily,
    );
  }
}
