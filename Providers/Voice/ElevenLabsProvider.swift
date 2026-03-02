import Foundation

struct ElevenLabsVoiceProvider: VoiceProvider {
    let providerType = VoiceProviderType.elevenLabs
    let displayName = "ElevenLabs"
    let apiKey: String

    private static let defaultVoiceID = "21m00Tcm4TlvDq8ikWAM" // Rachel

    var isAvailable: Bool {
        get async {
            guard !apiKey.isEmpty else { return false }
            do {
                let voices = try await availableVoices()
                return !voices.isEmpty
            } catch {
                return false
            }
        }
    }

    func synthesize(text: String, voiceID: String? = nil) async throws -> Data {
        let id = voiceID ?? Self.defaultVoiceID
        guard let url = URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(id)") else {
            throw AIProviderError.serverError("Invalid ElevenLabs URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("audio/mpeg", forHTTPHeaderField: "Accept")
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")

        let body: [String: Any] = [
            "text": text,
            "model_id": "eleven_monolingual_v1",
            "voice_settings": [
                "stability": 0.5,
                "similarity_boost": 0.75
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AIProviderError.serverError("Invalid ElevenLabs response")
        }
        guard (200...299).contains(http.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? ""
            throw AIProviderError.serverError("ElevenLabs HTTP \(http.statusCode): \(errorBody)")
        }

        return data // MP3 audio data
    }

    func availableVoices() async throws -> [VoiceOption] {
        guard let url = URL(string: "https://api.elevenlabs.io/v1/voices") else {
            throw AIProviderError.serverError("Invalid ElevenLabs voices URL")
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw AIProviderError.invalidAPIKey
        }

        let parsed = try JSONDecoder().decode(ElevenLabsVoicesResponse.self, from: data)
        return parsed.voices.map { voice in
            VoiceOption(
                id: voice.voice_id,
                name: voice.name,
                language: voice.labels?.language ?? "en",
                isDefault: voice.voice_id == Self.defaultVoiceID,
                qualityTier: voice.labels?.use_case ?? "General"
            )
        }
    }
}

// MARK: - API Response Models

private struct ElevenLabsVoicesResponse: Decodable {
    let voices: [ElevenLabsVoice]
}

private struct ElevenLabsVoice: Decodable {
    let voice_id: String
    let name: String
    let labels: ElevenLabsVoiceLabels?
}

private struct ElevenLabsVoiceLabels: Decodable {
    let language: String?
    let use_case: String?
}
