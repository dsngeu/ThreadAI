import Foundation

struct AIRequest: Sendable {
    let model: AIModel
    let messages: [AIMessage]
    let systemPrompt: String?
    let maxTokens: Int
    let temperature: Double

    init(
        model: AIModel,
        messages: [AIMessage],
        systemPrompt: String? = nil,
        maxTokens: Int = 4096,
        temperature: Double = 0.7
    ) {
        self.model = model
        self.messages = messages
        self.systemPrompt = systemPrompt
        self.maxTokens = maxTokens
        self.temperature = temperature
    }

    var nonSystemMessages: [AIMessage] {
        messages.filter { $0.role != .system }
    }

    var resolvedSystemPrompt: String? {
        systemPrompt ?? messages.first(where: { $0.role == .system })?.content
    }
}
