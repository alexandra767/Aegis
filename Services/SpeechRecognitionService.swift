import Foundation
import Speech
import AVFoundation

@MainActor
@Observable
final class SpeechRecognitionService {
    var isListening = false
    var transcribedText = ""
    var errorMessage: String?

    private(set) var speechAuthStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    private(set) var micPermissionGranted = false

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    var isAuthorized: Bool {
        speechAuthStatus == .authorized && micPermissionGranted
    }

    // MARK: - Permissions

    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor [weak self] in
                self?.speechAuthStatus = status
            }
        }
    }

    func requestMicrophonePermission() async {
        if #available(iOS 17.0, *) {
            micPermissionGranted = await AVAudioApplication.requestRecordPermission()
        } else {
            micPermissionGranted = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func requestAllPermissions() async {
        requestAuthorization()
        await requestMicrophonePermission()
    }

    // MARK: - Listening

    func startListening() throws {
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

        // Cancel any existing task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Configure audio session for recording
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = speechRecognizer.supportsOnDeviceRecognition
        self.recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        isListening = true
        transcribedText = ""
        errorMessage = nil

        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self else { return }

                if let result {
                    self.transcribedText = result.bestTranscription.formattedString
                }

                if error != nil || (result?.isFinal == true) {
                    if self.isListening {
                        self.stopListening()
                    }
                }
            }
        }
    }

    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isListening = false

        // Restore audio session for playback
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
}
