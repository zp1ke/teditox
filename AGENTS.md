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
- `pubspec.yaml` pins `environment: flutter: 3.50.1` (exact) and `sdk: >=3.10.0`.
  CI reads the Flutter version from it via `flutter-version-file`.
- Java **17** is the Android bytecode target (`compileOptions` + `kotlin.compilerOptions`
  in `android/app/build.gradle.kts`). Gradle itself runs on **JDK 21**, pinned in
  `mise.toml` (`[tools] java = "21"`); CI `release.yml` uses Temurin 21. Keep the
  bytecode target and the build JDK distinct concepts when changing either.
- The system/global JDK here is 25, which AGP/Gradle reject. Run builds as
  `mise x -- flutter build ...` (or `mise run build`) so JDK 21 from `mise.toml` is used;
  a bare `flutter build` picks up the global JDK and fails.
- Android toolchain: Gradle **9.5.0**, AGP **9.3.1**, Kotlin **2.4.20**
  (archived plan: `docs/archive/ROADMAP-upgrade-0.2.0.md`).
  `compileSdk = maxOf(flutter.compileSdkVersion, 37)` because `receive_sharing_intent`
  requires API 37; `targetSdk` follows Flutter (36). `gradle.properties` sets
  `android.newDsl=false` + `android.builtInKotlin=false` (from the template) — with
  built-in Kotlin off, Flutter's Gradle plugin auto-applies `kotlin-android`, so
  `app/build.gradle.kts` must NOT apply the Kotlin plugin manually.
- **There is no `flutter migrate` command** (the `.metadata` comment refers to an
  unshipped feature). `flutter create .` only *repairs missing* files — it never
  updates existing platform files, and it can add template junk (delete any recreated
  `test/widget_test.dart` / stock `ic_launcher.png` mipmaps; keep `launcher_icon.png`).
  For platform upgrades, diff against a freshly generated reference project — see
  `docs/archive/ROADMAP-upgrade-0.2.0.md` (Phase 0).
- Shell notes: use `rg`/`fdfind`/`batcat` if available. `pubspec.lock` **is committed**
  (reproducible CI/release builds) — keep it in sync with `pubspec.yaml` and commit the
  lock change together with any dependency bump.
- Zero-permission note: the *source* `AndroidManifest.xml` declares no
  `<uses-permission>`. Merged builds add `INTERNET` only in **debug** (Dart VM service)
  and a signature-level `…DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` from AndroidX in
  release (not a user-facing capability). Neither needs justification.

## Commands

```bash
flutter pub get                                          # dependencies
flutter analyze                                          # lint (very_good_analysis)
flutter test --coverage                                  # unit tests
flutter test integration_test                             # integration (needs a device)
flutter run -d linux                                     # quick manual smoke
flutter build apk --debug                                # Android debug (prefix with `mise x --`)
mise run build                                           # debug APK via JDK 21 from mise.toml
```

**There is no build_runner/freezed codegen in this project** (removed in
the 0.2.0 upgrade — no `@freezed`, no `*.g.dart`, nothing to generate). The only
generated sources are the localizations:
- `lib/src/core/localization/app_localizations*.dart` — generated from `arb/` by
  `flutter gen-l10n`, which runs automatically via `generate: true` + `flutter pub get`;
  excluded from the analyzer — do not hand-edit, do not "fix" their deprecations.
  After editing an `.arb` file, run `flutter gen-l10n` (or `flutter pub get`).

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
  `ROADMAP.md` (mark items done),
  `CHANGELOG.md` (Keep-a-Changelog format + version summary list), `pubspec.yaml`
  version (`x.y.z+build`; bump build number for every Play upload).

## Conventions

- **UI imports: use `package:material_ui/material_ui.dart` — never
  `package:flutter/material.dart`** (unbundled from the SDK in Flutter 3.47+; the two
  are NOT type-compatible; migration completed 2025-11, see
  `docs/archive/ROADMAP-upgrade-0.2.0.md` Phase 0.5).
  `package:flutter/widgets.dart`, `services`, `foundation` etc. stay as-is. Before
  adding any UI-flavored dependency, verify its pubspec depends on material_ui
  (flex_color_scheme ≥9, dynamic_color ≥2.1, google_fonts ≥9 do).
  Localization delegates come from material_ui: `...GlobalMaterialLocalizations.delegates`.
