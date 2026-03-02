import SwiftUI

struct SettingsView: View {
    @Environment(ProviderManager.self) private var providerManager
    @Environment(VoiceProviderManager.self) private var voiceProviderManager
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

                    // Avatar & Voice
                    Section {
                        NavigationLink {
                            avatarSettingsDestination
                        } label: {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Avatar")
                                        .foregroundStyle(.white)
                                    Text(AvatarConfig.selected.name)
                                        .font(.caption)
                                        .foregroundStyle(AegisTheme.textSecondary)
                                }
                            } icon: {
                                SmallAvatarView(avatar: AvatarConfig.selected, size: 24)
                            }
                        }

                        NavigationLink {
                            voiceSettingsDestination
                        } label: {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Voice")
                                        .foregroundStyle(.white)
                                    Text(SpeechService().selectedVoiceName)
                                        .font(.caption)
                                        .foregroundStyle(AegisTheme.textSecondary)
                                }
                            } icon: {
                                Image(systemName: "waveform")
                                    .foregroundStyle(AegisTheme.cyan)
                            }
                        }

                        NavigationLink {
                            VoiceBackendSettingsView()
                        } label: {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Voice Providers")
                                        .foregroundStyle(.white)
                                    Text("Active: \(voiceProviderManager.activeProviderType.displayName)")
                                        .font(.caption)
                                        .foregroundStyle(AegisTheme.textSecondary)
                                }
                            } icon: {
                                Image(systemName: "speaker.wave.3.fill")
                                    .foregroundStyle(AegisTheme.cyan)
                            }
                        }
                    } header: {
                        Text("Avatar & Voice")
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
                                Text("Version 1.0.0 (Phase 2)")
                                    .font(.caption)
                                    .foregroundStyle(AegisTheme.textMuted)
                            }
                        } icon: {
                            Image(systemName: "shield.checkered")
                                .foregroundStyle(AegisTheme.cyan)
                        }

                        Button {
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

    // MARK: - Settings Destinations

    private var avatarSettingsDestination: some View {
        ZStack {
            AegisTheme.backgroundDeep.ignoresSafeArea()
            ScrollView {
                AvatarPickerView()
                    .padding(.top, 20)
                    .padding(.horizontal, 16)
            }
        }
        .navigationTitle("Avatar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var voiceSettingsDestination: some View {
        ZStack {
            AegisTheme.backgroundDeep.ignoresSafeArea()
            VoicePickerView()
                .padding(.top, 20)
                .padding(.horizontal, 16)
        }
        .navigationTitle("Voice")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
