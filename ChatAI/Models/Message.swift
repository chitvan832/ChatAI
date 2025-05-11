import Foundation
import SwiftData

@Model
final class Message {
    var id: UUID
    @Attribute(.externalStorage) var content: String
    var isUser: Bool
    var timestamp: Date
    var role: Role
    
    init(content: String, role: Role, timestamp: Date = Date()) {
        self.id = UUID()
        self.content = content
        self.role = role
        self.isUser = (role == .user)
        self.timestamp = timestamp
    }
}

extension Message {
    enum Role: String, Codable {
        case system = "system"
        case user = "user"
        case assistant = "assistant"
    }
} 