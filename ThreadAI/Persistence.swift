import CoreData
import OSLog

private let logger = Logger(subsystem: "com.threadai", category: "PersistenceController")

final class PersistenceController: @unchecked Sendable {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ThreadAI")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error {
                logger.critical("CoreData failed to load: \(error.localizedDescription)")
                fatalError("CoreData store failed to load: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
}

extension PersistenceController {
    static let preview = PersistenceController(inMemory: true)
    static let testing = PersistenceController(inMemory: true)
}
