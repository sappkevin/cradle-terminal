import Foundation

/// Wraps the `claude` CLI for in-app AI features. Input is always passed via
/// stdin (never shell-interpolated) so user prompts cannot be injected into
/// the command line.
final class ClaudeCLIService {
    enum ClaudeError: Error, LocalizedError {
        case cliNotFound
        case nonZeroExit(Int32, String)

        var errorDescription: String? {
            switch self {
            case .cliNotFound: return "Claude CLI not found. Set its path in Settings → Features."
            case .nonZeroExit(let code, let stderr): return "claude exited \(code): \(stderr)"
            }
        }
    }

    /// Override path. Empty string means auto-detect from PATH.
    var explicitPath: String = ""

    func resolvedCLIPath() -> String? {
        if !explicitPath.isEmpty, FileManager.default.isExecutableFile(atPath: explicitPath) {
            return explicitPath
        }
        let candidates = [
            "/opt/homebrew/bin/claude",
            "/usr/local/bin/claude",
            "\(NSHomeDirectory())/.local/bin/claude",
            "\(NSHomeDirectory())/.claude/local/claude"
        ]
        for c in candidates where FileManager.default.isExecutableFile(atPath: c) { return c }
        return nil
    }

    // MARK: - Public methods

    func improvePrompt(_ prompt: String) async throws -> String {
        try await run(template: PromptTemplates.promptImprover, input: prompt)
    }

    func reduceHallucinations(_ prompt: String) async throws -> String {
        try await run(template: PromptTemplates.reduceHallucinations, input: prompt)
    }

    func increaseConsistency(_ prompt: String) async throws -> String {
        try await run(template: PromptTemplates.increaseConsistency, input: prompt)
    }

    func evaluatePrompt(_ prompt: String) async throws -> String {
        try await run(template: PromptTemplates.evaluatePrompt, input: prompt)
    }

    func generateDocumentation(fromTranscript transcript: String) async throws -> String {
        try await run(template: PromptTemplates.documentationFromTranscript, input: transcript)
    }

    // MARK: - Process plumbing

    /// Wraps the user's input inside a meta-prompt template using `<<<INPUT>>>`
    /// as the placeholder, then pipes it to `claude` on stdin in non-interactive
    /// mode (`-p -`).
    private func run(template: String, input: String) async throws -> String {
        guard let path = resolvedCLIPath() else { throw ClaudeError.cliNotFound }
        let composed = template.replacingOccurrences(of: "<<<INPUT>>>", with: input)

        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<String, Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: path)
                process.arguments = ["-p", "-"]

                let stdinPipe = Pipe()
                let stdoutPipe = Pipe()
                let stderrPipe = Pipe()
                process.standardInput = stdinPipe
                process.standardOutput = stdoutPipe
                process.standardError = stderrPipe

                do {
                    try process.run()
                } catch {
                    cont.resume(throwing: error)
                    return
                }

                stdinPipe.fileHandleForWriting.write(composed.data(using: .utf8) ?? Data())
                try? stdinPipe.fileHandleForWriting.close()

                let outData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let errData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()

                if process.terminationStatus != 0 {
                    let stderr = String(data: errData, encoding: .utf8) ?? ""
                    cont.resume(throwing: ClaudeError.nonZeroExit(process.terminationStatus, stderr))
                    return
                }
                let out = String(data: outData, encoding: .utf8) ?? ""
                cont.resume(returning: out.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
    }
}
