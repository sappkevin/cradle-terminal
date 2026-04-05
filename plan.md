# Cradle — Build Plan for Claude Code

## Overview

Build a native macOS terminal app called "Cradle" in Swift. The app opens multiple terminal sessions in a single window using a tab bar with a "+" button. Each new tab spawns a shell in a user-configured default directory, optimized for running multiple Claude Code CLI sessions without needing to `cd` each time.

The name is inspired by the Cradle from Westworld — the simulation environment where consciousness runs. Here, it's where your terminal sessions live.

---

## Bootstrap vs From Scratch — Decision

**Use XcodeGen to bootstrap.**

Rationale: Xcode `.xcodeproj` files are complex binary-ish plists that are extremely difficult to write by hand. XcodeGen lets you define the project in a simple `project.yml` file, then generates the `.xcodeproj` automatically. This is the standard approach for CLI-driven macOS/iOS project creation and is used in production by large teams. The alternative — writing raw `.pbxproj` XML — is fragile, error-prone, and wastes tokens on boilerplate that XcodeGen handles perfectly.

The workflow is:
1. Install XcodeGen via Homebrew
2. Write all Swift source files and a `project.yml`
3. Run `xcodegen generate` to create the `.xcodeproj`
4. Run `xcodebuild` to compile
5. Package into a `.app` bundle (xcodebuild does this automatically)

No manual Xcode GUI interaction is needed at any point.

---

## Prerequisites

Run these first:

```bash
# Install XcodeGen (generates .xcodeproj from YAML)
brew install xcodegen

# Install create-dmg (packages .app into .dmg for distribution)
brew install create-dmg

# Verify Xcode command line tools
xcode-select --print-path
# Should return something like /Applications/Xcode.app/Contents/Developer
# If not: xcode-select --install
```

---

## Project Root

Create all files under a single project directory:

```
~/Developer/Cradle/
```

---

## File Manifest

Every file Claude Code needs to create, in order:

```
Cradle/
├── project.yml                              # XcodeGen project definition
├── Cradle/
│   ├── Info.plist                            # App metadata
│   ├── Cradle.entitlements                   # No sandbox (needed for forkpty)
│   ├── Assets.xcassets/
│   │   ├── Contents.json                     # Asset catalog root
│   │   └── AppIcon.appiconset/
│   │       └── Contents.json                # App icon placeholder
│   ├── App/
│   │   ├── CradleApp.swift                  # @main entry, Scene definitions
│   │   └── AppDelegate.swift                # NSApplicationDelegate, tab management
│   ├── Models/
│   │   ├── TerminalSession.swift            # Owns a PTYService + state for one tab
│   │   ├── SessionManager.swift             # Tracks all active sessions
│   │   ├── Profile.swift                    # Launch profile (name, dir, command)
│   │   └── AppSettings.swift                # @AppStorage / UserDefaults wrapper
│   ├── Views/
│   │   ├── TerminalContentView.swift        # Main window content view
│   │   ├── TerminalViewRepresentable.swift  # NSViewRepresentable wrapping SwiftTerm
│   │   ├── SettingsView.swift               # Preferences pane (Cmd+,)
│   │   └── ProfileEditorView.swift          # Add/edit launch profiles
│   └── Services/
│       ├── PTYService.swift                 # forkpty() wrapper — spawn, read, write, resize, kill
│       └── ShellEnvironment.swift           # Detects user's login shell and PATH
└── scripts/
    └── build.sh                             # Build + package script
```

---

## File-by-File Specifications

### 1. `project.yml` (XcodeGen project definition)

