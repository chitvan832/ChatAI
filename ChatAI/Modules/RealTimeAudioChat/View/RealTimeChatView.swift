import SwiftUI

struct RealTimeChatView: View {
    @StateObject private var voiceManager: VoiceInputManager
    @State private var isAIResponding = false // Could not implement the animation for equaliser
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
