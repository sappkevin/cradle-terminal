import SwiftUI

struct TerminalContentView: View {
    @ObservedObject var session: TerminalSession
    let fontSize: CGFloat

    var body: some View {
        TerminalViewRepresentable(
            session: session,
            fontSize: fontSize
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
