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

    /// Build the env array for the spawned shell. When `settings` is provided,
    /// per-feature toggles are forwarded so bundled shell-integration scripts
    /// can respect them, and `CRADLE_RESOURCES` is set to the bundle resource
    /// path so the scripts can locate things like zsh-autosuggestions.
    static func shellEnvironment(settings: AppSettings? = nil) -> [String] {
        var env = ProcessInfo.processInfo.environment
        env["TERM"] = "xterm-256color"
        env["LANG"] = "en_US.UTF-8"

        if let resourcePath = Bundle.main.resourcePath {
            env["CRADLE_RESOURCES"] = resourcePath
        }
        if let settings {
            env["CRADLE_INTELLISENSE_ENABLED"] = settings.intellisenseEnabled ? "1" : "0"
            env["CRADLE_COPYFILE_ENABLED"] = settings.copyfileHelpersEnabled ? "1" : "0"
        }

        return env.map { "\($0.key)=\($0.value)" }
    }
}
