import SwiftUI

@main
struct CradleApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            TerminalContentView(
                session: appDelegate.sessionManager.sessions.last
                    ?? appDelegate.sessionManager.createSession(
                        cwd: appDelegate.settings.defaultDirectory,
                        shell: appDelegate.settings.resolvedShell,
                        autoCommand: appDelegate.settings.autoCommand.isEmpty ? nil : appDelegate.settings.autoCommand
                    ),
                fontSize: CGFloat(appDelegate.settings.fontSize)
            )
            .frame(minWidth: 600, minHeight: 400)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Tab") {
                    appDelegate.newTab(nil)
                }
                .keyboardShortcut("t", modifiers: .command)

                Button("New Claude Tab") {
                    appDelegate.newClaudeTab(nil)
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])
            }
        }

        Settings {
            SettingsView(settings: appDelegate.settings)
        }
    }
}
