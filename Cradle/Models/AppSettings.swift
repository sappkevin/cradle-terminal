import Foundation
import SwiftUI

class AppSettings: ObservableObject {
    @AppStorage("defaultDirectory") var defaultDirectory: String = NSHomeDirectory()
    @AppStorage("defaultShell") var shell: String = ""
    @AppStorage("fontSize") var fontSize: Double = 14
    @AppStorage("autoCommand") var autoCommand: String = ""
    @AppStorage("profilesJSON") var profilesJSON: String = "[]"

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
