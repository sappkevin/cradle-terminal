import AppKit

class TerminalSession: ObservableObject, Identifiable {
    let id = UUID()
    @Published var title: String
    let cwd: String
    let shell: String
    let autoCommand: String?
    weak var window: NSWindow?

    init(title: String = "Cradle", cwd: String, shell: String, autoCommand: String? = nil) {
        self.title = title
        self.cwd = cwd
        self.shell = shell
        self.autoCommand = autoCommand
    }

    func updateWindowTitle(_ terminalTitle: String, cols: Int, rows: Int) {
        let sizeStr = "\(cols)x\(rows)"
        let displayTitle = terminalTitle.isEmpty ? title : terminalTitle
        title = displayTitle
        window?.title = "\(displayTitle) — \(sizeStr)"
    }
}
