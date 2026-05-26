import Foundation
import Security
import OSLog

private let logger = Logger(subsystem: "com.threadai", category: "KeychainService")

final class KeychainService: KeychainServiceProtocol, @unchecked Sendable {

    private enum Key: String {
        case claude  = "com.threadai.apikey.claude"
        case openAI  = "com.threadai.apikey.openai"

        init(provider: AIProviderType) {
            switch provider {
            case .claude:  self = .claude
            case .openAI:  self = .openAI
            }
        }
    }

    func set(_ value: String, for provider: AIProviderType) {
        guard !value.isEmpty, let data = value.data(using: .utf8) else { return }
        let account = Key(provider: provider).rawValue

        var query = baseQuery(account: account)
        query[kSecValueData as String] = data

        SecItemDelete(baseQuery(account: account) as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)

        if status != errSecSuccess {
            logger.error("Keychain write failed for \(account, privacy: .private): \(status)")
        }
    }

    func get(for provider: AIProviderType) -> String? {
        let account = Key(provider: provider).rawValue

        var query = baseQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func delete(for provider: AIProviderType) {
        let account = Key(provider: provider).rawValue
        SecItemDelete(baseQuery(account: account) as CFDictionary)
    }

    func hasKey(for provider: AIProviderType) -> Bool {
        get(for: provider) != nil
    }

    // MARK: - Private

    private func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String:   kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
    }
}
