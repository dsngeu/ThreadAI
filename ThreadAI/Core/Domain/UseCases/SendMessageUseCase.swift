import Foundation
import OSLog

private let logger = Logger(subsystem: "com.threadai", category: "SendMessageUseCase")

@Observable
@MainActor
final class SendMessageUseCase {
    private let aiHarness: AIHarnessService
    private let contextChain: BuildContextChainUseCase
    private let messageRepo: any MessageRepository
    private let conversationRepo: any ConversationRepository

    init(
        aiHarness: AIHarnessService,
        contextChain: BuildContextChainUseCase,
        messageRepo: any MessageRepository,
        conversationRepo: any ConversationRepository
    ) {
        self.aiHarness = aiHarness
        self.contextChain = contextChain
        self.messageRepo = messageRepo
        self.conversationRepo = conversationRepo
    }

    /// Saves the user message, streams the AI response, saves the assistant message,
    /// and updates the conversation timestamp — all in one atomic flow.
    func execute(
        userContent: String,
        in conversation: Conversation
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let userMessage = Message.user(userContent, conversationID: conversation.id)
                    try await self.messageRepo.save(userMessage)

                    let contextMessages = try await self.contextChain.execute(for: conversation.id)
                    let request = AIRequest(
                        model: conversation.model,
                        messages: contextMessages,
                        systemPrompt: conversation.systemPrompt
                    )

                    var accumulated = ""
                    for try await token in self.aiHarness.stream(request) {
                        accumulated += token
                        continuation.yield(token)
                    }

                    let assistantMessage = Message.assistant(accumulated, conversationID: conversation.id)
                    try await self.messageRepo.save(assistantMessage)

                    var updated = conversation
                    updated.updatedAt = Date()
                    updated.messageCount = conversation.messageCount + 2
                    try await self.conversationRepo.update(updated)

                    continuation.finish()
                } catch {
                    logger.error("SendMessageUseCase failed: \(error.localizedDescription)")
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
