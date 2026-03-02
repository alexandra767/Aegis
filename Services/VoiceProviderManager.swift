import Foundation
import SwiftUI

@Observable
final class VoiceProviderManager: @unchecked Sendable {
    private(set) var providers: [VoiceProviderType: any VoiceProvider] = [:]
    var activeProviderType: VoiceProviderType {
        didSet {
            UserDefaults.standard.set(activeProviderType.rawValue, forKey: "activeVoiceProvider")
        }
    }

    var selectedVoiceIDs: [VoiceProviderType: String] = [:] {
        didSet {
            if let data = try? JSONEncoder().encode(selectedVoiceIDs.mapKeys { $0.rawValue }) {
                UserDefaults.standard.set(data, forKey: "selectedVoiceIDs")
            }
        }
    }

    var activeProvider: (any VoiceProvider)? {
        providers[activeProviderType]
    }

    var configuredProviders: [any VoiceProvider] {
        VoiceProviderType.allCases.compactMap { providers[$0] }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "activeVoiceProvider")
        self.activeProviderType = VoiceProviderType(rawValue: saved ?? "") ?? .apple

        // Load stored voice selections
        if let data = UserDefaults.standard.data(forKey: "selectedVoiceIDs"),
           let dict = try? JSONDecoder().decode([String: String].self, from: data) {
            var ids: [VoiceProviderType: String] = [:]
            for (key, value) in dict {
                if let type = VoiceProviderType(rawValue: key) {
                    ids[type] = value
                }
            }
            self.selectedVoiceIDs = ids
        }

        // Always register Apple
        providers[.apple] = AppleVoiceProvider()

        // Load ElevenLabs from Keychain
        Task { await loadStoredProviders() }
    }

    func loadStoredProviders() async {
        let keychain = KeychainService.shared

        if let key = await keychain.retrieve(for: .elevenLabsKey) {
            providers[.elevenLabs] = ElevenLabsVoiceProvider(apiKey: key)
        }

        if let url = await keychain.retrieve(for: .customServerURL) {
            let token = await keychain.retrieve(for: .customServerToken)
            providers[.customServer] = ServerVoiceProvider(baseURL: url, bearerToken: token)
        }
    }

    func registerElevenLabs(apiKey: String) async throws {
        try await KeychainService.shared.save(apiKey, for: .elevenLabsKey)
        providers[.elevenLabs] = ElevenLabsVoiceProvider(apiKey: apiKey)
    }

    func removeElevenLabs() async throws {
        try await KeychainService.shared.delete(for: .elevenLabsKey)
        providers.removeValue(forKey: .elevenLabs)
        if activeProviderType == .elevenLabs {
            activeProviderType = .apple
        }
    }

    func verifyElevenLabsKey(_ key: String) async -> Bool {
        let provider = ElevenLabsVoiceProvider(apiKey: key)
        return await provider.isAvailable
    }

    func removeProvider(_ type: VoiceProviderType) async throws {
        switch type {
        case .apple:
            return // Can't remove Apple
        case .elevenLabs:
            try await removeElevenLabs()
        case .customServer:
            providers.removeValue(forKey: .customServer)
            if activeProviderType == .customServer {
                activeProviderType = .apple
            }
        }
    }

    func selectedVoiceID(for type: VoiceProviderType) -> String? {
        selectedVoiceIDs[type]
    }

    func setSelectedVoiceID(_ id: String, for type: VoiceProviderType) {
        selectedVoiceIDs[type] = id
    }
}

// MARK: - Dictionary Key Mapping Helper

private extension Dictionary {
    func mapKeys<T: Hashable>(_ transform: (Key) -> T) -> [T: Value] {
        var result: [T: Value] = [:]
        for (key, value) in self {
            result[transform(key)] = value
        }
        return result
    }
}
