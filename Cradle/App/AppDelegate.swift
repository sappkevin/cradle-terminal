import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    let settings = AppSettings()
    let sessionManager = SessionManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = true

        // Close the default SwiftUI window if one was created
        // We manage windows ourselves
        if NSApp.windows.isEmpty {
            createAndShowWindow()
        } else {
            // Configure the existing window
            if let window = NSApp.keyWindow ?? NSApp.windows.first {
                configureWindow(window)
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            createAndShowWindow()
        }
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    @discardableResult
    func createAndShowWindow(profile: Profile? = nil) -> NSWindow {
        let window = createTerminalWindow(profile: profile)
        window.makeKeyAndOrderFront(nil)
        return window
    }

    func createTerminalWindow(profile: Profile? = nil) -> NSWindow {
        let cwd = profile?.directory ?? settings.defaultDirectory
        let shell = settings.resolvedShell
        let cmd = profile?.command ?? (settings.autoCommand.isEmpty ? nil : settings.autoCommand)
        let session = sessionManager.createSession(cwd: cwd, shell: shell, autoCommand: cmd)

        let contentView = TerminalContentView(session: session, fontSize: CGFloat(settings.fontSize))
        let hostingView = NSHostingView(rootView: contentView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.contentView = hostingView
        window.title = profile?.name ?? "Cradle"
        window.tabbingMode = .preferred
        window.center()
        window.delegate = self

        return window
    }

    private func configureWindow(_ window: NSWindow) {
        window.tabbingMode = .preferred
    }

    @objc func newTab(_ sender: Any?) {
        let newWindow = createTerminalWindow()
        if let keyWindow = NSApp.keyWindow {
            keyWindow.addTabbedWindow(newWindow, ordered: .above)
            newWindow.makeKeyAndOrderFront(nil)
        } else {
            newWindow.makeKeyAndOrderFront(nil)
        }
    }

    @objc func newClaudeTab(_ sender: Any?) {
        let claudeProfile = settings.profiles.first { $0.command?.lowercased().contains("claude") == true }
        let profile = claudeProfile ?? Profile(name: "Claude", directory: settings.defaultDirectory, command: "claude")
        let newWindow = createTerminalWindow(profile: profile)
        if let keyWindow = NSApp.keyWindow {
            keyWindow.addTabbedWindow(newWindow, ordered: .above)
            newWindow.makeKeyAndOrderFront(nil)
        } else {
            newWindow.makeKeyAndOrderFront(nil)
        }
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        // Clean up session when window closes
        // We could track window-to-session mapping if needed
        _ = window
    }
}
