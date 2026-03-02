import Foundation
import AVFoundation

struct VoiceInfo: Identifiable, Sendable {
    let id: String
    let name: String
    let language: String
    let qualityTier: String
}

@MainActor
@Observable
final class SpeechService: NSObject, AVSpeechSynthesizerDelegate, AVAudioPlayerDelegate {
    var isSpeaking = false
    var mouthOpenness: CGFloat = 0.0
    var currentWord: String = ""

    private var synthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?
    private var mouthTask: Task<Void, Never>?
    private var speechStartTime: Date?
    private var voiceProviderManager: VoiceProviderManager?

    var selectedVoiceID: String? {
        get { UserDefaults.standard.string(forKey: "selectedVoiceID") }
        set { UserDefaults.standard.set(newValue, forKey: "selectedVoiceID") }
    }

    var selectedVoiceName: String {
        guard let id = selectedVoiceID,
              let voice = AVSpeechSynthesisVoice(identifier: id) else {
            return "System Default"
        }
        return voice.name
    }

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: - Configuration

    func configure(voiceProviderManager: VoiceProviderManager) {
        self.voiceProviderManager = voiceProviderManager
    }

    // MARK: - Speech Control

    func speak(text: String) {
        stop()

        guard let manager = voiceProviderManager else {
            // Fallback to Apple TTS if no manager configured
            speakWithApple(text: text)
            return
        }

        let activeType = manager.activeProviderType
        let voiceID = manager.selectedVoiceID(for: activeType)

        switch activeType {
        case .apple:
            speakWithApple(text: text, voiceID: voiceID ?? selectedVoiceID)
        case .elevenLabs, .customServer:
            speakWithCloudProvider(text: text, voiceID: voiceID)
        }
    }

    private func speakWithApple(text: String, voiceID: String? = nil) {
        // Configure audio session for playback
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: .duckOthers)
            try session.setActive(true)
        } catch {
            // Continue anyway — TTS may still work
        }

        let utterance = AVSpeechUtterance(string: text)
        let id = voiceID ?? selectedVoiceID
        if let id, let voice = AVSpeechSynthesisVoice(identifier: id) {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        isSpeaking = true
        speechStartTime = Date()
        synthesizer.speak(utterance)
        startMouthAnimation(useMetering: false)
    }

    private func speakWithCloudProvider(text: String, voiceID: String?) {
        guard let manager = voiceProviderManager,
              let provider = manager.activeProvider else { return }

        isSpeaking = true
        speechStartTime = Date()
        startMouthAnimation(useMetering: false) // Start sine wave until audio loads

        Task {
            do {
                // Configure audio session for playback
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .default)
                try session.setActive(true)

                let audioData = try await provider.synthesize(text: text, voiceID: voiceID)
                let player = try AVAudioPlayer(data: audioData)
                player.delegate = self
                player.isMeteringEnabled = true
                player.prepareToPlay()

                self.audioPlayer = player
                player.play()

                // Switch to metered mouth animation
                stopMouthAnimation()
                startMouthAnimation(useMetering: true)
            } catch {
                self.isSpeaking = false
                self.mouthOpenness = 0
                stopMouthAnimation()
            }
        }
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        audioPlayer?.stop()
        audioPlayer = nil
        stopMouthAnimation()
        isSpeaking = false
        mouthOpenness = 0
        currentWord = ""
        // Release audio session so STT can take over
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Mouth Animation

    private func startMouthAnimation(useMetering: Bool) {
        mouthTask?.cancel()
        mouthTask = Task { @MainActor in
            while !Task.isCancelled && self.isSpeaking {
                if useMetering, let player = self.audioPlayer, player.isPlaying {
                    player.updateMeters()
                    let power = player.averagePower(forChannel: 0)
                    let normalized = max(0, (power + 50) / 50)
                    let smoothed = min(1.0, CGFloat(normalized) * 1.2)
                    self.mouthOpenness = max(0.05, smoothed)
                } else {
                    let t = Date().timeIntervalSince1970
                    let wave1 = sin(t * 11.0) * 0.25
                    let wave2 = sin(t * 7.3) * 0.15
                    let base = 0.35 + wave1 + wave2
                    self.mouthOpenness = max(0.05, min(1.0, CGFloat(base)))
                }
                try? await Task.sleep(for: .milliseconds(80))
            }
        }
    }

    private func stopMouthAnimation() {
        mouthTask?.cancel()
        mouthTask = nil
    }

    // MARK: - AVSpeechSynthesizerDelegate

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = true
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.stopMouthAnimation()
            self.isSpeaking = false
            self.mouthOpenness = 0
            self.currentWord = ""
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.stopMouthAnimation()
            self.isSpeaking = false
            self.mouthOpenness = 0
            self.currentWord = ""
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance
    ) {
        let text = utterance.speechString
        if let range = Range(characterRange, in: text) {
            let word = String(text[range])
            Task { @MainActor in
                self.currentWord = word
                self.mouthOpenness = min(1.0, self.mouthOpenness + 0.2)
            }
        }
    }

    // MARK: - AVAudioPlayerDelegate

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.stopMouthAnimation()
            self.isSpeaking = false
            self.mouthOpenness = 0
            self.audioPlayer = nil
        }
    }

    // MARK: - Voice Discovery

    func availableVoices() -> [(quality: String, voices: [VoiceInfo])] {
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("en") }
            .sorted { $0.name < $1.name }

        var premium: [VoiceInfo] = []
        var enhanced: [VoiceInfo] = []
        var defaultVoices: [VoiceInfo] = []

        for voice in allVoices {
            let tier: String
            switch voice.quality {
            case .premium: tier = "Premium"
            case .enhanced: tier = "Enhanced"
            default: tier = "Default"
            }
            let info = VoiceInfo(
                id: voice.identifier,
                name: voice.name,
                language: voice.language,
                qualityTier: tier
            )
            switch voice.quality {
            case .premium: premium.append(info)
            case .enhanced: enhanced.append(info)
            default: defaultVoices.append(info)
            }
        }

        var result: [(quality: String, voices: [VoiceInfo])] = []
        if !premium.isEmpty { result.append(("Premium", premium)) }
        if !enhanced.isEmpty { result.append(("Enhanced", enhanced)) }
        if !defaultVoices.isEmpty { result.append(("Default", defaultVoices)) }
        return result
    }

    func previewVoice(id: String, sampleText: String = "Hello, I'm Aegis, your personal AI assistant.") {
        stop()
        let utterance = AVSpeechUtterance(string: sampleText)
        utterance.voice = AVSpeechSynthesisVoice(identifier: id)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        isSpeaking = true
        synthesizer.speak(utterance)
        startMouthAnimation(useMetering: false)
    }
}
