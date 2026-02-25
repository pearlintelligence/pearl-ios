import Foundation
import SwiftData

// MARK: - Conversation

@Model
final class Conversation {
    var id: UUID
    var title: String?
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .cascade)
    var messages: [ChatMessage]
    
    init(title: String? = nil) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
        self.messages = []
    }
}

// MARK: - Chat Message

@Model
final class ChatMessage {
    var id: UUID
    var content: String
    var role: MessageRole
    var createdAt: Date
    var isStreaming: Bool
    
    var conversation: Conversation?
    
    enum MessageRole: String, Codable {
        case user
        case pearl
        case system
    }
    
    init(content: String, role: MessageRole, isStreaming: Bool = false) {
        self.id = UUID()
        self.content = content
        self.role = role
        self.createdAt = Date()
        self.isStreaming = isStreaming
    }
}

// MARK: - Weekly Insight

@Model
final class WeeklyInsight {
    var id: UUID
    var title: String
    var content: String
    var weekStartDate: Date
    var createdAt: Date
    var isRead: Bool
    var transitContext: String?
    
    init(title: String, content: String, weekStartDate: Date, transitContext: String? = nil) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.weekStartDate = weekStartDate
        self.createdAt = Date()
        self.isRead = false
        self.transitContext = transitContext
    }
}
