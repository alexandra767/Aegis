import SwiftUI
import SwiftData

@main
struct AegisApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var providerManager = ProviderManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(providerManager)
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [Conversation.self, ChatMessage.self, CameraConfig.self])
    }
}
