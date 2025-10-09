# Changelog

All notable changes to Teditox will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Version History Summary

- **v0.1.3+4** - External file handling, UI improvements
- **v0.1.2+3** - Play Store assets, dependency updates
- **v0.1.1+2** - Navigation fixes, privacy policy, CI/CD
- **v0.1.0+1** - Initial release with core features

---

## [0.1.3+4] - 2025-10-09

### Added
- External file open intent handling for Android
- Support for opening files from external applications (file managers, email attachments, etc.)

### Changed
- Improved line number synchronization and display accuracy
- Enhanced text area focus management for better user experience
- Standardized Java version to 11 across Android build configuration

### Fixed
- Line number alignment issues during scrolling
- Text area focus behavior when switching between files

## [0.1.2+3] - 2025-09-10

### Added
- `cupertino_icons` dependency for better cross-platform icon support
- Spanish feature graphics for Google Play Store localization
- English and Spanish Play Store descriptions
- Complete Play Store marketing assets (feature graphics, screenshots)

### Changed
- Updated `file_picker` to latest version for improved file selection
- Updated `package_info_plus` for better app metadata handling
- Upgraded Android libraries for better compatibility
- Updated `build_runner` and `freezed` dependencies for latest code generation features
- Updated Flutter SDK to 3.35.5

### Fixed
- Font warning during Android app bundle builds
- Material Icons and Cupertino Icons detection issues

## [0.1.1+2] - 2025-08-22

### Added
- **Privacy Policy** - Comprehensive privacy documentation
- **Navigation improvements** - Better back button and gesture handling on Android
- **Error handling localization** - Translated error messages for file operations
- **Play Store assets** - App icons, feature graphics, and marketing materials
- **GitHub Actions CI/CD** - Automated build and release workflow
- **Release notes** - Initial release documentation in English and Spanish

### Changed
- Improved routing and navigation with GoRouter integration
- Enhanced PopScope handling for Android back gesture support
- Updated application ID and package structure for better organization

### Fixed
- App closing unexpectedly when navigating back from recent files screen via gesture
- Navigation stack issues with GoRouter

## [0.1.0+1] - 2025-08-15

### Added - Initial Release

#### Core Editor Features
- **Plain text editing** with full UTF-8 support
- **Multiple encoding support** - UTF-8, UTF-16 LE/BE, ISO-8859-1, Windows-1252, ASCII
- **Line ending detection and conversion** - LF, CRLF, CR with normalization options
- **Undo/Redo** - Configurable depth (default 5) using ring buffer implementation
- **Manual save model** - Explicit save actions with dirty state indicator
- **Line numbers** - Optional display for code editing
- **Statistics** - Real-time character, word, and line counters

#### File Management
- **Create new files** - Start with empty buffer
- **Open files** - Via file picker with encoding selection
- **Save files** - Manual save with overwrite protection
- **Save As** - Export to new location with encoding choice
- **Recent files** - List of up to 10 recently opened files with metadata
- **Crash recovery** - Automatic snapshot for unsaved buffer recovery

#### User Interface
- **Material 3 Design** - Modern Android UI with smooth animations
- **Dynamic Color** - Android 12+ system color integration
- **Theme modes** - Light, Dark, and System-adaptive themes
- **Multiple fonts** - Bundled fonts including:
  - Fira Code (programming font with ligatures)
  - Inter (modern sans-serif)
  - JetBrains Mono (monospace for coding)
  - Nata Sans (readable sans-serif)
  - Open Sans (clean, friendly sans-serif)
  - Roboto (Material Design default)
  - Source Code Pro (Adobe's monospace)
- **Adjustable font size** - User-configurable text scaling
- **Native splash screen** - Professional app launch experience
- **Adaptive icons** - Android 12+ themed icons

#### Internationalization
- **English localization** (en) - Primary language
- **Spanish localization** (es) - Full translation
- **Extensible i18n system** - ARB-based localization framework

#### Settings & Preferences
- **Theme selection** - Light, Dark, System modes
- **Editor preferences** - Font family, size, line numbers
- **Encoding defaults** - Preferred text encoding
- **Line ending preferences** - LF/CRLF/CR handling
- **Recent files management** - Clear history option
- **Persistent settings** - Saved via shared_preferences

#### Technical Architecture
- **Provider** - State management pattern
- **GetIt** - Service locator for dependency injection
- **GoRouter** - Declarative routing and navigation
- **Freezed** - Immutable data classes and unions
- **Build runner** - Code generation for models and localizations
- **Very Good Analysis** - Strict linting rules for code quality
- **Unit tests** - Core functionality test coverage
- **Integration tests** - End-to-end app flow testing

#### Platform Support
- **Android** - Primary target with full feature support
  - Signed release builds
  - Material 3 with Dynamic Color
  - Adaptive icons and splash screens
- **Linux** - Desktop support for development and testing

#### Developer Tools
- **GitHub Actions** - CI/CD pipeline for automated testing and builds
- **Flutter Launcher Icons** - Automated icon generation
- **Flutter Native Splash** - Splash screen generation
- **Code generation** - Freezed models and localizations
- **Coverage reporting** - Test coverage tracking

### Platform Requirements
- **Android**: Android 6.0 (API 23) or higher
- **Linux**: Desktop Linux distributions
- **Flutter SDK**: 3.35.5+
- **Dart SDK**: 3.9.0+

---

## Legend

- **Added** - New features
- **Changed** - Changes in existing functionality
- **Deprecated** - Soon-to-be removed features
- **Removed** - Removed features
- **Fixed** - Bug fixes
- **Security** - Vulnerability fixes

---

*For detailed commit history, see the [Git log](https://github.com/zp1ke/teditox/commits/main).*
