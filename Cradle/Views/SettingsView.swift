import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        TabView {
            GeneralSettingsView(settings: settings)
                .tabItem { Label("General", systemImage: "gear") }
            FeaturesSettingsView(settings: settings)
                .tabItem { Label("Features", systemImage: "switch.2") }
            ProfilesSettingsView(settings: settings)
                .tabItem { Label("Profiles", systemImage: "list.bullet") }
        }
        .frame(width: 520, height: 420)
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            HStack {
                Text("Default Directory")
                Spacer()
                Text(settings.defaultDirectory)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: 200)
                Button("Choose...") {
                    let panel = NSOpenPanel()
                    panel.canChooseDirectories = true
                    panel.canChooseFiles = false
                    panel.allowsMultipleSelection = false
                    if panel.runModal() == .OK, let url = panel.url {
                        settings.defaultDirectory = url.path
                    }
                }
            }

            TextField("Shell (leave empty to auto-detect)", text: $settings.shell)
            TextField("Auto-run Command (e.g. claude)", text: $settings.autoCommand)

            HStack {
                Text("Font Size: \(Int(settings.fontSize))")
                Slider(value: $settings.fontSize, in: 10...24, step: 1)
            }
        }
        .padding()
    }
}

struct FeaturesSettingsView: View {
    @ObservedObject var settings: AppSettings
    @State private var installResult: String?

    var body: some View {
        Form {
            Section("AI") {
                Toggle("AI Prompt Inspector sidebar", isOn: $settings.aiInspectorEnabled)
                Toggle("Generate documentation from replays", isOn: $settings.claudeDocGenEnabled)
                TextField("Claude CLI path (auto if empty)", text: $settings.claudeCLIPath)
            }
            Section("Shell Integration") {
                Toggle("Track commands & cwd (OSC 133 / 7)", isOn: $settings.shellIntegrationEnabled)
                Toggle("copyfile / pastefile helpers", isOn: $settings.copyfileHelpersEnabled)
                Toggle("Inline autosuggestions (zsh)", isOn: $settings.intellisenseEnabled)
                HStack {
                    Button("Install Shell Integration…") { installShellIntegration() }
                    if let r = installResult {
                        Text(r).font(.caption).foregroundColor(.secondary)
                    }
                }
            }
            Section("Instant Replay") {
                Toggle("Record session for replay", isOn: $settings.instantReplayEnabled)
                Toggle("Allow exporting replays", isOn: $settings.replayExportEnabled)
                Stepper("Buffer size: \(settings.replayBufferSizeMB) MB",
                        value: $settings.replayBufferSizeMB, in: 1...500)
            }
        }
        .padding()
    }

    private func installShellIntegration() {
        // Copies bundled scripts into ~/.config/cradle and prints the line(s)
        // the user should add to their rc file. We don't auto-edit rc files
        // — show the user what to add and let them paste it themselves.
        guard let resPath = Bundle.main.resourcePath else {
            installResult = "Bundle resources not found."
            return
        }
        let src = (resPath as NSString).appendingPathComponent("shell-integration")
        let destDir = ("~/.config/cradle" as NSString).expandingTildeInPath
        do {
            try FileManager.default.createDirectory(atPath: destDir, withIntermediateDirectories: true)
            for name in ["cradle.zsh", "cradle.bash", "cradle.fish"] {
                let s = (src as NSString).appendingPathComponent(name)
                let d = (destDir as NSString).appendingPathComponent(name)
                if FileManager.default.fileExists(atPath: d) {
                    try? FileManager.default.removeItem(atPath: d)
                }
                if FileManager.default.fileExists(atPath: s) {
                    try FileManager.default.copyItem(atPath: s, toPath: d)
                }
            }
            installResult = "Installed to \(destDir). Add `source ~/.config/cradle/cradle.zsh` to your ~/.zshrc."
        } catch {
            installResult = "Failed: \(error.localizedDescription)"
        }
    }
}

struct ProfilesSettingsView: View {
    @ObservedObject var settings: AppSettings
    @State private var editingProfile: Profile?
    @State private var showEditor = false

    var body: some View {
        VStack {
            List {
                ForEach(settings.profiles) { profile in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(profile.name).font(.headline)
                            Text(profile.directory).font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Edit") {
                            editingProfile = profile
                            showEditor = true
                        }
                    }
                }
                .onDelete { indexSet in
                    var profiles = settings.profiles
                    profiles.remove(atOffsets: indexSet)
                    settings.profiles = profiles
                }
            }

            HStack {
                Spacer()
                Button("Add Profile") {
                    editingProfile = nil
                    showEditor = true
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .sheet(isPresented: $showEditor) {
            ProfileEditorView(settings: settings, profile: editingProfile)
        }
    }
}
