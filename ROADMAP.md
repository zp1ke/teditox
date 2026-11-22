# Teditox Roadmap — Product & Quality

Version 0.2.0 is in **open testing** on Google Play; the toolchain upgrade work is
archived in [`docs/archive/ROADMAP-upgrade-0.2.0.md`](docs/archive/ROADMAP-upgrade-0.2.0.md).

This roadmap is about making the editor better to *use*: faster on real files, fewer
sharp edges, and the features people expect from a plain-text editor. Product/marketing
notes live in [`docs/GROWTH.md`](docs/GROWTH.md).

Guiding constraints (do not trade away): no ads, no tracking, **no user-facing
permissions**, manual-save model with crash recovery, small and boring.

**Definition of done for every item**: `flutter analyze` clean, tests added/adjusted,
`dart format` clean, coverage ≥ 20% (`tool/check_coverage.py`), and a manual pass on a
debug build with a 1 MB file (the worst realistic case in the app).

---

## Phase A — Performance & memory (highest impact, no UI redesign)

The editor is currently O(document) per keystroke in several places. With the default
2 MB file-size ceiling these are the things that make it feel slow.

### A1. Line-number gutter rebuilds the whole document every keystroke ⚠️
`widgets/editor_text_area.dart` does `text.split('\n')` and
`List<Widget>.generate(lines.length, …)` inside a `ValueListenableBuilder` on the text
controller. For a 5 000-line file that allocates 5 000 widgets + 5 000 `Text`s **per
keystroke**, and re-lays-out a `TextPainter` each time.
Fix: render the gutter with a single `CustomPaint` (or `ListView.builder` sized by
line height) driven by the scroll offset + visible line range; cache the `TextPainter`
line height and recompute only on style/metric change.
Acceptance: typing in a 5 000-line file shows no dropped frames in the Flutter
performance overlay; gutter still aligns when wrapping is enabled/disabled.

### A2. Undo history stores full text snapshots
`EditorController._pushUndo` stores an entire `String` per undo step (depth 5/10/20).
A 2 MB file × 20 steps ≈ 40 MB+ of live strings, and each push compares whole strings.
Fix: keep bounded snapshots (e.g. store text only while `< 64 KB`, otherwise store
deltas), cap total undo memory, and compare using length + content hash before the
string compare.
Acceptance: opening a 2 MB file and typing 100 characters keeps heap growth bounded
(measure with DevTools memory); undo/redo behaviour unchanged.

### A3. Word/char/line counts are recomputed in `build`
`editor_screen.dart` reads `ctl.wordCount` (which does `text.trim().split(RegExp)`) on
every rebuild — i.e. on every keystroke when the counter is enabled.
Fix: compute counts once per text change in the controller (already has a change hook),
debounce ~250 ms, and store the results; make it lazy when the setting is off.
Acceptance: with the counter enabled, typing in a 1 MB file does not spike frame times;
values update within 250 ms.

### A4. Recovery snapshots are heavy and unconditional
`Timer.periodic(10s)` writes the full buffer to JSON on disk whenever `dirty`. On large
files that is a 2 MB encode + write every 10 s, forever.
Fix: snapshot on a content-version change only, skip when nothing changed since the last
snapshot, keep the previous snapshot as a backup (write to `.tmp` then rename), and
consider stopping the timer while the buffer is clean.
Acceptance: idle app does zero disk writes; kill-and-relaunch still restores unsaved
content.

### A5. Micro-optimisations while in there
- `EditorController` notifies listeners on every text change; split the "document
  changed" notification from "selection changed" so the app bar/status bar don't rebuild
  on cursor moves.
- `_previousText` is a full copy of the document; compare via length + hash for large
  buffers.
- Avoid `File(path).uri.pathSegments` in hot paths (it is fine at open time only).

---

## Phase B — Correctness & sharp edges

### B1. Encoding detection is BOM-only
`EncodingService.detectEncoding` only looks for UTF-8/UTF-16 BOMs; everything else is
assumed UTF-8. A Latin-1 or Windows-1252 file therefore opens as mojibake, even though
the app advertises those encodings.
Fix: validate UTF-8 by attempting strict decode; fall back to a byte-histogram heuristic
(or `chardet`-style scoring) between windows-1252/iso-8859-1; keep BOM wins. Persist the
detected encoding per recent-file entry (already stored) and offer "Reopen with
encoding…".
Acceptance: unit tests over sample byte fixtures for each supported encoding, no false
positives on normal ASCII.

### B2. Stale recent files are never pruned
`RecentFilesService.pruneInvalid()` is an empty placeholder, so deleted/moved files stay
in the list and fail on tap.
Fix: implement it (existence check for plain paths; for `content://` URIs check via
`ContentUriService` or drop after a failed open), call it on app start and after a failed
open; show the "missing" state in the recent list UI.
Acceptance: deleting a file outside the app removes/dims it on the next launch.

