import Foundation

enum AIProviderType: String, Codable, CaseIterable, Identifiable, Sendable {
    var id: String { rawValue }

    case claude
    case openAI

    var displayName: String {
        switch self {
        case .claude: "Claude (Anthropic)"
        case .openAI: "OpenAI"
        }
    }
}

enum AIModel: String, Codable, CaseIterable, Identifiable, Sendable {
    case claudeOpus4     = "claude-opus-4-7"
    case claudeSonnet4   = "claude-sonnet-4-6"
    case claudeHaiku4    = "claude-haiku-4-5-20251001"
    case gpt4o           = "gpt-4o"
    case gpt4oMini       = "gpt-4o-mini"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .claudeOpus4:   "Claude Opus 4"
        case .claudeSonnet4: "Claude Sonnet 4"
        case .claudeHaiku4:  "Claude Haiku 4"
        case .gpt4o:         "GPT-4o"
        case .gpt4oMini:     "GPT-4o mini"
        }
    }

    var provider: AIProviderType {
        switch self {
        case .claudeOpus4, .claudeSonnet4, .claudeHaiku4: .claude
        case .gpt4o, .gpt4oMini: .openAI
        }
    }

    var contextWindow: Int {
        switch self {
        case .claudeOpus4, .claudeSonnet4, .claudeHaiku4: 200_000
        case .gpt4o, .gpt4oMini: 128_000
        }
    }

    var isRecommended: Bool {
        self == .claudeSonnet4 || self == .gpt4o
    }

    static var claudeModels: [AIModel] { [.claudeOpus4, .claudeSonnet4, .claudeHaiku4] }
    static var openAIModels: [AIModel] { [.gpt4o, .gpt4oMini] }

    static func models(for provider: AIProviderType) -> [AIModel] {
        switch provider {
        case .claude: claudeModels
        case .openAI: openAIModels
        }
    }
}
