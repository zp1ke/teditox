# Teditox Upgrade Roadmap — Flutter 3.50.x + latest dependencies

Goal: move from the current pinned, unbuildable state (Flutter pin **3.38.1**, deps
several majors behind) to **Flutter 3.50.1 / Dart 3.14** with latest dependencies and
a modernized Android toolchain — in small, verifiable phases, ending in a Play release.

Each phase ends with the **verify gate**:
`flutter pub get` → `dart run build_runner build --delete-conflicting-outputs` →
`flutter analyze` → `flutter test` → manual smoke on a debug APK (open/save/share a
file, undo/redo, crash recovery, settings, both locales, light/dark).

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

## Phase 1 — Safe (minor/patch) dependency bumps

Bump constraints — near-zero API risk:

| Package | From | To | Risk |
|---|---|---|---|
| intl | 0.20.2 | 0.20.3 | none |
| logger | ^2.6.2 | ^2.8.0 | low |
| get_it | ^9.0.5 | ^9.3.0 | low |
| url_launcher | ^6.3.1 | ^6.3.3 | none |
| build_runner | ^2.10.3 | ^2.17.1 | low (regen + CI timing) |
| mocktail | ^1.0.3 | ^1.0.5 | none |
| flutter_native_splash | ^2.4.7 | ^2.4.8 | none |
| charset_converter | ^2.3.0 | ^2.5.1 | low — re-test encoding round-trips |
| collection | ^1.18.0 | ^1.19.1 | none |

Then `flutter pub upgrade --major-versions` **scoped to these packages** (avoid the
indiscriminate flag — it will also pull the Phase-2 majors). Verify gate.

---

## Phase 2 — Breaking majors (one PR per package, in this order)

Done already (pulled forward into Phase 0.5): ~~flex_color_scheme~~ 9.0.0,
~~dynamic_color~~ 2.1.0, ~~google_fonts~~ 9.0.0. Remaining:

1. **cupertino_icons `1.x → 2.x`** — constraint bump only (iOS glyphs unused here).
2. **receive_sharing_intent `^1.8.0 → ^1.9.0`** — check `IntentService` still compiles;
   re-test "open with Teditox" + "share to Teditox" flows on a real device (cold start
   and warm). This is the app's most fragile platform integration (plugin, not maintained
   hard — evaluate `flutter_sharing_intent` as successor if 1.9 misbehaves).
3. **freezed `3.2 → 4.x` + build_runner** — rerun codegen; freezed 4 may require
   annotation/import tweaks in models (`UndoEntry` etc. are handwritten, so likely just
   regeneration + `json_serializable` alignment). Grep for generated files committed
   anywhere; they must not be.
4. **very_good_analysis `10 → 11`** — expect a wave of new lint findings; fix in a
   dedicated lint-only commit so feature diffs stay clean.
5. **package_info_plus `9 → 10`** — used only in about screen; check API for
   `PackageInfo.fromPlatform()` and plugin's new minSdk/namespace requirements.
6. **go_router `17 → 18`** — update `router.dart`; majors historically change
   navigation APIs (e.g. error/no-op builder handling, ShellRoute generics). Re-test
   back-button behavior with unsaved-changes dialog and drawer navigation.
7. **package_info_plus / receive_sharing_intent** — as listed above; verify each new
   version's pubspec depends on `material_ui` (not framework material) before bumping.

**Breaking-change policy:** Phase 2 changes are internal; user-visible behavior should
not change. If any observable UI/behavior shift is unavoidable, document it in
CHANGELOG under `Changed` and ship as **0.2.0**.

---

## Phase 3 — Android toolchain & Play target

1. Java target `11 → 17`:
   - `android/app/build.gradle.kts`: `JavaVersion.VERSION_17`, `JvmTarget.JVM_17`
   - `android/build.gradle.kts`: subproject `JVM_17` block
   - `.java-version`: `17` (and confirm mise has temurin-17 locally — it does)
   - CI `release.yml` `java-version: '17'` stays (bump to 21 only if AGP requires)
2. Port the reference-project diffs (see below for how to regenerate the reference
project; the numbers were captured 2025-11 — re-verify if SDK moved since):
   - `gradle-wrapper.properties`: 8.13 → **9.5.0** (Gradle 9 is a major: check
     convention/deprecation warnings in `./gradlew` output; may need `gradle.properties`
     compatibility flags temporarily)
   - `settings.gradle.kts`: AGP → **9.3.1**, Kotlin → **2.4.20** (AGP 9 drops defaults
     like `buildConfig`/`androidResources` behaviors — build a debug APK early in this
     step to surface failures)
   - `gradle.properties`: drop `android.enableJetifier` + `kotlin.jvm.target.validation.mode`;
     add `android.newDsl=false`, `android.builtInKotlin=false` (keep our jvmargs)
   - `android/build.gradle.kts`: remove our subprojects JVM-target hack once app-level
     target is 17
   - `linux/`: port `CMakeLists.txt` + `runner/` diffs (cosmetic here)
   Then regenerate a reference project again after each SDK upgrade to re-diff.

   > How-to (there is **no `flutter migrate` command** — the `.metadata` comment refers
   > to an unshipped feature; `flutter create .` only *repairs missing* files and never
   > overwrites existing ones):
   > ```bash
   > flutter create --no-pub --org org.zp1ke --project-name teditox --platforms=android,linux /tmp/teditox_ref
   > diff -rq /tmp/teditox_ref/android android && diff -rq /tmp/teditox_ref/linux linux
   > ```
   > Optionally also run `flutter create --no-pub --platforms=android,linux .` to repair
   > missing files — then delete template junk it recreates (`test/widget_test.dart`,
   > stock `ic_launcher.png` mipmaps; our icons are `launcher_icon.png`).
3. Confirm `targetSdk`/`compileSdk` resolve from `flutter.targetSdkVersion` and meet
   the current Play target-API policy (Android 15/API 35 for updates). If Flutter 3.50's
   default is below policy, set explicitly.
4. Build a **release AAB locally** with the real keystore once (`flutter build appbundle`)
   to catch signing/R8 issues outside CI.
5. Re-run `flutter_launcher_icons` + `flutter_native_splash` (template changes can drift).

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

- **Highest risk:** receive_sharing_intent (Phase 2.2) and go_router (Phase 2.6) —
  both affect core open/save navigation flows. Mitigation: one PR each, device testing
  before merge, tag `v0.1.6` as known-good fallback.
- **Google Fonts 6→9** may be a dead end if APIs moved incompatibly; fallback plan is
  removing the dep and wiring bundled fonts via `pubspec` `fonts:` declarations.
- If freezed 4 codegen fights the current models, staying on freezed 3 for one more
  release is acceptable — it is not SDK-blocked.
- Timeline: Phases 0–1 are ~an hour each; 2 is the bulk (a day); 3–5 a day. Realistically
  a weekend project, shipping 0.2.0 within a week of device testing.
