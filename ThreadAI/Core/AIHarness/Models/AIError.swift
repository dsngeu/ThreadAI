import Foundation

enum AIError: LocalizedError, Sendable {
    case missingAPIKey(AIProviderType)
    case invalidAPIKey(AIProviderType)
    case networkError(String)
    case rateLimitExceeded
    case contextWindowExceeded
    case serverError(statusCode: Int, message: String)
    case streamInterrupted
    case unsupportedModel(AIModel)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey(let provider):
            "No API key for \(provider.displayName). Add your key in Settings."
        case .invalidAPIKey(let provider):
            "Invalid API key for \(provider.displayName). Check your key in Settings."
        case .networkError(let detail):
            "Network error: \(detail)"
        case .rateLimitExceeded:
            "Rate limit exceeded. Please wait a moment and try again."
        case .contextWindowExceeded:
            "Conversation is too long. Start a new thread or fork from an earlier message."
        case .serverError(let code, let message):
            "Server error (\(code)): \(message)"
        case .streamInterrupted:
            "The response stream was interrupted. Please try again."
        case .unsupportedModel(let model):
            "Model \(model.displayName) is not supported by this provider."
        }
    }

    var isRetryable: Bool {
        switch self {
        case .networkError, .rateLimitExceeded, .streamInterrupted: true
        default: false
        }
    }
}
