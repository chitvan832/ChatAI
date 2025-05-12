import SwiftUI
import AVFoundation

class VoiceInputManager: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording = false
    @Published var volume: Float = 1.0
    @Published var transcribedText: String = ""
    @Published var streamingService = StreamingResponseService()
    
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private let speechService: SpeechRecognitionService
    private let cohereService: CohereService
    
    init(apiKey: String) {
        self.speechService = SpeechRecognitionService()
        self.cohereService = CohereService(apiKey: apiKey)
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    func startRecording() {
        do {
            try speechService.startRecording()
            isRecording = true
            
            // Start monitoring volume
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.volume = self.speechService.isRecording ? 1.0 : 0.0
                self.transcribedText = self.speechService.transcribedText
            }
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    func stopRecording() {
        speechService.stopRecording()
        timer?.invalidate()
        timer = nil
        isRecording = false
        volume = 0
        
        // Start streaming response if we have transcribed text
        if !transcribedText.isEmpty {
            Task {
                await streamingService.startStreamingResponse(from: cohereService, prompt: transcribedText)
            }
        }
    }
}

struct RealTimeChatView: View {
    @StateObject private var voiceManager: VoiceInputManager
    @State private var isAIResponding = false
    @Environment(\.dismiss) private var dismiss
    
    init(apiKey: String) {
        _voiceManager = StateObject(wrappedValue: VoiceInputManager(apiKey: apiKey))
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.1).ignoresSafeArea()
            
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    
                    Spacer()
                }
                
                ScrollView {
                    VStack(spacing: 16) {
                        if !voiceManager.transcribedText.isEmpty {
                            Text(voiceManager.transcribedText)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(radius: 2)
                                .padding(.horizontal)
                        }
                        
                        if !voiceManager.streamingService.currentResponse.isEmpty {
                            Text(voiceManager.streamingService.currentResponse)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                                .shadow(radius: 2)
                                .padding(.horizontal)
                        }
                    }
                }
                
                Spacer()
                
                VoiceAnimationView(isListening: $voiceManager.isRecording)
                
                Spacer()
                
                Button(action: {
                    if voiceManager.isRecording {
                        voiceManager.stopRecording()
                    } else {
                        voiceManager.startRecording()
                    }
                }) {
                    Image(systemName: voiceManager.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(voiceManager.isRecording ? .red : .blue)
                }
                .padding(.bottom, 40)
            }
        }
    }
} 
