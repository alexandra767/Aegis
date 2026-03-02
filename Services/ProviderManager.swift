import Foundation
import SwiftUI

@Observable
final class ProviderManager: @unchecked Sendable {
    private(set) var providers: [AIProviderType: any AIProvider] = [:]
    var activeProviderType: AIProviderType {
        didSet {
            UserDefaults.standard.set(activeProviderType.rawValue, forKey: "activeAIProvider")
        }
    }
    var selectedModelID: String? {
        didSet {
            if let id = selectedModelID {
                UserDefaults.standard.set(id, forKey: "selectedModelID")
            }
        }
    }

    var activeProvider: (any AIProvider)? {
        providers[activeProviderType]
    }

    var configuredProviders: [any AIProvider] {
        AIProviderType.allCases.compactMap { providers[$0] }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "activeAIProvider")
        self.activeProviderType = AIProviderType(rawValue: saved ?? "") ?? .apple
        self.selectedModelID = UserDefaults.standard.string(forKey: "selectedModelID")

        // Always register Apple AI
        providers[.apple] = AppleAIProvider()

        // Check Keychain for stored keys and register providers
        Task { await loadStoredProviders() }
    }

    func loadStoredProviders() async {
        let keychain = KeychainService.shared

        if let key = await keychain.retrieve(for: .openAIKey) {
            providers[.openAI] = OpenAIProvider(apiKey: key)
        }

        if let key = await keychain.retrieve(for: .anthropicKey) {
            providers[.anthropic] = AnthropicProvider(apiKey: key)
        }

        if let key = await keychain.retrieve(for: .geminiKey) {
            providers[.gemini] = GeminiProvider(apiKey: key)
        }

        if let key = await keychain.retrieve(for: .groqKey) {
            providers[.groq] = GroqProvider(apiKey: key)
        }

        if let url = await keychain.retrieve(for: .customServerURL) {
            let token = await keychain.retrieve(for: .customServerToken)
            providers[.customServer] = CustomServerProvider(baseURL: url, bearerToken: token)
        }
    }

    func registerProvider(_ type: AIProviderType, apiKey: String) async throws {
        let keychain = KeychainService.shared

        switch type {
        case .openAI:
            try await keychain.save(apiKey, for: .openAIKey)
            providers[.openAI] = OpenAIProvider(apiKey: apiKey)
        case .anthropic:
            try await keychain.save(apiKey, for: .anthropicKey)
            providers[.anthropic] = AnthropicProvider(apiKey: apiKey)
        case .gemini:
            try await keychain.save(apiKey, for: .geminiKey)
            providers[.gemini] = GeminiProvider(apiKey: apiKey)
        case .groq:
            try await keychain.save(apiKey, for: .groqKey)
            providers[.groq] = GroqProvider(apiKey: apiKey)
        case .apple, .customServer:
            break
        }
    }

    func registerCustomServer(url: String, token: String?) async throws {
        let keychain = KeychainService.shared
        try await keychain.save(url, for: .customServerURL)
        if let token {
            try await keychain.save(token, for: .customServerToken)
        }
        providers[.customServer] = CustomServerProvider(baseURL: url, bearerToken: token)
    }

    func removeProvider(_ type: AIProviderType) async throws {
        let keychain = KeychainService.shared

        switch type {
        case .openAI: try await keychain.delete(for: .openAIKey)
        case .anthropic: try await keychain.delete(for: .anthropicKey)
        case .gemini: try await keychain.delete(for: .geminiKey)
        case .groq: try await keychain.delete(for: .groqKey)
        case .customServer:
            try await keychain.delete(for: .customServerURL)
            try await keychain.delete(for: .customServerToken)
        case .apple:
            return  // Can't remove Apple AI
        }

        providers.removeValue(forKey: type)

        // If active provider was removed, fall back to Apple
        if activeProviderType == type {
            activeProviderType = .apple
        }
    }

    func verifyAPIKey(type: AIProviderType, key: String) async -> Bool {
        switch type {
        case .openAI:
            let provider = OpenAIProvider(apiKey: key)
            return await provider.isAvailable
        case .anthropic:
            let provider = AnthropicProvider(apiKey: key)
            return await provider.isAvailable
        case .gemini:
            let provider = GeminiProvider(apiKey: key)
            return await provider.isAvailable
        case .groq:
            let provider = GroqProvider(apiKey: key)
            return await provider.isAvailable
        case .customServer, .apple:
            return true
        }
    }
}
