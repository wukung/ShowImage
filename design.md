# ShowImage — Design Document

> Snapshot of the **current** architecture and behavior for later sessions.
> Update this file when structure, responsibilities, or product constraints change.
>
> Last aligned with: `master` after PR #8 (welcome, sticky fit, icon, comments).
> Repo: https://github.com/wukung/ShowImage

---

## 1. Product intent

| Item | Decision |
|------|----------|
| Product | macOS image viewer (practical v1) |
| UI | Native **AppKit** (Objective-C++) |
| Core logic | **C++17** static library (no AppKit in core) |
| Build | **CMake** ≥ 3.21, produces `ShowImage.app` |
| Formats | System **ImageIO / NSImage** common types only |
| Distribution target | **Mac App Store** (App Sandbox from day one) |
| Min OS | macOS **12.0** |
| Arch | Universal default: `arm64;x86_64` |

**v1 features**

- Startup **welcome screen**: Open File… / Open Folder… (also menus / Finder open)
- Open file / open folder
- Previous / next within a folder (wrap-around)
- Zoom: fit, actual size, in/out (menu, keys, pinch, ⌘+scroll)
- **Sticky Fit to View**: while fit mode is active, window resize re-fits the image
- Full screen (⌃⌘F)
- Status bar: filename, pixel size, zoom % (Fit/Zoom), index

**Explicit non-goals (for now)**

- Editing / export
- Custom third-party decoders (RAW plugins, libvips, etc.)
- SwiftUI / Qt / multi-window document model
- Persisting folder bookmarks across launches (entitlement may exist; not implemented)

---

## 2. Repository layout

```text
ShowImage/
├── CMakeLists.txt              # Root: standards, options, subdirs, bundle hook
├── cmake/ShowImageBundle.cmake # Info.plist + sandbox / Xcode attributes
├── include/showimage/          # Public C++ headers (API boundary)
│   ├── types.hpp
│   ├── supported_formats.hpp
│   └── image_list.hpp
├── lib/                        # showimage_core (static)
│   ├── CMakeLists.txt
│   ├── supported_formats.cpp
│   └── image_list.cpp
├── src/                        # App target ShowImageApp (MACOSX_BUNDLE)
│   ├── CMakeLists.txt
│   ├── main.mm
│   ├── AppDelegate.{h,mm}
│   ├── MainWindowController.{h,mm}
│   ├── ImageCanvasView.{h,mm}
│   ├── ImageLoader.{h,mm}
│   └── SandboxAccess.{h,mm}
├── resources/
│   ├── Info.plist.in
│   └── ShowImage.entitlements
├── design.md                   # This file
├── AGENT.md                    # Agent / contributor rules
└── README.md                   # Build & user-facing notes
```

| Layer | Path | Responsibility |
|-------|------|----------------|
| Public API | `include/showimage/` | Stable C++ surface for core |
| Core | `lib/` | Paths, formats, ordered image list, navigation |
| UI / platform | `src/` | AppKit, ImageIO load, sandbox URL lifetime |
| Packaging | `resources/`, `cmake/` | Bundle ID, entitlements, Info.plist |

---

## 3. Layered architecture

```text
┌──────────────────────────────────────────────────────────┐
│  AppKit UI (src/*.mm)                                    │
│  AppDelegate · MainWindowController · ImageCanvasView    │
│  menus · open panels · first responder · fullscreen      │
├──────────────────────────────────────────────────────────┤
│  Platform adapters                                       │
│  ImageLoader (NSImage / ImageIO)                         │
│  SandboxAccess (security-scoped URLs)                    │
├──────────────────────────────────────────────────────────┤
│  showimage_core (lib/, C++17)                            │
│  ImageList · SupportedFormats · PathString / ImageEntry  │
└──────────────────────────────────────────────────────────┘
```

**Rules of the split**

1. **Core never links AppKit / Foundation.** Paths are UTF-8 `std::string`.
2. **UI owns all sandbox lifetime** (`startAccessingSecurityScopedResource` / stop).
3. **Decoding stays in UI** (`ImageLoader`); core only decides *which file* is current.
4. ObjC++ (`.mm`) is the bridge; keep C++ types behind `#include` in `.mm` files, not in pure ObjC headers if avoidable.

---

## 4. Core library (`showimage_core`)

### 4.1 Types (`types.hpp`)

