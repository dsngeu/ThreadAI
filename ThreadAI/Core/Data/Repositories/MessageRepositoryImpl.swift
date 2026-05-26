import CoreData
import OSLog

private let logger = Logger(subsystem: "com.threadai", category: "MessageRepository")

final class MessageRepositoryImpl: MessageRepository, @unchecked Sendable {
    private let persistence: PersistenceController

    init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    func fetchMessages(for conversationID: UUID) async throws -> [Message] {
        let context = persistence.container.viewContext
        return try await context.perform {
            let request = CDMessage.fetchRequest()
            request.predicate = NSPredicate(format: "conversationID == %@", conversationID as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \CDMessage.timestamp, ascending: true)]
            return try context.fetch(request).map { $0.toEntity() }
        }
    }

    func fetch(id: UUID) async throws -> Message? {
        let context = persistence.container.viewContext
        return try await context.perform {
            let request = CDMessage.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            return try context.fetch(request).first?.toEntity()
        }
    }

    func fetchBookmarked() async throws -> [Message] {
        let context = persistence.container.viewContext
        return try await context.perform {
            let request = CDMessage.fetchRequest()
            request.predicate = NSPredicate(format: "isBookmarked == YES")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \CDMessage.timestamp, ascending: false)]
            return try context.fetch(request).map { $0.toEntity() }
        }
    }

    func save(_ message: Message) async throws {
        let context = persistence.newBackgroundContext()
        try await context.perform {
            let cd = CDMessage(context: context)
            cd.populate(from: message)

            let convRequest = CDConversation.fetchRequest()
            convRequest.predicate = NSPredicate(format: "id == %@", message.conversationID as CVarArg)
            convRequest.fetchLimit = 1
            cd.conversation = try context.fetch(convRequest).first

            try context.save()
        }
    }

    func update(_ message: Message) async throws {
        let context = persistence.newBackgroundContext()
        try await context.perform {
            let request = CDMessage.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", message.id as CVarArg)
            request.fetchLimit = 1
            guard let cd = try context.fetch(request).first else {
                logger.warning("Message \(message.id) not found for update — saving instead.")
                let new = CDMessage(context: context)
                new.populate(from: message)
                let convRequest = CDConversation.fetchRequest()
                convRequest.predicate = NSPredicate(format: "id == %@", message.conversationID as CVarArg)
                convRequest.fetchLimit = 1
                new.conversation = try context.fetch(convRequest).first
                try context.save()
                return
            }
            cd.populate(from: message)
            try context.save()
        }
    }

    func delete(id: UUID) async throws {
        let context = persistence.newBackgroundContext()
        try await context.perform {
            let request = CDMessage.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            let objects = try context.fetch(request)
            objects.forEach { context.delete($0) }
            if context.hasChanges { try context.save() }
        }
    }

    func deleteAll(for conversationID: UUID) async throws {
        let context = persistence.newBackgroundContext()
        try await context.perform {
            let request = CDMessage.fetchRequest()
            request.predicate = NSPredicate(format: "conversationID == %@", conversationID as CVarArg)
            let objects = try context.fetch(request)
            objects.forEach { context.delete($0) }
            if context.hasChanges { try context.save() }
        }
    }
}
