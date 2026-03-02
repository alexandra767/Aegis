import Foundation

@MainActor
@Observable
final class SmartHomeViewModel {
    var rooms: [SmartRoom] = []
    var scenes: [SmartScene] = []
    var isLoading = false
    var errorMessage: String?

    // Phase 3: Full smart home view model implementation
}
