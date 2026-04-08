# Cradle

A native macOS terminal app built in Swift, optimized for running multiple [Claude Code](https://claude.ai/code) CLI sessions. Each tab spawns a shell in a configurable default directory — no `cd` needed.

The name is inspired by the Cradle from Westworld — the simulation environment where consciousness runs. Here, it's where your terminal sessions live.

![macOS 14.0+](https://img.shields.io/badge/macOS-14.0%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)
[![Build & Release](https://github.com/sappkevin/cradle-terminal/actions/workflows/build-release.yml/badge.svg)](https://github.com/sappkevin/cradle-terminal/actions/workflows/build-release.yml)
[![Latest Release](https://img.shields.io/github/v/release/sappkevin/cradle-terminal)](https://github.com/sappkevin/cradle-terminal/releases/latest)

## Download

Download the latest `.dmg` from the [Releases page](https://github.com/sappkevin/cradle-terminal/releases/latest). Releases are signed with a Developer ID certificate and notarized by Apple, so they install without Gatekeeper warnings.

See [CHANGES.md](CHANGES.md) for release notes.

## Features

### Terminal basics
- **Native macOS tabs** — uses AppKit's `NSWindow.addTabbedWindow` for real OS-level tab bar with "+" button
- **Default directory** — every new tab starts in your configured directory
- **Auto-run command** — automatically execute a command (e.g. `claude`) when a tab opens
- **Launch profiles** — save named profiles with directory + command combos
- **Dynamic window titles** — shows terminal title and size (e.g. `user@host:~ — 80x24`)
- **Full terminal emulation** — [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm), 256 colors, native macOS colors
- **Text selection** — click+drag selects, ⌘C copies. Disable per-tab mouse reporting for TUIs in Settings.
- **Clickable URLs** — hover highlights URLs, plain-click opens them in the default browser
- **Appearance picker** — System / Light / Dark in Settings → General

### Shell integration (iTerm2-style)
- **OSC 133 prompt marks** — Cradle tracks every command's start, end, exit code, and cwd
- **OSC 7 cwd tracking** — current directory follows the shell, even after `cd`
- **`copyfile` / `pastefile`** — wrap `scp -r` with glob support so you don't have to remember scp syntax
- **Inline autosuggestions** — fish-style ghost text in zsh (via bundled `zsh-autosuggestions` hook)
- One-click install from **Settings → Features → Install Shell Integration…**

### Instant Replay
- **Time-indexed scrollback** — every byte from the PTY is recorded into a size-capped ring buffer
- **Command-anchored scrubber** — jump between previous commands with `⌘⇧R`
- **Export** to **Markdown** (default), plain text, or JSON (`⌘E` inside the replay view)
- **Generate Documentation with Claude** — pipe the transcript through the `claude` CLI and get back a Markdown runbook (summary, prerequisites, steps, troubleshooting)

### AI Prompt Inspector
- Right-sidebar panel that shells out to the `claude` CLI for:
  - **Improve** — rewrite a prompt to be clearer and more structured
  - **Evaluate** — score on clarity, specificity, hallucination resistance, consistency
  - **Reduce hallucinations** — add factual-accuracy guardrails
  - **Increase consistency** — constrain output for deterministic responses
- Copy results or send straight to the active terminal

### Per-feature toggles
Every major feature above is gated by a toggle in **Settings → Features**, including a master switch for shell integration, instant replay, replay export, doc generation, AI inspector, copyfile helpers, and inline autosuggestions. Disabling a feature avoids spinning up its services entirely.

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `Cmd+T` | New tab |
| `Cmd+Shift+T` | New Claude tab |
| `Cmd+W` | Close tab |
| `Cmd+Shift+[` | Previous tab |
| `Cmd+Shift+]` | Next tab |
| `Cmd+,` | Settings |
| `Cmd+Shift+R` | Open Instant Replay |
| `Cmd+E` | Export replay (inside Replay view) |

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

**General tab**
- **Default Directory**, **Shell**, **Auto-run Command**, **Font Size**

**Features tab**
- **AI Prompt Inspector sidebar** + **Claude CLI path** (auto-detected if blank)
- **Generate documentation from replays**
- **Shell integration** (OSC 133/7 command + cwd tracking) + **Install Shell Integration…** button
- **copyfile / pastefile helpers**
- **Inline autosuggestions** (zsh ghost text)
- **Instant replay** + **Allow exporting replays** + **Buffer size (MB)**

**Profiles tab**
- Saved name + directory + command combos, accessible from the Shell menu

### Installing shell integration
Click **Settings → Features → Install Shell Integration…** to copy `cradle.zsh` / `cradle.bash` / `cradle.fish` into `~/.config/cradle/`. Then add one line to your rc file:

```bash
# ~/.zshrc
[[ -f ~/.config/cradle/cradle.zsh ]] && source ~/.config/cradle/cradle.zsh
```

After sourcing, every command you run will be tracked with cwd + exit code, replay anchors will land at command boundaries, and `copyfile foo.txt user@host:~/` will Just Work.

## License

MIT
