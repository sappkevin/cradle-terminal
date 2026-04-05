import Foundation

struct Profile: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var directory: String
    var command: String?
}