```yaml
name: Cradle
options:
  bundleIdPrefix: com.cradleterm
  deploymentTarget:
    macOS: "14.0"
  xcodeVersion: "15.0"
  generateEmptyDirectories: true

settings:
  base:
    PRODUCT_NAME: Cradle
    MARKETING_VERSION: "1.0.0"
    CURRENT_PROJECT_VERSION: "1"
    SWIFT_VERSION: "5.9"
    MACOSX_DEPLOYMENT_TARGET: "14.0"
    CODE_SIGN_IDENTITY: "-"
    CODE_SIGN_STYLE: Automatic
    PRODUCT_BUNDLE_IDENTIFIER: com.cradleterm.app

packages:
  SwiftTerm:
    url: https://github.com/migueldeicaza/SwiftTerm.git
    from: "1.0.0"

targets:
  Cradle:
    type: application
    platform: macOS
    sources:
      - Cradle
    settings:
      base:
        INFOPLIST_FILE: Cradle/Info.plist
        CODE_SIGN_ENTITLEMENTS: Cradle/Cradle.entitlements
        ENABLE_HARDENED_RUNTIME: true
    dependencies:
      - package: SwiftTerm
    entitlements:
      path: Cradle/Cradle.entitlements
```

**Important:** After creating this file, run `xcodegen generate` to produce `Cradle.xcodeproj`. The SwiftTerm package will be resolved automatically by xcodebuild on first build.

### 2. `Cradle/Info.plist`

Standard macOS app plist. Must include:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Cradle</string>
    <key>CFBundleDisplayName</key>
    <string>Cradle</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleVersion</key>
    <string>$(CURRENT_PROJECT_VERSION)</string>
    <key>CFBundleShortVersionString</key>
    <string>$(MARKETING_VERSION)</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>LSMinimumSystemVersion</key>
    <string>$(MACOSX_DEPLOYMENT_TARGET)</string>
    <key>NSMainStoryboardFile</key>
    <string></string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>LSUIElement</key>
    <false/>
</dict>
</plist>
```

### 3. `Cradle/Cradle.entitlements`

Terminal apps cannot run in the App Store sandbox because `forkpty()` requires unrestricted process spawning. Disable sandbox:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
</dict>
</plist>
```

### 4. `Cradle/Assets.xcassets/Contents.json`

```json
{
  "info": {
    "version": 1,
    "author": "xcode"
  }
}
```

### 5. `Cradle/Assets.xcassets/AppIcon.appiconset/Contents.json`

Empty icon set (app will build without an icon — can add one later):

```json
{
  "images": [
    { "idiom": "mac", "scale": "1x", "size": "16x16" },
    { "idiom": "mac", "scale": "2x", "size": "16x16" },
    { "idiom": "mac", "scale": "1x", "size": "32x32" },
    { "idiom": "mac", "scale": "2x", "size": "32x32" },
    { "idiom": "mac", "scale": "1x", "size": "128x128" },
    { "idiom": "mac", "scale": "2x", "size": "128x128" },
    { "idiom": "mac", "scale": "1x", "size": "256x256" },
    { "idiom": "mac", "scale": "2x", "size": "256x256" },
    { "idiom": "mac", "scale": "1x", "size": "512x512" },
    { "idiom": "mac", "scale": "2x", "size": "512x512" }
  ],
  "info": { "version": 1, "author": "xcode" }
}
```

---

### 6. `Cradle/Services/PTYService.swift`

This is the most critical file. It wraps the POSIX `forkpty()` call to spawn a real shell process and provides read/write/resize/kill operations.

**Requirements:**
- `spawn(shell:arguments:cwd:size:)` — calls `forkpty()`, then in the child process calls `chdir(cwd)` before `execve(shell)`. The `cwd` parameter is how the default directory feature works — the shell starts there with no visible `cd`.
- After fork, the parent process must start a background `DispatchIO` or `Thread` that continuously reads from `masterFD` and calls an `onData: (Data) -> Void` callback with the output bytes.
- `write(_ data: Data)` — writes keystrokes to `masterFD` using `Darwin.write()`.
- `resize(cols:rows:)` — sends `TIOCSWINSZ` ioctl to `masterFD`.
- `terminate()` — sends `SIGTERM` to `childPID`, then closes `masterFD`.
- Must `import Darwin` for POSIX APIs. The `forkpty` function is in `<util.h>` — in Swift, it's available via Darwin.
- Store `masterFD: Int32` and `childPID: pid_t` as instance properties.
- Must handle the case where the child process exits (detect via read returning 0 or SIGCHLD). Notify the session so the tab can show "[Process exited]" or auto-close.

