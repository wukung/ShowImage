
## 2026-07-23 — PR #8 merged

- PR: https://github.com/wukung/ShowImage/pull/8 → **MERGED**
- Welcome screen, sticky Fit to View, app icon, source comments
- Local `master` synced to `origin/master`


# debug.md — Issues & fix log

Running log of **problems found** (reviews, bugs, regressions) and **what was changed**.
Not a design doc — see `design.md` for architecture.

Severity guide (aligns with `AGENT.md` §8):

| Label | Level | Review loop |
|-------|--------|-------------|
| bug / high | high | Must fix; re-review |
| suggestion / medium | medium | Must fix; re-review |
| nit / low | low | Optional in loop |

---

## 2026-07-23 — Feature: welcome screen + sticky Fit to View

### Change

- Startup welcome overlay: Open File… / Open Folder… when no image is open.
- `ImageCanvasView.fitToView`: resize re-fits while mode is active; cleared by manual zoom.
- Status shows `Fit` vs `Zoom`.

### Files

- `src/MainWindowController.mm`, `src/ImageCanvasView.{h,mm}`, `design.md`

### Status

- implemented; review fixes applied (see next section)

---

## 2026-07-23 — Review: welcome + sticky fit (pass 1 → fixes)

| ID | Severity | Summary | Fix | Status |
|----|----------|---------|-----|--------|
| W1 | medium | Fit from `-layout` forced subtree layout + always notified | Re-fit only on size change; no layoutSubtreeIfNeeded in layout; deferred notify | fixed |
| W2 | medium | Welcome buttons duplicate menu key equivalents | Removed button keyEquivalents | fixed |
| W3 | nit | Hard-coded welcome bg | Aligned to canvas 0.12 chrome | fixed |
| W4 | nit | Fit gate checked only width | Require width and height | fixed |

---

## 2026-07-23 — Review: welcome + sticky fit (pass 2 → fix)

| ID | Severity | Summary | Fix | Status |
|----|----------|---------|-----|--------|
| W5 | medium | Fit measured contentView.bounds lagging after resize | Use `scrollView.bounds` / canvas bounds via `fitVisibleSize` | fixed |
| W1–W4 | — | Prior | verified | fixed |

---

## 2026-07-23 — Review: welcome + sticky fit (pass 3 → fixes)

| ID | Severity | Summary | Fix | Status |
|----|----------|---------|-----|--------|
| W6 | medium | Document layout clip also used lagging contentView | `layoutDocument` uses `fitVisibleSize` | fixed |
| W7 | high (bug) | Welcome labels unreadable in Light Mode on dark bg | Force DarkAqua appearance on welcome root | fixed |

---

## 2026-07-23 — Review: welcome + sticky fit (pass 4) — loop exit

Result: **no medium+**. W1–W7 verified. Sticky fit + welcome ready for commit/PR when requested.

---

## 2026-07-23 — PR #8 merged

- PR: https://github.com/wukung/ShowImage/pull/8 → **MERGED**
- Welcome screen, sticky Fit to View, app icon, source comments
- Local `master` synced to `origin/master`

## 2026-07-23 — Comments pass on existing sources

- Added file-level and key-logic comments across `include/`, `lib/`, and `src/`
  (why / contracts / sandbox / zoom layout; English per AGENT §3.3).
- No intentional behavior changes.
- Review: **no medium+** (comment-only, accurate). Loop exit.
- Status: local

---

## 2026-07-23 — App icon

- Generated macOS-style rounded icon (landscape photo in frame on dark glass).
- Assets: `resources/AppIcon-1024.png`, `resources/AppIcon.iconset/`, `resources/ShowImage.icns`
- CMake POST_BUILD copies `ShowImage.icns` into the app bundle; Info.plist `CFBundleIconFile=ShowImage`
- Status: implemented (local)

---

## 2026-07-23 — PR #7 merged

