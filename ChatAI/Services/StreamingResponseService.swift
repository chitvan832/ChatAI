import Foundation
import AVFoundation
import SwiftUI

class StreamingResponseService: NSObject, ObservableObject {
    @Published var isProcessing = false
    @Published var isSpeaking = false
    @Published var currentResponse = ""
    
    private var synthesizer: AVSpeechSynthesizer?
    private var currentUtterance: AVSpeechUtterance?
    private var responseTask: Task<Void, Never>?
    
    override init() {
        super.init()
        synthesizer = AVSpeechSynthesizer()
        synthesizer?.delegate = self
    }
    
    func startStreamingResponse(from cohereService: CohereService, prompt: String) async {
        guard !isProcessing else { return }
        
        isProcessing = true
        currentResponse = ""
        
        // Cancel any existing response
        responseTask?.cancel()
        
        // Create new response task
        responseTask = Task {
            do {
                for try await token in try await cohereService.streamChatCompletion(messages: [
                    Message(content: prompt, role: .user)
                ]) {
                    guard !Task.isCancelled else { break }
                    
                    await MainActor.run {
                        currentResponse += token
                        speakToken(token)
                    }
                }
            } catch {
                print("Error streaming response: \(error)")
            }
            
            await MainActor.run {
                isProcessing = false
            }
        }
    }
    
    func stopStreaming() {
        responseTask?.cancel()
        synthesizer?.stopSpeaking(at: .immediate)
        isProcessing = false
        isSpeaking = false
        currentResponse = ""
    }
    
    private func speakToken(_ token: String) {
        // If we're not currently speaking, start a new utterance
        if !isSpeaking {
            let utterance = AVSpeechUtterance(string: token)
            utterance.rate = 0.5
            utterance.pitchMultiplier = 1.0
            utterance.volume = 1.0
            currentUtterance = utterance
            synthesizer?.speak(utterance)
            isSpeaking = true
        } else {
            // Append to current utterance
            if let currentUtterance = currentUtterance {
                let newText = currentUtterance.speechString + token
                let newUtterance = AVSpeechUtterance(string: newText)
                newUtterance.rate = currentUtterance.rate
                newUtterance.pitchMultiplier = currentUtterance.pitchMultiplier
                newUtterance.volume = currentUtterance.volume
                self.currentUtterance = newUtterance
                synthesizer?.speak(newUtterance)
            }
        }
    }
}

extension StreamingResponseService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
} 
