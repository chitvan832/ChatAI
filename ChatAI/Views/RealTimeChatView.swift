import SwiftUI
import AVFoundation

class VoiceInputManager: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording = false
    @Published var volume: Float = 0
    @Published var transcribedText: String = ""
    @Published var aiResponse: String = ""
    
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private let speechService: GoogleSpeechService
    
    init(apiKey: String) {
        self.speechService = GoogleSpeechService()
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
        speechService.startRecording()
        isRecording = true
        
        // Start monitoring volume
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
//            self.volume = self.speechService.isProcessing ? 0.5 : 0.0
            self.transcribedText = self.speechService.transcribedText
            self.aiResponse = self.speechService.aiResponse
        }
    }
    
    func stopRecording() {
        speechService.stopRecording()
        timer?.invalidate()
        timer = nil
        isRecording = false
        volume = 0
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
                        
                        if !voiceManager.aiResponse.isEmpty {
                            Text(voiceManager.aiResponse)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                                .shadow(radius: 2)
                                .padding(.horizontal)
                        }
                    }
                }
                
                Spacer()
                
                VoiceAnimationView(
                    isSpeaking: voiceManager.isRecording,
                    volume: voiceManager.volume,
                    isAIResponding: isAIResponding
                )
                
                Spacer()
                
                Button(action: {
                    if voiceManager.isRecording {
                        voiceManager.stopRecording()
                        isAIResponding = true
                    } else {
                        voiceManager.startRecording()
                        isAIResponding = false
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
