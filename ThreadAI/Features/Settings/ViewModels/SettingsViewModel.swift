import Foundation
import OSLog
import UIKit

private let logger = Logger(subsystem: "com.threadai", category: "SettingsViewModel")

@Observable
@MainActor
final class SettingsViewModel {

    enum KeyStatus: Equatable {
        case notSet
        case set
        case validating
        case valid
        case invalid(String)

        var isSet: Bool { self == .set || self == .valid }
        var isValidating: Bool { self == .validating }

        var displayLabel: String {
            switch self {
            case .notSet:          return "Not configured"
            case .set:             return "Configured"
            case .validating:      return "Validating…"
            case .valid:           return "Valid"
            case .invalid(let msg): return "Invalid: \(msg)"
            }
        }

        var color: KeyStatusColor {
            switch self {
            case .notSet:    return .secondary
            case .set:       return .accent
            case .validating: return .secondary
            case .valid:     return .success
            case .invalid:   return .error
            }
        }
    }

    enum KeyStatusColor { case secondary, accent, success, error }

    private(set) var keyStatuses: [AIProviderType: KeyStatus] = [:]
    var errorMessage: String?

    private let keychainService: any KeychainServiceProtocol
    private let aiHarnessService: AIHarnessService

    init(keychainService: any KeychainServiceProtocol, aiHarnessService: AIHarnessService) {
        self.keychainService = keychainService
        self.aiHarnessService = aiHarnessService
        refreshStatuses()
    }

    // MARK: - Status

    func refreshStatuses() {
        for provider in AIProviderType.allCases {
            keyStatuses[provider] = keychainService.hasKey(for: provider) ? .set : .notSet
        }
    }

    func status(for provider: AIProviderType) -> KeyStatus {
        keyStatuses[provider] ?? .notSet
    }

    func hasKey(for provider: AIProviderType) -> Bool {
        keychainService.hasKey(for: provider)
    }

    // MARK: - Save & Validate

    func saveAndValidate(_ key: String, for provider: AIProviderType) async {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        keyStatuses[provider] = .validating
        do {
            let isValid = try await aiHarnessService.validateAPIKey(trimmed, for: provider)
            if isValid {
                keychainService.set(trimmed, for: provider)
                keyStatuses[provider] = .valid
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                logger.info("API key validated and saved for \(provider.rawValue)")
            } else {
                keyStatuses[provider] = .invalid("Rejected by provider")
            }
        } catch {
            keyStatuses[provider] = .invalid(error.localizedDescription)
            logger.error("Key validation failed for \(provider.rawValue): \(error.localizedDescription)")
        }

        Task {
            try? await Task.sleep(for: .seconds(3))
            refreshStatuses()
        }
    }

    // MARK: - Delete

    func deleteKey(for provider: AIProviderType) {
        keychainService.delete(for: provider)
        keyStatuses[provider] = .notSet
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        logger.info("API key deleted for \(provider.rawValue)")
    }

    func clearError() { errorMessage = nil }
}
