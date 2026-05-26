import Foundation

protocol ConversationRepository: Sendable {
    func fetchAll() async throws -> [Conversation]
    func fetchTopLevel() async throws -> [Conversation]
    func fetchSubThreads(of parentID: UUID) async throws -> [Conversation]
    func fetch(id: UUID) async throws -> Conversation?
    func save(_ conversation: Conversation) async throws
    func update(_ conversation: Conversation) async throws
    func delete(id: UUID) async throws
}
