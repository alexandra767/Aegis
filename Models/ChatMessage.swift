import Foundation
import SwiftData

@Model
final class ChatMessage {
    @Attribute(.unique) var id: String
    var role: String  // "user" or "assistant"
    var content: String
    var timestamp: Date
    var providerType: String?
    var isStreaming: Bool

    var conversation: Conversation?

    init(id: String = UUID().uuidString, role: String, content: String, providerType: String? = nil) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = Date()
        self.providerType = providerType
        self.isStreaming = false
    }

    var isUser: Bool { role == "user" }
    var isAssistant: Bool { role == "assistant" }
}
