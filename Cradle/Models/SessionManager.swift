import Foundation

class SessionManager: ObservableObject {
    @Published var sessions: [TerminalSession] = []
    @Published var activeSessionID: UUID?

    var activeSession: TerminalSession? {
        sessions.first { $0.id == activeSessionID }
    }

    @discardableResult
    func createSession(cwd: String, shell: String, autoCommand: String? = nil) -> TerminalSession {
        let session = TerminalSession(cwd: cwd, shell: shell, autoCommand: autoCommand)
        sessions.append(session)
        activeSessionID = session.id
        return session
    }

    func closeSession(id: UUID) {
        sessions.removeAll { $0.id == id }
        if activeSessionID == id {
            activeSessionID = sessions.last?.id
        }
    }
}
