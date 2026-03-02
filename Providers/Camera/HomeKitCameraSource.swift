import Foundation
import CoreImage

struct HomeKitCameraSource: CameraSource {
    let name: String
    let accessoryID: String

    var isConnected: Bool {
        get async { false }  // Phase 4: HMCameraStreamControl check
    }

    func snapshot() async throws -> Data {
        // Phase 4: HMCameraSnapshotControl
        throw AIProviderError.unavailable("HomeKit cameras coming in Phase 4")
    }

    func streamFrames() -> AsyncThrowingStream<CIImage, Error> {
        // Phase 4: HMCameraStreamControl
        AsyncThrowingStream { $0.finish(throwing: AIProviderError.unavailable("HomeKit cameras coming in Phase 4")) }
    }
}
