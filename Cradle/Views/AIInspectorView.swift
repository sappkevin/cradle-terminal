import SwiftUI

/// Right-sidebar inspector that pipes prompts through the `claude` CLI for
/// improvement, evaluation, hallucination reduction, and consistency tuning.
struct AIInspectorView: View {
    @ObservedObject var settings: AppSettings
    var onSendToTerminal: ((String) -> Void)?

    @State private var input: String = ""
    @State private var output: String = ""
    @State private var isRunning: Bool = false
    @State private var errorMessage: String?

    private let service = ClaudeCLIService()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Claude Prompt Inspector").font(.headline)

            Text("Input").font(.caption).foregroundColor(.secondary)
            TextEditor(text: $input)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 100)
                .border(Color.gray.opacity(0.3))

            HStack(spacing: 6) {
                actionButton("Improve")    { try await service.improvePrompt($0) }
                actionButton("Evaluate")   { try await service.evaluatePrompt($0) }
                actionButton("Reduce hallucinations") { try await service.reduceHallucinations($0) }
                actionButton("Consistency") { try await service.increaseConsistency($0) }
            }

            if let err = errorMessage {
                Text(err).font(.caption).foregroundColor(.red)
            }

            Text("Output").font(.caption).foregroundColor(.secondary)
            ScrollView {
                Text(output.isEmpty ? "—" : output)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(6)
            }
            .frame(minHeight: 150)
            .border(Color.gray.opacity(0.3))

            HStack {
                Button("Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(output, forType: .string)
                }.disabled(output.isEmpty)
                Button("Send to Terminal") {
                    onSendToTerminal?(output)
                }.disabled(output.isEmpty || onSendToTerminal == nil)
                Spacer()
                if isRunning { ProgressView().controlSize(.small) }
            }
        }
        .padding(10)
        .frame(width: 320)
    }

    @ViewBuilder
    private func actionButton(_ label: String, run: @escaping (String) async throws -> String) -> some View {
        Button(label) {
            runAction(run)
        }
        .disabled(isRunning || input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .controlSize(.small)
    }

    private func runAction(_ run: @escaping (String) async throws -> String) {
        let snapshot = input
        service.explicitPath = settings.claudeCLIPath
        isRunning = true
        errorMessage = nil
        Task {
            do {
                let result = try await run(snapshot)
                await MainActor.run {
                    output = result
                    isRunning = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isRunning = false
                }
            }
        }
    }
}
