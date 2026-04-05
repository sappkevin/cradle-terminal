import Foundation

enum ShellEnvironment {
    static func defaultShell() -> String {
        if let shell = UserDefaults.standard.string(forKey: "defaultShell"), !shell.isEmpty {
            return shell
        }
        if let shell = ProcessInfo.processInfo.environment["SHELL"], !shell.isEmpty {
            return shell
        }
        return "/bin/zsh"
    }

    static func shellEnvironment() -> [String] {
        var env = ProcessInfo.processInfo.environment
        env["TERM"] = "xterm-256color"
        env["LANG"] = "en_US.UTF-8"
        return env.map { "\($0.key)=\($0.value)" }
    }
}
