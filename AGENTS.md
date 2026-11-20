# AGENTS.md — Teditox

Guidance for AI agents and contributors working in this repo.

## What this project is

**Teditox** is a free, simple plain-text editor built with Flutter. Android is the
primary target (published on Google Play as `org.zp1ke.teditox`); Linux is kept for
development/testing. MIT licensed. ~3.7k lines of Dart.

Key product traits to preserve: lightweight, no ads, no tracking, manual-save model,
crash recovery, encoding support (UTF-8/UTF-16/ISO-8859-1/Windows-1252/ASCII),
Android SAF + share-intent file handling, en/es localization.

## Environment

- Flutter and Dart are installed at `/home/matt/Tools/flutter` (not mise-managed).
  Current toolchain on this machine: **Flutter 3.50.1 / Dart 3.14.0**.
- `pubspec.yaml` currently pins `environment: flutter: 3.38.1` (exact), which **fails
  `pub get` on newer SDKs**. See `ROADMAP.md` Phase 0 — do not "fix" this incidentally;
  the SDK upgrade is a deliberate, tested step.
- Java 11 is the Android bytecode target (`.java-version`, Gradle `JVM_11`); CI uses
  Temurin 17 to run Gradle. Keep these consistent if you change one.
- Shell notes: use `rg`/`fdfind`/`batcat` if available; `pubspec.lock` is gitignored by
  design (it will appear locally after `pub get` — never commit it).

## Commands

```bash
flutter pub get                                          # dependencies
dart run build_runner build --delete-conflicting-outputs # freezed + l10n codegen
flutter analyze                                          # lint (very_good_analysis)
flutter test --coverage                                  # unit tests
flutter test integration_test                             # integration (needs a device)
flutter run -d linux                                     # quick manual smoke
flutter build apk --debug                                # Android debug build
```

Codegen outputs are committed/generated artifacts:
- `lib/src/core/localization/app_localizations*.dart` — generated from `arb/` by
  `flutter gen-l10n` (runs automatically via `generate: true` + `flutter pub get`).
- `*.g.dart` / `*.freezed.dart` — excluded in `analysis_options.yaml`; edit the source
  file, then re-run build_runner.

## Architecture map

```
lib/main.dart                      entry: splash preserve, DI, font licenses
lib/src/app/                       app.dart (root widget), router.dart (AppRoute enum + GoRouter)
lib/src/core/di/                   service_locator.dart — GetIt singleton `sl`, configureDependencies()
lib/src/core/services/             file_service, content_uri_service (SAF channel), encoding_service,
                                   intent_service (receive_sharing_intent), preferences_service,
                                   recent_files_service, recovery_service
lib/src/core/localization/arb/     app_en.arb, app_es.arb (add keys here, then codegen)
lib/src/core/theme/                app_theme.dart (flex_color_scheme + dynamic_color)
lib/src/core/utils/                line_endings, byte_size_formatter, context ext, icons
lib/src/features/<feature>/presentation/  editor (controller/screen/widgets), recent, settings
```

Patterns to follow:
- **DI**: services are registered lazily in `configureDependencies()`; take a
  `Logger` via constructor. Controllers are `ChangeNotifier`s consumed with `provider`.
- **Routes**: add new screens by extending the `AppRoute` enum and `buildRouter()`.
- **Files**: all file I/O goes through `FileService` (paths *or* Android content URIs —
  check `FileOpenResult.isContentUri`). Never re-add `file_picker`; SAF replaced it in v0.1.5.
- **Docs to keep in sync when you change things**: `README.md` (features, deps),
  `CHANGELOG.md` (Keep-a-Changelog format + version summary list), `pubspec.yaml`
  version (`x.y.z+build`; bump build number for every Play upload).

## Conventions

- `very_good_analysis` lint set: public members **require doc comments** — most analyzer
  errors here are missing `///`.
- Immutable models use `freezed`; run codegen before `flutter analyze`.
- Tests use `flutter_test` + `mocktail`; see `test/editor_controller_test.dart` for the
  fake-service pattern (subclass + override, real `PreferencesService` is lightweight).
- Commit style: Conventional Commits (`feat:`/`fix:`/`chore:`/`refactor:`), sometimes
  scoped (`fix(android):`). Release commits bump `pubspec.yaml` + `CHANGELOG.md` together.
- Keep the "no ads / no analytics / no permissions in manifest" property — the
  AndroidManifest declares **zero** `<uses-permission>`; adding one needs a product
  justification (it's a store-listing selling point).

## CI/CD

- `.github/workflows/ci.yml`: analyze → build_runner → `flutter test --coverage`
  (integration tests are a stubbed echo step — not yet run on CI).
- `.github/workflows/release.yml`: manual dispatch → signed AAB build using secrets
  (`KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`) → artifact upload.
  Keystore is decoded into `android/app/keystore.jks`; `key.properties` points at it.
  The workflow does not (yet) upload to Play — that's done manually via Play Console.

## Known state / debt (as of 2025-11)

- SDK pin 3.38.1 vs toolchain 3.50.1 (blocks builds locally). → ROADMAP.md Phase 0
- 12+ deps behind latest majors. → ROADMAP.md Phase 2
- README prerequisites section is stale (lists Flutter 3.35.6, mentions `file_picker`).
- Test coverage is thin (one unit test file); no coverage gate in CI.
- Only en + es locales. See `docs/GROWTH.md` for product priorities.