- PR: https://github.com/wukung/ShowImage/pull/7 → **MERGED** (`6a93c93`)
- Center image + axis scrollbars + review-loop AGENT rule on `master`
- Local `master` fast-forwarded to `origin/master`

## 2026-07-23 — PR #6 merged

- PR: https://github.com/wukung/ShowImage/pull/6 → **MERGED** (`9a969eb`)
- Pending review `4761319988` submitted as **COMMENT** (GitHub blocks self-APPROVE)
- Issues **#1–#5** closed by merge
- Local `master` fast-forwarded to match `origin/master`

## 2026-07-23 — Initial code review (f7ec9a6) + fixes (PR #6)

Branch: `fix/review-bugs-1-5` · Commit: `87cedcc` · PR: https://github.com/wukung/ShowImage/pull/6

### Findings → fixes

| ID | Severity | Summary | Location | Fix | Status |
|----|----------|---------|----------|-----|--------|
| R1 / #1 | high (bug) | Finder Open With / launch race replaces controller | `AppDelegate.mm` | Single controller; queue URLs until `didFinishLaunching` | fixed |
| R2 / #2 | high (bug) | `openURLs:` treats directories as files | `MainWindowController.mm` | Route directory URLs to `openFolderURL:` | fixed |
| R3 / #3 | high (bug) | Click steals first responder; keyboard nav dies | `ImageCanvasView.mm` | Host/scroll refuse FR; click restores canvas | fixed |
| R4 / #4 | high (bug) | Dual zoom (frame + magnification) desync | `ImageCanvasView.mm` | Frame-only zoom; forward pinch / ⌘+scroll | fixed |
| R5 / #5 | high (bug) | Full Screen bound to ⌘F | `AppDelegate.mm` | ⌃⌘F modifier mask | fixed |
| R6 | medium | SandboxAccess success return optimistic | `SandboxAccess.mm` | — | open (deferred) |
| R7 | medium | Ninja does not apply entitlements | `cmake/ShowImageBundle.cmake` | — | open (documented) |
| R8 | medium | No sticky fit on resize | `ImageCanvasView.mm` | — | open (deferred) |
| R9 | medium | Retina 100% = point not device pixel | `ImageLoader.mm` | — | open (deferred) |
| R10 | medium | Open panel UTTypes empty / weak filter | `MainWindowController.mm` | — | open (deferred) |
| R11 | medium | FullSizeContentView content under titlebar | `MainWindowController.mm` | — | open (deferred) |
| R12 | medium | Main-thread full decode; large files stall | `ImageLoader.mm` / display path | — | open (deferred) |
| R13–R16 | low (nit) | Unused bookmarks entitlement; deprecated activate; legacy color API; byte sort | various | partial (color API in zoom fix path) | open / partial |

### Notes

- High (bug) items #1–#5 fixed in `87cedcc`; GitHub issues #1–#5 closed on merge of PR #6.
- Medium items left open intentionally for later work; re-review after that PR should still target **no new medium+** on the fix diff.
- When the next full review runs, append a new dated section rather than rewriting this one.

---

## 2026-07-23 — PR #6 review (pass 1) + fixes

PR: https://github.com/wukung/ShowImage/pull/6  
Reviewed commit: `87cedcc` · PENDING review id: `4761319988`  
Submit UI: https://github.com/wukung/ShowImage/pull/6/files

### Findings → fixes

| ID | Severity | Summary | Location | Fix | Status |
|----|----------|---------|----------|-----|--------|
| P6-1 | high (bug) | ⌘+scroll infinite recurse when delta small/zero | `ImageCanvasView.mm` `scrollWheel:` | Always consume Command+scroll; never re-enter scroll view | fixed (local) |
| P6-2 | medium | Directory probe before security scope may fail under sandbox | `MainWindowController.mm` `openURLs:` | `startAccessingURL` before `NSURLIsDirectoryKey` | fixed (local) |
| P6-3 | medium | Pre-launch pending URLs last-write-wins | `AppDelegate.mm` | Append to `NSMutableArray` | fixed (local) |
| P6-4 | low (nit) | Full Screen menu title never “Exit…” | `AppDelegate.mm` | deferred | open |

