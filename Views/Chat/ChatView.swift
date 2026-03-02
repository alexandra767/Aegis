import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ProviderManager.self) private var providerManager
    @Environment(VoiceProviderManager.self) private var voiceProviderManager
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Query(sort: \Conversation.updatedAt, order: .reverse) private var conversations: [Conversation]

    @State private var viewModel: ChatViewModel?
    @State private var showConversationList = false
    @State private var showModelPicker = false
    @State private var speechService = SpeechService()
    @State private var speechRecognitionService = SpeechRecognitionService()
    @State private var showPermissionAlert = false
    @State private var autoSpeakEnabled = true
    @State private var showLiveAvatar = false

    var body: some View {
        Group {
            if sizeClass == .regular {
                iPadLayout
            } else {
                iPhoneLayout
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ChatViewModel(modelContext: modelContext, providerManager: providerManager)
            }
            speechService.configure(voiceProviderManager: voiceProviderManager)
        }
        .onChange(of: viewModel?.lastCompletedResponseText) { _, newText in
            if autoSpeakEnabled, let text = newText, !text.isEmpty {
                speechService.speak(text: text)
                viewModel?.lastCompletedResponseText = nil
            }
        }
        .alert("Permissions Required", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Aegis needs microphone and speech recognition permissions for voice chat. Please enable them in Settings.")
        }
        .fullScreenCover(isPresented: $showLiveAvatar) {
            LiveAvatarView(
                viewModel: $viewModel,
                speechService: speechService,
                speechRecognitionService: speechRecognitionService
            )
        }
    }

    // MARK: - iPad Layout (Split View)

    private var iPadLayout: some View {
        NavigationSplitView {
            ZStack {
                AegisTheme.backgroundDeep.ignoresSafeArea()
                sidebarContent
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        } detail: {
            NavigationStack {
                chatContent
                    .navigationTitle("Aegis")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                    .toolbar { chatToolbarItems }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .tint(AegisTheme.cyan)
    }

    // MARK: - iPhone Layout (Stack)

    private var iPhoneLayout: some View {
        NavigationStack {
            chatContent
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
                    chatToolbarItems
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
        }
    }

    // MARK: - Sidebar Content (iPad)

    private var sidebarContent: some View {
        Group {
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
                            viewModel?.loadConversation(conversation)
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
                        .listRowBackground(
                            viewModel?.activeConversation?.id == conversation.id
                                ? AegisTheme.cyan.opacity(0.1)
                                : AegisTheme.surface
                        )
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            viewModel?.deleteConversation(conversations[index])
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }

    // MARK: - Chat Content

    private var chatContent: some View {
        ZStack {
            AegisTheme.backgroundDeep.ignoresSafeArea()

            VStack(spacing: 0) {
                // Persistent avatar header — always visible, animates when speaking
                chatAvatarHeader

                if let conversation = viewModel?.activeConversation {
                    messageList(for: conversation)
                } else {
                    emptyState
                }

                inputBar
            }
        }
    }

    // MARK: - Avatar Header (Always Visible)

    private var chatAvatarHeader: some View {
        HStack(spacing: 12) {
            AvatarView(
                avatar: AvatarConfig.selected,
                size: 44,
                mouthOpenness: speechService.mouthOpenness,
                isSpeaking: speechService.isSpeaking
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(AvatarConfig.selected.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                if speechService.isSpeaking {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(AegisTheme.cyan)
                            .frame(width: 6, height: 6)
                        Text("Speaking...")
                            .font(.caption2)
                            .foregroundStyle(AegisTheme.cyan)
                    }
                } else {
                    Text("Online")
                        .font(.caption2)
                        .foregroundStyle(AegisTheme.success)
                }
            }

            Spacer()

            // Auto-speak toggle
            Button {
                autoSpeakEnabled.toggle()
                if !autoSpeakEnabled {
                    speechService.stop()
                }
            } label: {
                Image(systemName: autoSpeakEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .font(.subheadline)
                    .foregroundStyle(autoSpeakEnabled ? AegisTheme.cyan : AegisTheme.textMuted)
                    .padding(8)
                    .background(
                        (autoSpeakEnabled ? AegisTheme.cyan : AegisTheme.textMuted).opacity(0.12)
                    )
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(AegisTheme.background.opacity(0.95))
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var chatToolbarItems: some ToolbarContent {
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

    // MARK: - Message List

    private func messageList(for conversation: Conversation) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(conversation.messages.sorted(by: { $0.timestamp < $1.timestamp })) { message in
                        MessageBubbleView(
                            message: message,
                            speechService: speechService
                        )
                        .id(message.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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

    // MARK: - Empty State (Hero Avatar)

    private var emptyState: some View {
        let avatarSize: CGFloat = sizeClass == .regular ? 120 : 100

        return VStack(spacing: 20) {
            Spacer()

            AvatarView(
                avatar: AvatarConfig.selected,
                size: avatarSize,
                mouthOpenness: speechService.mouthOpenness,
                isSpeaking: speechService.isSpeaking
            )

            Text("Start a conversation")
                .font(.title3)
                .foregroundStyle(AegisTheme.textSecondary)

            Text("Using \(providerManager.activeProviderType.displayName)")
                .font(.caption)
                .foregroundStyle(AegisTheme.textMuted)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    // MARK: - Input Bar

    @ViewBuilder
    private var inputBar: some View {
        VStack(spacing: 0) {
            // Live transcription bar
            if speechRecognitionService.isListening {
                HStack(spacing: 8) {
                    Circle()
                        .fill(AegisTheme.danger)
                        .frame(width: 8, height: 8)

                    Text(speechRecognitionService.transcribedText.isEmpty
                         ? "Listening..."
                         : speechRecognitionService.transcribedText)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(AegisTheme.surface)
            }

            if let error = viewModel?.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(AegisTheme.danger)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
            }

            HStack(spacing: 10) {
                // Live avatar mode button
                Button {
                    showLiveAvatar = true
                } label: {
                    Image(systemName: "person.wave.2.fill")
                        .font(.title3)
                        .foregroundStyle(AegisTheme.cyan)
                }

                // Mic button — tap to toggle recording
                Button {
                    toggleVoiceInput()
                } label: {
                    Image(systemName: speechRecognitionService.isListening ? "mic.fill" : "mic.fill")
                        .font(.title3)
                        .foregroundStyle(speechRecognitionService.isListening ? AegisTheme.orange : AegisTheme.textMuted)
                        .symbolEffect(.pulse, isActive: speechRecognitionService.isListening)
                }

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

    // MARK: - Voice Input

    private func toggleVoiceInput() {
        if speechRecognitionService.isListening {
            // Stop listening and send
            speechRecognitionService.stopListening()
            let text = speechRecognitionService.transcribedText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                viewModel?.currentMessage = text
                viewModel?.sendMessage()
            }
        } else {
            // Start listening
            Task {
                // Request permissions if needed
                if speechRecognitionService.speechAuthStatus == .notDetermined {
                    speechRecognitionService.requestAuthorization()
                    await speechRecognitionService.requestMicrophonePermission()
                    // Small delay for authorization to process
                    try? await Task.sleep(for: .milliseconds(500))
                }

                guard speechRecognitionService.speechAuthStatus == .authorized else {
                    if speechRecognitionService.speechAuthStatus == .denied ||
                       speechRecognitionService.speechAuthStatus == .restricted {
                        showPermissionAlert = true
                    } else {
                        speechRecognitionService.requestAuthorization()
                    }
                    return
                }

                if !speechRecognitionService.micPermissionGranted {
                    await speechRecognitionService.requestMicrophonePermission()
                    guard speechRecognitionService.micPermissionGranted else {
                        showPermissionAlert = true
                        return
                    }
                }

                // Stop any TTS before starting STT
                speechService.stop()
                try? await Task.sleep(for: .milliseconds(300))
                speechRecognitionService.startListening()
            }
        }
    }
}
