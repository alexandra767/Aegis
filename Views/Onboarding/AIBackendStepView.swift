import SwiftUI

struct AIBackendStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    let providerManager: ProviderManager

    @State private var showBYOKeys = false
    @State private var showCustomServer = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Choose AI Backend")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                    Text("You can always change this later in Settings")
                        .font(.subheadline)
                        .foregroundStyle(AegisTheme.textSecondary)
                }
                .padding(.top, 24)

                // Apple AI (Recommended)
                ProviderOption(
                    title: "Apple AI",
                    subtitle: "Free, private, works offline. No setup needed.",
                    icon: "apple.logo",
                    badge: "Recommended",
                    isSelected: viewModel.selectedProviderType == .apple
                ) {
                    viewModel.selectedProviderType = .apple
                }

                // BYO API Keys section
                DisclosureGroup(isExpanded: $showBYOKeys) {
                    VStack(spacing: 16) {
                        APIKeyField(
                            provider: "OpenAI",
                            key: $viewModel.openAIKey,
                            isVerifying: viewModel.verifyingProvider == .openAI,
                            isVerified: viewModel.verificationResults[.openAI]
                        ) {
                            Task { await viewModel.verifyAPIKey(type: .openAI, providerManager: providerManager) }
                        }

                        APIKeyField(
                            provider: "Anthropic",
                            key: $viewModel.anthropicKey,
                            isVerifying: viewModel.verifyingProvider == .anthropic,
                            isVerified: viewModel.verificationResults[.anthropic]
                        ) {
                            Task { await viewModel.verifyAPIKey(type: .anthropic, providerManager: providerManager) }
                        }

                        APIKeyField(
                            provider: "Gemini",
                            key: $viewModel.geminiKey,
                            isVerifying: viewModel.verifyingProvider == .gemini,
                            isVerified: viewModel.verificationResults[.gemini]
                        ) {
                            Task { await viewModel.verifyAPIKey(type: .gemini, providerManager: providerManager) }
                        }

                        APIKeyField(
                            provider: "Groq",
                            key: $viewModel.groqKey,
                            isVerifying: viewModel.verifyingProvider == .groq,
                            isVerified: viewModel.verificationResults[.groq]
                        ) {
                            Task { await viewModel.verifyAPIKey(type: .groq, providerManager: providerManager) }
                        }
                    }
                    .padding(.top, 8)
                } label: {
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundStyle(AegisTheme.orange)
                        Text("Bring Your Own Key")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                        Spacer()
                    }
                }
                .tint(AegisTheme.textSecondary)
                .padding(16)
                .aegisCard()

                // Custom Server section
                DisclosureGroup(isExpanded: $showCustomServer) {
                    VStack(spacing: 12) {
                        TextField("Server URL (e.g., https://192.168.1.100:8000)", text: $viewModel.customServerURL)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(AegisTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(.white)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)

                        SecureField("Bearer Token (optional)", text: $viewModel.customServerToken)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(AegisTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(.white)

                        HStack {
                            CyanButton(title: "Test Connection", icon: "antenna.radiowaves.left.and.right", style: .secondary) {
                                Task { await viewModel.testServerConnection(providerManager: providerManager) }
                            }

                            if viewModel.verifyingProvider == .customServer {
                                ProgressView()
                                    .tint(AegisTheme.cyan)
                            } else if let result = viewModel.verificationResults[.customServer] {
                                Image(systemName: result ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(result ? AegisTheme.success : AegisTheme.danger)
                            }
                        }

                        Text("Connect to a self-hosted AI server. Your messages will be sent to this server.")
                            .font(.caption)
                            .foregroundStyle(AegisTheme.textMuted)
                    }
                    .padding(.top, 8)
                } label: {
                    HStack {
                        Image(systemName: "server.rack")
                            .foregroundStyle(AegisTheme.cyan)
                        Text("Custom Server")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                        Spacer()
                    }
                }
                .tint(AegisTheme.textSecondary)
                .padding(16)
                .aegisCard()

                // Privacy disclosure
                privacyDisclosure

                // Navigation buttons
                HStack(spacing: 12) {
                    Button("Back") { viewModel.previousStep() }
                        .foregroundStyle(AegisTheme.textSecondary)

                    Spacer()

                    CyanButton(title: "Continue", icon: "arrow.right") {
                        viewModel.nextStep()
                    }
                    .frame(width: 160)
                }
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
        }
    }

    @ViewBuilder
    private var privacyDisclosure: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Privacy", systemImage: "lock.shield.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AegisTheme.cyan)

            Group {
                switch viewModel.selectedProviderType {
                case .apple:
                    Text("All processing happens on your device. Nothing leaves your phone.")
                case .openAI:
                    Text("Your messages will be processed by OpenAI. See their privacy policy.")
                case .anthropic:
                    Text("Your messages will be processed by Anthropic. See their privacy policy.")
                case .gemini:
                    Text("Your messages will be processed by Google. See their privacy policy.")
                case .groq:
                    Text("Your messages will be processed by Groq. See their privacy policy.")
                case .customServer:
                    Text("Your messages will be sent to a server you specify.")
                }
            }
            .font(.caption)
            .foregroundStyle(AegisTheme.textSecondary)
        }
        .padding(12)
        .aegisCard(borderColor: AegisTheme.cyan.opacity(0.1))
    }
}

// MARK: - Supporting Views

private struct ProviderOption: View {
    let title: String
    let subtitle: String
    let icon: String
    var badge: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(AegisTheme.cyan)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                        if let badge {
                            Text(badge)
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(AegisTheme.cyan.opacity(0.2))
                                .foregroundStyle(AegisTheme.cyan)
                                .clipShape(Capsule())
                        }
                    }
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AegisTheme.textSecondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? AegisTheme.cyan : AegisTheme.textMuted)
                    .font(.title3)
            }
            .padding(16)
            .aegisCard(borderColor: isSelected ? AegisTheme.cyan.opacity(0.5) : AegisTheme.cyan.opacity(0.1))
        }
    }
}

private struct APIKeyField: View {
    let provider: String
    @Binding var key: String
    let isVerifying: Bool
    let isVerified: Bool?
    let onVerify: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(provider)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)

            HStack(spacing: 8) {
                SecureField("API Key", text: $key)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(AegisTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(.white)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                Button(action: onVerify) {
                    if isVerifying {
                        ProgressView()
                            .tint(AegisTheme.cyan)
                    } else {
                        Text("Verify")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AegisTheme.cyan)
                    }
                }
                .frame(width: 60)
                .disabled(key.isEmpty || isVerifying)

                if let isVerified {
                    Image(systemName: isVerified ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(isVerified ? AegisTheme.success : AegisTheme.danger)
                }
            }
        }
    }
}
