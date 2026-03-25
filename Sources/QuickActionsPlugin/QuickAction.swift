import Foundation

struct QuickAction: Codable, Identifiable, Sendable {
    var id: UUID
    var icon: String
    var label: String
    var command: String

    init(id: UUID = UUID(), icon: String, label: String, command: String) {
        self.id = id
        self.icon = icon
        self.label = label
        self.command = command
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        icon = try container.decode(String.self, forKey: .icon)
        label = try container.decode(String.self, forKey: .label)
        command = try container.decode(String.self, forKey: .command)
    }
}

struct QuickActionsConfig: Codable, Sendable {
    var actions: [QuickAction]
}
