import Foundation
import CoreImage

struct RTSPCameraSource: CameraSource {
    let name: String
    let rtspURL: String

    var isConnected: Bool {
        get async { false }  // Phase 4: MobileVLCKit connection check
    }

    func snapshot() async throws -> Data {
        // Phase 4: Capture frame via MobileVLCKit
        throw AIProviderError.unavailable("RTSP cameras coming in Phase 4")
    }

    func streamFrames() -> AsyncThrowingStream<CIImage, Error> {
        // Phase 4: VLCKit frame streaming
        AsyncThrowingStream { $0.finish(throwing: AIProviderError.unavailable("RTSP cameras coming in Phase 4")) }
    }
}
