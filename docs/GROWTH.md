# Teditox — Growth & Product Analysis

How to grow users for a free, no-ads, open-source plain-text editor on Google Play.
Written 2025-11. Package: `org.zp1ke.teditox`.

## Where we stand

- **USP today:** truly free, MIT open source, **no ads, no tracking, zero manifest
  permissions** (SAF means no storage permission at all), tiny APK, crash recovery,
  real encoding support (UTF-16/Latin-1/CP1252) — rare in this category.
- **Category:** "text editor / notepad" on Play is dominated by ad-ridden freemium apps
  (Quikr, Notally-family) and a few open-source standouts (Gnam, Acode, Markor —
  markdown-first, desktop-first). The "clean, no-ads, no-permission notepad" niche is
  real and under-served *on phones*, especially among privacy-conscious users.
- **Weaknesses:** discoverability (no F-Droid, no web presence beyond the repo), thin
  store listing, only en/es. Search/replace and session restore shipped in 0.2.1+9.
  Current Play open testing is **0.2.2+10** (2026-11-23), which also fixes cold-start
  open-with.

Assumption: "customers" = installs + ratings + community, not revenue (app is and
should stay free).

## A. Quick wins (days, no code risk)

1. **GitHub Releases with attached APKs + changelogs.** Right now a release build only
   exists as a CI artifact. Publishing `v0.2.0.apk` on GitHub makes the project testable
   by anyone, which F-Droid and bloggers require.
2. **F-Droid submission.** Open-source + reproducible builds is their entire filter
   list, and Teditox already qualifies (strip/avoid any non-free bits). F-Droid users are
   exactly this app's audience; listings are free SEO ("no-permission text editor").
   Start with the `data.safe.txt` metadata + their MR bot.
3. **Store listing (ASO) refresh:**
   - Title/subtitle with keywords: "Teditox — Plain Text Editor · No Ads · No Tracking"
   - Rewrite `android/store/description-en.md` (short/full) around the privacy USP;
     currently buried.
   - Screenshots with caption overlays (recovery, encodings, intents). Feature graphic
     already exists in 4 variants — good.
   - Translate listing to es (already have description-es.md — upload it!) and add de,
     pt-BR, fr if easy.
4. **"No permissions" as the headline claim** everywhere: README badge, store listing,
   F-Droid summary. It's verifiable (manifest) and a genuine differentiator.
5. **Ratings:** add a lightweight in-app "rate us" prompt after N successful saves
   (no library needed — `url_launcher` to the Play page is already a dep).

## B. Product gaps that block adoption (weeks)

Ordered by (users gained) ÷ (effort), given the "simple editor" positioning:

1. ~~Search & replace~~ shipped in 0.2.1+9.
2. ~~Session restore~~ shipped in 0.2.1+9.
3. ~~Share out~~ shipped in 0.2.1+9.
4. **Markdown niceties** (optional tier): syntax-only highlighting + preview toggle.
   Careful — this is where "simple" dies; ship behind a setting. Markor's popularity
   shows markdown users overlap heavily with privacy users.
5. **More locales** via existing ARB pipeline: de, pt-BR, fr, it, ja. The l10n infra
   and untranslated-messages tooling already exist; translation itself can come from
   the community (Weblate is free for FOSS).
6. **Tablet/desktop story**: side panel and keyboard shortcuts shipped in 0.2.1+9.
   Chromebook use is still an underserved "simple notepad" market; no extra work until
   someone asks.

Skip (against positioning): cloud sync, accounts, themes marketplace, in-app purchases.

## C. Community & visibility (ongoing)

- **Launch posts:** r/privacy, r/FOSSAndroid, r/androiddev, HN ("Show HN: no-permission
  text editor"), lobste.rs, NanoTechTextPad-style comparison blogs/YouTube (a handful of
  "best open-source Android apps" channels drive outsized installs). Cadence: announce
  **0.2.2+10** (find/replace, session restore, share, open-with), not the 0.2.0 toolchain bump.
- **Inclusive repo hygiene:** CONTRIBUTING.md (done), good-first-issues, issue template
  with reproduction steps, reply to every Play review in the first month — Play ranking
  responds to review velocity + dev replies.
- **Publish the changelog inside the app** (about screen → what's new) — trust signal.
- **GitHub star growth** matters for F-Droid/press: README hero screenshot row,
  GIficle of intent-handling demo.

## D. If money ever matters (not now)

If asked later: keep 100% free core; GitHub Sponsors + a one-time "Supporter badge"
IAP (no feature gating — matches e.g. Organic Maps/Tor Browser norms). Ad-based
monetization would gut the differentiator; do not.

## Suggested sequencing

1. ~~Phases A–D~~ shipped, then **0.2.2+10** to Play open testing (2026-11-23).
2. → announce 0.2.2+10: GitHub release, refreshed listing (en+es), F-Droid MR.
3. → launch posts + rate prompt, measure Play console installs/crash-free 4 weeks.
   Promote to production at crash-free ≥ 99.5% for 7 days.
4. → locales only if asked. Decide on markdown from user feedback.

North-star metric: 30-day organic installs & rating count (currently the two numbers
that gate store search visibility). Guardrail metric: crash-free sessions ≥ 99.5%.
