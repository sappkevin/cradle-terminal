import Foundation

/// Records a time-indexed history of PTY bytes for instant replay and export.
///
/// The recorder is a simple ring of (timestamp, bytes) frames capped by total
/// byte size. Frame indices are stable as long as nothing has been evicted;
/// once eviction kicks in, indices shift and `evictedFrameCount` reflects
/// how many frames have been dropped from the front. CommandRecord frame
/// indices are absolute, so callers should subtract `evictedFrameCount`
/// when looking up frames in the live array.
final class ReplayRecorder {
    struct Frame {
        let timestamp: Date
        let bytes: Data
    }

    private(set) var frames: [Frame] = []
    private(set) var totalBytes: Int = 0
    private(set) var evictedFrameCount: Int = 0
    private let maxBytes: Int

    /// Total number of frames ever captured (including evicted ones). Use this
    /// when anchoring CommandRecord.replayStartFrame so indices are stable.
    var frameCount: Int { evictedFrameCount + frames.count }

    init(maxBytes: Int) {
        self.maxBytes = max(maxBytes, 1024)
    }

    func append(_ slice: ArraySlice<UInt8>) {
        let data = Data(slice)
        frames.append(Frame(timestamp: Date(), bytes: data))
        totalBytes += data.count
        evictIfNeeded()
    }

    private func evictIfNeeded() {
        while totalBytes > maxBytes, !frames.isEmpty {
            let dropped = frames.removeFirst()
            totalBytes -= dropped.bytes.count
            evictedFrameCount += 1
        }
    }

    /// Concatenate bytes for the absolute frame index range `[start, end)`.
    func bytes(absoluteStart start: Int, absoluteEnd end: Int) -> Data {
        let liveStart = max(0, start - evictedFrameCount)
        let liveEnd = min(frames.count, end - evictedFrameCount)
        guard liveStart < liveEnd else { return Data() }
        var out = Data()
        for i in liveStart..<liveEnd {
            out.append(frames[i].bytes)
        }
        return out
    }

    /// Plain-text view of the bytes in the given range (ANSI/CSI stripped,
    /// carriage returns normalized).
    func plainText(absoluteStart start: Int, absoluteEnd end: Int) -> String {
        let data = bytes(absoluteStart: start, absoluteEnd: end)
        let raw = String(data: data, encoding: .utf8) ?? ""
        return ANSIStripper.strip(raw)
    }

    // MARK: - Exports

    /// Markdown export — one section per command.
    func exportAsMarkdown(commands: [CommandRecord], sessionTitle: String, shell: String) -> String {
        let formatter = ISO8601DateFormatter()
        var md = "# \(sessionTitle)\n\n"
        md += "- **Shell:** `\(shell)`\n"
        md += "- **Recorded:** \(formatter.string(from: Date()))\n"
        md += "- **Commands:** \(commands.count)\n\n"
        md += "---\n\n"

        for (i, cmd) in commands.enumerated() {
            md += "## Command \(i + 1)\n\n"
            md += "- **cwd:** `\(cmd.cwd)`\n"
            if let exit = cmd.exitCode { md += "- **exit:** \(exit)\n" }
            md += "- **started:** \(formatter.string(from: cmd.startedAt))\n"
            if let ended = cmd.endedAt {
                let dur = ended.timeIntervalSince(cmd.startedAt)
                md += "- **duration:** \(String(format: "%.2fs", dur))\n"
            }
            md += "\n"
            if !cmd.commandLine.isEmpty {
                md += "```bash\n\(cmd.commandLine)\n```\n\n"
            }
            let end = cmd.replayEndFrame ?? frameCount
            let output = plainText(absoluteStart: cmd.replayStartFrame, absoluteEnd: end)
            if !output.isEmpty {
                md += "```text\n\(output)\n```\n\n"
            }
        }
        return md
    }

    /// Plain-text export — concatenated, ANSI stripped.
    func exportAsText(commands: [CommandRecord]) -> String {
        var out = ""
        for cmd in commands {
            if !cmd.commandLine.isEmpty {
                out += "$ \(cmd.commandLine)\n"
            }
            let end = cmd.replayEndFrame ?? frameCount
            out += plainText(absoluteStart: cmd.replayStartFrame, absoluteEnd: end)
            if !out.hasSuffix("\n") { out += "\n" }
        }
        return out
    }

    /// Structured JSON export.
    func exportAsJSON(commands: [CommandRecord], sessionTitle: String, shell: String) -> Data {
        let formatter = ISO8601DateFormatter()
        var cmdDicts: [[String: Any]] = []
        for cmd in commands {
            let end = cmd.replayEndFrame ?? frameCount
            var dict: [String: Any] = [
                "cwd": cmd.cwd,
                "command": cmd.commandLine,
                "startedAt": formatter.string(from: cmd.startedAt),
                "output": plainText(absoluteStart: cmd.replayStartFrame, absoluteEnd: end)
            ]
            if let ended = cmd.endedAt { dict["endedAt"] = formatter.string(from: ended) }
            if let exit = cmd.exitCode { dict["exitCode"] = Int(exit) }
            cmdDicts.append(dict)
        }
        let root: [String: Any] = [
            "title": sessionTitle,
            "shell": shell,
            "recordedAt": formatter.string(from: Date()),
            "commands": cmdDicts
        ]
        return (try? JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys])) ?? Data()
    }
}

/// Strips common ANSI escape sequences (CSI, OSC, simple ESC) for export.
/// Not a full terminal emulator — good enough for human-readable transcripts.
enum ANSIStripper {
    static func strip(_ input: String) -> String {
        var out = String()
        out.reserveCapacity(input.count)
        var iter = input.unicodeScalars.makeIterator()
        while let c = iter.next() {
            if c == "\u{1B}" { // ESC
                guard let next = iter.next() else { break }
                switch next {
                case "[":
                    // CSI: parameter bytes 0x30-0x3F, intermediate 0x20-0x2F, final 0x40-0x7E
                    while let p = iter.next() {
                        let v = p.value
                        if v >= 0x40 && v <= 0x7E { break }
                    }
                case "]":
                    // OSC: terminated by BEL (0x07) or ESC \
                    while let p = iter.next() {
                        if p == "\u{07}" { break }
                        if p == "\u{1B}" { _ = iter.next(); break }
                    }
                case "(", ")":
                    _ = iter.next() // charset designator
                default:
                    break // single-char ESC
                }
                continue
            }
            if c == "\r" { continue } // strip CR; LF preserved
            out.unicodeScalars.append(c)
        }
        return out
    }
}
