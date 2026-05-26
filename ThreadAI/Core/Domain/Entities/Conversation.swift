import Foundation

struct Conversation: Identifiable, Hashable, Sendable {
    let id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool
    var model: AIModel
    var systemPrompt: String?
    var parentConversationID: UUID?
    var forkMessageID: UUID?
    var messageCount: Int

    var isSubThread: Bool { parentConversationID != nil }

    static func new(
        title: String,
        model: AIModel,
        systemPrompt: String? = nil,
        parentConversationID: UUID? = nil,
        forkMessageID: UUID? = nil
    ) -> Conversation {
        Conversation(
            id: UUID(),
            title: title,
            createdAt: Date(),
            updatedAt: Date(),
            isPinned: false,
            model: model,
            systemPrompt: systemPrompt,
            parentConversationID: parentConversationID,
            forkMessageID: forkMessageID,
            messageCount: 0
        )
    }
}
