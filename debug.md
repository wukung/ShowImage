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
