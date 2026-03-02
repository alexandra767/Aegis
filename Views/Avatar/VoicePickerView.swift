import SwiftUI
import AVFoundation

struct VoicePickerView: View {
    @Environment(VoiceProviderManager.self) private var voiceProviderManager
    @State private var speechService = SpeechService()
    @State private var previewingVoiceID: String?
    @State private var selectedTab: VoiceProviderType = .apple
    @State private var cloudVoices: [VoiceOption] = []
    @State private var isLoadingCloudVoices = false
    @State private var cloudVoiceError: String?
    var compact: Bool = false

    private var availableTabs: [VoiceProviderType] {
        VoiceProviderType.allCases.filter { voiceProviderManager.providers[$0] != nil }
    }

    var body: some View {
        VStack(spacing: compact ? 8 : 16) {
            if !compact {
                Text("Choose a Voice")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text("Tap the play button to preview")
                    .font(.caption)
                    .foregroundStyle(AegisTheme.textMuted)
            }

            // Provider tabs (only show if more than one provider)
            if availableTabs.count > 1 {
                Picker("Provider", selection: $selectedTab) {
                    ForEach(availableTabs, id: \.self) { tab in
                        Text(tabLabel(for: tab)).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, compact ? 0 : 16)
                .onChange(of: selectedTab) { _, newTab in
                    if newTab != .apple {
                        loadCloudVoices(for: newTab)
                    }
                }
            }

            // Voice list
            if selectedTab == .apple {
                appleVoiceList
            } else {
                cloudVoiceList
            }
        }
        .onAppear {
            selectedTab = availableTabs.first ?? .apple
        }
    }

    // MARK: - Tab Labels

    private func tabLabel(for type: VoiceProviderType) -> String {
        switch type {
        case .apple: "System"
        case .elevenLabs: "ElevenLabs"
        case .customServer: "Server"
        }
    }

    // MARK: - Apple Voice List

    private var appleVoiceList: some View {
        let voiceGroups = speechService.availableVoices()

        return Group {
            if voiceGroups.isEmpty {
                noVoicesView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(voiceGroups, id: \.quality) { group in
                            voiceSection(quality: group.quality, voices: group.voices)
                        }
                    }
                    .padding(.horizontal, compact ? 0 : 16)
                }
            }
        }
    }

    // MARK: - Cloud Voice List

    private var cloudVoiceList: some View {
        Group {
            if isLoadingCloudVoices {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(AegisTheme.cyan)
                    Text("Loading voices...")
                        .foregroundStyle(AegisTheme.textSecondary)
                }
                .frame(maxHeight: .infinity)
            } else if let error = cloudVoiceError {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 32))
                        .foregroundStyle(AegisTheme.orange)
                    Text(error)
                        .foregroundStyle(AegisTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
            } else if cloudVoices.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "speaker.slash")
                        .font(.system(size: 32))
                        .foregroundStyle(AegisTheme.textMuted)
                    Text("No voices available")
                        .foregroundStyle(AegisTheme.textSecondary)
                }
                .padding(24)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(cloudVoices) { voice in
                            cloudVoiceRow(voice)
                        }
                    }
                    .padding(.horizontal, compact ? 0 : 16)
                }
            }
        }
    }

    private func cloudVoiceRow(_ voice: VoiceOption) -> some View {
        let isSelected = voiceProviderManager.selectedVoiceID(for: selectedTab) == voice.id

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(voice.name)
                    .font(.subheadline)
                    .foregroundStyle(isSelected ? AegisTheme.cyan : .white)

                Text(voice.qualityTier)
                    .font(.caption2)
                    .foregroundStyle(AegisTheme.textMuted)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AegisTheme.cyan)
            } else {
                Button {
                    voiceProviderManager.setSelectedVoiceID(voice.id, for: selectedTab)
                } label: {
                    Text("Select")
                        .font(.caption)
                        .foregroundStyle(AegisTheme.cyan)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AegisTheme.cyan.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? AegisTheme.cyan.opacity(0.08) : AegisTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isSelected ? AegisTheme.cyan.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    private func loadCloudVoices(for type: VoiceProviderType) {
        guard let provider = voiceProviderManager.providers[type] else { return }
        isLoadingCloudVoices = true
        cloudVoiceError = nil
        cloudVoices = []

        Task {
            do {
                cloudVoices = try await provider.availableVoices()
            } catch {
                cloudVoiceError = error.localizedDescription
            }
            isLoadingCloudVoices = false
        }
    }

    // MARK: - Apple Voice Section

    private func voiceSection(quality: String, voices: [VoiceInfo]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(quality)
                    .font(.subheadline.bold())
                    .foregroundStyle(qualityColor(quality))
                qualityBadge(quality)
            }
            .padding(.horizontal, 4)

            ForEach(voices) { voice in
                voiceRow(voice)
            }
        }
    }

    private func voiceRow(_ voice: VoiceInfo) -> some View {
        let isSelected = speechService.selectedVoiceID == voice.id
        let isPreviewing = previewingVoiceID == voice.id && speechService.isSpeaking

        return HStack(spacing: 12) {
            Button {
                if isPreviewing {
                    speechService.stop()
                    previewingVoiceID = nil
                } else {
                    previewingVoiceID = voice.id
                    speechService.previewVoice(id: voice.id)
                }
            } label: {
                Image(systemName: isPreviewing ? "stop.circle.fill" : "play.circle.fill")
                    .font(.title3)
                    .foregroundStyle(isPreviewing ? AegisTheme.orange : AegisTheme.cyan)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(voice.name)
                    .font(.subheadline)
                    .foregroundStyle(isSelected ? AegisTheme.cyan : .white)

                Text(voiceLanguageLabel(voice.language))
                    .font(.caption2)
                    .foregroundStyle(AegisTheme.textMuted)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AegisTheme.cyan)
            } else {
                Button {
                    speechService.selectedVoiceID = voice.id
                    voiceProviderManager.setSelectedVoiceID(voice.id, for: .apple)
                } label: {
                    Text("Select")
                        .font(.caption)
                        .foregroundStyle(AegisTheme.cyan)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AegisTheme.cyan.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? AegisTheme.cyan.opacity(0.08) : AegisTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isSelected ? AegisTheme.cyan.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private var noVoicesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "speaker.slash")
                .font(.system(size: 32))
                .foregroundStyle(AegisTheme.textMuted)
            Text("No English voices found")
                .foregroundStyle(AegisTheme.textSecondary)
            Text("Check Settings > Accessibility > Spoken Content > Voices to download voices")
                .font(.caption)
                .foregroundStyle(AegisTheme.textMuted)
                .multilineTextAlignment(.center)
        }
        .padding(24)
    }

    private func qualityColor(_ quality: String) -> Color {
        switch quality {
        case "Premium": AegisTheme.orange
        case "Enhanced": AegisTheme.cyan
        default: AegisTheme.textSecondary
        }
    }

    @ViewBuilder
    private func qualityBadge(_ quality: String) -> some View {
        switch quality {
        case "Premium":
            Text("Best")
                .font(.caption2.bold())
                .foregroundStyle(.black)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(AegisTheme.orange)
                .clipShape(Capsule())
        case "Enhanced":
            Text("Better")
                .font(.caption2.bold())
                .foregroundStyle(.black)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(AegisTheme.cyan)
                .clipShape(Capsule())
        default:
            EmptyView()
        }
    }

    private func voiceLanguageLabel(_ language: String) -> String {
        switch language {
        case "en-US": "English (US)"
        case "en-GB": "English (UK)"
        case "en-AU": "English (Australia)"
        case "en-IE": "English (Ireland)"
        case "en-ZA": "English (South Africa)"
        case "en-IN": "English (India)"
        default: language
        }
    }
}
