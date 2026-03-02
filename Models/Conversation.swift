import Foundation
import SwiftData

@Model
final class Conversation {
    @Attribute(.unique) var id: String
    var title: String
    @Relationship(deleteRule: .cascade) var messages: [ChatMessage]
    var createdAt: Date
    var updatedAt: Date
    var providerType: String

    init(id: String = UUID().uuidString, title: String = "New Conversation", providerType: String = "apple") {
        self.id = id
        self.title = title
        self.messages = []
        self.createdAt = Date()
        self.updatedAt = Date()
        self.providerType = providerType
    }

    /// Auto-generate title from first user message
    func updateTitle(from firstMessage: String) {
        let trimmed = firstMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= 50 {
            title = trimmed
        } else {
            title = String(trimmed.prefix(47)) + "..."
        }
    }
}
