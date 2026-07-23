# ShowImage

A sandboxed macOS image viewer built with **CMake**, a **C++ core**, and a native **AppKit** (Objective-C++) UI.

## Features (v1)

- Open a single image or an entire folder
- Browse **Previous / Next** within a folder (with wrap-around)
- Zoom: fit, actual size, in/out (menu, `⌘+/-/0/9`, trackpad pinch, `⌘`+scroll)
- Full Screen (`⌃⌘F` / View menu)
- System ImageIO formats: JPEG, PNG, GIF, TIFF, BMP, HEIC/HEIF, WebP, JPEG 2000, and more
- App Sandbox entitlements prepared for **Mac App Store** distribution

## Layout

```text
ShowImage/
├── CMakeLists.txt          # Root project
├── cmake/                  # Bundle / packaging helpers
├── include/showimage/      # Public C++ API headers
├── lib/                    # C++ core (image list, formats)
├── src/                    # AppKit UI (ObjC++)
├── resources/              # Info.plist, entitlements
├── design.md               # Architecture snapshot (keep concise, in sync)
├── AGENT.md                # Project rules for agents / contributors
├── debug.md                # Review/bug findings and fix log
└── README.md
```

| Path | Role |
|------|------|
| `include/showimage/` | Headers consumed by the app and tests |
| `lib/` | Static library `showimage_core` |
| `src/` | `ShowImage.app` executable (MACOSX_BUNDLE) |
| `resources/` | App Store metadata & sandbox entitlements |
| `design.md` | Current design only; remove stale sections |
| `AGENT.md` | Coding / sandbox / Git / review-loop rules |
| `debug.md` | Issues found and modifications made |

## Requirements

- macOS 12.0+
- CMake 3.21+
- Xcode Command Line Tools (Clang with Objective-C++)

## Build

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
open build/src/ShowImage.app
```

Generate an Xcode project (recommended for signing / App Store):

```bash
cmake -S . -B build-xcode -G Xcode
open build-xcode/ShowImage.xcodeproj
```

### Useful options

| Option | Default | Description |
|--------|---------|-------------|
| `CMAKE_OSX_DEPLOYMENT_TARGET` | `12.0` | Minimum macOS |
| `CMAKE_OSX_ARCHITECTURES` | `arm64;x86_64` | Universal binary |
| `SHOWIMAGE_ENABLE_SANDBOX` | `ON` | Attach App Sandbox entitlements |

## Keyboard shortcuts

| Key | Action |
|-----|--------|
| `⌘O` | Open image |
| `⇧⌘O` | Open folder |
| `←` / `→` | Previous / next image |
| `Space` / `N` | Next image |
| `P` | Previous image |
| `⌘+` / `⌘-` | Zoom in / out |
| `⌘0` | Actual size |
| `⌘9` | Zoom to fit |
| `⌃⌘F` | Full Screen (Control-Command-F) |

## App Sandbox notes

Under App Sandbox the app can only read **user-selected** files/folders:

1. **Open…** grants access to that file. Sibling **Previous/Next** works only if the parent directory is also readable (best effort).
2. **Open Folder…** is the reliable way to enable full folder browsing in a sandboxed build.

Entitlements live in `resources/ShowImage.entitlements`.

## App Store checklist

1. Change `BUNDLE_IDENTIFIER` in `cmake/ShowImageBundle.cmake` to your team ID reverse-DNS.
2. Open the Xcode generator project, select your **Team**, enable **Automatically manage signing**.
3. Archive → Upload to App Store Connect.
4. Add an app icon set under `resources/Assets.xcassets` (optional for local runs).
5. Privacy: this viewer does not use camera/mic/location; no extra usage strings required for basic viewing.

## Architecture

```text
┌─────────────────────────────────────────┐
│  AppKit UI (src/*.mm)                   │
│  Window · menus · zoom canvas · open    │
├─────────────────────────────────────────┤
│  ImageLoader (ImageIO / NSImage)        │
│  SandboxAccess (security-scoped URLs)   │
├─────────────────────────────────────────┤
│  showimage_core (lib/, C++17)           │
│  ImageList · SupportedFormats           │
└─────────────────────────────────────────┘
```

The C++ core never links AppKit; the UI owns all sandbox lifetime and decoding.

## License

Add your license here before distribution.
