import SwiftUI

struct SmartHomeStepView: View {
    let viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "house.fill")
                .font(.system(size: 60))
                .foregroundStyle(AegisTheme.cyan)
                .cyanGlow(radius: 15, opacity: 0.4)

            VStack(spacing: 8) {
                Text("Smart Home")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                Text("Control your lights, scenes, and devices")
                    .font(.subheadline)
                    .foregroundStyle(AegisTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 16) {
                CyanButton(title: "Connect to HomeKit", icon: "homekit", style: .secondary) {
                    // HomeKit permission request will be triggered in Phase 3
                }

                CyanButton(title: "Use Custom Server", icon: "server.rack", style: .outline) {
                    // Server smart home setup in Phase 3
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Navigation
            HStack(spacing: 12) {
                Button("Back") { viewModel.previousStep() }
                    .foregroundStyle(AegisTheme.textSecondary)

                Spacer()

                Button("Skip") { viewModel.skipStep() }
                    .foregroundStyle(AegisTheme.textMuted)

                CyanButton(title: "Next", icon: "arrow.right") {
                    viewModel.nextStep()
                }
                .frame(width: 120)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}
