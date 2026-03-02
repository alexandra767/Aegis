import Foundation

@MainActor
@Observable
final class CameraViewModel {
    var cameras: [CameraConfig] = []
    var isLoading = false
    var errorMessage: String?

    // Phase 4: Full camera view model implementation
}
