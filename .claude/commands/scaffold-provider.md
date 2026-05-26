Create a new AI provider for ThreadAI.

Arguments: $ARGUMENTS (provider name in PascalCase, e.g. "Gemini", "Mistral")

Create the following files:

1. `ThreadAI/Core/AIHarness/Providers/$ARGUMENTS Provider.swift`
   - struct conforming to AIProvider
   - providerType: AIProviderType (add new case to AIProviderType enum first)
   - availableModels: [AIModel] (add new cases to AIModel enum first)
   - Implement send(_:) by collecting stream
   - Implement stream(_:) using AsyncThrowingStream + URLSession.bytes
   - Implement validateAPIKey(_:) with a minimal test request
   - Parse SSE lines from the provider's streaming format
   - Use OSLog Logger for errors (subsystem: "com.threadai", category: "$ARGUMENTS Provider")

2. Add to `ThreadAI/Core/AIHarness/Models/AIModel.swift`:
   - New AIProviderType case
   - New AIModel cases with rawValue = provider's model ID string
   - Update displayName, provider, contextWindow, models(for:)

3. Register in `ThreadAI/Core/AIHarness/AIHarnessService.swift`:
   - Add to providers dictionary in init

4. `ThreadAITests/AIHarness/$ARGUMENTS ProviderTests.swift`
   - Test SSE chunk parsing
   - Test missing API key throws AIError.missingAPIKey
   - Test HTTP 401 throws AIError.invalidAPIKey
   - Test HTTP 429 throws AIError.rateLimitExceeded

Rules:
- struct, not class (Sendable by default)
- No force unwraps
- Validate status code before reading stream
- Store only keychainService (any KeychainServiceProtocol) as property
