import AppKit
import Combine

class TerminalSession: ObservableObject, Identifiable {
    let id = UUID()
    @Published var title: String
    @Published var currentCwd: String
    @Published var commandHistory: [CommandRecord] = []

    let cwd: String
    let shell: String
    let autoCommand: String?
    weak var window: NSWindow?

    /// Replay recorder for instant replay + export. Created lazily so it can
    /// be skipped when `instantReplayEnabled` is off.
    var replayRecorder: ReplayRecorder?

    private var pendingCommandStartFrame: Int?

    init(title: String = "Cradle", cwd: String, shell: String, autoCommand: String? = nil) {
        self.title = title
        self.cwd = cwd
        self.currentCwd = cwd
        self.shell = shell
        self.autoCommand = autoCommand
    }

    func updateWindowTitle(_ terminalTitle: String, cols: Int, rows: Int) {
        let sizeStr = "\(cols)x\(rows)"
        let displayTitle = terminalTitle.isEmpty ? title : terminalTitle
        title = displayTitle
        window?.title = "\(displayTitle) — \(sizeStr)"
    }

    // MARK: - Shell integration ingest

    func handleShellEvent(_ event: ShellIntegrationEvent) {
        switch event {
        case .promptStart, .commandStart:
            // No state change yet — wait for commandExecuted to anchor a new record.
            break
        case .commandExecuted:
            let frame = replayRecorder?.frameCount ?? 0
            pendingCommandStartFrame = frame
            let record = CommandRecord(
                commandLine: "",
                cwd: currentCwd,
                startedAt: Date(),
                endedAt: nil,
                exitCode: nil,
                replayStartFrame: frame,
                replayEndFrame: nil
            )
            commandHistory.append(record)
        case .commandFinished(let exit):
            guard !commandHistory.isEmpty else { return }
            var last = commandHistory[commandHistory.count - 1]
            last.endedAt = Date()
            last.exitCode = exit
            last.replayEndFrame = replayRecorder?.frameCount ?? last.replayStartFrame
            commandHistory[commandHistory.count - 1] = last
            pendingCommandStartFrame = nil
        }
    }

    func updateCwd(_ path: String) {
        currentCwd = path
    }
}
