import Foundation
import Speech
import AVFoundation

// MARK: - Speech Service
// Voice input (speech recognition) and voice output (text-to-speech)
// Feature parity with web app's useSpeechRecognition + useTextToSpeech

@MainActor
class SpeechService: NSObject, ObservableObject {
    
    // MARK: - Voice Input (Speech Recognition)
    
    @Published var isListening = false
    @Published var transcript = ""
    @Published var interimTranscript = ""
    @Published var speechPermissionGranted = false
    
    // MARK: - Voice Output (Text-to-Speech)
    
    @Published var isSpeaking = false
    @Published var speakingMessageId: String?
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let synthesizer = AVSpeechSynthesizer()
    
    var isRecognitionAvailable: Bool {
        speechRecognizer?.isAvailable ?? false
    }
    
    override init() {
        super.init()
        synthesizer.delegate = self
        requestPermissions()
    }
    
    // MARK: - Permissions
    
    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor in
                self?.speechPermissionGranted = (status == .authorized)
            }
        }
    }
    
    // MARK: - Start Listening
    
    func startListening() {
        guard speechPermissionGranted, isRecognitionAvailable else { return }
        
        // Stop TTS if playing
        if isSpeaking { stopSpeaking() }
        
        // Cancel any existing task
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("⚠️ Audio session setup failed: \(error)")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Use on-device recognition when available (faster, private)
        if #available(iOS 13, *) {
            recognitionRequest.requiresOnDeviceRecognition = false
        }
        
        let inputNode = audioEngine.inputNode
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                guard let self = self else { return }
                
                if let result = result {
                    let text = result.bestTranscription.formattedString
                    if result.isFinal {
                        self.transcript = text
                        self.interimTranscript = ""
                    } else {
                        self.interimTranscript = text
                    }
                }
                
                if error != nil || (result?.isFinal ?? false) {
                    self.audioEngine.stop()
                    inputNode.removeTap(onBus: 0)
                    self.recognitionRequest = nil
                    self.recognitionTask = nil
                    
                    if result?.isFinal ?? false {
                        // Keep listening state for user to decide
                    } else {
                        self.isListening = false
                    }
                }
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            isListening = true
            transcript = ""
            interimTranscript = ""
        } catch {
            print("⚠️ Audio engine start failed: \(error)")
        }
    }
    
    // MARK: - Stop Listening
    
    func stopListening() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        audioEngine.inputNode.removeTap(onBus: 0)
        isListening = false
        
        // Finalize transcript from interim
        if !interimTranscript.isEmpty {
            transcript = interimTranscript
            interimTranscript = ""
        }
    }
    
    // MARK: - Toggle Listening
    
    func toggleListening() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }
    
    // MARK: - Speak (Text-to-Speech)
    
    func speak(_ text: String, messageId: String? = nil) {
        // Stop if already speaking this message
        if isSpeaking && speakingMessageId == messageId {
            stopSpeaking()
            return
        }
        
        // Stop any current speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        // Strip markdown-like formatting for cleaner speech
        let cleanText = text
            .replacingOccurrences(of: "✦", with: "")
            .replacingOccurrences(of: "—", with: ", ")
            .replacingOccurrences(of: "→", with: "to")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let utterance = AVSpeechUtterance(string: cleanText)
        
        // Pearl's voice — warm, measured, slightly slower
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.88
        utterance.pitchMultiplier = 1.0
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.05
        
        // Use a warm, clear voice
        if let voice = AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = voice
        }
        
        // Set audio session for playback
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers])
            try audioSession.setActive(true)
        } catch {
            print("⚠️ Audio session for speech failed: \(error)")
        }
        
        speakingMessageId = messageId
        isSpeaking = true
        synthesizer.speak(utterance)
    }
    
    // MARK: - Stop Speaking
    
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        speakingMessageId = nil
    }
    
    // MARK: - Toggle Speak
    
    func toggleSpeak(_ text: String, messageId: String) {
        if isSpeaking && speakingMessageId == messageId {
            stopSpeaking()
        } else {
            speak(text, messageId: messageId)
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension SpeechService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.speakingMessageId = nil
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.speakingMessageId = nil
        }
    }
}
