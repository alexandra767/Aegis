import SwiftUI

struct AvatarVoiceStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 44))
                        .foregroundStyle(AegisTheme.cyan)
                        .cyanGlow()

                    Text("Personalize Aegis")
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    Text("Choose how your assistant looks and sounds")
                        .font(.subheadline)
                        .foregroundStyle(AegisTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                // Avatar selection
                VStack(alignment: .leading, spacing: 8) {
                    Label("Appearance", systemImage: "face.smiling")
                        .font(.headline)
                        .foregroundStyle(AegisTheme.cyan)
                        .padding(.horizontal, 16)

                    AvatarPickerView(compact: true)
                        .padding(.horizontal, 16)
                }

                Divider()
                    .background(AegisTheme.surface)
                    .padding(.horizontal, 24)

                // Voice selection
                VStack(alignment: .leading, spacing: 8) {
                    Label("Voice", systemImage: "waveform")
                        .font(.headline)
                        .foregroundStyle(AegisTheme.cyan)
                        .padding(.horizontal, 16)

                    VoicePickerView(compact: true)
                        .frame(maxHeight: 300)
                        .padding(.horizontal, 16)
                }

                // Navigation buttons
                HStack(spacing: 16) {
                    Button {
                        viewModel.previousStep()
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundStyle(AegisTheme.textSecondary)
                    }

                    Spacer()

                    Button {
                        viewModel.skipStep()
                    } label: {
                        Text("Skip")
                            .foregroundStyle(AegisTheme.textMuted)
                    }

                    CyanButton(title: "Continue", icon: "chevron.right") {
                        viewModel.nextStep()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .frame(maxWidth: sizeClass == .regular ? 500 : .infinity)
            .frame(maxWidth: .infinity)
        }
    }
}
