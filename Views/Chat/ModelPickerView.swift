import SwiftUI

struct ModelPickerView: View {
    @Environment(ProviderManager.self) private var providerManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AegisTheme.backgroundDeep.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(providerManager.configuredProviders, id: \.providerType) { provider in
                            providerCard(for: provider)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("AI Provider")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AegisTheme.cyan)
                }
            }
        }
    }

    private func providerCard(for provider: any AIProvider) -> some View {
        let isActive = providerManager.activeProviderType == provider.providerType

        return Button {
            providerManager.activeProviderType = provider.providerType
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: iconForProvider(provider.providerType))
                    .font(.title3)
                    .foregroundStyle(AegisTheme.cyan)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(provider.displayName)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)

                    Text(provider.providerType.isCloudBased ? "Cloud" : "On-Device")
                        .font(.caption)
                        .foregroundStyle(provider.providerType.isCloudBased ? AegisTheme.orange : AegisTheme.success)
                }

                Spacer()

                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AegisTheme.cyan)
                }
            }
            .padding(14)
            .aegisCard(borderColor: isActive ? AegisTheme.cyan.opacity(0.5) : AegisTheme.cyan.opacity(0.1))
        }
    }

    private func iconForProvider(_ type: AIProviderType) -> String {
        switch type {
        case .apple: "apple.logo"
        case .openAI: "brain"
        case .anthropic: "sparkles"
        case .gemini: "diamond"
        case .groq: "bolt.fill"
        case .customServer: "server.rack"
        }
    }
}
