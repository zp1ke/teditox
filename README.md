# teditox

A simple, modular Flutter (Android-first) plain text editor supporting:
- Create/Open/Save/Save As for plain text files via file picker
- Encoding selection (UTF-8 default; UTF-16 LE/BE, ISO-8859-1, Windows-1252, ASCII)
- Line ending detection (LF / CRLF / CR) + optional normalization
- Manual save model with dirty state indicator
- Undo/Redo (configurable depth, default 5) using ring buffer
- Recent files list (max 10, configurable) with metadata
- Crash recovery snapshot for unsaved buffer
- Theme modes (Light, Dark, System) with Material 3 + Dynamic Color on Android 12+
- Localization (English, Spanish) & extensible i18n
- Configurable editor (line numbers, font, font size, word/char/line count)
- Provider for state management + get_it for service locator
- Freezed for immutable models
- CI workflow (analyze, test, build)
- Accessibility (semantics, scaling)

## Structure
```
lib/
  main.dart
  src/
    app/
      app.dart
      router.dart
    core/
      di/service_locator.dart
      localization/ (l10n setup)
      theme/
      utils/
      services/
    features/
      editor/
      recent/
      settings/
      common_widgets/
```

## Commands
Generate code (Freezed, localization):
```
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Run integration test:
```
flutter test integration_test
```

## Notes
- File picker “Save As” uses FilePicker saveFile (desktop/web fallback may differ).
- External VIEW intent handling stubbed (Android channel scaffolding placeholder).
- Charset conversion uses charset_converter; if a chosen encoding unsupported, fallback to Latin-1 or UTF-8 with warning.

## Future Extensions
Search, Favorites, syntax highlighting, cloud sync.

## License
MIT (see LICENSE).