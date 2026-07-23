# AGENT.md — Rules for ShowImage

Instructions for AI agents and humans working on this repository.
Read **`design.md`** first for architecture; this file is **policy**, not design narrative.

---

## 0. Always read before coding

1. `design.md` — current architecture, layers, known limitations  
2. This file — constraints and workflow  
3. `README.md` — build commands and user-facing behavior  
4. `debug.md` — known issues and fix history (if present)

Do not invent a second architecture that contradicts those docs without an explicit user decision.

---

## 1. Product constraints (locked unless user changes them)

| Rule | Detail |
|------|--------|
| Platform | **macOS only** for this product |
| UI toolkit | **AppKit** (Objective-C++). Do not switch to SwiftUI/Qt/SDL without asking |
| Core language | **C++17** in `lib/` + `include/` |
| UI language | **Objective-C++** (`.mm`) in `src/` |
| Build system | **CMake** (keep working for Ninja/Make **and** Xcode generator) |
| Image formats | Prefer **system ImageIO / NSImage**; no heavy third-party decoder deps unless requested |
| Distribution | Assume **App Store + App Sandbox**; do not remove sandbox entitlements casually |
| Min OS | **macOS 12.0** (`CMAKE_OSX_DEPLOYMENT_TARGET`) unless user raises/lowers it |

---

## 2. Architecture rules

### 2.1 Layering

- **`lib/` / `include/showimage/`** must stay free of AppKit, Foundation, and Objective-C.
- Path strings at the C++ boundary are **UTF-8** `std::string` (`PathString`).
- **Sandbox / security-scoped URLs** live only in UI (`SandboxAccess`, controllers).
- **Decoding** lives in UI (`ImageLoader`), not in `ImageList`.
- Prefer small, focused files; match existing names (`MainWindowController`, `ImageCanvasView`, …).

### 2.2 Directory placement

| Kind of change | Put it in |
|----------------|-----------|
| Portable logic, lists, format checks | `lib/` + headers in `include/showimage/` |
| Windows, menus, views, open panels | `src/` |
| Bundle ID, entitlements, Info.plist | `resources/` + `cmake/` |
| User-facing build docs | `README.md` |
| Architecture snapshot | `design.md` (keep concise; update when structure changes) |
| Process / policy | `AGENT.md` (this file) |
| Issues / fix log | `debug.md` |

Do not dump random sources at repo root.

### 2.3 Zoom & input (current contract)

