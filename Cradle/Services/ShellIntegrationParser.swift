import Foundation

/// Decodes OSC 133 (FinalTerm shell integration) payloads emitted by the shell.
/// We rely on SwiftTerm's `registerOscHandler` to deliver the raw payload —
/// no streaming state machine is required.
///
/// Payload format: `<kind>[;<exitCode>][;k=v]*`
/// - `A` prompt start
/// - `B` prompt end / command line start
/// - `C` command executed (output begins)
/// - `D[;exit]` command finished
enum ShellIntegrationEvent: Equatable {
    case promptStart
    case commandStart
    case commandExecuted
    case commandFinished(exitCode: Int32?)
}

enum ShellIntegrationParser {
    static func decodeOSC133(_ slice: ArraySlice<UInt8>) -> ShellIntegrationEvent? {
        guard let payload = String(bytes: slice, encoding: .utf8) else { return nil }
        let parts = payload.split(separator: ";", omittingEmptySubsequences: false)
        guard let kind = parts.first?.first else { return nil }
        switch kind {
        case "A": return .promptStart
        case "B": return .commandStart
        case "C": return .commandExecuted
        case "D":
            // D or D;<exit> or D;<exit>;k=v...
            if parts.count >= 2, let code = Int32(parts[1]) {
                return .commandFinished(exitCode: code)
            }
            return .commandFinished(exitCode: nil)
        default:
            return nil
        }
    }
}
