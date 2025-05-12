import Foundation
import SwiftData

@Model
final class Conversation {
    var id: UUID
    var createdAt: Date
    @Relationship(deleteRule: .cascade) var messages: [Message]
    var title: String
    
    init(id: UUID = UUID(), createdAt: Date = .now, messages: [Message] = [], title: String = "New Chat") {
        self.id = id
        self.createdAt = createdAt
        self.messages = messages
        self.title = title
    }
    
    var previewText: String {
        messages.first?.content ?? "No messages"
    }
    
    func updateTitle() {
        if let firstMessage = messages.first {
            title = firstMessage.content.prefix(30) + (firstMessage.content.count > 30 ? "..." : "")
        }
    }
} 