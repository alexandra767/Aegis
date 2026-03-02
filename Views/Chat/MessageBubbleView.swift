import SwiftUI

struct MessageBubbleView: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                // Content
                if message.isStreaming && message.content.isEmpty {
                    streamingIndicator
                } else {
                    Text(attributedContent)
                        .font(.body)
                        .foregroundStyle(.white)
                        .textSelection(.enabled)
                }

                // Metadata
                HStack(spacing: 6) {
                    if let provider = message.providerType, !message.isUser {
                        let type = AIProviderType(rawValue: provider)
                        Text(type?.isCloudBased == false ? "On-Device" : "Cloud")
                            .font(.caption2)
                            .foregroundStyle(type?.isCloudBased == false ? AegisTheme.success : AegisTheme.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background((type?.isCloudBased == false ? AegisTheme.success : AegisTheme.orange).opacity(0.15))
                            .clipShape(Capsule())
                    }

                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(AegisTheme.textMuted)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(bubbleBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            if message.isAssistant {
                Spacer(minLength: 60)
            }
        }
    }

    private var bubbleBackground: some View {
        Group {
            if message.isUser {
                AegisTheme.orange.opacity(0.15)
            } else {
                AegisTheme.cyan.opacity(0.08)
            }
        }
    }

    private var streamingIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(AegisTheme.cyan)
                    .frame(width: 6, height: 6)
                    .opacity(0.6)
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(i) * 0.2),
                        value: true
                    )
            }
        }
        .padding(4)
    }

    private var attributedContent: AttributedString {
        do {
            var attributed = try AttributedString(markdown: message.content)
            // Style code blocks
            for run in attributed.runs {
                if run.inlinePresentationIntent?.contains(.code) == true {
                    attributed[run.range].font = .system(.body, design: .monospaced)
                    attributed[run.range].backgroundColor = AegisTheme.surface
                }
            }
            return attributed
        } catch {
            return AttributedString(message.content)
        }
    }
}
