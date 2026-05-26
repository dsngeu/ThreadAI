import Foundation

protocol AIProvider: Sendable {
    var providerType: AIProviderType { get }
    var availableModels: [AIModel] { get }

    func send(_ request: AIRequest) async throws -> AIResponse
    func stream(_ request: AIRequest) -> AsyncThrowingStream<String, Error>
    func validateAPIKey(_ key: String) async throws -> Bool
}
