import Foundation

struct AIMessage: Codable, Sendable, Equatable, Hashable {
    enum Role: String, Codable, Sendable {
        case user
        case assistant
        case system
    }

    let role: Role
    let content: String

    init(role: Role, content: String) {
        self.role = role
        self.content = content
    }

    static func user(_ content: String) -> AIMessage {
        AIMessage(role: .user, content: content)
    }

    static func assistant(_ content: String) -> AIMessage {
        AIMessage(role: .assistant, content: content)
    }

    static func system(_ content: String) -> AIMessage {
        AIMessage(role: .system, content: content)
    }
}
