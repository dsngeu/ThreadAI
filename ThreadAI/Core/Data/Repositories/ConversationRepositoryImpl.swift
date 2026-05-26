import CoreData
import OSLog

private let logger = Logger(subsystem: "com.threadai", category: "ConversationRepository")

final class ConversationRepositoryImpl: ConversationRepository, @unchecked Sendable {
    private let persistence: PersistenceController

    init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    func fetchAll() async throws -> [Conversation] {
        let context = persistence.container.viewContext
        return try await context.perform {
            let request = CDConversation.fetchRequest()
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \CDConversation.isPinned, ascending: false),
                NSSortDescriptor(keyPath: \CDConversation.updatedAt, ascending: false)
            ]
            return try context.fetch(request).map { $0.toEntity() }
        }
    }

    func fetchTopLevel() async throws -> [Conversation] {
        let context = persistence.container.viewContext
        return try await context.perform {
            let request = CDConversation.fetchRequest()
            request.predicate = NSPredicate(format: "parentConversationID == nil")
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \CDConversation.isPinned, ascending: false),
                NSSortDescriptor(keyPath: \CDConversation.updatedAt, ascending: false)
            ]
            return try context.fetch(request).map { $0.toEntity() }
        }
    }

    func fetchSubThreads(of parentID: UUID) async throws -> [Conversation] {
        let context = persistence.container.viewContext
        return try await context.perform {
            let request = CDConversation.fetchRequest()
            request.predicate = NSPredicate(format: "parentConversationID == %@", parentID as CVarArg)
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \CDConversation.createdAt, ascending: true)
            ]
            return try context.fetch(request).map { $0.toEntity() }
        }
    }

    func fetch(id: UUID) async throws -> Conversation? {
        let context = persistence.container.viewContext
        return try await context.perform {
            let request = CDConversation.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            return try context.fetch(request).first?.toEntity()
        }
    }

    func save(_ conversation: Conversation) async throws {
        let context = persistence.newBackgroundContext()
        try await context.perform {
            let cd = CDConversation(context: context)
            cd.populate(from: conversation)
            try context.save()
        }
    }

    func update(_ conversation: Conversation) async throws {
        let context = persistence.newBackgroundContext()
        try await context.perform {
            let request = CDConversation.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", conversation.id as CVarArg)
            request.fetchLimit = 1
            guard let cd = try context.fetch(request).first else {
                logger.warning("Conversation \(conversation.id) not found for update — saving instead.")
                let new = CDConversation(context: context)
                new.populate(from: conversation)
                try context.save()
                return
            }
            cd.populate(from: conversation)
            try context.save()
        }
    }

    func delete(id: UUID) async throws {
        let context = persistence.newBackgroundContext()
        try await context.perform {
            let request = CDConversation.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            let objects = try context.fetch(request)
            objects.forEach { context.delete($0) }
            if context.hasChanges { try context.save() }
        }
    }
}
