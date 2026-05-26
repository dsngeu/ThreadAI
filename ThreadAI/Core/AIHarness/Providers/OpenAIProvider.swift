import Foundation
import OSLog

private let logger = Logger(subsystem: "com.threadai", category: "OpenAIProvider")

struct OpenAIProvider: AIProvider {
    let providerType: AIProviderType = .openAI
    let availableModels: [AIModel] = AIModel.openAIModels

    private let keychainService: any KeychainServiceProtocol
    private let baseURL = URL(string: "https://api.openai.com/v1/chat/completions")!

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
                    guard let apiKey = keychainService.get(for: .openAI) else {
                        throw AIError.missingAPIKey(.openAI)
                    }
                    let urlRequest = try buildRequest(request, apiKey: apiKey)
                    let (bytes, response) = try await URLSession.shared.bytes(for: urlRequest)

                    guard let http = response as? HTTPURLResponse else {
                        throw AIError.streamInterrupted
                    }
                    try validateStatus(http.statusCode, provider: .openAI)

                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let payload = String(line.dropFirst(6))
                        guard payload != "[DONE]" else { break }
                        if let token = parseChunk(payload) {
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
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": AIModel.gpt4oMini.rawValue,
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
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var messages: [[String: String]] = []
        if let system = request.resolvedSystemPrompt {
            messages.append(["role": "system", "content": system])
        }
        messages += request.nonSystemMessages.map {
            ["role": $0.role.rawValue, "content": $0.content]
        }

        let body: [String: Any] = [
            "model": request.model.rawValue,
            "messages": messages,
            "max_tokens": request.maxTokens,
            "temperature": request.temperature,
            "stream": true
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        return req
    }

    private func parseChunk(_ json: String) -> String? {
        guard
            let data = json.data(using: .utf8),
            let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = obj["choices"] as? [[String: Any]],
            let first = choices.first,
            let delta = first["delta"] as? [String: Any],
            let content = delta["content"] as? String,
            !content.isEmpty
        else { return nil }

        return content
    }

    private func validateStatus(_ code: Int, provider: AIProviderType) throws {
        switch code {
        case 200: return
        case 401: throw AIError.invalidAPIKey(provider)
        case 429: throw AIError.rateLimitExceeded
        case 400: throw AIError.serverError(statusCode: code, message: "Bad request — check model or parameters.")
        default:  throw AIError.serverError(statusCode: code, message: "Unexpected HTTP \(code).")
        }
    }
}
