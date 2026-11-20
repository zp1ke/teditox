# Teditox Upgrade Roadmap — Flutter 3.50.x + latest dependencies

Goal: move from the current pinned, unbuildable state (Flutter pin **3.38.1**, deps
several majors behind) to **Flutter 3.50.1 / Dart 3.14** with latest dependencies and
a modernized Android toolchain — in small, verifiable phases, ending in a Play release.

Each phase ends with the **verify gate**:
`flutter pub get` → `flutter analyze` → `flutter test` → manual smoke on a debug APK
(open/save/share a file, undo/redo, crash recovery, settings, both locales,
light/dark). (No build_runner step — the project has no codegen; see Phase 2.)

Commit per phase; bump `pubspec.yaml` version + `CHANGELOG.md` at the end (0.2.0+8 is
suggested — see Breaking-change note under Phase 2).

---

## Phase 0 — Unblock the SDK — ✅ DONE (2025-11)

Unpinned `environment: flutter: 3.50.1`, Dart SDK 3.14. `pub get`, codegen,
`analyze`, `test`, `format` all pass.

Note: build_runner 2.17 **removed `--delete-conflicting-outputs`** (now a no-op
warning flag). Plain `dart run build_runner build` is enough — update CI + docs.

---

## Phase 0.5 — material_ui unbundle migration — ✅ DONE (2025-11, unplanned)

Flutter 3.47+ deprecated `package:flutter/material.dart` and `cupertino.dart`:
Material/Cupertino were **unbundled** into the `material_ui` / `cupertino_ui`
packages (flutter/packages). The two implementations are **not type-compatible**,
so migrating the app forces the theming plugins onto the package versions.

What was done:
- Added `material_ui: ^1.11.1`, `cupertino_ui: ^1.1.7`.
- Ran the official migration: `dart fix --apply --code=migrate_design_widgets`
  (swapped imports in 15 files) + `dart fix --apply --code=directives_ordering`.
- Upgraded the plugins that had already moved to material_ui (pulled forward from
  Phase 2/1): **flex_color_scheme 8→9.0.0**, **dynamic_color 1.7→2.1.0**,
  **google_fonts 6→9.0.0** (v6 returned framework `TextTheme` → type errors).
- `app.dart`: replaced flutter_localizations delegates with
  `...GlobalMaterialLocalizations.delegates` (material_ui) — removed the
  flutter_localizations import entirely.
- `analysis_options.yaml`: excluded generated `app_localizations*.dart` (the
  gen-l10n template still emits deprecated Global delegates; their
  `localizationsDelegates` const is unused by the app).

Rules going forward: **import `package:material_ui/material_ui.dart`, never
`package:flutter/material.dart`** — and any new UI-flavored dependency must already
depend on material_ui (check its pubspec before adding).

---

## Phase 1 — Safe (minor/patch) dependency bumps — ✅ DONE (2025-11)

Bumped constraints + `flutter pub upgrade`; all resolved and verified:
intl 0.20.3, logger 2.8.0, get_it 9.3.0, url_launcher 6.3.3,
mocktail 1.0.5, flutter_native_splash 2.4.8, charset_converter 2.5.1,
collection 1.19.1 (+ shared_preferences 2.5.6 / path_provider 2.1.6 within range).

Deviations from the plan:
- **build_runner stays `^2.15.1`** — 2.17.1 conflicts with freezed 3.x
  (they are coupled; move together in Phase 2.3).
- **receive_sharing_intent already resolved 1.9.0** (latest, within `^1.8.0`) —
  constraint pinned to `^1.9.0`. Phase 2.2 remains as *device* verification work.
- charset_converter round-trips can't run headless (native platform channel):
  added `test/encoding_service_test.dart` covering BOM detection, UTF-8 paths and
  the graceful fallback; conversion itself must be smoke-tested on a device.

---

## Phase 2 — Breaking majors — ✅ DONE (2025-11)

Done already (pulled forward into Phase 0.5): ~~flex_color_scheme~~ 9.0.0,
~~dynamic_color~~ 2.1.0, ~~google_fonts~~ 9.0.0.

- **cupertino_icons 1→2** — bump (do NOT remove: `cupertino_ui`'s `CupertinoIcons`
  needs the font asset; removing it produced a release-build font warning. See
  Phase 3 note).
- ~~freezed 3→4 + build_runner 2.15→2.17~~ — **removed entirely**. The project has
  **no codegen**: no `@freezed`, no `part '*.g.dart'`, no generated files; the only
  "generated" sources are l10n (`flutter gen-l10n`, independent of build_runner).
  Dropping the dead toolchain removed 9 transitive packages and a no-op CI step.
- **package_info_plus 9→10** — API unchanged (`PackageInfo.fromPlatform()`).
- **go_router 17→18** — 18.0.0's only break was the material_ui migration + Flutter
  3.44 min; our usage (`GoRoute`, `errorBuilder`, `state.uri`) is unaffected.
- **very_good_analysis 10→11** — 5 new `async_return_with_no_await` findings fixed
  (2 dropped `async`, 3 `return await`).
