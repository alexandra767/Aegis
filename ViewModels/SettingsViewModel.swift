import Foundation
import SwiftUI

@Observable
final class SettingsViewModel {
    var showingAPIKeyEntry = false
    var editingProviderType: AIProviderType?
    var apiKeyInput = ""
    var isVerifying = false
    var verificationResult: Bool?

    func maskedKey(for type: AIProviderType) async -> String? {
        let keychain = KeychainService.shared
        let key: KeychainService.Key
        switch type {
        case .openAI: key = .openAIKey
        case .anthropic: key = .anthropicKey
        case .gemini: key = .geminiKey
        case .groq: key = .groqKey
        default: return nil
        }
        return await keychain.maskedPreview(for: key)
    }

    func serverURL() async -> String? {
        await KeychainService.shared.retrieve(for: .customServerURL)
    }
}
