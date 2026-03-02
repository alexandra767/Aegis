import SwiftUI

struct AIBackendSettingsView: View {
    @Environment(ProviderManager.self) private var providerManager
    @State private var showingAddKey = false
    @State private var addingType: AIProviderType?
    @State private var apiKeyInput = ""
    @State private var isVerifying = false
    @State private var verificationResult: Bool?

    // Custom server fields
    @State private var serverURL = ""
    @State private var serverToken = ""

    var body: some View {
        ZStack {
            AegisTheme.backgroundDeep.ignoresSafeArea()

            List {
                // Active provider
                Section {
                    ForEach(providerManager.configuredProviders, id: \.providerType) { provider in
                        providerRow(provider)
                    }
                } header: {
                    Text("Configured Providers")
                        .foregroundStyle(AegisTheme.cyan)
                }
                .listRowBackground(AegisTheme.surface)

                // Add provider
                Section {
                    ForEach(unconfiguredTypes, id: \.self) { type in
                        Button {
                            if type == .customServer {
                                addingType = .customServer
                                showingAddKey = true
                            } else {
                                addingType = type
                                apiKeyInput = ""
                                verificationResult = nil
                                showingAddKey = true
                            }
                        } label: {
                            Label {
                                Text("Add \(type.displayName)")
                                    .foregroundStyle(.white)
                            } icon: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(AegisTheme.cyan)
                            }
                        }
                    }
                } header: {
                    Text("Add Provider")
                        .foregroundStyle(AegisTheme.cyan)
                }
                .listRowBackground(AegisTheme.surface)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("AI Backends")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showingAddKey) {
            apiKeySheet
        }
    }

    private func providerRow(_ provider: any AIProvider) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(provider.displayName)
                        .foregroundStyle(.white)
                    if providerManager.activeProviderType == provider.providerType {
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
                    providerManager.activeProviderType = provider.providerType
                } label: {
                    Text(providerManager.activeProviderType == provider.providerType ? "Active" : "Set Active")
                        .font(.caption)
                        .foregroundStyle(AegisTheme.cyan)
                }

                Button(role: .destructive) {
                    Task { try? await providerManager.removeProvider(provider.providerType) }
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(AegisTheme.danger)
                }
            }
        }
    }

    private var unconfiguredTypes: [AIProviderType] {
        AIProviderType.allCases.filter { type in
            type != .apple && providerManager.providers[type] == nil
        }
    }

    private var apiKeySheet: some View {
        NavigationStack {
            ZStack {
                AegisTheme.backgroundDeep.ignoresSafeArea()

                VStack(spacing: 20) {
                    if addingType == .customServer {
                        serverFields
                    } else {
                        apiKeyFields
                    }

                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Add \(addingType?.displayName ?? "Provider")")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        showingAddKey = false
                    }
                    .foregroundStyle(AegisTheme.textSecondary)
                }
            }
        }
    }

    private var apiKeyFields: some View {
        VStack(spacing: 16) {
            SecureField("API Key", text: $apiKeyInput)
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
                guard let type = addingType else { return }
                isVerifying = true
                Task {
                    let success = await providerManager.verifyAPIKey(type: type, key: apiKeyInput)
                    verificationResult = success
                    if success {
                        try? await providerManager.registerProvider(type, apiKey: apiKeyInput)
                        showingAddKey = false
                    }
                    isVerifying = false
                }
            }
            .disabled(apiKeyInput.isEmpty || isVerifying)
        }
    }

    private var serverFields: some View {
        VStack(spacing: 16) {
            TextField("Server URL", text: $serverURL)
                .textFieldStyle(.plain)
                .padding(12)
                .background(AegisTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.white)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            SecureField("Bearer Token (optional)", text: $serverToken)
                .textFieldStyle(.plain)
                .padding(12)
                .background(AegisTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.white)

            CyanButton(title: "Test & Add", icon: "antenna.radiowaves.left.and.right") {
                Task {
                    isVerifying = true
                    let token = serverToken.isEmpty ? nil : serverToken
                    if let url = URL(string: "\(serverURL)/api/v1/health") {
                        let success = await NetworkService.shared.testConnection(url: url, bearerToken: token)
                        verificationResult = success
                        if success {
                            try? await providerManager.registerCustomServer(url: serverURL, token: token)
                            showingAddKey = false
                        }
                    }
                    isVerifying = false
                }
            }
            .disabled(serverURL.isEmpty || isVerifying)
        }
    }
}
