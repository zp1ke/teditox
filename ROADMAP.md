# Teditox Roadmap — Product & Quality

**0.2.2+10** is in **open testing** on Google Play (uploaded 2026-11-23). It is
0.2.1+9 plus the cold-start open-with fix. 0.2.1+9 has find and replace, session
restore, share, and the recent-file title fix. The toolchain upgrade is archived in
[`docs/archive/ROADMAP-upgrade-0.2.0.md`](docs/archive/ROADMAP-upgrade-0.2.0.md).
Working tree version is **0.2.3+11** so the next upload is not the same versionCode.

This roadmap is about making the editor better to *use*: faster on real files, fewer
sharp edges, and the features people expect from a plain-text editor. Product/marketing
notes live in [`docs/GROWTH.md`](docs/GROWTH.md).

Guiding constraints (do not trade away): no ads, no tracking, **no user-facing
permissions**, manual-save model with crash recovery, small and boring.

**Definition of done for every item**: `flutter analyze` clean, tests added/adjusted,
`dart format` clean, coverage ≥ 20% (`tool/check_coverage.py`), and a manual pass on a
debug build with a 1 MB file (the worst realistic case in the app).

---

## Phase A — Performance & memory — ✅ DONE

The editor was O(document) per keystroke in several places. With the default 2 MB
file-size ceiling these were the things that made it feel slow.

### A1. Line-number gutter — ✅
The gutter is a `CustomPaint` of the visible line window (`LineNumberGutter`), not one
widget per line. Wrapping still measures logical-line heights, but only when the text or
width changes, and only the visible numbers are painted.

### A1 notes
`widgets/editor_text_area.dart` does `text.split('\n')` and
`List<Widget>.generate(lines.length, …)` inside a `ValueListenableBuilder` on the text
controller. For a 5 000-line file that allocates 5 000 widgets + 5 000 `Text`s **per
keystroke**, and re-lays-out a `TextPainter` each time.
Fix: render the gutter with a single `CustomPaint` (or `ListView.builder` sized by
line height) driven by the scroll offset + visible line range; cache the `TextPainter`
line height and recompute only on style/metric change.
Acceptance: typing in a 5 000-line file shows no dropped frames in the Flutter
performance overlay; gutter still aligns when wrapping is enabled/disabled.

### A2. Undo history — ✅
Steps after the base entry are prefix/suffix deltas (`text_delta.dart`). A 200k-character
buffer plus one edit stays under two copies. Undo/redo behaviour is covered by tests.

### A2 notes
`EditorController._pushUndo` stores an entire `String` per undo step (depth 5/10/20).
A 2 MB file × 20 steps ≈ 40 MB+ of live strings, and each push compares whole strings.
Fix: keep bounded snapshots (e.g. store text only while `< 64 KB`, otherwise store
deltas), cap total undo memory, and compare using length + content hash before the
string compare.
Acceptance: opening a 2 MB file and typing 100 characters keeps heap growth bounded
(measure with DevTools memory); undo/redo behaviour unchanged.

### A3. Word/char/line counts — ✅
Counts are cached on the controller and refreshed 250 ms after a text change, and only
while the word-count setting is on.

### A3 notes
`editor_screen.dart` reads `ctl.wordCount` (which does `text.trim().split(RegExp)`) on
every rebuild — i.e. on every keystroke when the counter is enabled.
Fix: compute counts once per text change in the controller (already has a change hook),
debounce ~250 ms, and store the results; make it lazy when the setting is off.
Acceptance: with the counter enabled, typing in a 1 MB file does not spike frame times;
values update within 250 ms.

### A4. Recovery snapshots — ✅
The 10 s timer starts only while the buffer is dirty, skips a write when the content
fingerprint is unchanged, and replaces the snapshot via a temp file + rename so a failed
write leaves the previous snapshot intact.

### A4 notes
`Timer.periodic(10s)` writes the full buffer to JSON on disk whenever `dirty`. On large
files that is a 2 MB encode + write every 10 s, forever.
Fix: snapshot on a content-version change only, skip when nothing changed since the last
snapshot, keep the previous snapshot as a backup (write to `.tmp` then rename), and
consider stopping the timer while the buffer is clean.
Acceptance: idle app does zero disk writes; kill-and-relaunch still restores unsaved
content.

