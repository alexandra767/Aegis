import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(ProviderManager.self) private var providerManager
    @Environment(VoiceProviderManager.self) private var voiceProviderManager
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Query(sort: \Conversation.updatedAt, order: .reverse) private var conversations: [Conversation]

    @State private var speechService = SpeechService()
    @State private var navigateToChat = false
    @State private var navigateToSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                AegisTheme.backgroundDeep.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        heroSection
                        statusCards
                        quickActions
                        recentConversations
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                    .frame(maxWidth: sizeClass == .regular ? 600 : .infinity)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Aegis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 16) {
            AvatarView(
                avatar: AvatarConfig.selected,
                size: sizeClass == .regular ? 140 : 120,
                mouthOpenness: speechService.mouthOpenness,
                isSpeaking: speechService.isSpeaking
            )
            .padding(.top, 20)

            VStack(spacing: 4) {
                Text(AvatarConfig.selected.name)
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text(greetingText)
                    .font(.subheadline)
                    .foregroundStyle(AegisTheme.textSecondary)
            }
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Hello"
        }
    }

    // MARK: - Status Cards

    private var statusCards: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                statusCard(
                    icon: "brain",
                    title: "AI Provider",
                    value: providerManager.activeProviderType.displayName,
                    isCloud: providerManager.activeProviderType.isCloudBased
                )

                statusCard(
                    icon: "speaker.wave.3.fill",
                    title: "Voice",
                    value: voiceProviderManager.activeProviderType.displayName,
                    isCloud: voiceProviderManager.activeProviderType.isCloudBased
                )
            }

            HStack(spacing: 12) {
                statusCard(
                    icon: "message.fill",
                    title: "Conversations",
                    value: "\(conversations.count)",
                    isCloud: false
                )

                statusCard(
                    icon: "person.crop.circle.fill",
                    title: "Avatar",
                    value: AvatarConfig.selected.name,
                    isCloud: false
                )
            }
        }
    }

    private func statusCard(icon: String, title: String, value: String, isCloud: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(AegisTheme.cyan)

                Spacer()

                if isCloud {
                    Text("Cloud")
                        .font(.caption2)
                        .foregroundStyle(AegisTheme.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AegisTheme.orange.opacity(0.15))
                        .clipShape(Capsule())
                }
            }

            Text(title)
                .font(.caption)
                .foregroundStyle(AegisTheme.textMuted)

            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AegisTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(AegisTheme.cyan.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.leading, 4)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                quickActionButton(icon: "plus.message.fill", label: "New Chat", color: AegisTheme.cyan) {
                    // Switch to Chat tab
                    NotificationCenter.default.post(name: .switchToTab, object: 1)
                }

                quickActionButton(icon: "person.crop.circle", label: "Avatar", color: AegisTheme.orange) {
                    NotificationCenter.default.post(name: .switchToTab, object: 2)
                }

                quickActionButton(icon: "gearshape.fill", label: "Settings", color: AegisTheme.textSecondary) {
                    NotificationCenter.default.post(name: .switchToTab, object: 2)
                }
            }
        }
    }

    private func quickActionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)

                Text(label)
                    .font(.caption)
                    .foregroundStyle(AegisTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AegisTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(color.opacity(0.15), lineWidth: 1)
            )
        }
    }

    // MARK: - Recent Conversations

    private var recentConversations: some View {
        Group {
            if !conversations.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Recent")
                            .font(.headline)
                            .foregroundStyle(.white)

                        Spacer()

                        Button {
                            NotificationCenter.default.post(name: .switchToTab, object: 1)
                        } label: {
                            Text("See All")
                                .font(.caption)
                                .foregroundStyle(AegisTheme.cyan)
                        }
                    }
                    .padding(.horizontal, 4)

                    ForEach(conversations.prefix(3)) { conversation in
                        Button {
                            NotificationCenter.default.post(name: .switchToTab, object: 1)
                        } label: {
                            HStack(spacing: 12) {
                                SmallAvatarView(avatar: AvatarConfig.selected, size: 32)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(conversation.title)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)

                                    HStack(spacing: 6) {
                                        if let type = AIProviderType(rawValue: conversation.providerType) {
                                            Text(type.displayName)
                                                .font(.caption2)
                                                .foregroundStyle(AegisTheme.cyan)
                                        }
                                        Text("\(conversation.messages.count) messages")
                                            .font(.caption2)
                                            .foregroundStyle(AegisTheme.textMuted)
                                    }
                                }

                                Spacer()

                                Text(conversation.updatedAt, style: .relative)
                                    .font(.caption2)
                                    .foregroundStyle(AegisTheme.textMuted)
                            }
                            .padding(12)
                            .background(AegisTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Tab Switch Notification

extension Notification.Name {
    static let switchToTab = Notification.Name("switchToTab")
}
