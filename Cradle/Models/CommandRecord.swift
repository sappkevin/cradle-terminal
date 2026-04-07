import Foundation

/// One executed shell command, anchored by OSC 133 marks.
struct CommandRecord: Identifiable, Equatable {
    let id = UUID()
    var commandLine: String      // best-effort; may be empty if shell didn't expose it
    var cwd: String
    var startedAt: Date          // when OSC 133;C fired (output began)
    var endedAt: Date?
    var exitCode: Int32?
    /// Index into ReplayRecorder.frames where this command's output starts.
    var replayStartFrame: Int
    /// Index into ReplayRecorder.frames where this command's output ends (exclusive).
    var replayEndFrame: Int?
}
