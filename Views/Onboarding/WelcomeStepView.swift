import SwiftUI

struct WelcomeStepView: View {
    let viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Shield icon
            Image(systemName: "shield.checkered")
                .font(.system(size: 80))
                .foregroundStyle(AegisTheme.cyan)
                .cyanGlow(radius: 20, opacity: 0.4)

            VStack(spacing: 12) {
                Text("Aegis")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(.white)

                Text("Your AI Shield")
                    .font(.title3)
                    .foregroundStyle(AegisTheme.cyan)
            }

            // Feature overview
            VStack(spacing: 16) {
                FeatureRow(icon: "message.fill", title: "AI Chat", subtitle: "Apple AI, OpenAI, Claude, and more")
                FeatureRow(icon: "mic.fill", title: "Voice Control", subtitle: "Speak naturally, hands-free")
                FeatureRow(icon: "house.fill", title: "Smart Home", subtitle: "Control lights, scenes, and devices")
                FeatureRow(icon: "camera.fill", title: "Cameras", subtitle: "Monitor your security feeds")
            }
            .padding(.horizontal, 24)

            Spacer()

            CyanButton(title: "Get Started", icon: "arrow.right") {
                viewModel.nextStep()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AegisTheme.cyan)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AegisTheme.textSecondary)
            }

            Spacer()
        }
        .padding(12)
        .aegisCard()
    }
}
