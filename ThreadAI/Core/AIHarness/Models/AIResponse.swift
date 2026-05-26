import Foundation

struct AIResponse: Sendable {
    let content: String
    let model: AIModel
    let usage: TokenUsage?

    struct TokenUsage: Sendable {
        let inputTokens: Int
        let outputTokens: Int
        var totalTokens: Int { inputTokens + outputTokens }
    }
}
