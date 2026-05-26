import Foundation
import OSLog

private let logger = Logger(subsystem: "com.threadai", category: "BookmarkMessageUseCase")

struct BookmarkMessageUseCase: Sendable {
    let messageRepo: any MessageRepository
    let aiHarness: AIHarnessService

    @discardableResult
    func execute(messageID: UUID, conversationID: UUID) async throws -> Message {
        let messages = try await messageRepo.fetchMessages(for: conversationID)
        guard var message = messages.first(where: { $0.id == messageID }) else {
            throw DomainError.messageNotFound(messageID)
        }
        message.isBookmarked.toggle()

        if message.isBookmarked {
            let title = await generateTitle(for: message.content)
            message.bookmarkTitle = title
        } else {
            message.bookmarkTitle = nil
        }

        try await messageRepo.update(message)
        return message
    }

    private func generateTitle(for content: String) async -> String? {
        let truncated = String(content.prefix(500))
        let request = AIRequest(
            model: .gpt4oMini,
            messages: [
                .user("Generate a short bookmark title (max 6 words) for this message. Reply with ONLY the title, nothing else:\n\n\(truncated)")
            ],
            systemPrompt: "You generate concise bookmark titles. Reply with only the title text, no quotes, no punctuation at the end.",
            maxTokens: 30,
            temperature: 0.3
        )
        do {
            let response = try await aiHarness.send(request)
            let title = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty else { return nil }
            return title
        } catch {
            logger.error("Title generation failed: \(error.localizedDescription)")
            return nil
        }
    }
}
