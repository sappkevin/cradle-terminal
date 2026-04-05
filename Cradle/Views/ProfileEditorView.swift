import SwiftUI

struct ProfileEditorView: View {
    @ObservedObject var settings: AppSettings
    @Environment(\.dismiss) var dismiss

    @State private var name: String
    @State private var directory: String
    @State private var command: String
    private let existingID: UUID?

    init(settings: AppSettings, profile: Profile?) {
        self.settings = settings
        self.existingID = profile?.id
        _name = State(initialValue: profile?.name ?? "")
        _directory = State(initialValue: profile?.directory ?? NSHomeDirectory())
        _command = State(initialValue: profile?.command ?? "")
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(existingID == nil ? "New Profile" : "Edit Profile")
                .font(.headline)

            Form {
                TextField("Name", text: $name)
                HStack {
                    TextField("Directory", text: $directory)
                    Button("Choose...") {
                        let panel = NSOpenPanel()
                        panel.canChooseDirectories = true
                        panel.canChooseFiles = false
                        if panel.runModal() == .OK, let url = panel.url {
                            directory = url.path
                        }
                    }
                }
                TextField("Command (optional)", text: $command)
            }

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") {
                    let profile = Profile(
                        id: existingID ?? UUID(),
                        name: name,
                        directory: directory,
                        command: command.isEmpty ? nil : command
                    )
                    var profiles = settings.profiles
                    if let idx = profiles.firstIndex(where: { $0.id == existingID }) {
                        profiles[idx] = profile
                    } else {
                        profiles.append(profile)
                    }
                    settings.profiles = profiles
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
    }
}
