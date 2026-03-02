import SwiftUI

struct OnboardingContainerView: View {
    @Environment(ProviderManager.self) private var providerManager
    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        ZStack {
            AegisTheme.backgroundDeep.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(0..<viewModel.totalSteps, id: \.self) { step in
                        Capsule()
                            .fill(step <= viewModel.currentStep ? AegisTheme.cyan : AegisTheme.surface)
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // Step content
                TabView(selection: $viewModel.currentStep) {
                    WelcomeStepView(viewModel: viewModel)
                        .tag(0)

                    AIBackendStepView(viewModel: viewModel, providerManager: providerManager)
                        .tag(1)

                    SmartHomeStepView(viewModel: viewModel)
                        .tag(2)

                    CameraStepView(viewModel: viewModel)
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
            }
        }
    }
}
