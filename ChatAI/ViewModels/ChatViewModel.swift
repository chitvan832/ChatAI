import Foundation
import SwiftUI
import SwiftData
import CoreHaptics
import AVFoundation

@MainActor
class ChatViewModel: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var inputText: String = ""
    @Published var isThinking: Bool = false
    @Published var currentStreamedText: String = ""
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var showCopiedToast: Bool = false
    @Published var speakingMessageId: UUID? = nil
    
    private var engine: CHHapticEngine?
    private let cohereService: CohereService
    private let synthesizer = AVSpeechSynthesizer()
    
    let apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
        self.cohereService = CohereService(apiKey: apiKey)
        super.init()
        prepareHaptics()
    }
    
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Haptics error: \(error.localizedDescription)")
        }
    }
    
    func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        withAnimation {
            showCopiedToast = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                self.showCopiedToast = false
            }
        }
    }
    
    func toggleSpeech(for message: Message) {
        if speakingMessageId == message.id {
            synthesizer.stopSpeaking(at: .immediate)
            speakingMessageId = nil
        } else {
            let utterance = AVSpeechUtterance(string: message.content)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            utterance.rate = 0.5
            utterance.pitchMultiplier = 1.0
            utterance.volume = 1.0
            
            synthesizer.stopSpeaking(at: .immediate)
            synthesizer.speak(utterance)
            speakingMessageId = message.id
        }
    }
    
    func sendMessage(modelContext: ModelContext, conversation: Conversation) {
        let userMessage = Message(content: inputText, role: .user)
        conversation.messages.append(userMessage)
        
        // Update conversation title if it's the first message
        if conversation.title == "New Chat" {
            conversation.title = inputText.prefix(30) + (inputText.count > 30 ? "..." : "")
        }
        
        inputText = ""
        isThinking = true
        
        Task {
            do {
                var responseText = ""
                for try await token in try await cohereService.streamChatCompletion(messages: conversation.messages) {
                    responseText += token
                }
                let assistantMessage = Message(content: responseText, role: .assistant)
                conversation.messages.append(assistantMessage)
                isThinking = false
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                isThinking = false
            }
        }
    }
    
    private func triggerHapticFeedback() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play haptic pattern: \(error.localizedDescription)")
        }
    }
}
