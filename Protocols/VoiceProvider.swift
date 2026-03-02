import Foundation

enum VoiceProviderType: String, CaseIterable, Sendable {
    case apple = "apple"
    case elevenLabs = "elevenlabs"
    case customServer = "custom_server"

    var displayName: String {
        switch self {
        case .apple: "System Voice"
        case .elevenLabs: "ElevenLabs"
        case .customServer: "Custom Server"
        }
    }

    var requiresAPIKey: Bool {
        switch self {
        case .apple: false
        case .elevenLabs, .customServer: true
        }
    }

    var isCloudBased: Bool {
        self != .apple
    }
}

protocol VoiceProvider: Sendable {
    var providerType: VoiceProviderType { get }
    var displayName: String { get }
    var isAvailable: Bool { get async }
    func synthesize(text: String, voiceID: String?) async throws -> Data
    func availableVoices() async throws -> [VoiceOption]
}

struct VoiceOption: Identifiable, Sendable {
    let id: String
    let name: String
    let language: String
    let isDefault: Bool
    var qualityTier: String = "Default"
}