### B3. File-size rejection has no user-facing reason
`openByPath` throws `FileSystemException('File exceeds size threshold')` and the UI shows
a generic "could not open" message.
Fix: distinguish error kinds (too large / not found / permission / decode) and show a
localized message with the configured limit and a hint that it can be raised in settings.
Acceptance: opening a 5 MB file with a 1 MB limit explains the limit and links to the
setting.

### B4. Saves are not atomic for plain paths
`FileService.saveToPath` calls `writeAsBytes` directly, so a crash mid-write truncates
the user's file. Content-URI writes use `openOutputStream(…, "wt")`, same risk.
Fix: write to a sibling temp file and `rename` (plain paths); keep it best-effort for
content URIs and document the limitation.
Acceptance: simulated failure during write leaves the original file intact.

### B5. Session continuity
The app always starts with an empty buffer; the last file is not reopened (only *crash*
recovery restores content). This reads as a bug to users.
Fix: on start, if no recovery snapshot exists, offer to (or automatically) reopen the
most recent file (respect a setting), keeping the manual-save model.
Acceptance: relaunch returns to the last file with its encoding/line endings.

---

## Phase C — Missing features (highest user value first)

### C1. Search & replace in the buffer ⭐
The single biggest gap versus competing notepads (see `docs/GROWTH.md`).
Scope: in-file find bar (Ctrl/Cmd+F), match count, next/prev, case/whole-word toggles,
optional replace/replace-all with a single undo entry.
Acceptance: works with wrapping on/off and with the line-number gutter; covered by
controller tests (no UI-only logic).

### C2. Keyboard shortcuts (ChromeOS / tablet / external keyboards)
Ctrl/Cmd + S (save), Shift+S (save as), O (open), N (new), F (find), Z/Y (undo/redo),
and Escape to dismiss dialogs. Today only on-screen actions exist.
Acceptance: documented in the About screen; no conflicts with `TextField` defaults.

### C3. Share / export the current buffer
The app ingests shared text files but cannot send one out. Add "Share" that writes a
cache copy and fires `ACTION_SEND` (no new permissions needed).
Acceptance: round-trips with a stock file manager/messaging app.

### C4. Optional markdown comfort (behind a setting)
Syntax-free preview toggle + heading/list highlighting. Keep it off by default so
"simple" stays simple.

### C5. Line-ending / encoding conversion on save
Currently the detected style is preserved; let users deliberately convert (LF → CRLF,
UTF-8 → Windows-1252) from the actions menu, with a clear before/after label.

---

## Phase D — UX, accessibility, localization

- **D1. Accessibility pass**: verify TalkBack labels for the toolbar, actions menu,
  gutter toggle and dialogs; ensure 200% text scaling doesn't clip the status bar.
- **D2. More locales**: pipeline is ARB-based; add `de`, `pt-BR`, `fr`, `it` (community
  translation via Weblate), keeping `app_en.arb`/`app_es.arb` in sync.
- **D3. Tablet/desktop polish**: side panel exists at ≥600 px — make the drawer/panel
  state persist, and confirm layout at 1280×800 and 800×1280.
- **D4. Empty states**: recent list, editor and error dialogs should never show raw
  paths; show file name + parent folder.

---

## Phase E — Release & growth (see docs/GROWTH.md)

1. Promote 0.2.x from open testing → production when crash-free ≥ 99.5% for 7 days.
2. Ship C1 + B5 in 0.3.0 — that is the release worth announcing (Show HN / r/FOSSAndroid
   / r/privacy), not a maintenance bump.
3. F-Droid submission (needs only a tagged release + build recipe) and store-listing
   refresh in en/es.
4. Add an in-app "rate Teditox" prompt after N successful saves.

---

## Known issues / notes

- **Fixed in this cycle**: opening a recent file showed the title as "New File" — plain
  paths never produced a `displayName` (`FileService.openByPath`), and the recent list
  did not pass the name it already knew. Covered by
  `test/file_service_test.dart` and `test/editor_controller_test.dart`.
- **Test infrastructure caveat**: `EditorController` starts a periodic recovery timer,
  so unit tests must call `dispose()`; `testWidgets` + that timer hangs the harness — use
  plain `test()` with a stub `BuildContext` when `skipConfirmation` is true.
- `fileAllowedExtensions` includes an empty string, so "open any file" is intentional;
  do not tighten it without a UX plan.
- Only `en` + `es` are translated; new strings must land in both ARB files.

## Suggested order

1. **A1, A3** (biggest perceived speed wins, low risk)
2. **B1, B2, B5** (correctness users hit immediately)
3. **C1** (feature gap, then release 0.3.0)
4. **C2, C3**, then **A2, A4, B4** (deeper performance/data-safety work)
5. **D1–D4**, **C4/C5**, Phase E — as feedback dictates.