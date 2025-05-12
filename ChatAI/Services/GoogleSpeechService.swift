import Foundation
import AVFoundation
import SwiftUI

//class GoogleSpeechService: NSObject, ObservableObject {
//    @Published var transcribedText: String = ""
//    @Published var isProcessing: Bool = false
//    @Published var aiResponse: String = ""
//    
//    private let apiKey: String
//    private var audioEngine: AVAudioEngine?
//    private var audioData: Data?
//    
//    init(apiKey: String) {
//        self.apiKey = apiKey
//        super.init()
//    }
//    
//    func startStreaming() {
//        guard !isProcessing else { return }
//        
//        // Setup audio engine
//        let audioEngine = AVAudioEngine()
//        let inputNode = audioEngine.inputNode
//        let recordingFormat = inputNode.outputFormat(forBus: 0)
//        
//        // Ensure we're using the correct format
//        guard let format = AVAudioFormat(
//            commonFormat: .pcmFormatInt16,
//            sampleRate: 16000,
//            channels: 1,
//            interleaved: true
//        ) else {
//            print("Failed to create audio format")
//            return
//        }
//        
//        audioData = Data()
//        
//        // Install tap on input node
//        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, time in
//            guard let self = self else { return }
//            
//            // Convert buffer to data and append
//            if let channelData = buffer.int16ChannelData?[0] {
//                let frameLength = Int(buffer.frameLength)
//                let data = Data(bytes: channelData, count: frameLength * MemoryLayout<Int16>.size)
//                self.audioData?.append(data)
//            }
//        }
//        
//        do {
//            try audioEngine.start()
//            self.audioEngine = audioEngine
//            isProcessing = true
//        } catch {
//            print("Failed to start audio engine: \(error)")
//        }
//    }
//    
//    func stopStreaming() {
//        audioEngine?.stop()
//        audioEngine?.inputNode.removeTap(onBus: 0)
//        audioEngine = nil
//        isProcessing = false
//        
//        // Process the complete audio file
//        processCompleteAudio()
//    }
//    
//    private func processCompleteAudio() {
//        guard let audioData = audioData else { return }
//        
//        // Create URL request
//        let url = URL(string: "https://speech.googleapis.com/v1/speech:recognize")!
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        // Create request body
//        let requestBody: [String: Any] = [
//            "config": [
//                "encoding": "LINEAR16",
//                "sampleRateHertz": 16000,
//                "languageCode": "en-US",
//                "enableAutomaticPunctuation": true
//            ],
//            "audio": [
//                "content": audioData.base64EncodedString()
//            ]
//        ]
//        
//        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
//        
//        // Send request
//        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
//            guard let self = self,
//                  let data = data,
//                  error == nil else {
//                print("Error: \(error?.localizedDescription ?? "Unknown error")")
//                return
//            }
//            
//            do {
//                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
//                   let results = json["results"] as? [[String: Any]],
//                   let firstResult = results.first,
//                   let alternatives = firstResult["alternatives"] as? [[String: Any]],
//                   let firstAlternative = alternatives.first,
//                   let transcript = firstAlternative["transcript"] as? String {
//                    
//                    DispatchQueue.main.async {
//                        self.transcribedText = transcript
//                        // For now, just echo the transcript as the AI response
//                        self.aiResponse = "I heard you say: \(transcript)"
//                        self.speakResponse(self.aiResponse)
//                    }
//                }
//            } catch {
//                print("JSON parsing error: \(error)")
//            }
//        }.resume()
//    }
//    
//    private func speakResponse(_ text: String) {
//        let synthesizer = AVSpeechSynthesizer()
//        let utterance = AVSpeechUtterance(string: text)
//        utterance.rate = 0.5
//        utterance.pitchMultiplier = 1.0
//        utterance.volume = 1.0
//        synthesizer.speak(utterance)
//    }
//} 
