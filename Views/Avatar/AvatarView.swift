import SwiftUI

struct AvatarView: View {
    let avatar: AvatarConfig
    var size: CGFloat = 80
    var mouthOpenness: CGFloat = 0.0
    var isSpeaking: Bool = false

    @State private var breatheScale: CGFloat = 1.0
    @State private var isBlinking = false
    @State private var floatOffset: CGFloat = 0
    @State private var glowRadius: CGFloat = 8

    var body: some View {
        ZStack {
            // Main avatar image or SF Symbol placeholder
            avatarImage
                .scaleEffect(breatheScale)
                .offset(y: floatOffset)

            // Blink overlay — darkens the upper portion briefly
            if isBlinking {
                Circle()
                    .fill(Color.black.opacity(0.4))
                    .frame(width: size * 0.5, height: size * 0.12)
                    .offset(y: -size * 0.1)
                    .transition(.opacity)
            }

            // Mouth overlay when speaking
            if isSpeaking || mouthOpenness > 0.01 {
                mouthShape
                    .offset(y: size * 0.18)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .strokeBorder(
                    AegisTheme.cyan.opacity(isSpeaking ? 0.8 : 0.4),
                    lineWidth: isSpeaking ? 3 : 2
                )
        )
        .shadow(color: AegisTheme.cyan.opacity(isSpeaking ? 0.6 : 0.2), radius: glowRadius)
        .onAppear {
            startBreathing()
            startBlinking()
            startFloating()
        }
        .onChange(of: isSpeaking) { _, speaking in
            withAnimation(.easeInOut(duration: 0.3)) {
                glowRadius = speaking ? 18 : 8
            }
        }
    }

    // MARK: - Avatar Image

    @ViewBuilder
    private var avatarImage: some View {
        // Try loading a custom image first, fall back to generated gradient avatar
        if let uiImage = UIImage(named: avatar.imageName) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            Image(uiImage: AvatarImageGenerator.generatePlaceholder(for: avatar, size: size))
                .resizable()
                .scaledToFill()
        }
    }

    // MARK: - Mouth Shape

    private var mouthShape: some View {
        let openAmount = mouthOpenness * size * 0.12
        return Capsule()
            .fill(Color.black.opacity(0.7))
            .frame(width: size * 0.22, height: max(2, openAmount))
            .animation(.easeInOut(duration: 0.05), value: mouthOpenness)
    }

    // MARK: - Animations

    private func startBreathing() {
        withAnimation(
            .easeInOut(duration: 3.0)
            .repeatForever(autoreverses: true)
        ) {
            breatheScale = 1.02
        }
    }

    private func startBlinking() {
        scheduleNextBlink()
    }

    private func scheduleNextBlink() {
        let interval = Double.random(in: 3.0...5.5)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(interval))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.1)) {
                isBlinking = true
            }
            try? await Task.sleep(for: .seconds(0.15))
            withAnimation(.easeInOut(duration: 0.1)) {
                isBlinking = false
            }
            scheduleNextBlink()
        }
    }

    private func startFloating() {
        withAnimation(
            .easeInOut(duration: 4.0)
            .repeatForever(autoreverses: true)
        ) {
            floatOffset = -3
        }
    }
}

// MARK: - Small Avatar for Message Bubbles

struct SmallAvatarView: View {
    let avatar: AvatarConfig
    var size: CGFloat = 24

    var body: some View {
        Group {
            if let uiImage = UIImage(named: avatar.imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(uiImage: AvatarImageGenerator.generatePlaceholder(for: avatar, size: size))
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .strokeBorder(AegisTheme.cyan.opacity(0.3), lineWidth: 1)
        )
    }
}