### A5. Micro-optimisations — ✅
Text-change detection uses a fingerprint instead of retaining `_previousText`. Selection
changes already did not notify listeners. `displayNameForPath` stays off the typing path.

### A5 notes
- `EditorController` notifies listeners on every text change; split the "document
  changed" notification from "selection changed" so the app bar/status bar don't rebuild
  on cursor moves.
- `_previousText` is a full copy of the document; compare via length + hash for large
  buffers.
- Avoid `File(path).uri.pathSegments` in hot paths (it is fine at open time only).

---

## Phase B — Correctness & sharp edges — ✅ DONE

### B1. Encoding detection — ✅
BOM still wins. Valid UTF-8, including ASCII, stays UTF-8. Invalid UTF-8 with
Windows-1252 punctuation bytes is detected as windows-1252; other high bytes as
ISO-8859-1. UTF-16 without a BOM is recognised from NUL padding. The actions menu
can reopen the current file with a chosen encoding. The detected encoding was
already stored on recent entries and is reused when restoring the last file.

### B1 notes
`EncodingService.detectEncoding` only looks for UTF-8/UTF-16 BOMs; everything else is
assumed UTF-8. A Latin-1 or Windows-1252 file therefore opens as mojibake, even though
the app advertises those encodings.
Fix: validate UTF-8 by attempting strict decode; fall back to a byte-histogram heuristic
(or `chardet`-style scoring) between windows-1252/iso-8859-1; keep BOM wins. Persist the
detected encoding per recent-file entry (already stored) and offer "Reopen with
encoding…".
Acceptance: unit tests over sample byte fixtures for each supported encoding, no false
positives on normal ASCII.

### B2. Stale recent files — ✅
`pruneInvalid()` drops plain paths that no longer exist and runs when the recent
screen opens. `content://` URIs are removed when an open reports not found, because
they cannot be stat'ed. The open error says the file was removed from the list.

### B2 notes
`RecentFilesService.pruneInvalid()` is an empty placeholder, so deleted/moved files stay
in the list and fail on tap.
Fix: implement it (existence check for plain paths; for `content://` URIs check via
`ContentUriService` or drop after a failed open), call it on app start and after a failed
open; show the "missing" state in the recent list UI.
Acceptance: deleting a file outside the app removes/dims it on the next launch.

### B3. File-size rejection — ✅
Opens throw `FileOpenException` (`tooLarge`, `notFound`, `unreadable`). The dialog
names the limit and has a Settings button for the too-large case.

### B3 notes
`openByPath` throws `FileSystemException('File exceeds size threshold')` and the UI shows
a generic "could not open" message.
Fix: distinguish error kinds (too large / not found / permission / decode) and show a
localized message with the configured limit and a hint that it can be raised in settings.
Acceptance: opening a 5 MB file with a 1 MB limit explains the limit and links to the
setting.

### B4. Atomic saves — ✅
Plain paths are written to a sibling `.teditox.tmp` and renamed over the target, so a
failed write leaves the original file. Content-URI writes stay best-effort; Android
does not offer a rename-over for those streams.

### B4 notes
`FileService.saveToPath` calls `writeAsBytes` directly, so a crash mid-write truncates
the user's file. Content-URI writes use `openOutputStream(…, "wt")`, same risk.
Fix: write to a sibling temp file and `rename` (plain paths); keep it best-effort for
content URIs and document the limitation.
Acceptance: simulated failure during write leaves the original file intact.

### B5. Session continuity — ✅
Startup still prefers a crash snapshot. If there is none, and Settings →
"Reopen last file on startup" is on (the default), the most recent file is opened
with its stored encoding. The buffer is clean, so the manual-save model is unchanged.

### B5 notes
The app always starts with an empty buffer; the last file is not reopened (only *crash*
recovery restores content). This reads as a bug to users.
Fix: on start, if no recovery snapshot exists, offer to (or automatically) reopen the
most recent file (respect a setting), keeping the manual-save model.
Acceptance: relaunch returns to the last file with its encoding/line endings.

