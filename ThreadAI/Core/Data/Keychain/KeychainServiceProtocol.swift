import Foundation

protocol KeychainServiceProtocol: Sendable {
    func set(_ value: String, for provider: AIProviderType)
    func get(for provider: AIProviderType) -> String?
    func delete(for provider: AIProviderType)
    func hasKey(for provider: AIProviderType) -> Bool
}
