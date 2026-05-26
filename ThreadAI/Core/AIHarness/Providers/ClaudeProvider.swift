import Foundation
import OSLog

private let logger = Logger(subsystem: "com.threadai", category: "ClaudeProvider")

struct ClaudeProvider: AIProvider {
    let providerType: AIProviderType = .claude
    let availableModels: [AIModel] = AIModel.claudeModels

    private let keychainService: any KeychainServiceProtocol
    private let baseURL = URL(string: "https://api.anthropic.com/v1/messages")!
    private let anthropicVersion = "2023-06-01"

    init(keychainService: any KeychainServiceProtocol) {
        self.keychainService = keychainService
    }

    func send(_ request: AIRequest) async throws -> AIResponse {
        var accumulated = ""
        for try await token in stream(request) {
            accumulated += token
        }
        return AIResponse(content: accumulated, model: request.model, usage: nil)
    }

    func stream(_ request: AIRequest) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let apiKey = keychainService.get(for: .claude) else {
                        throw AIError.missingAPIKey(.claude)
                    }
                    let urlRequest = try buildRequest(request, apiKey: apiKey)
                    let (bytes, response) = try await URLSession.shared.bytes(for: urlRequest)

                    guard let http = response as? HTTPURLResponse else {
                        throw AIError.streamInterrupted
                    }
                    try validateStatus(http.statusCode, provider: .claude)

                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        if let token = parseChunk(String(line.dropFirst(6))) {
                            continuation.yield(token)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func validateAPIKey(_ key: String) async throws -> Bool {
        var req = URLRequest(url: baseURL)
        req.httpMethod = "POST"
        req.setValue(key, forHTTPHeaderField: "x-api-key")
        req.setValue(anthropicVersion, forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": AIModel.claudeHaiku4.rawValue,
            "max_tokens": 1,
            "messages": [["role": "user", "content": "Hi"]]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { return false }
        return http.statusCode != 401
    }

    // MARK: - Private

    private func buildRequest(_ request: AIRequest, apiKey: String) throws -> URLRequest {
        var req = URLRequest(url: baseURL)
        req.httpMethod = "POST"
        req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        req.setValue(anthropicVersion, forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "model": request.model.rawValue,
            "max_tokens": request.maxTokens,
            "stream": true,
            "messages": request.nonSystemMessages.map {
                ["role": $0.role.rawValue, "content": $0.content]
            }
        ]

        if let system = request.resolvedSystemPrompt {
            body["system"] = system
        }

        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        return req
    }

    private func parseChunk(_ json: String) -> String? {
        guard
            let data = json.data(using: .utf8),
            let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let type = obj["type"] as? String,
            type == "content_block_delta",
            let delta = obj["delta"] as? [String: Any],
            delta["type"] as? String == "text_delta",
            let text = delta["text"] as? String
        else { return nil }

        return text
    }

    private func validateStatus(_ code: Int, provider: AIProviderType) throws {
        switch code {
        case 200: return
        case 401: throw AIError.invalidAPIKey(provider)
        case 429: throw AIError.rateLimitExceeded
        case 400: throw AIError.serverError(statusCode: code, message: "Bad request — check model or parameters.")
        case 529: throw AIError.serverError(statusCode: code, message: "API overloaded. Try again shortly.")
        default:  throw AIError.serverError(statusCode: code, message: "Unexpected HTTP \(code).")
        }
    }
}
