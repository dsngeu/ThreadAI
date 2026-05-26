import Foundation
import OSLog
import UIKit

private let logger = Logger(subsystem: "com.threadai", category: "ConversationListViewModel")

@Observable
@MainActor
final class ConversationListViewModel {
    private(set) var conversations: [Conversation] = []
    private(set) var subThreads: [UUID: [Conversation]] = [:]
    private(set) var isLoading = false
    var errorMessage: String?
    var showCreateConversation = false
    var searchText = ""
    var newTopicName = ""

    private let conversationRepo: any ConversationRepository
    private let createSubThread: CreateSubThreadUseCase

    init(dependencies: AppDependencies) {
        self.conversationRepo = dependencies.conversationRepository
        self.createSubThread = dependencies.createSubThread
    }

    var filteredConversations: [Conversation] {
        guard !searchText.isEmpty else { return conversations }
        return conversations.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    // MARK: - Lifecycle

    func onAppear() async {
        await loadConversations()
    }

    // MARK: - Load

    func loadConversations() async {
        isLoading = conversations.isEmpty
        defer { isLoading = false }
        do {
            conversations = try await conversationRepo.fetchTopLevel()
            await loadSubThreads()
        } catch {
            errorMessage = error.localizedDescription
            logger.error("Load conversations failed: \(error.localizedDescription)")
        }
    }

    private func loadSubThreads() async {
        let ids = conversations.map(\.id)
        guard !ids.isEmpty else { return }
        var result: [UUID: [Conversation]] = [:]
        await withTaskGroup(of: (UUID, [Conversation]).self) { group in
            for id in ids {
                group.addTask { [conversationRepo] in
                    let threads = (try? await conversationRepo.fetchSubThreads(of: id)) ?? []
                    return (id, threads)
                }
            }
            for await (id, threads) in group where !threads.isEmpty {
                result[id] = threads
            }
        }
        subThreads = result
    }

    // MARK: - Create

    func createConversation(title: String, model: AIModel, systemPrompt: String?) async {
        let conversation = Conversation.new(title: title, model: model, systemPrompt: systemPrompt)
        do {
            try await conversationRepo.save(conversation)
            await loadConversations()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Delete

    func delete(conversation: Conversation) {
        Task {
            do {
                try await conversationRepo.delete(id: conversation.id)
                await loadConversations()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func delete(at offsets: IndexSet) {
        let source = filteredConversations
        let toDelete = offsets.compactMap { index -> Conversation? in
            guard source.indices.contains(index) else { return nil }
            return source[index]
        }
        toDelete.forEach { delete(conversation: $0) }
    }

    // MARK: - Pin

    func togglePin(conversation: Conversation) {
        Task {
            var updated = conversation
            updated.isPinned.toggle()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            do {
                try await conversationRepo.update(updated)
                await loadConversations()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Helpers

    func clearError() { errorMessage = nil }
}