**Read loop pattern:**

```swift
// After successful fork, on a background queue:
DispatchQueue.global(qos: .userInteractive).async {
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 4096)
    defer { buffer.deallocate() }
    while true {
        let bytesRead = read(self.masterFD, buffer, 4096)
        if bytesRead <= 0 { break }
        let data = Data(bytes: buffer, count: bytesRead)
        DispatchQueue.main.async {
            self.onData?(data)
        }
    }
    // Process exited
    DispatchQueue.main.async {
        self.onExit?()
    }
}
```

### 7. `Cradle/Services/ShellEnvironment.swift`

Utility to detect the user's default login shell and construct a clean environment.

**Requirements:**
- Function `defaultShell() -> String` — reads from `UserDefaults` first, falls back to the `SHELL` environment variable, falls back to `/bin/zsh`.
- Function `shellEnvironment() -> [String: String]` — returns `ProcessInfo.processInfo.environment` merged with `TERM=xterm-256color` and `LANG=en_US.UTF-8` (SwiftTerm needs these).

### 8. `Cradle/Models/TerminalSession.swift`

Represents one terminal tab's state.

**Requirements:**
- `class TerminalSession: ObservableObject, Identifiable`
- Properties: `id: UUID`, `title: String` (tab title), `isRunning: Bool`, `pty: PTYService`
- `onOutput: ((Data) -> Void)?` — callback wired to SwiftTerm's `feed()` method
- `init(cwd: String, shell: String, command: String?)` — creates a PTYService, spawns the shell, sets up the read loop. If `command` is non-nil and non-empty, after a short delay (0.5s) writes `command + "\n"` to the PTY to auto-run it (e.g., `claude`).
- `deinit` — calls `pty.terminate()`

### 9. `Cradle/Models/SessionManager.swift`

Tracks all active sessions across tabs.

**Requirements:**
- `class SessionManager: ObservableObject`
- `@Published var sessions: [TerminalSession] = []`
- `@Published var activeSessionID: UUID?`
- `func createSession(cwd: String, shell: String, command: String?) -> TerminalSession` — creates a new session, appends to `sessions`, sets it as active.
- `func closeSession(id: UUID)` — terminates the PTY, removes from `sessions`.
- `var activeSession: TerminalSession?` — computed property.

### 10. `Cradle/Models/Profile.swift`

```swift
struct Profile: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String           // e.g. "Claude Code"
    var directory: String      // e.g. "/Users/ke/claude-projects"
    var command: String?       // e.g. "claude" — auto-runs on tab open
}
```

### 11. `Cradle/Models/AppSettings.swift`

**Requirements:**
- `class AppSettings: ObservableObject`
- `@AppStorage("defaultDirectory") var defaultDirectory: String = NSHomeDirectory()`
- `@AppStorage("defaultShell") var shell: String = ""` (empty = auto-detect)
- `@AppStorage("fontSize") var fontSize: Double = 14`
- `@AppStorage("autoCommand") var autoCommand: String = ""` (e.g. `claude`)
- Stored profiles as JSON in `@AppStorage("profilesJSON")` with getter/setter that encodes/decodes `[Profile]`.
- Provide a `resolvedShell: String` computed property that returns `shell` if non-empty, else calls `ShellEnvironment.defaultShell()`.

### 12. `Cradle/Views/TerminalViewRepresentable.swift`

Bridges SwiftTerm's `TerminalView` (an NSView) into SwiftUI.

