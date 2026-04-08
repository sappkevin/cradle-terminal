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

    // MARK: - Pointer cursor over links
    //
    // SwiftTerm hardcodes the iBeam cursor and seals its mouse overrides
    // (declared `public` not `open`). To switch to pointingHand over a link,
    // we install a tracking area whose *owner* is a separate NSResponder —
    // tracking-area events go straight to the owner, no override needed.

    private lazy var linkCursorTracker = LinkCursorTracker(view: self)
    private var trackingArea: NSTrackingArea?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea { removeTrackingArea(trackingArea) }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseMoved, .mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect],
            owner: linkCursorTracker,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }
}

/// Owns a tracking area on a CradleTerminalView and sets the pointer cursor
/// when the mouse hovers over a cell whose `Terminal.link(at:mode:)` returns
/// a non-nil URL.
final class LinkCursorTracker: NSResponder {
    private weak var view: CradleTerminalView?
    private var isOverLink = false

    init(view: CradleTerminalView) {
        self.view = view
        super.init()
    }
    required init?(coder: NSCoder) { fatalError() }

    override func mouseMoved(with event: NSEvent) {
        guard let view else { return }
        let point = view.convert(event.locationInWindow, from: nil)
        updateCursor(at: point, in: view)
    }

    override func mouseExited(with event: NSEvent) {
        if isOverLink {
            isOverLink = false
            NSCursor.iBeam.set()
        }
    }

    private func updateCursor(at point: NSPoint, in view: CradleTerminalView) {
        let cols = view.terminal.cols
        let rows = view.terminal.rows
        guard cols > 0, rows > 0, view.bounds.width > 0, view.bounds.height > 0 else { return }
        let cellW = view.bounds.width / CGFloat(cols)
        let cellH = view.bounds.height / CGFloat(rows)
        let col = Int(point.x / cellW)
        var row = Int(point.y / cellH)
        if !view.isFlipped { row = rows - 1 - row }

        var nowOver = false
        if col >= 0, col < cols, row >= 0, row < rows {
            let position = Position(col: col, row: row)
            nowOver = view.terminal.link(at: .screen(position), mode: .explicitAndImplicit) != nil
        }
        if nowOver != isOverLink {
            isOverLink = nowOver
            if nowOver { NSCursor.pointingHand.set() } else { NSCursor.iBeam.set() }
        } else if nowOver {
            // Re-assert each move so SwiftTerm's iBeam reset doesn't win.
            NSCursor.pointingHand.set()
        }
    }
}
