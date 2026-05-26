import Foundation
import OSLog
import UIKit

private let logger = Logger(subsystem: "com.threadai", category: "BookmarksViewModel")

struct BookmarkedItem: Identifiable {
    let id: UUID
    let message: Message
    let conversation: Conversation?

    var conversationTitle: String { conversation?.title ?? "Unknown Conversation" }
}

@Observable
@MainActor
final class BookmarksViewModel {
    private(set) var bookmarks: [BookmarkedItem] = []
    private(set) var isLoading = false
    var errorMessage: String?

    private let messageRepo: any MessageRepository
    private let conversationRepo: any ConversationRepository

    init(dependencies: AppDependencies) {
        self.messageRepo = dependencies.messageRepository
        self.conversationRepo = dependencies.conversationRepository
    }

    func onAppear() async {
        await loadBookmarks()
    }

    func loadBookmarks() async {
        isLoading = bookmarks.isEmpty
        defer { isLoading = false }
        do {
            let messages = try await messageRepo.fetchBookmarked()
            let conversationIDs = Set(messages.map(\.conversationID))

            var conversationMap: [UUID: Conversation] = [:]
            await withTaskGroup(of: (UUID, Conversation?).self) { group in
                for id in conversationIDs {
                    group.addTask { [conversationRepo] in
                        (id, try? await conversationRepo.fetch(id: id))
                    }
                }
                for await (id, conv) in group {
                    if let conv { conversationMap[id] = conv }
                }
            }

            bookmarks = messages
                .map { BookmarkedItem(id: $0.id, message: $0, conversation: conversationMap[$0.conversationID]) }
                .sorted { $0.message.timestamp > $1.message.timestamp }
        } catch {
            errorMessage = error.localizedDescription
            logger.error("Load bookmarks failed: \(error.localizedDescription)")
        }
    }

    func removeBookmark(_ item: BookmarkedItem) {
        Task {
            do {
                var updated = item.message
                updated.isBookmarked = false
                try await messageRepo.update(updated)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                await loadBookmarks()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func clearError() { errorMessage = nil }
}
