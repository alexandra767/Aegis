import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

struct AppleAIProvider: AIProvider {
    let providerType: AIProviderType = .apple
    let displayName = "Apple AI"

    var isAvailable: Bool {
        get async {
            #if canImport(FoundationModels)
            return SystemLanguageModel.default.isAvailable
            #else
            return false
            #endif
        }
    }

    var availableModels: [AIModel] {
        get async {
            [AIModel(id: "apple-on-device", name: "Apple On-Device", providerType: .apple)]
        }
    }

    func sendMessage(_ content: String, context: ChatContext) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                #if canImport(FoundationModels)
                do {
                    let session = LanguageModelSession()

                    // Build conversation context
                    var prompt = ""
                    if let systemPrompt = context.systemPrompt {
                        prompt += "System: \(systemPrompt)\n\n"
                    }
                    for msg in context.previousMessages {
                        prompt += "\(msg.role == "user" ? "User" : "Assistant"): \(msg.content)\n\n"
                    }
                    prompt += "User: \(content)"

                    let stream = session.streamResponse(to: prompt)
                    for try await partial in stream {
                        if let text = partial.deltaContent {
                            continuation.yield(text)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
                #else
                continuation.finish(throwing: AIProviderError.unavailable("Apple Foundation Models not available on this device"))
                #endif
            }
        }
    }
}

enum AIProviderError: Error, LocalizedError {
    case unavailable(String)
    case invalidAPIKey
    case rateLimited
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .unavailable(let msg): msg
        case .invalidAPIKey: "Invalid API key"
        case .rateLimited: "Rate limited. Please wait and try again."
        case .serverError(let msg): "Server error: \(msg)"
        }
    }
}
