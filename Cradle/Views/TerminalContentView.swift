import SwiftUI

struct TerminalContentView: View {
    @ObservedObject var session: TerminalSession
    @ObservedObject var settings: AppSettings
    let fontSize: CGFloat

    @State private var showInspector: Bool = false
    @State private var showReplay: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            TerminalViewRepresentable(
                session: session,
                fontSize: fontSize,
                settings: settings
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if settings.aiInspectorEnabled && showInspector {
                Divider()
                AIInspectorView(settings: settings)
            }
        }
        .toolbar {
            if settings.aiInspectorEnabled {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showInspector.toggle()
                    } label: {
                        Image(systemName: "sparkles")
                    }
                    .help("Toggle Claude Prompt Inspector")
                }
            }
            if settings.instantReplayEnabled {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showReplay = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                    .help("Instant Replay (⌘⇧R)")
                    .keyboardShortcut("r", modifiers: [.command, .shift])
                }
            }
        }
        .sheet(isPresented: $showReplay) {
            ReplayView(session: session, settings: settings)
        }
    }
}