**Requirements:**
- `struct TerminalViewRepresentable: NSViewRepresentable`
- Takes a `TerminalSession` binding.
- `makeNSView()`:
  - Creates a `SwiftTerm.LocalProcessTerminalView` OR a raw `TerminalView`. **Important decision:** SwiftTerm provides `LocalProcessTerminalView` which has its own built-in PTY management. However, using raw `TerminalView` + our own `PTYService` gives more control. **Use `TerminalView` (the raw one) + our PTYService** for maximum flexibility.
  - Actually, re-evaluate: `LocalProcessTerminalView` already handles forkpty, read loops, resize, and delegates. It accepts a `startProcess(executable:args:environment:execName:)` method and a `cwd` can be set via its `currentDirectory` property or by passing it in the process start. **If LocalProcessTerminalView supports setting `cwd` before starting the process, use it instead of writing PTYService from scratch.** This dramatically simplifies the code. Check SwiftTerm's API — `LocalProcessTerminalView` has a `startProcess(executable:execName:args:environment:)` method. The working directory can be set before calling `startProcess` by setting an internal property, or by modifying the environment. **Research this at implementation time.** If `LocalProcessTerminalView` doesn't support `cwd`, use the raw `TerminalView` + custom `PTYService`.
  - Sets font to `NSFont.monospacedSystemFont(ofSize: settings.fontSize, weight: .regular)`.
  - Calls `configureNativeColors()` for system dark/light mode support.
- `makeCoordinator()` — coordinator implements `TerminalViewDelegate` (or `LocalProcessTerminalViewDelegate`), forwarding `sizeChanged` and `processTerminated` events.
- Wire `session.onOutput` to `terminalView.feed(byteArray:)`.
- Wire `terminalView.delegate.send()` to `session.pty.write()`.

**Fallback strategy:** If `LocalProcessTerminalView` handles everything including cwd, then `PTYService.swift` becomes a thin wrapper or can be eliminated. The session would just hold a reference to the `LocalProcessTerminalView` and call `startProcess()` on it. Decide at implementation time based on SwiftTerm's actual API.

### 13. `Cradle/Views/TerminalContentView.swift`

The main content view shown in each window/tab.

**Requirements:**
- Takes an `@ObservedObject session: TerminalSession` (or gets it from environment).
- Body is simply the `TerminalViewRepresentable` filling the entire view (`.frame(maxWidth: .infinity, maxHeight: .infinity)`).
- Background color matches terminal theme.

### 14. `Cradle/Views/SettingsView.swift`

Preferences window content (accessed via Cmd+,).

**Requirements:**
- `TabView` with two tabs: "General" and "Profiles"
- **General tab:**
  - "Default Directory" row: shows current path (truncated), "Choose..." button that opens `NSOpenPanel` (directory mode).
  - "Shell" text field (placeholder: "auto-detect").
  - "Auto-run Command" text field (placeholder: e.g. `claude`).
  - "Font Size" slider, range 10-24.
- **Profiles tab:**
  - List of saved profiles with add/edit/delete.
  - Each profile: name, directory (with folder picker), command.
- Use `@AppStorage` bindings or `@ObservedObject AppSettings`.

### 15. `Cradle/Views/ProfileEditorView.swift`

Sheet/popover for adding or editing a profile.

**Requirements:**
- Text fields for name, directory (with "Choose..." folder picker button), command.
- Save and Cancel buttons.

### 16. `Cradle/App/CradleApp.swift`

The `@main` app entry point.

**Requirements:**
- Uses `@NSApplicationDelegateAdaptor(AppDelegate.self)` to bridge to AppKit for tab management.
- Declares a `Settings` scene containing `SettingsView()`.
- The main `WindowGroup` scene shows `TerminalContentView`.
- Injects `AppSettings` and `SessionManager` into the environment.

**Critical note on window tabbing:** SwiftUI's `WindowGroup` creates new windows, but macOS native window tabbing (`NSWindow.addTabbedWindow`) requires AppKit control. The `AppDelegate` handles Cmd+T by creating a new `NSWindow` with a `TerminalContentView` hosted in an `NSHostingView`, then adding it as a tabbed window to the current key window. This is the standard pattern for native tab bar in non-document-based apps.

