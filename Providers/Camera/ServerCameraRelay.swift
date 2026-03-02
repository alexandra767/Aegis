import Foundation
import CoreImage

struct ServerCameraRelay: CameraSource {
    let name: String
    let baseURL: String
    let bearerToken: String?

    var isConnected: Bool {
        get async { false }  // Phase 4: WebSocket connection check
    }

    func snapshot() async throws -> Data {
        // Phase 4: GET /api/v1/camera/snapshot/{name}
        throw AIProviderError.unavailable("Server cameras coming in Phase 4")
    }

    func streamFrames() -> AsyncThrowingStream<CIImage, Error> {
        // Phase 4: WebSocket binary JPEG frames
        AsyncThrowingStream { $0.finish(throwing: AIProviderError.unavailable("Server cameras coming in Phase 4")) }
    }
}
