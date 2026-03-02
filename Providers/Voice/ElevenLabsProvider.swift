import Foundation

struct ElevenLabsVoiceProvider: VoiceProvider {
    let displayName = "ElevenLabs"
    let apiKey: String

    var isAvailable: Bool {
        get async { !apiKey.isEmpty }
    }

    func synthesize(text: String) async throws -> Data {
        // Phase 2: Full ElevenLabs TTS implementation
        // POST to https://api.elevenlabs.io/v1/text-to-speech/{voice_id}
        throw AIProviderError.unavailable("ElevenLabs voice coming in Phase 2")
    }

    func availableVoices() async throws -> [VoiceOption] {
        // Phase 2: Fetch from https://api.elevenlabs.io/v1/voices
        return []
    }
}