---

## Phase C — Missing features — C1–C3 and C5 done, C4 still open

### C1. Search & replace — ✅
Find bar with next/previous, match count, case and whole-word toggles, replace and
replace-all. Replace records one undo step. Logic is in `text_search.dart` and covered
by unit tests. The bar sits above the editor, so wrapping and the gutter are unchanged.

### C1 notes
The single biggest gap versus competing notepads (see `docs/GROWTH.md`).
Scope: in-file find bar (Ctrl/Cmd+F), match count, next/prev, case/whole-word toggles,
optional replace/replace-all with a single undo entry.
Acceptance: works with wrapping on/off and with the line-number gutter; covered by
controller tests (no UI-only logic).

### C2. Keyboard shortcuts — ✅
Ctrl/Cmd+S, Shift+S, O, N, F, Z, Shift+Z, Y, and Esc (closes find) are handled before
the text field sees them, so they do not fight the field's own undo. Listed on the
About screen.

### C2 notes
Ctrl/Cmd + S (save), Shift+S (save as), O (open), N (new), F (find), Z/Y (undo/redo),
and Escape to dismiss dialogs. Today only on-screen actions exist.
Acceptance: documented in the About screen; no conflicts with `TextField` defaults.

### C3. Share — ✅
Share writes a cache copy and, on Android, sends it with `ACTION_SEND` through a
FileProvider (no new permission). Other platforms copy the text to the clipboard.

### C3 notes
The app ingests shared text files but cannot send one out. Add "Share" that writes a
cache copy and fires `ACTION_SEND` (no new permissions needed).
Acceptance: round-trips with a stock file manager/messaging app.

### C4. Optional markdown comfort (behind a setting)
Syntax-free preview toggle + heading/list highlighting. Keep it off by default so
"simple" stays simple.

### C5. Save format — ✅
The actions menu can set the line ending and encoding used on the next save, and shows
the chosen pair. The buffer itself is not rewritten until save.

### C5 notes
Currently the detected style is preserved; let users deliberately convert (LF → CRLF,
UTF-8 → Windows-1252) from the actions menu, with a clear before/after label.

---

## Phase D — UX, accessibility, localization — ✅ except new locales

- **D1. Accessibility — ✅** Toolbar buttons keep tooltips (TalkBack labels). The
  line-number gutter is excluded from the semantics tree so it is not read digit by
  digit. Dialogs have semantic labels. The status bar is one label and wraps to two
  lines so 200% text scale does not clip it.
- **D2. More locales — deferred.** English and Spanish stay the only locales until
  that decision is revisited. Do not add `de` / `pt-BR` / `fr` / `it` yet. New strings
  still go in both `app_en.arb` and `app_es.arb`.
- **D3. Tablet/desktop — ✅** Width ≥ 600 (1280×800 and 800×1280) shows the side panel.
  Hiding it is remembered. Narrow widths use a drawer with the same panel.
- **D4. Empty states — ✅** Recent rows show the file name and parent folder, never a
  raw path or content URI. Open errors use the same rule.

---

## Phase D-human — Device approval (you, on an Android phone)

Do this **before** Phase E. Unit tests do not cover Storage Access Framework, the share
sheet, or how the editor feels. Install a build from this branch (`mise x -- flutter run`
or an internal-track upload) and tick each item. A fail blocks the release.

Use one phone on the current Play target (Android 14 or 15 is enough) and, if you have
one, a tablet or a phone in landscape wider than 600 px. Switch the device language to
English for steps 1–8, then repeat the marked steps in Spanish.

### 1. Install and first launch
- [x] App installs and opens to an empty editor titled with the localized "New file".
- [x] No permission dialog appears at any point in this whole list.
- [x] Light, dark, and system theme all look readable. Dynamic color on Android 12+ follows the wallpaper.

