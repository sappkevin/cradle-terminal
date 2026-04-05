import Foundation

class TerminalSession: ObservableObject, Identifiable {
    let id = UUID()
    @Published var title: String
    let cwd: String
    let shell: String
    let autoCommand: String?

    init(title: String = "Cradle", cwd: String, shell: String, autoCommand: String? = nil) {
        self.title = title
        self.cwd = cwd
        self.shell = shell
        self.autoCommand = autoCommand
    }
}
