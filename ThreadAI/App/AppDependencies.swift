import Foundation

@Observable
@MainActor
final class AppDependencies {
    let keychainService: KeychainService
    let aiHarnessService: AIHarnessService
    let conversationRepository: any ConversationRepository
    let messageRepository: any MessageRepository
    let buildContextChain: BuildContextChainUseCase
    let sendMessage: SendMessageUseCase
    let createSubThread: CreateSubThreadUseCase
    let bookmarkMessage: BookmarkMessageUseCase

    // MARK: - Production init

    init() {
        let keychain = KeychainService()
        let persistence = PersistenceController.shared
        let convRepo = ConversationRepositoryImpl(persistence: persistence)
        let msgRepo = MessageRepositoryImpl(persistence: persistence)
        let harness = AIHarnessService(keychainService: keychain)
        let contextChain = BuildContextChainUseCase(conversationRepo: convRepo, messageRepo: msgRepo)

        self.keychainService = keychain
        self.aiHarnessService = harness
        self.conversationRepository = convRepo
        self.messageRepository = msgRepo
        self.buildContextChain = contextChain
        self.sendMessage = SendMessageUseCase(
            aiHarness: harness, contextChain: contextChain,
            messageRepo: msgRepo, conversationRepo: convRepo
        )
        self.createSubThread = CreateSubThreadUseCase(conversationRepo: convRepo, messageRepo: msgRepo)
        self.bookmarkMessage = BookmarkMessageUseCase(messageRepo: msgRepo, aiHarness: harness)
    }

    // MARK: - Testing init

    init(
        keychainService: KeychainService,
        aiHarnessService: AIHarnessService,
        conversationRepository: any ConversationRepository,
        messageRepository: any MessageRepository,
        buildContextChain: BuildContextChainUseCase? = nil,
        sendMessage: SendMessageUseCase,
        createSubThread: CreateSubThreadUseCase? = nil,
        bookmarkMessage: BookmarkMessageUseCase
    ) {
        self.keychainService = keychainService
        self.aiHarnessService = aiHarnessService
        self.conversationRepository = conversationRepository
        self.messageRepository = messageRepository
        self.buildContextChain = buildContextChain
            ?? BuildContextChainUseCase(conversationRepo: conversationRepository, messageRepo: messageRepository)
        self.sendMessage = sendMessage
        self.createSubThread = createSubThread
            ?? CreateSubThreadUseCase(conversationRepo: conversationRepository, messageRepo: messageRepository)
        self.bookmarkMessage = bookmarkMessage
    }
}