- **One zoom system only**: frame-based `zoomFactor` on the image document view.
- Do **not** re-enable `NSScrollView.allowsMagnification` alongside frame zoom (caused desync — issue #4).
- Keyboard navigation must still work **after clicking the image** (first responder on canvas — issue #3).
- Full Screen shortcut is **⌃⌘F**, not ⌘F (issue #5).

### 2.4 Launch / open URLs

- Exactly **one** main window controller for the app lifecycle.
- URLs arriving before `applicationDidFinishLaunching` must be **queued**, not create a throwaway controller (issue #1).
- Directory URLs in `openURLs:` must open as folders (issue #2).

---

## 3. Coding standards

### 3.1 C++

- C++17, no compiler extensions required for core.
- Headers under `include/showimage/` use `#pragma once` and namespace `showimage`.
- Prefer clear names over clever templates; keep the core testable without UI.
- Handle filesystem errors with `std::error_code` where used (see `image_list.cpp`).

### 3.2 Objective-C++

- Enable **ARC** (`-fobjc-arc`).
- Avoid `typeof(self)` for weak captures in `.mm` (use explicit class type).
- If C++ objects are owned by ObjC, document ownership (`new`/`delete` in `init`/`dealloc` as today).
- Do not put non-POD C++ members in ObjC `@interface` without care; current style uses a pointer to `ImageList`.

### 3.3 General

- Match existing style (2-space indent in these sources, English identifiers/comments).
- No drive-by refactors unrelated to the task.
- No secrets, signing certs, or API keys in the tree.
- Do not commit `build/`, Xcode user state, or DerivedData (see `.gitignore`).

---

## 4. Build & verify

After non-trivial edits, **build must pass**:

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
```

For App Store / entitlements validation, prefer:

```bash
cmake -S . -B build-xcode -G Xcode
```

Remind the user that **sandbox only applies when the app is signed with entitlements** (Xcode or `codesign`).

---

## 5. Sandbox & App Store

- Keep user data access via **Open panels / user-selected** files unless a new entitlement is explicitly required.
- **Open Folder…** is the supported way to enable Previous/Next under sandbox; do not “fix” this by requesting broad file access.
- Do not add camera/mic/location entitlements without product need and privacy strings.
- Before release: replace `com.example.ShowImage` with a real bundle ID (see `cmake/ShowImageBundle.cmake`).

---

## 6. Git & GitHub workflow

- Remote: `https://github.com/wukung/ShowImage` (owner **wukung**).
- Prefer **feature branches** + PRs for non-trivial work; link issues with `Closes #N` when fixing tickets.
- Commit messages: concise, imperative, focus on *why*.
- Do **not** force-push `master` / rewrite published history unless the user explicitly asks.
- Do **not** skip hooks (`--no-verify`) unless the user explicitly asks.
- Do not push or open PRs unless the user asked for remote/GitHub actions (this session already connected `gh` as `wukung`).

### 6.1 After a PR is accepted / merged

When source code lands on the default branch (PR merge or equivalent accept):

1. **Mandatory:** Confirm **`design.md` matches the merged source**. Diff mental model vs tree; update or delete stale sections.
2. Confirm **`debug.md`** records the issues fixed in that PR (if any) and the resolution.
3. Do not consider the work “done” while `design.md` still describes pre-merge behavior.

---

## 7. Documentation duty

### 7.1 `design.md` — keep in sync and concise

- After any structural or behavior change (and **always after PR accept**, see §6.1), update `design.md` so it describes **current** code only.
- **Keep `design.md` short.** Prefer tables, bullet lists, and short contracts over long prose.
- **Remove outdated sections** as soon as they no longer match the code. Do not leave “historical” design in `design.md` (history belongs in git / `debug.md`).
- **Especially important** points may stay, but as **brief** statements (what/why one line), not essays.
- Touch `README.md` only when user-facing build steps or shortcuts change.
- Update **this file** only when policy/rules change.

### 7.2 `debug.md` — issues and fix log

- Record **discovered problems** and **modifications** in **`debug.md`** (create the file if missing).
- Log at least: date or commit, severity, summary, where (file), what changed, status (`open` / `fixed`).
- Use `debug.md` for review findings, bugfix notes, and post-fix verification — **not** as a second design doc.
- When a review finds issues, append them **before** fixing; after fixes, mark entries fixed and note the fix commit/PR if known.

---

## 8. Code review loop (required)

### 8.1 When the loop is mandatory

**After coding finishes for any feature add or modification (i.e. program source changed), always run the review → fix → re-review loop** without waiting for the user to say “review”.

Triggers include (non-exhaustive):

- New feature or behavior change in `src/`, `lib/`, `include/`, or related app packaging that affects runtime
- Bug fixes that change logic (not pure comment-only or whitespace-only edits)
- Follow-up fixes from a previous review pass (each fix batch still ends with re-review)

Also run the loop when the user **explicitly** asks for a review (local / branch / PR).

**Does not** require the full loop by itself:

- Docs-only edits (`design.md`, `AGENT.md`, `debug.md`, `README.md`) with **no** source change — still keep docs accurate
- Pure formatting / rename with no behavior change *if* trivial; when unsure, run the loop

Do **not** treat “coding done” as the end of the task while medium+ review findings remain open.

### 8.2 Loop steps

1. Finish implementation and ensure **build succeeds**.
2. **Start review** (local changes, branch, or PR as appropriate) — default: review the diff just produced.
3. Map severities:
   - Treat skill labels **`bug` → high**, **`suggestion` → medium**, **`nit` → low** (unless the review text says otherwise).
   - **Medium or higher** means: `bug` / high, and `suggestion` / medium.
4. **If any medium-or-higher issue remains:**
   - Append findings to **`debug.md`**
   - Fix the issues
   - Log the fix in **`debug.md`**
   - **Re-run review** on the updated code
5. **Repeat** steps 3–4 until a review pass finds **no medium or higher** issues.
6. Nits / low-severity items may be fixed in the same loop or deferred; they do **not** by themselves require another full cycle unless the user wants a clean slate.
7. After the loop exits cleanly, ensure **`design.md`** still matches the fixed code (and stays concise per §7.1).

### 8.3 Order of work

```text
implement → build → review → (fix → re-review)* → design.md sync → then commit/PR only if user asked
```

Do not declare “feature done” or “review done” while medium+ findings are still open.

---

## 9. What not to do

- Do not add Swift as the primary UI without an explicit decision (CMake + AppKit ObjC++ is the stack).
- Do not pull large dependencies for formats already handled by ImageIO.
- Do not implement malware, bypass sandbox for convenience, or disable security entitlements “to make listing folders easier.”
- Do not expand into a photo editor unless requested.
- Do not generate or commit large binary fixtures/assets unless requested.
- Do not let `design.md` accumulate obsolete design; delete or rewrite, do not stack contradictions.
- Do not end a review cycle with open **medium+** issues.
- Do not skip the review→fix→re-review loop after source code changed for a feature add/modify (§8.1).

---

## 10. Suggested task checklist

```text
[ ] Read design.md + AGENT.md + debug.md
[ ] Confirm change belongs in lib vs src vs resources
[ ] Implement minimal diff for the request
[ ] cmake --build succeeds
[ ] Manual smoke: open file, open folder, prev/next, zoom, fullscreen
[ ] After any source change: start review → fix → re-review until no medium+
[ ] Log issues/fixes in debug.md during the review loop
[ ] Keep design.md in sync and concise (remove stale parts)
[ ] After PR merge: re-check design.md vs source
[ ] Commit / PR only if user asked
```

---

## 11. Open follow-ups (not blockers; do not fix unless asked)

See `design.md` §8. High-value candidates:

- Async / downsampled image load for large files  
- Sticky zoom-to-fit on window resize  
- Retina-true 100% zoom  
- Finder-like natural sort  
- Real bundle ID + icon + Xcode signing docs  
- Unit tests for `ImageList` / format helpers  
- Security-scoped bookmark restore for last folder  
