# Cradle

A native macOS terminal app built in Swift, optimized for running multiple [Claude Code](https://claude.ai/code) CLI sessions. Each tab spawns a shell in a configurable default directory — no `cd` needed.

The name is inspired by the Cradle from Westworld — the simulation environment where consciousness runs. Here, it's where your terminal sessions live.

![macOS 14.0+](https://img.shields.io/badge/macOS-14.0%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)
[![Build & Release](https://github.com/sappkevin/cradle-terminal/actions/workflows/build-release.yml/badge.svg)](https://github.com/sappkevin/cradle-terminal/actions/workflows/build-release.yml)
[![Latest Release](https://img.shields.io/github/v/release/sappkevin/cradle-terminal)](https://github.com/sappkevin/cradle-terminal/releases/latest)

## Download

Download the latest `.dmg` from the [Releases page](https://github.com/sappkevin/cradle-terminal/releases/latest).

> **Note:** The app is ad-hoc signed. On first launch, macOS will warn about an unidentified developer — go to **System Settings > Privacy & Security** and click **Open Anyway**.

## Features

- **Native macOS tabs** — uses AppKit's `NSWindow.addTabbedWindow` for real OS-level tab bar with "+" button
- **Default directory** — every new tab starts in your configured directory (set via Settings)
- **Auto-run command** — automatically execute a command (e.g. `claude`) when a tab opens
- **Launch profiles** — save named profiles with directory + command combos for quick access
- **Dynamic window titles** — shows terminal title and size (e.g. `user@host:~ — 80x24`), just like Terminal.app
- **Full terminal emulation** — powered by [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm) with 256-color support and native macOS colors

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `Cmd+T` | New tab |
| `Cmd+Shift+T` | New Claude tab |
| `Cmd+W` | Close tab |
| `Cmd+Shift+[` | Previous tab |
| `Cmd+Shift+]` | Next tab |
| `Cmd+,` | Settings |

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode (with command line tools)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Build & Run

```bash
# Clone the repo
git clone https://github.com/sappkevin/cradle-terminal.git
cd cradle-terminal

# Install XcodeGen if you haven't
brew install xcodegen

# Build and run
./scripts/build.sh
open build/Build/Products/Release/Cradle.app
```

Or step by step:

```bash
xcodegen generate
xcodebuild build \
    -project Cradle.xcodeproj \
    -scheme Cradle \
    -configuration Release \
    -derivedDataPath build \
    CODE_SIGN_IDENTITY="-"
open build/Build/Products/Release/Cradle.app
```

## Package as DMG

```bash
brew install create-dmg
create-dmg --volname "Cradle" --app-drop-link 450 190 \
    "Cradle.dmg" "build/Build/Products/Release/Cradle.app"
```

## Install on Another Mac

Transfer `Cradle.app` or `Cradle.dmg` to the target machine. On first launch, macOS will warn about an unidentified developer — go to **System Settings > Privacy & Security** and click **Open Anyway**. Requires macOS 14.0+.

## Architecture

```
Cradle/
├── App/
│   ├── main.swift                    # Pure AppKit entry point
│   └── AppDelegate.swift             # Window/tab management, menus
├── Models/
│   ├── TerminalSession.swift         # Per-tab state, window title updates
│   ├── SessionManager.swift          # Tracks all active sessions
│   ├── Profile.swift                 # Launch profiles (name, dir, command)
│   └── AppSettings.swift             # UserDefaults-backed preferences
├── Views/
│   ├── TerminalViewRepresentable.swift  # Bridges SwiftTerm into SwiftUI
│   ├── TerminalContentView.swift     # Main terminal view per tab
│   ├── SettingsView.swift            # Preferences (General + Profiles tabs)
│   └── ProfileEditorView.swift       # Add/edit launch profiles
└── Services/
    └── ShellEnvironment.swift        # Login shell detection, env vars
```

**Key design decisions:**

- **Pure AppKit lifecycle** (`main.swift` + `NSApplication.shared.run()`) instead of SwiftUI's `App` protocol — required for native tab bar management without window ownership conflicts
- **SwiftTerm's `LocalProcessTerminalView`** handles PTY, process spawning, and terminal rendering — no custom `forkpty()` wrapper needed (KISS)
- **Default directory** works by passing `currentDirectory` to SwiftTerm's `startProcess()` — the shell starts there with no visible `cd`
- **Ad-hoc code signing** (`CODE_SIGN_IDENTITY="-"`) for local dev; distribution requires a paid Apple Developer account

## Configuration

Open **Settings** (`Cmd+,`) to configure:

- **Default Directory** — where new tabs open (defaults to home directory)
- **Shell** — leave empty to auto-detect, or specify a path (e.g. `/bin/zsh`)
- **Auto-run Command** — command to run on tab open (e.g. `claude`)
- **Font Size** — terminal font size (10–24pt)
- **Profiles** — saved name + directory + command combos, accessible from Shell menu

## License

MIT
