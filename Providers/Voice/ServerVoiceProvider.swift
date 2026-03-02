import Foundation

struct ServerVoiceProvider: VoiceProvider {
    let providerType = VoiceProviderType.customServer
    let displayName = "Server Voice"
    let baseURL: String
    let bearerToken: String?

    var isAvailable: Bool {
        get async {
            guard let url = URL(string: "\(baseURL)/api/v1/health") else { return false }
            return await NetworkService.shared.testConnection(url: url, bearerToken: bearerToken)
        }
    }

    func synthesize(text: String, voiceID: String? = nil) async throws -> Data {
        guard let url = URL(string: "\(baseURL)/api/v1/voice/synthesize") else {
            throw AIProviderError.serverError("Invalid server voice URL")
        }

        var headers: [String: String] = [:]
        if let token = bearerToken {
            headers["Authorization"] = "Bearer \(token)"
        }

        struct SynthesizeRequest: Encodable {
            let text: String
            let voice_id: String?
        }

        let body = SynthesizeRequest(text: text, voice_id: voiceID)
        return try await NetworkService.shared.post(url, body: body, headers: headers)
    }

    func availableVoices() async throws -> [VoiceOption] {
        guard let url = URL(string: "\(baseURL)/api/v1/voice/voices") else {
            throw AIProviderError.serverError("Invalid server voices URL")
        }

        var headers: [String: String] = [:]
        if let token = bearerToken {
            headers["Authorization"] = "Bearer \(token)"
        }

        struct ServerVoice: Decodable {
            let id: String
            let name: String
            let language: String?
        }

        let voices: [ServerVoice] = try await NetworkService.shared.request(url, headers: headers)
        return voices.map { voice in
            VoiceOption(
                id: voice.id,
                name: voice.name,
                language: voice.language ?? "en",
                isDefault: false,
                qualityTier: "Server"
            )
        }
    }
}
