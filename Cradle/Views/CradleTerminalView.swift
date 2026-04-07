import AppKit
import SwiftTerm

/// LocalProcessTerminalView subclass that taps the raw PTY byte stream before
/// SwiftTerm consumes it. Used by ReplayRecorder to capture session history.
///
/// `super.dataReceived` is always called so terminal rendering is unaffected.
final class CradleTerminalView: LocalProcessTerminalView {
    /// Called for every chunk of bytes read from the PTY, on the main thread,
    /// before being fed to the terminal emulator.
    var onDataReceived: ((ArraySlice<UInt8>) -> Void)?

    override func dataReceived(slice: ArraySlice<UInt8>) {
        onDataReceived?(slice)
        super.dataReceived(slice: slice)
    }
}