- `very_good_analysis` lint set: public members **require doc comments** — most analyzer
  errors here are missing `///`.
- Plain Dart classes for models (no freezed/codegen — the `freezed`/`build_runner`
  toolchain was removed in the 0.2.0 upgrade as unused).
- Tests use `flutter_test` + `mocktail`; see `test/editor_controller_test.dart` for the
  fake-service pattern (subclass + override, real `PreferencesService` is lightweight).
- Commit style: Conventional Commits (`feat:`/`fix:`/`chore:`/`refactor:`), sometimes
  scoped (`fix(android):`). Release commits bump `pubspec.yaml` + `CHANGELOG.md` together.
- Keep the "no ads / no analytics / no permissions in manifest" property — the
  AndroidManifest declares **zero** `<uses-permission>`; adding one needs a product
  justification (it's a store-listing selling point).

## CI/CD

- `.github/workflows/ci.yml` — on push/PR:
  1. `quality` job: `dart format --set-exit-if-changed` → `flutter analyze` →
     `flutter test --coverage` → `python3 tool/check_coverage.py --min 18` →
     uploads `coverage/lcov.info`.
  2. `android-build` job: `flutter build apk --debug` (Java 21) so Gradle/AGP/Kotlin
     breakage fails the PR, not the release.
- `.github/workflows/integration.yml` — weekly + `workflow_dispatch` + PRs labelled
  `integration`: runs `integration_test` on an Android emulator (API 34) via
  `ReactiveCircus/android-emulator-runner`.
- `.github/workflows/release.yml` — manual dispatch → signed AAB using secrets
  (`KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`) → artifact upload
  → GitHub Release tag. If `PLAY_SERVICE_ACCOUNT_JSON` is set it also publishes to the
  Play **internal** track via `fastlane supply` (`android/fastlane/Fastfile`,
  `android/Gemfile`); otherwise that step is skipped.
- `.github/dependabot.yml` — weekly pub + github-actions updates (Flutter tooling and
  material_ui-family packages are grouped to avoid conflicting bumps).
- Coverage accounting: `tool/check_coverage.py` ignores generated
  `app_localizations*` and `*.g.dart`/`*.freezed.dart`; current floor is 18%.

## Known state / debt (as of 2025-11)

- ✅ **0.2.x shipped to Play open testing.** Flutter 3.50.1 / Dart 3.14, material_ui
  (Material/Cupertino unbundled), all direct deps on latest, Gradle 9.5.0 / AGP 9.3.1 /
  Kotlin 2.4.20 / Java 17 bytecode (JDK 21 build pin), compileSdk 37, dead
  freezed/build_runner toolchain removed. Details: `docs/archive/ROADMAP-upgrade-0.2.0.md`.
- ✅ CI enforces format + a coverage floor (gate 18%) and builds a debug APK on every
  PR; emulator integration tests run weekly/on demand; release publishes to the Play
  internal track when a service-account key exists; dependabot configured.
- ✅ `IntentService` no-ops off Android (it used to throw `MissingPluginException` on
  Linux); opening a recent file now sets the editor title correctly.
- 🎯 Current work is planned in `ROADMAP.md` (product & quality): performance
  (line-number gutter, undo snapshots, counts, recovery writes), correctness (encoding
  detection, recent-file pruning, atomic saves, session restore) and features (search &
  replace, keyboard shortcuts, share-out).
- Coverage ~28% across services/utils; no widget tests yet. `charset_converter` real
  conversion can only be verified on a device.
- Perf hot spots identified, not yet fixed: gutter rebuilds per keystroke, full-text undo
  snapshots, `wordCount` computed inside `build`, full-buffer recovery write every 10 s.
- Only en + es locales. Product/marketing notes: `docs/GROWTH.md`.
