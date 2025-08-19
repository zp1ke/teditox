import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:teditox/src/features/settings/presentation/settings_controller.dart';

/// Manages application theming with support for dynamic colors and settings.
///
/// This class provides theme generation capabilities with support for both
/// light and dark themes, dynamic color schemes, and user preferences.
/// Uses FlexColorScheme for enhanced theming capabilities.
class AppTheme {
  /// Creates an app theme instance.
  ///
  /// [lightDynamic] and [darkDynamic] are optional dynamic color schemes.
  /// [fallbackSeed] is used when dynamic colors are not available.
  /// [settings] provides access to user font preferences.
  /// [flexScheme] determines the FlexColorScheme to use
  AppTheme({
    required this.lightDynamic,
    required this.darkDynamic,
    required this.fallbackSeed,
    required this.settings,
    this.flexScheme = FlexScheme.tealM3,
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

  /// The FlexColorScheme to use for theming.
  /// Defaults to Blue Stone Teal.
  final FlexScheme flexScheme;

  // Private properties for common theme values
  static const int _inputDecoratorBackgroundAlpha = 21;
  static const double _inputDecoratorRadius = 8;
  static const SchemeColor _inputDecoratorSchemeColor = SchemeColor.primary;
  static const SchemeColor _chipSelectedSchemeColor = SchemeColor.primary;
  static const SchemeColor _chipDeleteIconSchemeColor = SchemeColor.onPrimary;
  static const bool _interactionEffects = true;
  static const bool _tintedDisabledControls = true;
  static const bool _useM2StyleDividerInM3 = true;
  static const bool _fabUseShape = true;

  // Dropdown styling properties
  static const double _popupMenuRadius = 8;
  static const SchemeColor _popupMenuSchemeColor = SchemeColor.surface;
  static const double _popupMenuElevation = 3;
  static const double _popupMenuOpacity = 1;

  /// Common FlexSubThemesData configuration used by both light and dark themes.
  static const FlexSubThemesData _commonSubThemesData = FlexSubThemesData(
    interactionEffects: _interactionEffects,
    tintedDisabledControls: _tintedDisabledControls,
    useM2StyleDividerInM3: _useM2StyleDividerInM3,
    inputDecoratorSchemeColor: _inputDecoratorSchemeColor,
    inputDecoratorBackgroundAlpha: _inputDecoratorBackgroundAlpha,
    inputDecoratorRadius: _inputDecoratorRadius,
    fabUseShape: _fabUseShape,
    chipSelectedSchemeColor: _chipSelectedSchemeColor,
    chipDeleteIconSchemeColor: _chipDeleteIconSchemeColor,
    // Dropdown styling for outlined decoration
    popupMenuRadius: _popupMenuRadius,
    popupMenuSchemeColor: _popupMenuSchemeColor,
    popupMenuElevation: _popupMenuElevation,
    popupMenuOpacity: _popupMenuOpacity,
  );

  /// Builds the light theme for the application.
  ///
  /// Uses dynamic colors if available, otherwise falls back to FlexColorScheme
  /// with the specified scheme. Includes user font preferences and enhanced
  /// Material 3 theming.
  ThemeData buildLightTheme() {
    ThemeData baseTheme;

    // If dynamic colors are available, use them with FlexColorScheme
    if (lightDynamic != null) {
      baseTheme = FlexThemeData.light(
        colorScheme: lightDynamic,
        fontFamily: settings.currentFontFamily,
        subThemesData: _commonSubThemesData,
      );
    } else {
      // Use FlexColorScheme with the specified scheme
      baseTheme = FlexThemeData.light(
        scheme: flexScheme,
        fontFamily: settings.currentFontFamily,
        subThemesData: _commonSubThemesData,
      );
    }

    // Add custom dropdown styling with outlined decoration
    return baseTheme.copyWith(
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_inputDecoratorRadius),
          ),
        ),
      ),
      inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputDecoratorRadius),
        ),
      ),
    );
  }

  /// Builds the dark theme for the application.
  ///
  /// Uses dynamic colors if available, otherwise falls back to FlexColorScheme
  /// with the specified scheme in dark mode. Includes user font preferences
  /// and enhanced Material 3 theming.
  ThemeData buildDarkTheme() {
    ThemeData baseTheme;

    // If dynamic colors are available, use them with FlexColorScheme
    if (darkDynamic != null) {
      baseTheme = FlexThemeData.dark(
        colorScheme: darkDynamic,
        fontFamily: settings.currentFontFamily,
        subThemesData: _commonSubThemesData,
      );
    } else {
      // Use FlexColorScheme with the specified scheme in dark mode
      baseTheme = FlexThemeData.dark(
        scheme: flexScheme,
        fontFamily: settings.currentFontFamily,
        subThemesData: _commonSubThemesData,
      );
    }

    // Add custom dropdown styling with outlined decoration
    return baseTheme.copyWith(
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_inputDecoratorRadius),
          ),
        ),
      ),
      inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputDecoratorRadius),
        ),
      ),
    );
  }
}
