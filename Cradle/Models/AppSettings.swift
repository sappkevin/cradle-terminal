import Foundation
import SwiftUI

class AppSettings: ObservableObject {
    @AppStorage("defaultDirectory") var defaultDirectory: String = NSHomeDirectory()
    @AppStorage("defaultShell") var shell: String = ""
    @AppStorage("fontSize") var fontSize: Double = 14
    @AppStorage("autoCommand") var autoCommand: String = ""
    @AppStorage("profilesJSON") var profilesJSON: String = "[]"

    // MARK: - New feature settings

    @AppStorage("claudeCLIPath") var claudeCLIPath: String = ""
    @AppStorage("replayBufferSizeMB") var replayBufferSizeMB: Int = 10

    // MARK: - Feature toggles (default on)

    @AppStorage("shellIntegrationEnabled") var shellIntegrationEnabled: Bool = true
    @AppStorage("instantReplayEnabled") var instantReplayEnabled: Bool = true
    @AppStorage("replayExportEnabled") var replayExportEnabled: Bool = true
    @AppStorage("claudeDocGenEnabled") var claudeDocGenEnabled: Bool = true
    @AppStorage("aiInspectorEnabled") var aiInspectorEnabled: Bool = true
    @AppStorage("copyfileHelpersEnabled") var copyfileHelpersEnabled: Bool = true
    @AppStorage("intellisenseEnabled") var intellisenseEnabled: Bool = true

    /// "system", "light", or "dark"
    @AppStorage("appearance") var appearance: String = "system"

    /// When false (default), click+drag always selects text. Turn on if you
    /// need mouse-driven TUIs to receive click events.
    @AppStorage("mouseReportingEnabled") var mouseReportingEnabled: Bool = false

    var resolvedShell: String {
        shell.isEmpty ? ShellEnvironment.defaultShell() : shell
    }

    var profiles: [Profile] {
        get {
            guard let data = profilesJSON.data(using: .utf8) else { return [] }
            return (try? JSONDecoder().decode([Profile].self, from: data)) ?? []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue), let json = String(data: data, encoding: .utf8) {
                profilesJSON = json
            }
        }
    }
}
