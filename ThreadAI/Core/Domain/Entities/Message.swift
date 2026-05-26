import Foundation

enum MessageRole: String, Codable, Sendable {
    case user
    case assistant
    case system

    var aiRole: AIMessage.Role {
        switch self {
        case .user:      .user
        case .assistant: .assistant
        case .system:    .system
        }
    }
}

struct Message: Identifiable, Hashable, Sendable {
    let id: UUID
    var conversationID: UUID
    var role: MessageRole
    var content: String
    var timestamp: Date
    var isBookmarked: Bool
    var bookmarkTitle: String?
    var spawnedThreadID: UUID?

    var isUser: Bool      { role == .user }
    var isAssistant: Bool { role == .assistant }
    var hasSpawnedThread: Bool { spawnedThreadID != nil }

    static func user(_ content: String, conversationID: UUID) -> Message {
        Message(id: UUID(), conversationID: conversationID, role: .user,
                content: content, timestamp: Date(), isBookmarked: false,
                bookmarkTitle: nil, spawnedThreadID: nil)
    }

    static func assistant(_ content: String, conversationID: UUID) -> Message {
        Message(id: UUID(), conversationID: conversationID, role: .assistant,
                content: content, timestamp: Date(), isBookmarked: false,
                bookmarkTitle: nil, spawnedThreadID: nil)
    }
}
