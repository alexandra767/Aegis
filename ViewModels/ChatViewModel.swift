import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable
final class ChatViewModel {
    var currentMessage = ""
    var isStreaming = false
    var errorMessage: String?
    var activeConversation: Conversation?
    private var streamTask: Task<Void, Never>?

    private let modelContext: ModelContext
    private let providerManager: ProviderManager

    init(modelContext: ModelContext, providerManager: ProviderManager) {
        self.modelContext = modelContext
        self.providerManager = providerManager
    }

    func sendMessage() {
        let text = currentMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isStreaming else { return }

        currentMessage = ""
        errorMessage = nil

        // Create or use existing conversation
        if activeConversation == nil {
            let conv = Conversation(providerType: providerManager.activeProviderType.rawValue)
            modelContext.insert(conv)
            activeConversation = conv
        }

        guard let conversation = activeConversation else { return }

        // Add user message
        let userMessage = ChatMessage(role: "user", content: text)
        userMessage.conversation = conversation
        conversation.messages.append(userMessage)
        conversation.updatedAt = Date()

        // Auto-title from first message
        if conversation.messages.count == 1 {
            conversation.updateTitle(from: text)
        }

        // Create placeholder assistant message
        let assistantMessage = ChatMessage(
            role: "assistant",
            content: "",
            providerType: providerManager.activeProviderType.rawValue
        )
        assistantMessage.isStreaming = true
        assistantMessage.conversation = conversation
        conversation.messages.append(assistantMessage)

        try? modelContext.save()

        // Stream response
        isStreaming = true
        streamTask = Task {
            await streamResponse(text: text, assistantMessage: assistantMessage, conversation: conversation)
        }
    }

    private func streamResponse(text: String, assistantMessage: ChatMessage, conversation: Conversation) async {
        guard let provider = providerManager.activeProvider else {
            assistantMessage.content = "No AI provider configured. Please set up a provider in Settings."
            assistantMessage.isStreaming = false
            isStreaming = false
            try? modelContext.save()
            return
        }

        // Build context from conversation history (exclude current exchange)
        let previousMessages = conversation.messages
            .filter { $0.id != assistantMessage.id }
            .dropLast()  // Drop the user message we just added (it's the prompt)
            .map { (role: $0.role, content: $0.content) }

        let context = ChatContext(
            conversationID: conversation.id,
            previousMessages: Array(previousMessages),
            systemPrompt: "You are Aegis, a helpful AI assistant. Be concise and helpful."
        )

        let stream = provider.sendMessage(text, context: context)

        do {
            for try await chunk in stream {
                assistantMessage.content += chunk
            }
        } catch {
            if assistantMessage.content.isEmpty {
                assistantMessage.content = "Error: \(error.localizedDescription)"
            }
            errorMessage = error.localizedDescription
        }

        assistantMessage.isStreaming = false
        isStreaming = false
        try? modelContext.save()
    }

    func stopStreaming() {
        streamTask?.cancel()
        streamTask = nil
        isStreaming = false
    }

    func newConversation() {
        activeConversation = nil
        currentMessage = ""
        errorMessage = nil
    }

    func loadConversation(_ conversation: Conversation) {
        activeConversation = conversation
        errorMessage = nil
    }

    func deleteConversation(_ conversation: Conversation) {
        if activeConversation?.id == conversation.id {
            activeConversation = nil
        }
        modelContext.delete(conversation)
        try? modelContext.save()
    }
}
