import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ProviderManager.self) private var providerManager
    @Query(sort: \Conversation.updatedAt, order: .reverse) private var conversations: [Conversation]

    @State private var viewModel: ChatViewModel?
    @State private var showConversationList = false
    @State private var showModelPicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                AegisTheme.backgroundDeep.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Messages
                    if let conversation = viewModel?.activeConversation {
                        messageList(for: conversation)
                    } else {
                        emptyState
                    }

                    // Input bar
                    inputBar
                }
            }
            .navigationTitle("Aegis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showConversationList = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(AegisTheme.cyan)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            showModelPicker = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: providerManager.activeProviderType == .apple ? "apple.logo" : "cloud.fill")
                                    .font(.caption)
                                Text(providerManager.activeProviderType.displayName)
                                    .font(.caption2)
                            }
                            .foregroundStyle(AegisTheme.cyan)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AegisTheme.cyan.opacity(0.1))
                            .clipShape(Capsule())
                        }

                        Button {
                            viewModel?.newConversation()
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .foregroundStyle(AegisTheme.cyan)
                        }
                    }
                }
            }
            .sheet(isPresented: $showConversationList) {
                ConversationListView(
                    conversations: conversations,
                    onSelect: { conv in
                        viewModel?.loadConversation(conv)
                        showConversationList = false
                    },
                    onDelete: { conv in
                        viewModel?.deleteConversation(conv)
                    }
                )
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showModelPicker) {
                ModelPickerView()
                    .presentationDetents([.medium])
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = ChatViewModel(modelContext: modelContext, providerManager: providerManager)
                }
            }
        }
    }

    // MARK: - Message List

    private func messageList(for conversation: Conversation) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(conversation.messages.sorted(by: { $0.timestamp < $1.timestamp })) { message in
                        MessageBubbleView(message: message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .onChange(of: conversation.messages.count) {
                if let lastMessage = conversation.messages.sorted(by: { $0.timestamp < $1.timestamp }).last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "shield.checkered")
                .font(.system(size: 48))
                .foregroundStyle(AegisTheme.cyan.opacity(0.3))

            Text("Start a conversation")
                .font(.title3)
                .foregroundStyle(AegisTheme.textSecondary)

            Text("Using \(providerManager.activeProviderType.displayName)")
                .font(.caption)
                .foregroundStyle(AegisTheme.textMuted)

            Spacer()
        }
    }

    // MARK: - Input Bar

    @ViewBuilder
    private var inputBar: some View {
        VStack(spacing: 0) {
            // Error banner
            if let error = viewModel?.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(AegisTheme.danger)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
            }

            HStack(spacing: 12) {
                // Mic button (placeholder for Phase 2)
                Button {
                    // Voice input — Phase 2
                } label: {
                    Image(systemName: "mic.fill")
                        .font(.title3)
                        .foregroundStyle(AegisTheme.textMuted)
                }

                // Text field
                TextField("Message Aegis...", text: Binding(
                    get: { viewModel?.currentMessage ?? "" },
                    set: { viewModel?.currentMessage = $0 }
                ), axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AegisTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .foregroundStyle(.white)

                // Send / Stop button
                Button {
                    if viewModel?.isStreaming == true {
                        viewModel?.stopStreaming()
                    } else {
                        viewModel?.sendMessage()
                    }
                } label: {
                    Image(systemName: viewModel?.isStreaming == true ? "stop.circle.fill" : "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(AegisTheme.cyan)
                }
                .disabled(viewModel?.currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true && viewModel?.isStreaming != true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AegisTheme.background)
        }
    }
}