### 17. `Cradle/App/AppDelegate.swift`

The `NSApplicationDelegate` that manages window tabbing and menus.

**Requirements:**
- `applicationDidFinishLaunching`: set `NSWindow.allowsAutomaticWindowTabbing = true`. Create the initial terminal window.
- `createTerminalWindow(profile: Profile?) -> NSWindow`:
  - Creates an `NSWindow` with `styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]`.
  - Sets `window.tabbingMode = .preferred` so the tab bar always shows.
  - Sets `window.title` to the profile name or "Cradle".
  - Content view: `NSHostingView(rootView: TerminalContentView(session: newSession))`.
  - The session is created with `cwd` from the profile's directory or `AppSettings.defaultDirectory`, and `command` from the profile or `AppSettings.autoCommand`.
  - Returns the window.
- `newTab(_ sender: Any?)`:
  - Calls `createTerminalWindow()`.
  - If there's a key window, calls `keyWindow.addTabbedWindow(newWindow, ordered: .above)`.
  - Otherwise, `newWindow.makeKeyAndOrderFront(nil)`.
- `applicationShouldHandleReopen`: create a new window if none exist.
- Set up the main menu programmatically or via SwiftUI `.commands`:
  - File -> New Tab (Cmd+T) -> calls `newTab()`
  - File -> Close Tab (Cmd+W) -> closes key window
  - Shell -> New Claude Tab -> creates tab with claude profile
  - Edit -> standard copy/paste (SwiftTerm handles these internally but menu items should exist)
  - Window -> standard window menu items

### 18. `scripts/build.sh`

Build and package script:

```bash
#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

echo "=== Generating Xcode project ==="
xcodegen generate

echo "=== Resolving Swift packages ==="
xcodebuild -resolvePackageDependencies \
    -project Cradle.xcodeproj \
    -scheme Cradle

echo "=== Building ==="
xcodebuild build \
    -project Cradle.xcodeproj \
    -scheme Cradle \
    -configuration Release \
    -derivedDataPath build \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_ALLOWED=NO

APP_PATH="build/Build/Products/Release/Cradle.app"

if [ -d "$APP_PATH" ]; then
    echo "=== Build succeeded ==="
    echo "App location: $APP_PATH"
    echo ""
    echo "To create a .dmg, run:"
    echo "  create-dmg --volname 'Cradle' --app-drop-link 450 190 'Cradle.dmg' '$APP_PATH'"
    echo ""
    echo "To run directly:"
    echo "  open '$APP_PATH'"
else
    echo "=== Build failed — check output above ==="
    exit 1
fi
```

---

## Build & Run Commands

After all files are created:

```bash
cd ~/Developer/Cradle

# 1. Generate .xcodeproj from project.yml
xcodegen generate

# 2. Build
xcodebuild build \
    -project Cradle.xcodeproj \
    -scheme Cradle \
    -configuration Release \
    -derivedDataPath build \
    CODE_SIGN_IDENTITY="-"

# 3. Run
open "build/Build/Products/Release/Cradle.app"

# 4. Package as .dmg (optional)
create-dmg \
    --volname "Cradle" \
    --window-size 600 400 \
    --icon "Cradle.app" 150 190 \
    --app-drop-link 450 190 \
    "Cradle.dmg" \
    "build/Build/Products/Release/Cradle.app"
```

---

## Implementation Order

Claude Code should build in this order, verifying compilation at each checkpoint:

### Step 1: Skeleton (verify project compiles)
Create these files:
- `project.yml`
- `Info.plist`
- `Cradle.entitlements`
- `Assets.xcassets/Contents.json`
- `Assets.xcassets/AppIcon.appiconset/Contents.json`
- A minimal `CradleApp.swift` with just an empty window
- Run `xcodegen generate && xcodebuild build` — must compile clean

