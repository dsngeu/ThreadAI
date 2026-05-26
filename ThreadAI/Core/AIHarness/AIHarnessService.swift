import Foundation
import OSLog

private let logger = Logger(subsystem: "com.threadai", category: "AIHarnessService")

@Observable
@MainActor
final class AIHarnessService {
    private(set) var activeProviderType: AIProviderType = .claude

    @ObservationIgnored private let providers: [AIProviderType: any AIProvider]
    @ObservationIgnored private let keychainService: any KeychainServiceProtocol

    init(keychainService: any KeychainServiceProtocol) {
        self.keychainService = keychainService
        self.providers = [
            .claude: ClaudeProvider(keychainService: keychainService),
            .openAI: OpenAIProvider(keychainService: keychainService)
        ]
    }

    /// Testing initialiser — inject pre-built providers directly.
    init(providers: [AIProviderType: any AIProvider], keychainService: any KeychainServiceProtocol) {
        self.keychainService = keychainService
        self.providers = providers
    }

    var availableModels: [AIModel] {
        AIModel.models(for: activeProviderType)
    }

    var allModels: [AIModel] {
        AIModel.allCases
    }

    func setActiveProvider(_ type: AIProviderType) {
        activeProviderType = type
        logger.info("Active provider changed to \(type.rawValue)")
    }

    func send(_ request: AIRequest) async throws -> AIResponse {
        let provider = resolvedProvider(for: request.model)
        return try await provider.send(request)
    }

    func stream(_ request: AIRequest) -> AsyncThrowingStream<String, Error> {
        resolvedProvider(for: request.model).stream(request)
    }

    func validateAPIKey(_ key: String, for providerType: AIProviderType) async throws -> Bool {
        guard let provider = providers[providerType] else { return false }
        return try await provider.validateAPIKey(key)
    }

    func hasAPIKey(for providerType: AIProviderType) -> Bool {
        keychainService.hasKey(for: providerType)
    }

    // MARK: - Private

    private func resolvedProvider(for model: AIModel) -> any AIProvider {
        guard let provider = providers[model.provider] else {
            logger.error("No provider registered for \(model.provider.rawValue)")
            return providers[.claude]!
        }
        return provider
    }
}
