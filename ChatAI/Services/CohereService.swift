import Foundation
import SwiftData

actor CohereService {
    private let apiKey: String
    private let baseURL = URL(string: "https://api.cohere.com/v2")!
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func streamChatCompletion(messages: [Message]) async throws -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            let url = baseURL.appendingPathComponent("chat")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let mappedMessages = messages.map { message -> [String: Any] in
                [
                    "role": message.role.rawValue,
                    "content": message.content
                ]
            }
            
            let body: [String: Any] = [
                "model": "command-r-plus",  // Using Cohere's latest model
                "messages": mappedMessages,
                "stream": true,
                "temperature": 0.3,  // Default temperature for balanced responses
                "p": 0.75,  // Default nucleus sampling
                "k": 0,  // Disable top-k sampling
                "frequency_penalty": 0.0,
                "presence_penalty": 0.0
            ]
            
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            
            Task {
                do {
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw NSError(domain: "CohereService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                    }
                    
                    guard httpResponse.statusCode == 200 else {
                        throw NSError(domain: "CohereService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error: \(httpResponse.statusCode)"])
                    }
                    
                    var buffer = Data()
                    for try await byte in bytes {
                        buffer.append(byte)
                        
                        if byte == 10 { // Newline character
                            if let line = String(data: buffer, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                                buffer.removeAll()
                                
                                guard !line.isEmpty else { continue }
                                guard line != "data: [DONE]" else {
                                    continuation.finish()
                                    return
                                }
                                
                                // Parse SSE format
                                if line.hasPrefix("data: ") {
                                    let jsonString = String(line.dropFirst(6))
                                    if let jsonData = jsonString.data(using: .utf8),
                                       let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                                        
                                        // Handle different event types
                                        if let type = json["type"] as? String {
                                            switch type {
                                            case "content-delta":
                                                if let delta = json["delta"] as? [String: Any],
                                                   let message = delta["message"] as? [String: Any],
                                                   let content = message["content"] as? [String: Any],
                                                   let text = content["text"] as? String {
                                                    continuation.yield(text)
                                                }
                                            case "message-end":
                                                continuation.finish()
                                                return
                                            default:
                                                break
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    print("***** Error:", error)
                    continuation.finish(throwing: error)
                }
            }
        }
    }
} 