### Step 2: PTY (verify shell spawning works)
- Create `ShellEnvironment.swift`
- Create `PTYService.swift`
- Test by spawning a shell, writing `echo hello\n`, and reading output
- If using `LocalProcessTerminalView` from SwiftTerm instead, skip PTYService and test that directly in Step 3

### Step 3: Terminal View (verify terminal renders)
- Create `TerminalViewRepresentable.swift`
- Create a minimal `TerminalContentView.swift`
- Wire into the app — should see a working terminal in the window
- Verify: typing commands works, output renders, colors work
- Verify: the terminal starts in the default directory (initially `$HOME`)

### Step 4: Tab Management (verify tabs work)
- Create `AppDelegate.swift` with window tabbing
- Create `SessionManager.swift`
- Create `TerminalSession.swift`
- Verify: Cmd+T opens a new tab, Cmd+W closes it, "+" button works
- Verify: each tab has its own independent shell session

### Step 5: Settings (verify default directory works)
- Create `AppSettings.swift`
- Create `SettingsView.swift`
- Wire settings to session creation
- Verify: changing default directory in Settings -> new tabs open there
- Verify: Cmd+, opens Settings

### Step 6: Profiles (verify auto-launch works)
- Create `Profile.swift`
- Create `ProfileEditorView.swift`
- Add profile picker to toolbar or menu
- Verify: creating a profile with command `claude` -> new tab opens in the right directory and `claude` starts automatically

### Step 7: Polish & Package
- Add keyboard shortcuts (Cmd+Shift+[ and ] for tab switching)
- Ensure clean window title per tab
- Create `build.sh`
- Run full build -> test `.app` bundle -> create `.dmg`

---

## Potential Issues and Mitigations

### SwiftTerm API uncertainty
SwiftTerm's `LocalProcessTerminalView` may or may not expose a `cwd` parameter. At implementation time:
1. First, check the API by looking at the SwiftTerm source or its public interface after the package resolves.
2. If `LocalProcessTerminalView` supports setting working directory: use it directly, skip custom PTYService.
3. If not: use the raw `TerminalView` class + the custom `PTYService` described above. Wire them together via the delegate pattern.

### forkpty availability in Swift
`forkpty()` is a C function from `<util.h>`. In Swift, it's available via `import Darwin`. If the compiler can't find it, add `#include <util.h>` in a bridging header, or use the alternative approach: `posix_spawn` + manual PTY creation via `openpty()`.

### SwiftTerm version pinning
The `project.yml` pins SwiftTerm `from: "1.0.0"`. If the latest version has breaking API changes, check the SwiftTerm releases page and pin to a specific working version. As of writing, the latest stable API uses `TerminalView` with `feed(byteArray:)` for output and `TerminalViewDelegate` for input.

### Code signing for local testing
During development, use `CODE_SIGN_IDENTITY="-"` (ad-hoc signing). This allows the app to run locally without an Apple Developer account. For distribution as a `.dmg` to others, a paid Apple Developer account ($99/year) is needed for Developer ID signing + notarization.

### macOS version
The project targets macOS 14.0 (Sonoma). If the Mac Mini runs an older version, lower the deployment target in `project.yml` to `"13.0"` (Ventura) — SwiftTerm and the APIs used here support macOS 13+.

---

## Summary

- **App Name:** Cradle
- **Bundle ID:** com.cradleterm.app
- **Language:** Swift 5.9
- **UI:** SwiftUI + AppKit bridging (for native window tabbing)
- **Terminal engine:** SwiftTerm (MIT, via SPM)
- **Shell spawning:** POSIX `forkpty()` or SwiftTerm's built-in `LocalProcessTerminalView`
- **Project generation:** XcodeGen (from `project.yml`)
- **Build system:** `xcodebuild` (CLI, no GUI needed)
- **Distribution:** `.app` bundle -> `.dmg` via `create-dmg`
- **Key feature:** `cwd` parameter on PTY spawn = every tab starts in the configured directory, zero `cd` needed
