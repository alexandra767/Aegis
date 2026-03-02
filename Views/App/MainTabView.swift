import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Chat", systemImage: "message.fill", value: 0) {
                ChatView()
            }

            Tab("Settings", systemImage: "gearshape.fill", value: 3) {
                SettingsView()
            }

            // Smart Home and Cameras tabs will be added in Phase 3 & 4
        }
        .tint(AegisTheme.cyan)
    }
}
