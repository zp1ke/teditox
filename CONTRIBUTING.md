# Contributing to Teditox

Thanks for helping! This doc covers the human workflow; agents and advanced setup
details live in [AGENTS.md](AGENTS.md).

## Setup

1. Install Flutter (see `environment:` in `pubspec.yaml` for the required SDK).
2. `flutter pub get`
3. `dart run build_runner build`
4. `flutter run -d linux` (or an Android device/emulator)

## Workflow

- Fork → branch from `main` → Conventional Commits (`feat:`, `fix:`, `chore:`…)
- Before pushing: `flutter analyze` and `flutter test` must pass; format with
  `dart format .`.
- UI changes: run the app and smoke-test both locales + light/dark.
- New strings go in `lib/src/core/localization/arb/app_en.arb` **and** `app_es.arb`;
  re-run codegen. Other translations welcome as separate PRs.
- Version bumps and CHANGELOG entries are done by the maintainer at release time —
  don't bump `version:` in feature PRs.

## Proposing features

Teditox is deliberately a *simple* plain-text editor. For new features, open an issue
first and explain the user problem. Things that add permissions, accounts, analytics,
or ads will not be merged — "no ads, no tracking, no permissions" is the product.

Good first issues are tagged in the issue tracker.
