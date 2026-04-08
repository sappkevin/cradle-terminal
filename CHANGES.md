# Changelog

All notable changes to Cradle are documented here. Versions follow [SemVer](https://semver.org/).

## [1.1.4] — 2026-04-08

### Fixed
- Settings window labels were being clipped on the left edge. Widened the window to 640×460 so all Form labels fit.

## [1.1.3] — 2026-04-08

### Added
- **Clickable URLs.** Hover highlights any detected URL; a plain click opens it in the default browser (no ⌘ modifier required).
- **Pointer cursor over links.** The mouse cursor switches to a pointing hand when hovering a link cell.
- **Settings → General → "Forward mouse events to TUIs"** toggle for users who need mouse-driven terminal apps.

### Fixed
- **Text selection now works.** SwiftTerm's `allowMouseReporting` is disabled by default so click+drag selects text and ⌘C copies it. Previously interactive TUIs (including Claude Code) could swallow clicks.

## [1.1.2] — 2026-04-08

### Added
- **Appearance picker** in Settings → General: System / Light / Dark. Applies globally to the whole app via `NSApp.appearance`.

## [1.1.1] — 2026-04-08

### Added
- **Signed and notarized releases.** The GitHub Actions workflow now imports a Developer ID Application certificate, builds with the hardened runtime, submits the `.app` and `.dmg` to Apple's notary service, and staples the ticket. Installed `.dmg`s no longer trigger Gatekeeper "unidentified developer" warnings.

### Fixed
- Signing now uses `--timestamp` (required by notarization) and notarizes both the app and the DMG before stapling.

## [1.1.0] — 2026-04-07

First major feature drop. Every feature below is gated by a toggle in **Settings → Features**.

### Added — Shell integration (iTerm2-style)
- **OSC 133 prompt marks** — Cradle tracks every command's start, end, exit code, and cwd.
- **OSC 7 cwd tracking** — current directory follows the shell.
- **`copyfile` / `pastefile`** shell helpers wrapping `scp -r` with glob support.
- **Inline autosuggestions** (fish-style ghost text) via bundled `zsh-autosuggestions` hook.
- Bundled `cradle.{zsh,bash,fish}` scripts and a **Settings → Features → Install Shell Integration…** button that copies them into `~/.config/cradle/`.

### Added — Instant Replay
- Time-indexed scrollback ring buffer (size-capped, default 10 MB per session).
- **⌘⇧R** opens a read-only replay view with a command-anchored scrubber.
- **⌘E** export to **Markdown** (default), plain text, or JSON.
- **"Generate Documentation with Claude"** pipes the transcript through the `claude` CLI and returns a Markdown runbook (summary / prerequisites / steps / troubleshooting / notes).

### Added — AI Prompt Inspector
- Right-sidebar panel that shells out to the `claude` CLI for:
  - **Improve** — rewrite a prompt for clarity and structure.
  - **Evaluate** — score on clarity, specificity, hallucination resistance, consistency.
  - **Reduce hallucinations** — add factual-accuracy guardrails.
  - **Increase consistency** — constrain output for deterministic responses.
- Copy results or send straight to the active terminal.

### Added — App icon
- First-class AppIcon asset at all required macOS sizes.

### Added — Per-feature toggles
- Every major feature above is gated by an `@AppStorage` toggle so it can be disabled entirely from Settings → Features.

## [1.0.0] — 2026-04-06

Initial release.

- Native macOS terminal built on SwiftTerm, with real `NSWindow.addTabbedWindow` tabs.
- Per-tab default directory, auto-run command, and launch profiles.
- Dynamic window titles showing the terminal title and size.
- `./scripts/build.sh` + GitHub Actions workflow producing an ad-hoc signed `.dmg`.

[1.1.4]: https://github.com/sappkevin/cradle-terminal/releases/tag/v1.1.4
[1.1.3]: https://github.com/sappkevin/cradle-terminal/releases/tag/v1.1.3
[1.1.2]: https://github.com/sappkevin/cradle-terminal/releases/tag/v1.1.2
[1.1.1]: https://github.com/sappkevin/cradle-terminal/releases/tag/v1.1.1
[1.1.0]: https://github.com/sappkevin/cradle-terminal/releases/tag/v1.1.0
[1.0.0]: https://github.com/sappkevin/cradle-terminal/releases/tag/v1.0.0
