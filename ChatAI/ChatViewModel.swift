import Foundation
import SwiftUI
import SwiftData
import CoreHaptics

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var inputText: String = ""
    @Published var isThinking: Bool = false
    private var engine: CHHapticEngine?
    
    init() {
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
    
    func sendMessage(modelContext: ModelContext) {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Create and save user message
        let userMessage = Message(content: inputText, isUser: true)
        modelContext.insert(userMessage)
        
        // Trigger haptic feedback
        triggerHapticFeedback()
        
        // Clear input and show thinking state
        let messageText = inputText
        inputText = ""
        isThinking = true
        
        // Simulate API call
        Task {
            do {
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 second delay
                
                // Create and save AI response
                let aiMessage = Message(content: "Echo: \(messageText)", isUser: false)
                modelContext.insert(aiMessage)
                
                isThinking = false
            } catch {
                isThinking = false
                // TODO: Handle error
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