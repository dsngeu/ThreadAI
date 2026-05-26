import CoreData

extension CDMessage {
    func toEntity() -> Message {
        Message(
            id: id ?? UUID(),
            conversationID: conversationID ?? UUID(),
            role: MessageRole(rawValue: role ?? "") ?? .user,
            content: content ?? "",
            timestamp: timestamp ?? Date(),
            isBookmarked: isBookmarked,
            bookmarkTitle: bookmarkTitle,
            spawnedThreadID: spawnedThreadID
        )
    }

    func populate(from entity: Message) {
        id = entity.id
        conversationID = entity.conversationID
        role = entity.role.rawValue
        content = entity.content
        timestamp = entity.timestamp
        isBookmarked = entity.isBookmarked
        bookmarkTitle = entity.bookmarkTitle
        spawnedThreadID = entity.spawnedThreadID
    }
}
