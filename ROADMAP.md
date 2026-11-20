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

## Phase 0 — Unblock the SDK (prerequisite for everything)

**Problem:** `environment: flutter: 3.38.1` is an *exact* pin; `flutter pub get` fails
on Flutter 3.50.1. No branch can even build right now.

1. Change `pubspec.yaml`:
   - `environment: sdk: ^3.14.0` (or `>=3.14.0 <4.0.0`), `flutter: ">=3.50.1"`
     (keep the pin in the file so CI's `flutter-version-file:` keeps working; if you
     prefer reproducibility, pin exact `3.50.1` and install that version).
2. Run `flutter migrate` to refresh platform template files (android/, linux/) —
   review diffs, don't blind-accept.
3. Verify gate. Commit `chore: upgrade SDK pin to Flutter 3.50.1 / Dart 3.14`.

**Deliverable:** repo builds again. This alone unblocks all other work.

---

## Phase 1 — Safe (minor/patch) dependency bumps

Bump constraints within `^` ranges first — near-zero API risk:

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

Order chosen so riskier theme/router changes land after the mechanical ones.

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
7. **google_fonts `6 → 9`** — three majors. `GoogleFonts.config.allowRuntimeFetching`
   in `main.dart` and any generated `GoogleFonts.xxx()` calls need review; app bundles
   the fonts as assets, so worst case is dropping google_fonts entirely and declaring
   `fontFamily` from bundled assets (nice-to-have: removes a network-capable dep).
8. **flex_color_scheme `8 → 9` + dynamic_color `1.7 → 2.1`** — touch `app_theme.dart`
   only; screenshot-compare light/dark/M3-dynamic on Android 12+. Re-generate splash +
   launcher icons after (Phase 3 tooling).

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
2. `flutter migrate` again on this SDK to update Gradle wrapper (8.13 → template's
   version), AGP, Kotlin, and `android/gradle.properties` (e.g. `flutter.*` flags).
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
