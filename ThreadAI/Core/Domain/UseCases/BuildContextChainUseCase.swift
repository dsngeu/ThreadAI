import Foundation

struct BuildContextChainUseCase: Sendable {
    let conversationRepo: any ConversationRepository
    let messageRepo: any MessageRepository

    /// Builds the full AIMessage context chain for a conversation,
    /// walking up through parent conversations recursively.
    func execute(for conversationID: UUID) async throws -> [AIMessage] {
        guard let conversation = try await conversationRepo.fetch(id: conversationID) else {
            throw DomainError.conversationNotFound(conversationID)
        }
        return try await buildChain(conversation: conversation, cutoff: nil)
    }

    // MARK: - Private

    /// `cutoff`: if set, only messages up to and including this ID are included
    /// from this conversation's message list. Used when building parent context.
    private func buildChain(conversation: Conversation, cutoff: UUID?) async throws -> [AIMessage] {
        var chain: [AIMessage] = []

        if let parentID = conversation.parentConversationID,
           let forkID = conversation.forkMessageID,
           let parent = try await conversationRepo.fetch(id: parentID) {
            chain = try await buildChain(conversation: parent, cutoff: forkID)
        }

        let messages = try await messageRepo.fetchMessages(for: conversation.id)
        for msg in messages {
            chain.append(AIMessage(role: msg.role.aiRole, content: msg.content))
            if let cutoff, msg.id == cutoff { break }
        }

        return chain
    }
}
