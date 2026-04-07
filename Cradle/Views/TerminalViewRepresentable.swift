import SwiftUI
import SwiftTerm

struct TerminalViewRepresentable: NSViewRepresentable {
    let session: TerminalSession
    let fontSize: CGFloat
    let settings: AppSettings

    func makeNSView(context: Context) -> CradleTerminalView {
        let terminalView = CradleTerminalView(frame: .zero)
        context.coordinator.session = session
        context.coordinator.terminalView = terminalView
        terminalView.processDelegate = context.coordinator
        terminalView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        terminalView.configureNativeColors()

        // Wire instant replay before the process starts.
        if settings.instantReplayEnabled {
            let recorder = ReplayRecorder(maxBytes: settings.replayBufferSizeMB * 1024 * 1024)
            session.replayRecorder = recorder
            terminalView.onDataReceived = { [weak recorder] slice in
                recorder?.append(slice)
            }
        }

        // Wire shell integration: OSC 133 via registerOscHandler, OSC 7 via delegate.
        if settings.shellIntegrationEnabled {
            let weakSession = session
            terminalView.terminal.registerOscHandler(code: 133) { payload in
                if let event = ShellIntegrationParser.decodeOSC133(payload) {
                    DispatchQueue.main.async {
                        weakSession.handleShellEvent(event)
                    }
                }
            }
        }

        let env = ShellEnvironment.shellEnvironment(settings: settings)
        terminalView.startProcess(
            executable: session.shell,
            args: ["-l"],
            environment: env,
            execName: "-" + (session.shell as NSString).lastPathComponent,
            currentDirectory: session.cwd
        )

        if let cmd = session.autoCommand, !cmd.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let data = Array((cmd + "\n").utf8)
                terminalView.send(source: terminalView, data: data[...])
            }
        }

        return terminalView
    }

    func updateNSView(_ nsView: CradleTerminalView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, LocalProcessTerminalViewDelegate {
        weak var session: TerminalSession?
        weak var terminalView: CradleTerminalView?

        func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {
            guard let session else { return }
            session.updateWindowTitle(session.title, cols: newCols, rows: newRows)
        }

        func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
            guard let session, let tv = terminalView else { return }
            session.updateWindowTitle(title, cols: tv.terminal.cols, rows: tv.terminal.rows)
        }

        func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
            guard let session, let dir = directory, !dir.isEmpty else { return }
            DispatchQueue.main.async {
                session.updateCwd(dir)
            }
        }

        func processTerminated(source: TerminalView, exitCode: Int32?) {}
    }
}
