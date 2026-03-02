import SwiftUI

struct VoiceBackendSettingsView: View {
    @Environment(VoiceProviderManager.self) private var voiceProviderManager
    @State private var showingAddSheet = false
    @State private var apiKeyInput = ""
    @State private var isVerifying = false
    @State private var verificationResult: Bool?

    var body: some View {
        ZStack {
            AegisTheme.backgroundDeep.ignoresSafeArea()

            List {
                // Configured providers
                Section {
                    ForEach(voiceProviderManager.configuredProviders, id: \.providerType) { provider in
                        providerRow(provider)
                    }
                } header: {
                    Text("Configured Providers")
                        .foregroundStyle(AegisTheme.cyan)
                }
                .listRowBackground(AegisTheme.surface)

                // Add ElevenLabs (if not configured)
                if voiceProviderManager.providers[.elevenLabs] == nil {
                    Section {
                        Button {
                            apiKeyInput = ""
                            verificationResult = nil
                            showingAddSheet = true
                        } label: {
                            Label {
                                Text("Add ElevenLabs")
                                    .foregroundStyle(.white)
                            } icon: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(AegisTheme.cyan)
                            }
                        }
                    } header: {
                        Text("Add Provider")
                            .foregroundStyle(AegisTheme.cyan)
                    }
                    .listRowBackground(AegisTheme.surface)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Voice Providers")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showingAddSheet) {
            addElevenLabsSheet
        }
    }

    // MARK: - Provider Row

    private func providerRow(_ provider: any VoiceProvider) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(provider.displayName)
                        .foregroundStyle(.white)
                    if voiceProviderManager.activeProviderType == provider.providerType {
                        Text("Active")
                            .font(.caption2)
                            .foregroundStyle(AegisTheme.cyan)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AegisTheme.cyan.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                Text(provider.providerType.isCloudBased ? "Cloud" : "On-Device")
                    .font(.caption)
                    .foregroundStyle(AegisTheme.textSecondary)
            }

            Spacer()

            if provider.providerType != .apple {
                Button {
                    voiceProviderManager.activeProviderType = provider.providerType
                } label: {
                    Text(voiceProviderManager.activeProviderType == provider.providerType ? "Active" : "Set Active")
                        .font(.caption)
                        .foregroundStyle(AegisTheme.cyan)
                }

                Button(role: .destructive) {
                    Task { try? await voiceProviderManager.removeProvider(provider.providerType) }
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(AegisTheme.danger)
                }
            }
        }
    }

    // MARK: - Add ElevenLabs Sheet

    private var addElevenLabsSheet: some View {
        NavigationStack {
            ZStack {
                AegisTheme.backgroundDeep.ignoresSafeArea()

                VStack(spacing: 20) {
                    SecureField("ElevenLabs API Key", text: $apiKeyInput)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(AegisTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(.white)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    if let result = verificationResult {
                        HStack {
                            Image(systemName: result ? "checkmark.circle.fill" : "xmark.circle.fill")
                            Text(result ? "Key verified" : "Invalid key")
                        }
                        .foregroundStyle(result ? AegisTheme.success : AegisTheme.danger)
                        .font(.subheadline)
                    }

                    CyanButton(title: isVerifying ? "Verifying..." : "Verify & Add", icon: "checkmark.shield") {
                        isVerifying = true
                        Task {
                            let success = await voiceProviderManager.verifyElevenLabsKey(apiKeyInput)
                            verificationResult = success
                            if success {
                                try? await voiceProviderManager.registerElevenLabs(apiKey: apiKeyInput)
                                showingAddSheet = false
                            }
                            isVerifying = false
                        }
                    }
                    .disabled(apiKeyInput.isEmpty || isVerifying)

                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Add ElevenLabs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        showingAddSheet = false
                    }
                    .foregroundStyle(AegisTheme.textSecondary)
                }
            }
        }
    }
}
