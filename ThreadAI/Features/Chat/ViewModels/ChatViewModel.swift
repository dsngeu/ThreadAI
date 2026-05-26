import Foundation
import UIKit
import OSLog

private let logger = Logger(subsystem: "com.threadai", category: "ChatViewModel")

@Observable
@MainActor
final class ChatViewModel {
    private(set) var conversation: Conversation
    private(set) var messages: [Message] = []
    private(set) var isStreaming = false
    private(set) var streamingContent = ""
    private(set) var subThreadConversations: [UUID: Conversation] = [:]
    private(set) var allSubThreads: [Conversation] = []
    var navigateToThread: Conversation?
    var inputText = ""
    var errorMessage: String?
    var showCreateSubThread = false
    var showThreadsList = false
    var selectedForkMessageID: UUID?
    let dependencies: AppDependencies

    private let sendMessageUseCase: SendMessageUseCase
    private let bookmarkUseCase: BookmarkMessageUseCase
    private let createSubThreadUseCase: CreateSubThreadUseCase
    private let messageRepo: any MessageRepository
    private let conversationRepo: any ConversationRepository
    private var streamingTask: Task<Void, Never>?
    private var tokenBuffer = ""
    private var lastFlush: ContinuousClock.Instant = .now

    init(conversation: Conversation, dependencies: AppDependencies) {
        self.conversation = conversation
        self.dependencies = dependencies
        self.sendMessageUseCase = dependencies.sendMessage
        self.bookmarkUseCase = dependencies.bookmarkMessage
        self.createSubThreadUseCase = dependencies.createSubThread
        self.messageRepo = dependencies.messageRepository
        self.conversationRepo = dependencies.conversationRepository
    }

    func onAppear() async {
        await loadMessages()
        await loadSubThreadConversations()
    }

    // MARK: - Messaging

    func send() {
        let content = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty, !isStreaming else { return }

        inputText = ""
        isStreaming = true
        streamingContent = ""
        messages.append(Message.user(content, conversationID: conversation.id))
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        streamingTask = Task {
            do {
                tokenBuffer = ""
                lastFlush = .now
                for try await token in sendMessageUseCase.execute(userContent: content, in: conversation) {
                    tokenBuffer += token
                    let now = ContinuousClock.Instant.now
                    if now - lastFlush >= .seconds(1) {
                        streamingContent += tokenBuffer
                        tokenBuffer = ""
                        lastFlush = now
                    }
                }
                streamingContent += tokenBuffer
                tokenBuffer = ""
            } catch is CancellationError {
            } catch {
                errorMessage = error.localizedDescription
                logger.error("Stream failed: \(error.localizedDescription)")
            }
            streamingContent = ""
            isStreaming = false
            await loadMessages()
        }
    }

    func stopStreaming() {
        streamingTask?.cancel()
        streamingTask = nil
    }

    // MARK: - Bookmarks

    func toggleBookmark(messageID: UUID) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        Task {
            do {
                try await bookmarkUseCase.execute(messageID: messageID, conversationID: conversation.id)
                await loadMessages()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Sub-threads

    func startCreateSubThread(fromMessage messageID: UUID) {
        selectedForkMessageID = messageID
        showCreateSubThread = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func createSubThread(title: String, model: AIModel, systemPrompt: String?) async {
        guard let messageID = selectedForkMessageID else { return }
        do {
            let thread = try await createSubThreadUseCase.execute(
                title: title, fromMessage: messageID,
                in: conversation.id, model: model, systemPrompt: systemPrompt
            )
            showCreateSubThread = false
            selectedForkMessageID = nil
            await loadMessages()
            await loadSubThreadConversations()
            navigateToThread = thread
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Model

    func changeModel(to model: AIModel) {
        guard !isStreaming else { return }
        conversation.model = model
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        Task {
            do { try await conversationRepo.update(conversation) }
            catch { errorMessage = error.localizedDescription }
        }
    }

    // MARK: - Helpers

    func clearError() { errorMessage = nil }

    var threadsList: [Conversation] {
        allSubThreads.sorted { $0.createdAt < $1.createdAt }
    }

    private func loadMessages() async {
        do { messages = try await messageRepo.fetchMessages(for: conversation.id) }
        catch { errorMessage = error.localizedDescription }
    }

    private func loadSubThreadConversations() async {
        do {
            let threads = try await conversationRepo.fetchSubThreads(of: conversation.id)
            var map: [UUID: Conversation] = [:]
            for thread in threads {
                map[thread.id] = thread
            }
            subThreadConversations = map
            allSubThreads = threads
        } catch {
            logger.error("Failed to load sub-threads: \(error.localizedDescription)")
        }
    }

}