- **receive_sharing_intent** — already 1.9.0; remaining work is *device* verification
  only: re-test "open with Teditox" + "share to Teditox" (cold start and warm).
  Plugin is lightly maintained — evaluate `flutter_sharing_intent` as successor if it
  misbehaves.

All direct dependencies are now on their latest versions (`flutter pub outdated` is
clean).

**Breaking-change policy:** Phase 2 changes are internal; user-visible behavior should
not change. If any observable UI/behavior shift is unavoidable, document it in
CHANGELOG under `Changed` and ship as **0.2.0**.

---

## Phase 3 — Android toolchain & Play target — ✅ DONE (2025-11)

Result: Gradle **9.5.0**, AGP **9.3.1**, Kotlin **2.4.20**, Java bytecode target **17**,
build JDK **21**. Verified: `flutter build apk --debug`, `flutter build appbundle`
(release, R8) and `flutter build linux --debug` all succeed. Resulting APK:
minSdk 24, targetSdk 36, compileSdk 37, zero user-facing permissions.

What changed:
1. Gradle wrapper → 9.5.0 (jar + `gradlew` + `gradlew.bat` copied from a fresh template).
2. `android/settings.gradle.kts`: AGP 8.13.0 → 9.3.1, Kotlin 2.2.20 → 2.4.20.
3. `android/gradle.properties`: dropped `android.enableJetifier` and
   `kotlin.jvm.target.validation.mode`; added template flags `android.newDsl=false`
   and `android.builtInKotlin=false`.
4. `android/build.gradle.kts`: removed the subprojects JVM-target hack (app-level 17
   covers it).
5. `android/app/build.gradle.kts`: `VERSION_17` + `JVM_17`; the `kotlin-android` plugin
   id was removed because Flutter's Gradle plugin auto-applies KGP when
   `builtInKotlin=false` (verified: `MainActivity.class` is produced). Release signing
   now falls back to debug keys when `key.properties` is absent (local/contributor
   builds work).
6. `compileSdk = maxOf(flutter.compileSdkVersion, 37)` — `receive_sharing_intent`
   requires API 37, Flutter's default is 36.
7. Build JDK pinned: `mise.toml` `[tools] java = "21"`, `.java-version` → 21,
   `release.yml` `java-version: '21'`. Bare `flutter build` picks up the machine-global
   JDK 25 (incompatible with AGP/Gradle) — use `mise x --` / `mise run build`.
8. `.gitignore`: added `android/key.properties`, `**/*.jks`, `**/*.keystore` (secret
   leak guard — release.yml writes those).

Note: `cupertino_icons` was re-added (`^2.0.0`) — the font warning during a release
build proved `cupertino_ui`'s `CupertinoIcons` needs it (Phase 2 had wrongly removed
it). Original plan was right.

Remaining manual step: build a local release AAB **with the real keystore** once to
exercise signing outside CI (needs `android/key.properties`), and re-run
`flutter_launcher_icons` / `flutter_native_splash` only if icon assets change.

---

## Phase 4 — CI/CD & quality hardening

1. `ci.yml`: pin Flutter via `flutter-version-file` (already) + add
   `dart format --output=none --set-exit-if-changed .` (currently not enforced).
2. Integration tests: replace the echo stub with a headless emulator job
   (`reactive-dev/android-emulator-runner` or `melos`-style matrix) running
   `integration_test/app_flow_test.dart` — at minimum on release-tag pushes, to keep CI
   time sane.
3. Add coverage artifact + a floor (e.g. fail under current baseline) to prevent regress.
4. `release.yml`: after the AAB builds, upload to Play **internal track** via
   `r0ad/r0ad`-safe alternative — `softprops/action-gh-release` with the AAB attached +
   `google/publish` step using a service-account secret (`rcupload`/`fastlane supply`).
   This turns "manual dispatch → download artifact → Play Console drag-drop" into a
   tagged-push pipeline (Phase 5 needs it).
5. Optional: dependabot for pub + github-actions.

---

## Phase 5 — Release 0.2.0

1. Version bump `0.2.0+8` in `pubspec.yaml`; CHANGELOG entry summarizing: SDK, deps,
   toolchain, CI. Update README prerequisites + deps list (it currently still mentions
   `file_picker` and Flutter 3.35.6 — fix as part of this).
2. GitHub tag `v0.2.0` → CI builds signed AAB → Play internal → closed testing (let
   crash-free-rate settle ≥ 7 days) → production.
3. Refresh store assets in `android/store/` if any UI changed; update
   `what's new` text from CHANGELOG (en + es).
4. Post-release: monitor Play vitals for ANR/crash deltas vs 0.1.6.

---

## Risks & rollback

- **Highest risk:** receive_sharing_intent device flows (Phase 2) — mitigation: device
  testing before merge, tag `v0.1.6` as known-good fallback.
- Timeline: Phases 0–2 are done; 3–5 remain (a day or two). Shipping 0.2.0 within a
  week of device testing is realistic.
