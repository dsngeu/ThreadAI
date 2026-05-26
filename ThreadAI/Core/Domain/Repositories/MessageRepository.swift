import Foundation

protocol MessageRepository: Sendable {
    func fetchMessages(for conversationID: UUID) async throws -> [Message]
    func fetch(id: UUID) async throws -> Message?
    func fetchBookmarked() async throws -> [Message]
    func save(_ message: Message) async throws
    func update(_ message: Message) async throws
    func delete(id: UUID) async throws
    func deleteAll(for conversationID: UUID) async throws
}
