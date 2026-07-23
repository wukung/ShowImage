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
