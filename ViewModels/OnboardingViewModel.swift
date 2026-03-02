import Foundation
import SwiftUI

@Observable
final class OnboardingViewModel {
    var currentStep = 0
    var selectedProviderType: AIProviderType = .apple

    // API Key fields
    var openAIKey = ""
    var anthropicKey = ""
    var geminiKey = ""
    var groqKey = ""

    // Custom server fields
    var customServerURL = ""
    var customServerToken = ""

    // Verification states
    var verifyingProvider: AIProviderType?
    var verificationResults: [AIProviderType: Bool] = [:]

    // Camera fields
    var cameraName = ""
    var cameraURL = ""
    var useHomeKitCameras = false

    var totalSteps: Int { 4 }

    func nextStep() {
        if currentStep < totalSteps - 1 {
            currentStep += 1
        }
    }

    func previousStep() {
        if currentStep > 0 {
            currentStep -= 1
        }
    }

    func skipStep() {
        nextStep()
    }

    func verifyAPIKey(type: AIProviderType, providerManager: ProviderManager) async {
        verifyingProvider = type
        let key: String
        switch type {
        case .openAI: key = openAIKey
        case .anthropic: key = anthropicKey
        case .gemini: key = geminiKey
        case .groq: key = groqKey
        default: return
        }

        guard !key.isEmpty else {
            verifyingProvider = nil
            return
        }

        let success = await providerManager.verifyAPIKey(type: type, key: key)
        verificationResults[type] = success

        if success {
            try? await providerManager.registerProvider(type, apiKey: key)
        }

        verifyingProvider = nil
    }

    func testServerConnection(providerManager: ProviderManager) async {
        guard !customServerURL.isEmpty else { return }
        verifyingProvider = .customServer

        let token = customServerToken.isEmpty ? nil : customServerToken
        guard let url = URL(string: "\(customServerURL)/api/v1/health") else {
            verificationResults[.customServer] = false
            verifyingProvider = nil
            return
        }

        let success = await NetworkService.shared.testConnection(url: url, bearerToken: token)
        verificationResults[.customServer] = success

        if success {
            try? await providerManager.registerCustomServer(url: customServerURL, token: token)
        }

        verifyingProvider = nil
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}
