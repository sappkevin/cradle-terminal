import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    let settings = AppSettings()
    let sessionManager = SessionManager()
    private var windows: [NSWindow] = []
    private var windowSessionMap: [ObjectIdentifier: UUID] = [:]
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = true
        setupMenus()
        createAndShowWindow()
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

    // MARK: - Window Creation

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
        window.tabbingIdentifier = "CradleTerminal"
        window.isReleasedWhenClosed = false
        window.center()
        window.delegate = self

        windows.append(window)
        windowSessionMap[ObjectIdentifier(window)] = session.id
        return window
    }

    private func removeWindow(_ window: NSWindow) {
        if let sessionID = windowSessionMap[ObjectIdentifier(window)] {
            sessionManager.closeSession(id: sessionID)
        }
        windowSessionMap.removeValue(forKey: ObjectIdentifier(window))
        windows.removeAll { $0 === window }
    }

    // MARK: - Tab Actions

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

    @objc func openProfile(_ sender: NSMenuItem) {
        guard let profile = sender.representedObject as? Profile else { return }
        let newWindow = createTerminalWindow(profile: profile)
        if let keyWindow = NSApp.keyWindow {
            keyWindow.addTabbedWindow(newWindow, ordered: .above)
            newWindow.makeKeyAndOrderFront(nil)
        } else {
            newWindow.makeKeyAndOrderFront(nil)
        }
    }

    @objc func selectPreviousTab(_ sender: Any?) {
        NSApp.keyWindow?.selectPreviousTab(sender)
    }

    @objc func selectNextTab(_ sender: Any?) {
        NSApp.keyWindow?.selectNextTab(sender)
    }

    // MARK: - Settings

    @objc func showSettings(_ sender: Any?) {
        if let existing = settingsWindow {
            existing.makeKeyAndOrderFront(nil)
            return
        }
        let hostingView = NSHostingView(rootView: SettingsView(settings: settings))
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.contentView = hostingView
        window.title = "Settings"
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)
        settingsWindow = window
    }

    // MARK: - Menus

    private func setupMenus() {
        let mainMenu = NSMenu()

        // App menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About Cradle", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Settings…", action: #selector(showSettings), keyEquivalent: ",")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Hide Cradle", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        let hideOthers = appMenu.addItem(withTitle: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(withTitle: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit Cradle", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // Shell menu
        let shellMenuItem = NSMenuItem()
        let shellMenu = NSMenu(title: "Shell")
        shellMenu.addItem(withTitle: "New Tab", action: #selector(newTab), keyEquivalent: "t")
        let claudeItem = NSMenuItem(title: "New Claude Tab", action: #selector(newClaudeTab), keyEquivalent: "t")
        claudeItem.keyEquivalentModifierMask = [.command, .shift]
        shellMenu.addItem(claudeItem)
        shellMenu.addItem(NSMenuItem.separator())

        // Profile submenu
        let profilesItem = NSMenuItem(title: "Open Profile", action: nil, keyEquivalent: "")
        let profilesMenu = NSMenu(title: "Open Profile")
        for profile in settings.profiles {
            let item = NSMenuItem(title: profile.name, action: #selector(openProfile), keyEquivalent: "")
            item.representedObject = profile
            profilesMenu.addItem(item)
        }
        if settings.profiles.isEmpty {
            let emptyItem = NSMenuItem(title: "No Profiles", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            profilesMenu.addItem(emptyItem)
        }
        profilesItem.submenu = profilesMenu
        shellMenu.addItem(profilesItem)

        shellMenu.addItem(NSMenuItem.separator())
        shellMenu.addItem(withTitle: "Close Tab", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        shellMenuItem.submenu = shellMenu
        mainMenu.addItem(shellMenuItem)

        // Edit menu
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        // View menu
        let viewMenuItem = NSMenuItem()
        let viewMenu = NSMenu(title: "View")
        viewMenu.addItem(withTitle: "Show Tab Bar", action: #selector(NSWindow.toggleTabBar(_:)), keyEquivalent: "")
        viewMenu.addItem(NSMenuItem.separator())
        let prevTab = NSMenuItem(title: "Show Previous Tab", action: #selector(selectPreviousTab), keyEquivalent: "[")
        prevTab.keyEquivalentModifierMask = [.command, .shift]
        viewMenu.addItem(prevTab)
        let nextTab = NSMenuItem(title: "Show Next Tab", action: #selector(selectNextTab), keyEquivalent: "]")
        nextTab.keyEquivalentModifierMask = [.command, .shift]
        viewMenu.addItem(nextTab)
        viewMenuItem.submenu = viewMenu
        mainMenu.addItem(viewMenuItem)

        // Window menu
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        windowMenu.addItem(NSMenuItem.separator())
        windowMenu.addItem(withTitle: "Bring All to Front", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: "")
        windowMenuItem.submenu = windowMenu
        NSApp.windowsMenu = windowMenu
        mainMenu.addItem(windowMenuItem)

        NSApp.mainMenu = mainMenu
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        if window === settingsWindow {
            settingsWindow = nil
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.removeWindow(window)
        }
    }

    func windowDidBecomeKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              let sessionID = windowSessionMap[ObjectIdentifier(window)] else { return }
        sessionManager.activeSessionID = sessionID
    }

    // Enables the "+" button in the native macOS tab bar
    func newWindowForTab(_ sender: Any?) -> NSWindow {
        return createTerminalWindow()
    }
}
