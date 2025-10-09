# Teditox

A simple, modular Flutter text editor.

## Features

### Core Functionality
- **File Operations**: Create, Open, Save, Save As for plain text files via file picker
- **Android Intent Handling**: Open text files directly from other apps (share/open with functionality)
- **Encoding Support**: UTF-8 (default), UTF-16 LE/BE, ISO-8859-1, Windows-1252, ASCII with charset conversion
- **Line Ending Handling**: Automatic detection (LF/CRLF/CR) with optional normalization
- **Manual Save Model**: Explicit save actions with dirty state indicator

### Editor Features
- **Undo/Redo**: Configurable depth (5, 10, or 20 levels) with visual indicators in toolbar
- **Recent Files**: List of up to 10 recent files with metadata
- **Crash Recovery**: Automatic snapshot for unsaved buffer recovery
- **Configurable Display**: 
  - Line numbers with synchronized scrolling
  - Multiple font families (System, JetBrains Mono, Fira Code, Source Code Pro)
  - Adjustable font size (10-28pt)
  - Line wrapping toggle
  - Word/character/line count in status bar
  - Configurable max file size (256KB - 2MB)

### User Experience
- **Responsive UI**: 
  - Adaptive layout with side panel on desktop (≥600px width)
  - Drawer navigation on mobile
  - Collapsible actions menu
- **Theming**: Light, Dark, System modes with Material 3 design + Dynamic Color on Android 12+
- **Fonts**: Bundled with multiple font families (Fira Code, Inter, JetBrains Mono, Nata Sans, Open Sans, Roboto, Source Code Pro)
- **Internationalization**: English and Spanish localization with extensible i18n system
- **Accessibility**: Semantic labeling and scaling support

### Technical Architecture
- **State Management**: Provider pattern with GetIt service locator
- **Navigation**: go_router with declarative routing and enum-based routes
- **Logging**: Structured logging with logger package
- **Immutable Models**: Freezed for type-safe data classes
- **Code Generation**: Build runner for Freezed models and localizations
- **Testing**: Unit tests and integration tests with coverage reporting
- **CI/CD**: Automated analysis, testing, and Android app bundle builds

## Platform Support

- **Android**: Primary target platform with full feature support
  - Material 3 with Dynamic Color (Android 12+)
  - Adaptive icons and splash screens
  - Intent handling for opening files from other apps
  - Signed release builds via CI/CD
- **Linux**: Desktop support for development and testing
- **iOS, Web, Windows, macOS**: Not currently supported

## Development

### Prerequisites
- Flutter 3.35.5+
- Dart SDK 3.9.0+

### Setup
```bash
# Get dependencies
flutter pub get

# Generate code (Freezed models, localizations)
dart run build_runner build --delete-conflicting-outputs

# Generate app icons
dart run flutter_launcher_icons

# Generate splash screens
dart run flutter_native_splash:create
```

### Testing
```bash
# Run unit tests with coverage
flutter test --coverage

# Run integration tests (local device)
flutter test integration_test

# Analyze code
flutter analyze
```

### Building
```bash
# Debug build
flutter build apk --debug

# Release build (requires signing configuration)
flutter build appbundle --release
```

## Project Structure

```
lib/
├── main.dart                    # App entry point
└── src/
    ├── app/                     # App-level configuration
    │   ├── app.dart            # Main app widget
    │   └── router.dart         # Navigation routing (go_router)
    ├── core/                    # Core infrastructure
    │   ├── di/                 # Dependency injection (GetIt)
    │   ├── localization/       # i18n setup and ARB files
    │   ├── services/           # Core services
    │   │   ├── encoding_service.dart      # Text encoding conversion
    │   │   ├── file_service.dart          # File I/O operations
    │   │   ├── intent_service.dart        # Android intent handling
    │   │   ├── preferences_service.dart   # Settings persistence
    │   │   ├── recent_files_service.dart  # Recent files tracking
    │   │   └── recovery_service.dart      # Crash recovery
    │   ├── theme/              # Theme configuration
    │   └── utils/              # Utility functions
    │       ├── byte_size_formatter.dart   # File size formatting
    │       ├── context.dart               # Context extensions
    │       └── line_endings.dart          # Line ending utilities
    └── features/               # Feature modules
        ├── editor/             # Text editing functionality
        │   └── presentation/
        │       ├── editor_controller.dart     # Editor state management
        │       ├── editor_screen.dart         # Main editor UI
        │       └── widgets/
        │           ├── actions_menu.dart      # Toolbar actions
        │           ├── editor_text_area.dart  # Text input with line numbers
        │           └── side_panel.dart        # Navigation sidebar
        ├── recent/             # Recent files management
        │   └── presentation/
        │       └── recent_screen.dart
        └── settings/           # App settings and preferences
            └── presentation/
                ├── about_screen.dart
                ├── settings_controller.dart
                └── settings_screen.dart
```

### Localization
Currently supports:
- **English** (en) - Primary language
- **Spanish** (es) - Secondary language

Localization files are in `lib/src/core/localization/arb/` and can be extended by adding new ARB files.

### Technical Dependencies

#### Core
- **charset_converter**: Text encoding conversion
- **file_picker**: Cross-platform file selection
- **path_provider**: Platform-specific paths
- **shared_preferences**: Persistent storage
- **package_info_plus**: App metadata
- **receive_sharing_intent**: Android intent handling for file sharing
- **logger**: Structured logging

#### UI & Theming
- **dynamic_color**: Material 3 dynamic theming
- **flex_color_scheme**: Advanced theming
- **google_fonts**: Additional font options
- **flutter_native_splash**: Splash screen generation
- **url_launcher**: Open URLs in browser

#### State & Navigation
- **provider**: State management
- **get_it**: Service locator/DI
- **go_router**: Declarative routing

#### Development
- **freezed**: Immutable data classes
- **build_runner**: Code generation
- **very_good_analysis**: Linting rules
- **mocktail**: Testing utilities

## CI/CD

The project includes GitHub Actions workflows:

- **CI Pipeline**: Runs on every push/PR
  - Code analysis (`flutter analyze`)
  - Unit tests with coverage
  - Build runner code generation
  - Integration tests (disabled on headless CI)

- **Release Pipeline**: Manual workflow dispatch
  - Builds signed Android App Bundle
  - Uses GitHub secrets for keystore management
  - Uploads build artifacts

## License
MIT (see LICENSE).
