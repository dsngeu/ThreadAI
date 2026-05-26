import CoreData

extension CDConversation {
    func toEntity() -> Conversation {
        Conversation(
            id: id ?? UUID(),
            title: title ?? "",
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date(),
            isPinned: isPinned,
            model: AIModel(rawValue: modelID ?? "") ?? .claudeSonnet4,
            systemPrompt: systemPrompt,
            parentConversationID: parentConversationID,
            forkMessageID: forkMessageID,
            messageCount: messages?.count ?? 0
        )
    }

    func populate(from entity: Conversation) {
        id = entity.id
        title = entity.title
        createdAt = entity.createdAt
        updatedAt = entity.updatedAt
        isPinned = entity.isPinned
        modelID = entity.model.rawValue
        systemPrompt = entity.systemPrompt
        parentConversationID = entity.parentConversationID
        forkMessageID = entity.forkMessageID
    }
}