- `PathString` — UTF-8 path string
- `ImageEntry` — `{ path, fileName }`
- `NavigateDirection` — `Previous = -1`, `Next = 1`

### 4.2 Formats (`supported_formats.*`)

- Extension allow-list aligned with ImageIO on modern macOS (jpg/png/gif/tiff/heic/webp/…).
- Case-insensitive; extension without leading dot.
- `IsSupportedImagePath` used when scanning directories.

### 4.3 ImageList (`image_list.*`)

| Method | Behavior |
|--------|----------|
| `SetSingleFile` | One entry; directory = parent path |
| `ScanDirectory` | List regular files with supported extensions; sort by `fileName` (byte order) |
| `ScanDirectorySelecting` | Scan then select preferred path if present |
| `Navigate` | ±1 with wrap; no-op if size ≤ 1 |
| `Current` / `Index` / `Size` | Read accessors |

**Not in core:** security scope, decoding, EXIF, caching, threading.

---

## 5. UI / app layer

### 5.1 Entry & lifecycle

| Component | Role |
|-----------|------|
| `main.mm` | `NSApplication`, set delegate, `NSApplicationMain` |
| `AppDelegate` | Single `MainWindowController`; main menu; `openURLs` |

**Launch / Open With (bug #1 fix)**

- `didFinishLaunching` creates controller **once**, builds menu, then drains `pendingOpenURLs`.
- `application:openURLs:` **before** launch finishes only **queues** URLs (does not create a throwaway controller).
- After launch: `ensureMainWindowController` + `openURLs:`.

### 5.2 MainWindowController

- Owns window, `ImageCanvasView`, status label, **welcome overlay**, `SandboxAccess`, and a **heap** `showimage::ImageList*` (`new` in `init`, `delete` in `dealloc`).
- **Welcome view** shown when no image is open; buttons call `openDocument:` / `openFolder:`. Hidden after a successful open (or Finder Open With).
- Actions: open file, open folder, prev/next, zoom*, implements `ImageCanvasViewDelegate`.
- `openURLs:`:
  - Directory → `openFolderURL:`
  - File → sandbox start + `SetSingleFile` + best-effort parent `ScanDirectorySelecting` if listable
- Status string: name · WxH · zoom% (Fit|Zoom) · index/total

### 5.3 ImageCanvasView

- Dark `NSScrollView` whose **document** is `SIDocumentContainer` (not the image alone).
- **Center when smaller:** document size = `max(scaledImage, clipView)` per axis; image frame centered (integral origin).
- **Scroll when larger:** overflowing axes grow the document → axis scrollers (`autohidesScrollers`).
- **Zoom scroll:** open / fit / actual-size **re-center**; incremental zoom **preserves** viewport focus on the image.
- **`fitToView` sticky mode:** set by open-with-fit / Zoom to Fit; cleared by zoom in/out, actual size, pinch, ⌘+scroll. While sticky, `layout` re-runs fit so resize keeps Fit to View.
- **Single zoom system:** frame scale via `zoomFactor`; `allowsMagnification = NO`.
- Container / image / scroll view restore canvas first responder on click.
- Keyboard on canvas: arrows, Space/N, P, +/-/0/9. GIF animates.

### 5.4 ImageLoader

- `NSImage` load from file URL; set `size` from ImageIO pixel dimensions when available.
- Synchronous, main-thread today (large files can stall UI — known limitation).

### 5.5 SandboxAccess

- Tracks security-scoped URLs; `stopAll` on replace/dealloc.
- Note: return value currently optimistic for non-nil URLs; parent directory after file open may not be listable under sandbox (documented UX: use **Open Folder…**).

### 5.6 Menus & shortcuts

| Action | Binding |
|--------|---------|
| Open | ⌘O |
| Open Folder | ⇧⌘O |
| Prev / Next | `[` / `]` (arrows via canvas) |
| Zoom in/out/actual/fit | ⌘+ / ⌘- / ⌘0 / ⌘9 |
| Full Screen | **⌃⌘F** (bug #5) |

---

## 6. Build & packaging

### 6.1 Targets

| Target | Type | Notes |
|--------|------|--------|
| `showimage_core` | STATIC | Public include: `include/` |
| `ShowImageApp` | MACOSX_BUNDLE executable | Links core + AppKit, Foundation, ImageIO, CoreGraphics, QuartzCore, UniformTypeIdentifiers |
| Output name | `ShowImage.app` | Under `build/src/` for Ninja/Make |

### 6.2 Options

| CMake option | Default | Meaning |
|--------------|---------|---------|
| `CMAKE_OSX_DEPLOYMENT_TARGET` | `12.0` | Min macOS |
| `CMAKE_OSX_ARCHITECTURES` | `arm64;x86_64` | Universal when not overridden |
| `SHOWIMAGE_ENABLE_SANDBOX` | `ON` | Wire entitlements for Xcode signing |

### 6.3 Bundle identity

Configured in `cmake/ShowImageBundle.cmake` (change before App Store):

- Bundle ID: `com.example.ShowImage` (placeholder)
- Version: project `VERSION` / build `1`
- Category: `public.app-category.photography`
- Document types: `public.image` and common UTIs

### 6.4 Entitlements (`resources/ShowImage.entitlements`)

- `com.apple.security.app-sandbox`
- `com.apple.security.files.user-selected.read-only`
- `com.apple.security.files.bookmarks.app-scope` (reserved; bookmark persistence not implemented)

**Important:** Ninja/Makefile builds do **not** automatically codesign with entitlements. Sandbox is real when signed via **Xcode** (or explicit `codesign --entitlements`). Local `open build/src/ShowImage.app` is typically **unsigned / unsandboxed**.

### 6.5 Build commands

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
open build/src/ShowImage.app

# Signing / App Store workflow
cmake -S . -B build-xcode -G Xcode
open build-xcode/ShowImage.xcodeproj
```

---

## 7. Data / control flow

### Open file

```text
User Open / Finder Open With / Dock drop
  → AppDelegate openURLs (or pending queue)
  → MainWindowController openURLs
  → if directory: openFolderURL
  → else: SandboxAccess + ImageList SetSingleFile
       → optional parent scan if listable
  → ImageLoader → ImageCanvasView setImage:fit
  → status + first responder = canvas
```

### Previous / Next

```text
Menu / key / canvas delegate
  → ImageList::Navigate
  → displayCurrentImage (reload path through ImageLoader)
```

### Zoom

```text
Menu / key / pinch / ⌘+scroll
  → ImageCanvasView applyZoom (frame size = pixels * zoomFactor)
  → delegate imageCanvasViewDidChangeZoom → status refresh
```

---

## 8. Known limitations (carry into next work)

From initial code review (suggestions / nits not all fixed):

1. **Sandbox folder browse** after single-file open is best-effort; **Open Folder…** is the reliable path.
2. ~~No sticky fit-on-resize~~ — **fixed**: sticky `fitToView` mode.
3. **Retina “100%”** is 1 image pixel = 1 point (not device pixel).
4. **Main-thread full decode** — large HEIC/TIFF can freeze UI.
5. **Sort order** is C++ string byte order, not Finder natural sort.
6. **Bundle ID** still `com.example.ShowImage`.
7. **No unit tests** yet for `ImageList` / formats.
8. Open panel content-type filtering is still permissive.

Fixed in PR path `fix/review-bugs-1-5` (issues #1–#5): launch race, directory `openURLs`, first responder, dual zoom, ⌃⌘F.

---

## 9. Extension guide (where to change what)

| Want to… | Prefer touching… |
|----------|------------------|
| Add format extension | `lib/supported_formats.cpp` (+ Info.plist UTIs if needed) |
| Change navigation rules | `lib/image_list.*` |
| Change open / sandbox UX | `MainWindowController.mm`, `SandboxAccess.*` |
| Change zoom / pan / keys | `ImageCanvasView.*` |
| Change decode / downsampling | `ImageLoader.*` |
| Menus / launch | `AppDelegate.mm` |
| Bundle ID / entitlements | `cmake/ShowImageBundle.cmake`, `resources/*` |
| Min OS / languages | Root `CMakeLists.txt` |

---

## 10. Git / project state (session handoff)

| Item | Value |
|------|--------|
| GitHub | `https://github.com/wukung/ShowImage` |
| Account used | `wukung` |
| Issues #1–#5 | **Closed** (fixed in PR #6) |
| PR #6 | Merged `9a969eb` |
| PR #7 | **Merged** `6a93c93` — center image + AGENT review loop |

When this doc drifts from the repo, update **§1–§8** and the “Last aligned with” line at the top.
