import Foundation
import OSLog

private let logger = Logger(subsystem: "com.threadai", category: "CreateSubThreadUseCase")

struct CreateSubThreadUseCase: Sendable {
    let conversationRepo: any ConversationRepository
    let messageRepo: any MessageRepository

    /// Creates a sub-thread forked from `messageID` in `parentConversationID`.
    /// Marks the fork message with the new thread's ID for inline card display.
    @discardableResult
    func execute(
        title: String,
        fromMessage messageID: UUID,
        in parentConversationID: UUID,
        model: AIModel,
        systemPrompt: String? = nil
    ) async throws -> Conversation {
        guard try await conversationRepo.fetch(id: parentConversationID) != nil else {
            throw DomainError.conversationNotFound(parentConversationID)
        }

        let subThread = Conversation.new(
            title: title,
            model: model,
            systemPrompt: systemPrompt,
            parentConversationID: parentConversationID,
            forkMessageID: messageID
        )
        try await conversationRepo.save(subThread)

        if var forkMessage = try await messageRepo.fetch(id: messageID) {
            forkMessage.spawnedThreadID = subThread.id
            try await messageRepo.update(forkMessage)

            let contextCopy = Message(
                id: UUID(),
                conversationID: subThread.id,
                role: forkMessage.role,
                content: forkMessage.content,
                timestamp: forkMessage.timestamp,
                isBookmarked: false,
                bookmarkTitle: nil,
                spawnedThreadID: nil
            )
            try await messageRepo.save(contextCopy)
        } else {
            logger.warning("Fork message \(messageID) not found — sub-thread created without inline card.")
        }

        logger.info("Sub-thread '\(title)' created from message \(messageID)")
        return subThread
    }
}