### Notes

- Pass 1 verdict: #1–#5 intent OK; merge blocked by P6-1 recursion.
- Re-review required after push (AGENT §8) until no medium+.
- Local branch also has docs commit `9cc1c47` (design/AGENT/debug) not yet on PR at review time.

---

## 2026-07-23 — PR #6 review (pass 2) + fix

Reviewed commit: `43b5b7c`

### Findings → fixes

| ID | Severity | Summary | Location | Fix | Status |
|----|----------|---------|----------|-----|--------|
| P6-1..3 | — | Prior medium+ | — | verified fixed in pass 2 | fixed |
| P6-5 | high (bug) | Non-Command wheel: canvas → scrollView → nextResponder canvas loop | `ImageCanvasView.mm` | non-Command uses `[super scrollWheel:]` only | fixed (local) |
| P6-4 | low (nit) | Full Screen menu title | `AppDelegate.mm` | deferred | open |

### Notes

- Pass 2 closed P6-1..3; new P6-5 found on non-Command path.
- Pass 3 re-review after push of P6-5.

---

## 2026-07-23 — PR #6 review (pass 3) — loop exit

Reviewed commit: `3095982`  
Result: **no medium or higher findings**. Residual: P6-4 nit only.

| Prior | Status |
|-------|--------|
| P6-1 Command scroll recurse | fixed (verified) |
| P6-2 Directory probe vs scope | fixed (verified) |
| P6-3 Pending URL append | fixed (verified) |
| P6-5 Non-Command scroll re-entry | fixed (verified) |
| P6-4 Full Screen title | open (nit, deferred) |

AGENT §8 review loop for PR #6: **complete**.

---

## 2026-07-23 — Feature: center image + axis scrollbars

### Change

- **Request:** Image centered in the view; show scrollbars only on axes that overflow the window.
- **Implementation:** `ImageCanvasView` uses `SIDocumentContainer` as `documentView`. Document size is `max(scaled image, clip)` per axis; `imageView` centered inside. Resize clamps scroll.
- **Files:** `src/ImageCanvasView.mm`, `MainWindowController.mm` (status non-selectable), `design.md` §5.3
- **Status:** implemented (local)

### Notes

- Zoom-to-fit still fits entirely inside the clip (no bars at fit).
- Scrollbars use `autohidesScrollers` (visible when content exceeds).

---

## 2026-07-23 — Code review: center image layout (pass 1 → fixes)

### Findings → fixes

| ID | Severity | Summary | Fix | Status |
|----|----------|---------|-----|--------|
| C1 | medium | `applyZoom` always re-centers; pan lost on zoom | Incremental zoom uses `SIDocScrollPreserveVisibleCenter`; fit/actual/open use Center | fixed |
| C2 | medium | Padding clicks don’t restore first responder | `SIDocumentContainer` + `statusLabel.selectable = NO` | fixed |
| C3 | low | Non-integral image origin | `floor` on center origin | fixed |
| C4 | low | Nil image leaves stale scroll origin | Reset bounds origin + reflect | fixed |

### Notes

- Re-review required until no medium+.

---

## 2026-07-23 — Code review: center image layout (pass 2) — loop exit

Result: **no medium+**. C1–C4 verified fixed.

| Residual | Severity | Notes |
|----------|----------|--------|
| Non-integral pan origin after preserve zoom | nit | Optional floor on preserve/clamp origins |

AGENT §8 review loop for center-layout change: **complete**.

---

## Template (copy for new entries)

```markdown
## YYYY-MM-DD — <context: review / bug / PR #N>

### Findings → fixes

| ID | Severity | Summary | Location | Fix | Status |
|----|----------|---------|----------|-----|--------|
| | | | | | open / fixed |

### Notes

-
```
