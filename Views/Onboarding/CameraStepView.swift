import SwiftUI

struct CameraStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundStyle(AegisTheme.cyan)
                .cyanGlow(radius: 15, opacity: 0.4)

            VStack(spacing: 8) {
                Text("Cameras")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                Text("Monitor your security feeds")
                    .font(.subheadline)
                    .foregroundStyle(AegisTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 16) {
                // Add Camera form
                VStack(spacing: 12) {
                    TextField("Camera Name", text: $viewModel.cameraName)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(AegisTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(.white)

                    TextField("RTSP URL", text: $viewModel.cameraURL)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(AegisTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(.white)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    CyanButton(title: "Add Camera", icon: "plus", style: .secondary) {
                        // Camera will be saved in Phase 4
                    }
                    .disabled(viewModel.cameraName.isEmpty || viewModel.cameraURL.isEmpty)
                }
                .padding(16)
                .aegisCard()

                Toggle(isOn: $viewModel.useHomeKitCameras) {
                    HStack {
                        Image(systemName: "homekit")
                            .foregroundStyle(AegisTheme.cyan)
                        Text("Use HomeKit Cameras")
                            .foregroundStyle(.white)
                    }
                }
                .tint(AegisTheme.cyan)
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 24)

            Spacer()

            // Navigation
            HStack(spacing: 12) {
                Button("Back") { viewModel.previousStep() }
                    .foregroundStyle(AegisTheme.textSecondary)

                Spacer()

                Button("Skip") {
                    viewModel.completeOnboarding()
                }
                .foregroundStyle(AegisTheme.textMuted)

                CyanButton(title: "Done", icon: "checkmark") {
                    viewModel.completeOnboarding()
                }
                .frame(width: 120)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}
