import Foundation
import AVFoundation

struct AppleVoiceProvider: VoiceProvider {
    let providerType = VoiceProviderType.apple
    let displayName = "System Voice"

    var isAvailable: Bool {
        get async { true }
    }

    func synthesize(text: String, voiceID: String? = nil) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            let utterance = AVSpeechUtterance(string: text)
            if let voiceID, let voice = AVSpeechSynthesisVoice(identifier: voiceID) {
                utterance.voice = voice
            } else {
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            }

            var audioData = Data()
            let synthesizer = AVSpeechSynthesizer()
            synthesizer.write(utterance) { buffer in
                guard let pcmBuffer = buffer as? AVAudioPCMBuffer else { return }
                if pcmBuffer.frameLength == 0 {
                    continuation.resume(returning: audioData)
                    return
                }
                if let channelData = pcmBuffer.floatChannelData {
                    let byteCount = Int(pcmBuffer.frameLength) * MemoryLayout<Float>.size
                    let data = Data(bytes: channelData[0], count: byteCount)
                    audioData.append(data)
                }
            }
        }
    }

    func availableVoices() async throws -> [VoiceOption] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("en") }
            .sorted { $0.name < $1.name }
            .map { voice in
                let tier: String
                switch voice.quality {
                case .premium: tier = "Premium"
                case .enhanced: tier = "Enhanced"
                default: tier = "Default"
                }
                return VoiceOption(
                    id: voice.identifier,
                    name: voice.name,
                    language: voice.language,
                    isDefault: voice.quality == .enhanced,
                    qualityTier: tier
                )
            }
    }
}
