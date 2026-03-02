import SwiftUI
import SwiftData

@main
struct AegisApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var providerManager = ProviderManager()
    @State private var voiceProviderManager = VoiceProviderManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(providerManager)
                .environment(voiceProviderManager)
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [Conversation.self, ChatMessage.self, CameraConfig.self])
    }
}
