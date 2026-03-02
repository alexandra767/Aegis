import Foundation
import Speech
import AVFoundation

/// Speech recognition service. NOT MainActor-isolated because AVAudioEngine
/// requires background thread access for audio tap callbacks.
@Observable
final class SpeechRecognitionService: @unchecked Sendable {
    // UI-visible state (read from MainActor, written via main queue)
    var isListening = false
    var transcribedText = ""
    var errorMessage: String?
    var speechAuthStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    var micPermissionGranted = false

    // Internal audio state
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?
    private var tapInstalled = false

    // Dedicated serial queue for all audio operations
    private let audioQueue = DispatchQueue(label: "com.aegis.speechrecognition")

    var isAuthorized: Bool {
        speechAuthStatus == .authorized && micPermissionGranted
    }

    // MARK: - Permissions

    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            Task { @MainActor [weak self] in
                self?.speechAuthStatus = status
            }
        }
    }

    func requestMicrophonePermission() async {
        if #available(iOS 17.0, *) {
            let granted = await AVAudioApplication.requestRecordPermission()
            await MainActor.run { self.micPermissionGranted = granted }
        } else {
            let granted = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
            await MainActor.run { self.micPermissionGranted = granted }
        }
    }

    // MARK: - Listening

    func startListening() {
        guard speechAuthStatus == .authorized else {
            errorMessage = "Speech recognition not authorized"
            return
        }
        guard micPermissionGranted else {
            errorMessage = "Microphone access not granted"
            return
        }
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognition unavailable"
            return
        }

        // Tear down any previous session
        stopEngine()

        // Configure audio session
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Audio setup failed: \(error.localizedDescription)"
            return
        }

        // Fresh engine
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        guard recordingFormat.channelCount > 0 else {
            errorMessage = "No microphone available"
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if speechRecognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }

        // Install tap — this callback runs on audio thread, only touches `request`
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        engine.prepare()

        do {
            try engine.start()
        } catch {
            inputNode.removeTap(onBus: 0)
            errorMessage = "Could not start recording: \(error.localizedDescription)"
            return
        }

        // Store state
        self.audioEngine = engine
        self.recognitionRequest = request
        self.tapInstalled = true
        self.isListening = true
        self.transcribedText = ""
        self.errorMessage = nil

        // Start recognition — callback comes on arbitrary thread
        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let result {
                let text = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.transcribedText = text
                }
            }

            if error != nil || (result?.isFinal == true) {
                DispatchQueue.main.async {
                    self.isListening = false
                }
            }
        }
    }

    func stopListening() {
        stopEngine()
        isListening = false

        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func stopEngine() {
        if let engine = audioEngine {
            if engine.isRunning {
                engine.stop()
            }
            if tapInstalled {
                engine.inputNode.removeTap(onBus: 0)
            }
        }
        audioEngine = nil
        tapInstalled = false
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.finish()
        recognitionTask = nil
    }
}
