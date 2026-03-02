import SwiftUI

struct ConversationListView: View {
    let conversations: [Conversation]
    let onSelect: (Conversation) -> Void
    let onDelete: (Conversation) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AegisTheme.backgroundDeep.ignoresSafeArea()

                if conversations.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock")
                            .font(.system(size: 36))
                            .foregroundStyle(AegisTheme.textMuted)
                        Text("No conversations yet")
                            .foregroundStyle(AegisTheme.textSecondary)
                    }
                } else {
                    List {
                        ForEach(conversations) { conversation in
                            Button {
                                onSelect(conversation)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(conversation.title)
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)

                                    HStack {
                                        if let type = AIProviderType(rawValue: conversation.providerType) {
                                            Text(type.displayName)
                                                .font(.caption2)
                                                .foregroundStyle(AegisTheme.cyan)
                                        }

                                        Text("\(conversation.messages.count) messages")
                                            .font(.caption2)
                                            .foregroundStyle(AegisTheme.textMuted)

                                        Spacer()

                                        Text(conversation.updatedAt, style: .relative)
                                            .font(.caption2)
                                            .foregroundStyle(AegisTheme.textMuted)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .listRowBackground(AegisTheme.surface)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                onDelete(conversations[index])
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
