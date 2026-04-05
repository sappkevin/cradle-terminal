import SwiftUI
import SwiftTerm

struct TerminalViewRepresentable: NSViewRepresentable {
    let session: TerminalSession
    let fontSize: CGFloat
    var onProcessExit: (() -> Void)?
    var onTitleChange: ((String) -> Void)?

    func makeNSView(context: Context) -> LocalProcessTerminalView {
        let terminalView = LocalProcessTerminalView(frame: .zero)
        terminalView.processDelegate = context.coordinator
        terminalView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        terminalView.configureNativeColors()

        let env = ShellEnvironment.shellEnvironment()
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

    func updateNSView(_ nsView: LocalProcessTerminalView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onProcessExit: onProcessExit, onTitleChange: onTitleChange)
    }

    class Coordinator: NSObject, LocalProcessTerminalViewDelegate {
        var onProcessExit: (() -> Void)?
        var onTitleChange: ((String) -> Void)?

        init(onProcessExit: (() -> Void)?, onTitleChange: ((String) -> Void)?) {
            self.onProcessExit = onProcessExit
            self.onTitleChange = onTitleChange
        }

        func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}

        func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
            onTitleChange?(title)
        }

        func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}

        func processTerminated(source: TerminalView, exitCode: Int32?) {
            onProcessExit?()
        }
    }
}
