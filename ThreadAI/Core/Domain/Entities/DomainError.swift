import Foundation

enum DomainError: LocalizedError, Sendable {
    case conversationNotFound(UUID)
    case messageNotFound(UUID)
    case subThreadCreationFailed(String)

    var errorDescription: String? {
        switch self {
        case .conversationNotFound(let id):
            "Conversation not found: \(id)"
        case .messageNotFound(let id):
            "Message not found: \(id)"
        case .subThreadCreationFailed(let reason):
            "Failed to create sub-thread: \(reason)"
        }
    }
}