### 2. Open, edit, save (SAF)
- [x] Open a `.txt` from the system picker. The title is the real file name, not "New file" and not a number like `14`.
- [x] Type. The file-name row (above the keyboard) turns to "name • Modified". Save. Reopen the same file from a file manager: the text is there.
- [x] Save As creates a new document with the name you chose. The title updates to that name.
- [x] A missing file (delete it outside the app, then tap it in Recent) shows a not-found message and disappears from Recent. The message does not show a raw `content://` URI.

### 3. Recent files and restart
- [x] After saving, the file is in Recent with its name and a folder or "Shared document", not the full URI.
- [x] Force-stop the app and relaunch. The last file reopens and is **not** marked dirty.
- [x] Turn off Settings → "Reopen last file on startup", force-stop, relaunch: empty editor. Turn it back on.

### 4. Crash recovery
- [x] Type without saving, then kill the app from the recents screen (swipe away).
- [x] Relaunch: the unsaved text is back and marked dirty. Save, kill again: it does not restore over the saved file.

### 5. Share in and share out
- [x] From a file manager, "Open with" Teditox (app was closed). The file opens with the right name.
- [x] Repeat with Teditox already open.
- [x] Share a text file into Teditox from another app. Same result.
- [x] In Teditox, Share. The system share sheet opens and a messaging or files app can receive the text. No permission prompt.

### 6. Find, replace, undo
- [x] Search finds the next and previous match. Match case and whole word behave as labeled.
- [ ] Retest: every match is highlighted in the file, the current match is stronger, and match case / whole word / replace stay filled while on.
- [x] Replace one match, then Replace all. Undo once restores the buffer from before replace-all.
- [x] Esc closes the find bar.

### 7. Encodings and line endings
- [x] Open a Windows-1252 or Latin-1 file (smart quotes or `é` saved as Latin-1). It is not mojibake. The status bar names the encoding.
- [x] More actions → Reopen with encoding → UTF-8, then back. The text changes only when the encoding was wrong.
- [x] More actions → Save as encoding. The snackbar names the line ending and charset. Save, reopen: the file matches that choice.

### 8. Limits, performance, and text size
- [x] Set max file size to 256 KB and open a larger file. The dialog names the limit and the Settings button opens Settings. Raise the limit and open the file.
- [x] Open a file of about 1 MB with line numbers on. Typing does not visibly stall. Scrolling the gutter stays aligned with the text, including with wrap on.
- [x] Settings → display size / font size at the largest step. The status bar wraps or ellipsizes. It is not cut off. Toolbar buttons still have spoken labels in TalkBack (spot-check Open, Save, Find, Share, Undo).

### 9. Layout
- [x] Phone portrait: navigation is a drawer, not a permanent side panel.
- [x] Width ≥ 600 px (tablet, or phone landscape if it is wide enough): the side panel is visible. Hide it, leave the app, come back: it stays hidden. Show it again.

### 10. Spanish
- [x] Switch the app language to Spanish. Repeat steps 2, 5, and 6. Buttons, errors, and the empty recent list are Spanish, not English and not raw keys.

### Sign-off
- [x] I approve this build for the next Play upload. 2026-11-22, version 0.2.1+9.

Write the date and the version (`pubspec.yaml` `version:`) next to the sign-off when you pass it. Do not start Phase E until that line is filled in.

---

## Phase E — Release & growth (see docs/GROWTH.md)

0.2.2+10 is the open-testing build to promote. Do not cut another feature release
just to announce find and replace.

1. Promote **0.2.2+10** from open testing → production when crash-free ≥ 99.5% for 7 days.
2. Announce 0.2.2+10 (find/replace, session restore, share, encodings, open-with) on
   Show HN, r/FOSSAndroid, and r/privacy. That is the release worth announcing, not a
   later bump.
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

1. ~~A1–A5~~ done.
2. ~~B1–B5~~ done.
3. ~~C1–C3, C5~~ done. **C4** (optional markdown) is still open.
4. ~~D1, D3, D4~~ done. **D2** stays en/es only.
5. ~~Phase D-human~~ signed off. Uploaded as **0.2.1+9**, then **0.2.2+10** (2026-11-23).
6. Phase E. **C4** only if feedback asks.