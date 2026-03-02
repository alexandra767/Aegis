import Foundation

struct ServerVoiceProvider: VoiceProvider {
    let displayName = "Server Voice"
    let baseURL: String
    let bearerToken: String?

    var isAvailable: Bool {
        get async {
            guard let url = URL(string: "\(baseURL)/api/v1/health") else { return false }
            return await NetworkService.shared.testConnection(url: url, bearerToken: bearerToken)
        }
    }

    func synthesize(text: String) async throws -> Data {
        // Phase 2: POST to /api/v1/voice/synthesize
        throw AIProviderError.unavailable("Server voice coming in Phase 2")
    }

    func availableVoices() async throws -> [VoiceOption] {
        // Phase 2: GET /api/v1/voice/voices
        return []
    }
}
