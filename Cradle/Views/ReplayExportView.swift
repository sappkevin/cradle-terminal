import SwiftUI
import UniformTypeIdentifiers

/// Sheet for exporting recorded session bytes as Markdown / Plain text / JSON,
/// with an optional pass through `claude` to generate Markdown documentation.
struct ReplayExportView: View {
    @ObservedObject var session: TerminalSession
    @ObservedObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    enum Format: String, CaseIterable, Identifiable {
        case markdown = "Markdown"
        case text = "Plain text"
        case json = "JSON"
        var id: String { rawValue }
        var ext: String {
            switch self {
            case .markdown: return "md"
            case .text: return "txt"
            case .json: return "json"
            }
        }
    }

    @State private var format: Format = .markdown
    @State private var preview: String = ""
    @State private var isGenerating = false
    @State private var errorMessage: String?

    private let claude = ClaudeCLIService()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Export Replay").font(.headline)

            Picker("Format", selection: $format) {
                ForEach(Format.allCases) { f in Text(f.rawValue).tag(f) }
            }
            .pickerStyle(.segmented)
            .onChange(of: format) { regeneratePreview() }

            ScrollView {
                Text(preview.isEmpty ? "—" : preview)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(6)
            }
            .border(Color.gray.opacity(0.3))
            .frame(minHeight: 280)

            if let err = errorMessage {
                Text(err).font(.caption).foregroundColor(.red)
            }

            HStack {
                if settings.claudeDocGenEnabled {
                    Button("Generate Documentation with Claude") { generateDocumentation() }
                        .disabled(isGenerating || session.commandHistory.isEmpty)
                }
                if isGenerating { ProgressView().controlSize(.small) }
                Spacer()
                Button("Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(preview, forType: .string)
                }.disabled(preview.isEmpty)
                Button("Save As…") { saveAs() }
                    .disabled(preview.isEmpty)
                Button("Close") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
        }
        .padding()
        .frame(width: 700, height: 500)
        .onAppear { regeneratePreview() }
    }

    private func regeneratePreview() {
        guard let recorder = session.replayRecorder else {
            preview = "Replay recorder disabled."
            return
        }
        let cmds = session.commandHistory
        switch format {
        case .markdown:
            preview = recorder.exportAsMarkdown(commands: cmds, sessionTitle: session.title, shell: session.shell)
        case .text:
            preview = recorder.exportAsText(commands: cmds)
        case .json:
            let data = recorder.exportAsJSON(commands: cmds, sessionTitle: session.title, shell: session.shell)
            preview = String(data: data, encoding: .utf8) ?? ""
        }
    }

    private func generateDocumentation() {
        guard let recorder = session.replayRecorder else { return }
        let transcript = recorder.exportAsText(commands: session.commandHistory)
        claude.explicitPath = settings.claudeCLIPath
        isGenerating = true
        errorMessage = nil
        Task {
            do {
                let md = try await claude.generateDocumentation(fromTranscript: transcript)
                await MainActor.run {
                    format = .markdown
                    preview = md
                    isGenerating = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isGenerating = false
                }
            }
        }
    }

    private func saveAs() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "cradle-replay.\(format.ext)"
        if panel.runModal() == .OK, let url = panel.url {
            try? preview.data(using: .utf8)?.write(to: url)
        }
    }
}
