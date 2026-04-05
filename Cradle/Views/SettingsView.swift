import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        TabView {
            GeneralSettingsView(settings: settings)
                .tabItem { Label("General", systemImage: "gear") }
            ProfilesSettingsView(settings: settings)
                .tabItem { Label("Profiles", systemImage: "list.bullet") }
        }
        .frame(width: 450, height: 300)
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
