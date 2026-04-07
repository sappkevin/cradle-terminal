import SwiftUI

/// Read-only view of recorded session bytes with a command-anchored scrubber.
/// Shows the plain-text reconstruction of bytes between selected anchor points.
struct ReplayView: View {
    @ObservedObject var session: TerminalSession
    @ObservedObject var settings: AppSettings
    @State private var selectedCommandIndex: Int = 0
    @State private var showExport: Bool = false

    private var commands: [CommandRecord] { session.commandHistory }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Instant Replay").font(.headline)
                Spacer()
                if settings.replayExportEnabled {
                    Button("Export…") { showExport = true }
                        .keyboardShortcut("e", modifiers: .command)
                }
                Button("Done") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }

            if commands.isEmpty {
                Text("No commands recorded yet. Enable shell integration and run a command.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack(spacing: 6) {
                    Button("⏮") { selectedCommandIndex = 0 }
                    Button("◀") { selectedCommandIndex = max(0, selectedCommandIndex - 1) }
                    Slider(
                        value: Binding(
                            get: { Double(selectedCommandIndex) },
                            set: { selectedCommandIndex = Int($0) }
                        ),
                        in: 0...Double(max(commands.count - 1, 0)),
                        step: 1
                    )
                    Button("▶") { selectedCommandIndex = min(commands.count - 1, selectedCommandIndex + 1) }
                    Button("⏭") { selectedCommandIndex = commands.count - 1 }
                    Text("\(selectedCommandIndex + 1)/\(commands.count)")
                        .monospacedDigit()
                }

                let cmd = commands[min(selectedCommandIndex, commands.count - 1)]
                Group {
                    Text("cwd: \(cmd.cwd)").font(.caption).foregroundColor(.secondary)
                    if let exit = cmd.exitCode {
                        Text("exit: \(exit)").font(.caption).foregroundColor(exit == 0 ? .green : .red)
                    }
                }

                ScrollView {
                    Text(commandText(cmd))
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding(6)
                }
                .border(Color.gray.opacity(0.3))
            }
        }
        .padding()
        .frame(minWidth: 700, minHeight: 500)
        .sheet(isPresented: $showExport) {
            ReplayExportView(session: session, settings: settings)
        }
    }

    private func commandText(_ cmd: CommandRecord) -> String {
        guard let recorder = session.replayRecorder else { return "Replay recorder disabled." }
        let end = cmd.replayEndFrame ?? recorder.frameCount
        return recorder.plainText(absoluteStart: cmd.replayStartFrame, absoluteEnd: end)
    }

    @Environment(\.dismiss) private var dismiss
}
