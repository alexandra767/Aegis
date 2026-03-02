import Foundation

enum AIProviderType: String, Codable, CaseIterable, Sendable {
    case apple = "apple"
    case openAI = "openai"
    case anthropic = "anthropic"
    case gemini = "gemini"
    case groq = "groq"
    case customServer = "custom_server"

    var displayName: String {
        switch self {
        case .apple: "Apple AI"
        case .openAI: "OpenAI"
        case .anthropic: "Anthropic"
        case .gemini: "Gemini"
        case .groq: "Groq"
        case .customServer: "Custom Server"
        }
    }

    var requiresAPIKey: Bool {
        switch self {
        case .apple: false
        default: true
        }
    }

    var isCloudBased: Bool {
        self != .apple
    }
}

struct AIModel: Identifiable, Sendable {
    let id: String
    let name: String
    let providerType: AIProviderType
}

struct ChatContext: Sendable {
    let conversationID: String
    let previousMessages: [(role: String, content: String)]
    let systemPrompt: String?

    init(conversationID: String, previousMessages: [(role: String, content: String)] = [], systemPrompt: String? = nil) {
        self.conversationID = conversationID
        self.previousMessages = previousMessages
        self.systemPrompt = systemPrompt
    }
}

protocol AIProvider: Sendable {
    var providerType: AIProviderType { get }
    var displayName: String { get }
    var isAvailable: Bool { get async }
    var requiresAPIKey: Bool { get }
    var availableModels: [AIModel] { get async }
    func sendMessage(_ content: String, context: ChatContext) -> AsyncThrowingStream<String, Error>
}

extension AIProvider {
    var requiresAPIKey: Bool { providerType.requiresAPIKey }
}
