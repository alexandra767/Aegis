import Foundation
import AVFoundation

struct AppleVoiceProvider: VoiceProvider {
    let displayName = "System Voice"

    var isAvailable: Bool {
        get async { true }
    }

    func synthesize(text: String) async throws -> Data {
        // Phase 2: Full AVSpeechSynthesizer implementation
        // For now, return empty data — voice will be implemented with full audio pipeline
        return Data()
    }

    func availableVoices() async throws -> [VoiceOption] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("en") }
            .prefix(10)
            .map { voice in
                VoiceOption(
                    id: voice.identifier,
                    name: voice.name,
                    language: voice.language,
                    isDefault: voice.quality == .enhanced
                )
            }
    }
}
