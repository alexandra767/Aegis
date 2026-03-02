import SwiftUI

struct LiveAvatarView: View {
    @Binding var viewModel: ChatViewModel?
    var speechService: SpeechService
    var speechRecognitionService: SpeechRecognitionService
    @Environment(\.dismiss) private var dismiss
    @State private var showPermissionAlert = false
    @State private var captionText = ""
    @State private var showCaption = false

    var body: some View {
        ZStack {
            AegisTheme.backgroundDeep
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                Spacer()

                // Avatar with single glow ring
                ZStack {
                    Circle()
                        .stroke(AegisTheme.cyan.opacity(speechService.isSpeaking ? 0.2 : 0.06), lineWidth: 1.5)
                        .frame(width: 280, height: 280)

                    AvatarView(
                        avatar: AvatarConfig.selected,
                        size: 220,
                        mouthOpenness: speechService.mouthOpenness,
                        isSpeaking: speechService.isSpeaking
                    )
                }

                Text(AvatarConfig.selected.name)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.top, 16)

                statusLabel
                    .padding(.top, 6)

                Spacer()

                // Caption
                if showCaption {
                    Text(captionText)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(AegisTheme.surface.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 24)
                        .transition(.opacity)
                }

                // User transcription
                if speechRecognitionService.isListening {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(AegisTheme.orange)
                            .frame(width: 8, height: 8)
                        Text(speechRecognitionService.transcribedText.isEmpty
                             ? "Listening..."
                             : speechRecognitionService.transcribedText)
                            .font(.callout)
                            .foregroundStyle(.white.opacity(0.8))
                            .lineLimit(2)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AegisTheme.surface.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }

                voiceControls
                    .padding(.top, 24)
                    .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: viewModel?.lastCompletedResponseText) { _, newText in
            if let text = newText, !text.isEmpty {
                speechService.speak(text: text)
                displayCaption(text)
                viewModel?.lastCompletedResponseText = nil
            }
        }
        .onChange(of: speechService.isSpeaking) { _, speaking in
            if !speaking && showCaption {
                withAnimation { showCaption = false }
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
            Text("Aegis needs microphone and speech recognition permissions for voice chat.")
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                speechService.stop()
                speechRecognitionService.stopListening()
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(AegisTheme.textMuted)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    // MARK: - Status

    private var statusLabel: some View {
        Group {
            if speechService.isSpeaking {
                Text("Speaking")
                    .font(.subheadline)
                    .foregroundStyle(AegisTheme.cyan)
            } else if speechRecognitionService.isListening {
                Text("Listening...")
                    .font(.subheadline)
                    .foregroundStyle(AegisTheme.orange)
            } else if viewModel?.isStreaming == true {
                Text("Thinking...")
                    .font(.subheadline)
                    .foregroundStyle(AegisTheme.textSecondary)
            } else {
                Text("Tap the mic to talk")
                    .font(.subheadline)
                    .foregroundStyle(AegisTheme.textMuted)
            }
        }
    }

    // MARK: - Voice Controls

    private var voiceControls: some View {
        HStack(spacing: 40) {
            // Stop
            Button {
                speechService.stop()
            } label: {
                Image(systemName: "stop.fill")
                    .font(.title3)
                    .foregroundStyle(speechService.isSpeaking ? AegisTheme.orange : AegisTheme.textMuted)
                    .frame(width: 50, height: 50)
                    .background(AegisTheme.surface, in: Circle())
            }
            .disabled(!speechService.isSpeaking)
            .opacity(speechService.isSpeaking ? 1.0 : 0.4)

            // Mic
            Button {
                toggleVoiceInput()
            } label: {
                Circle()
                    .fill(speechRecognitionService.isListening ? AegisTheme.orange : AegisTheme.cyan)
                    .frame(width: 72, height: 72)
                    .overlay(
                        Image(systemName: speechRecognitionService.isListening ? "waveform" : "mic.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                    )
                    .shadow(color: (speechRecognitionService.isListening ? AegisTheme.orange : AegisTheme.cyan).opacity(0.3), radius: 8)
            }
            .disabled(viewModel?.isStreaming == true)

            // Back to chat
            Button {
                speechService.stop()
                speechRecognitionService.stopListening()
                dismiss()
            } label: {
                Image(systemName: "text.bubble.fill")
                    .font(.title3)
                    .foregroundStyle(AegisTheme.textSecondary)
                    .frame(width: 50, height: 50)
                    .background(AegisTheme.surface, in: Circle())
            }
        }
    }

    // MARK: - Helpers

    private func displayCaption(_ text: String) {
        captionText = text.count > 150 ? String(text.prefix(150)) + "..." : text
        withAnimation { showCaption = true }
    }

    private func toggleVoiceInput() {
        if speechRecognitionService.isListening {
            speechRecognitionService.stopListening()
            let text = speechRecognitionService.transcribedText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                viewModel?.currentMessage = text
                viewModel?.sendMessage()
            }
        } else {
            Task {
                if speechRecognitionService.speechAuthStatus == .notDetermined {
                    speechRecognitionService.requestAuthorization()
                    await speechRecognitionService.requestMicrophonePermission()
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

                speechService.stop()
                try? await Task.sleep(for: .milliseconds(300))
                speechRecognitionService.startListening()
            }
        }
    }
}
