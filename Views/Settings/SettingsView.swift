import SwiftUI

struct SettingsView: View {
    @Environment(ProviderManager.self) private var providerManager
    @State private var settingsVM = SettingsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AegisTheme.backgroundDeep.ignoresSafeArea()

                List {
                    // AI Backends
                    Section {
                        NavigationLink {
                            AIBackendSettingsView()
                        } label: {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("AI Backends")
                                        .foregroundStyle(.white)
                                    Text("Active: \(providerManager.activeProviderType.displayName)")
                                        .font(.caption)
                                        .foregroundStyle(AegisTheme.textSecondary)
                                }
                            } icon: {
                                Image(systemName: "brain")
                                    .foregroundStyle(AegisTheme.cyan)
                            }
                        }
                    } header: {
                        Text("AI")
                            .foregroundStyle(AegisTheme.cyan)
                    }
                    .listRowBackground(AegisTheme.surface)

                    // Smart Home (Phase 3 placeholder)
                    Section {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Smart Home")
                                    .foregroundStyle(.white)
                                Text("Coming soon")
                                    .font(.caption)
                                    .foregroundStyle(AegisTheme.textMuted)
                            }
                        } icon: {
                            Image(systemName: "house.fill")
                                .foregroundStyle(AegisTheme.cyan.opacity(0.5))
                        }
                    } header: {
                        Text("Home")
                            .foregroundStyle(AegisTheme.cyan)
                    }
                    .listRowBackground(AegisTheme.surface)

                    // Cameras (Phase 4 placeholder)
                    Section {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Cameras")
                                    .foregroundStyle(.white)
                                Text("Coming soon")
                                    .font(.caption)
                                    .foregroundStyle(AegisTheme.textMuted)
                            }
                        } icon: {
                            Image(systemName: "camera.fill")
                                .foregroundStyle(AegisTheme.cyan.opacity(0.5))
                        }
                    } header: {
                        Text("Security")
                            .foregroundStyle(AegisTheme.cyan)
                    }
                    .listRowBackground(AegisTheme.surface)

                    // About
                    Section {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Aegis")
                                    .foregroundStyle(.white)
                                Text("Version 1.0.0 (Phase 1)")
                                    .font(.caption)
                                    .foregroundStyle(AegisTheme.textMuted)
                            }
                        } icon: {
                            Image(systemName: "shield.checkered")
                                .foregroundStyle(AegisTheme.cyan)
                        }

                        Button {
                            // Reset onboarding
                            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                        } label: {
                            Label("Re-run Onboarding", systemImage: "arrow.counterclockwise")
                                .foregroundStyle(AegisTheme.orange)
                        }
                    } header: {
                        Text("About")
                            .foregroundStyle(AegisTheme.cyan)
                    }
                    .listRowBackground(AegisTheme.surface)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
