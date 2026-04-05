# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Cradle is a native macOS terminal app built in Swift. It provides multiple terminal sessions in a single window using native macOS window tabbing, optimized for running multiple Claude Code CLI sessions. Each new tab spawns a shell in a user-configured default directory (no `cd` needed).

## Build Commands

Prerequisites: `brew install xcodegen create-dmg`, Xcode command line tools installed.

```bash
# Generate .xcodeproj from project.yml
xcodegen generate

# Build the app
xcodebuild build \
    -project Cradle.xcodeproj \
    -scheme Cradle \
    -configuration Release \
    -derivedDataPath build \
    CODE_SIGN_IDENTITY="-"

# Run the app
open "build/Build/Products/Release/Cradle.app"

# Full build script (generate + resolve deps + build)
./scripts/build.sh

# Package as .dmg (optional)
create-dmg --volname "Cradle" --app-drop-link 450 190 "Cradle.dmg" "build/Build/Products/Release/Cradle.app"
```

## Architecture

- **Language:** Swift 5.9, **UI:** SwiftUI + AppKit bridging, **Target:** macOS 14.0+
- **Project generation:** XcodeGen (`project.yml` → `.xcodeproj`)
- **Terminal engine:** [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm) via SPM
- **Shell spawning:** POSIX `forkpty()` via `import Darwin`, or SwiftTerm's `LocalProcessTerminalView` if it supports setting `cwd`
- **Bundle ID:** `com.cradleterm.app`
- **Sandbox disabled** — required for `forkpty()` process spawning

### Key Layers

- **App/** — `CradleApp.swift` (`@main` entry, scene definitions) and `AppDelegate.swift` (NSApplicationDelegate for native window tab management via `NSWindow.addTabbedWindow`)
- **Services/** — `PTYService.swift` (forkpty wrapper: spawn/read/write/resize/kill) and `ShellEnvironment.swift` (login shell detection, env vars like `TERM=xterm-256color`)
- **Models/** — `TerminalSession` (one tab's state, owns a PTY), `SessionManager` (tracks all sessions), `Profile` (launch profiles with name/dir/command), `AppSettings` (@AppStorage wrapper)
- **Views/** — `TerminalViewRepresentable` (NSViewRepresentable bridging SwiftTerm into SwiftUI), `TerminalContentView` (main window content), `SettingsView`/`ProfileEditorView` (preferences)

### Core Design Decisions

- **Native macOS tab bar** uses AppKit's `NSWindow.addTabbedWindow` (not SwiftUI tabs). The `AppDelegate` creates `NSWindow` instances with `NSHostingView` content and `tabbingMode = .preferred`.
- **Default directory feature** works by passing `cwd` to `forkpty()`/`chdir()` before `execve()` — the shell starts in the target directory with no visible `cd`.
- **SwiftTerm integration strategy:** Prefer `LocalProcessTerminalView` if it supports `cwd`; fall back to raw `TerminalView` + custom `PTYService` if not. Check SwiftTerm's API at implementation time.
- **Ad-hoc signing** (`CODE_SIGN_IDENTITY="-"`) for local dev. Distribution requires a paid Apple Developer account.

## Implementation Order

Follow `plan.md` steps: skeleton → PTY/shell → terminal view → tab management → settings → profiles → polish. Verify compilation at each checkpoint with `xcodegen generate && xcodebuild build`.
