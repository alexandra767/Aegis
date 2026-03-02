import Foundation

protocol VoiceProvider: Sendable {
    var displayName: String { get }
    var isAvailable: Bool { get async }
    func synthesize(text: String) async throws -> Data  // Audio data (PCM/MP3)
    func availableVoices() async throws -> [VoiceOption]
}

struct VoiceOption: Identifiable, Sendable {
    let id: String
    let name: String
    let language: String
    let isDefault: Bool
}
