# ThreadAI — Claude Code Instructions

## Project Overview
ThreadAI is a production-quality, open-source iOS AI chat app built for portfolio (GitHub, Upwork, LinkedIn).
It targets Claude API + OpenAI API with a beautiful SwiftUI UI that is significantly better than ChatGPT mobile.
The key differentiator is **thread-based discussions** — sub-threads can be spawned from any message within a parent conversation, with the parent context carried forward automatically.

---

## Tech Stack
- **Language**: Swift 5.9+
- **UI**: SwiftUI only (no UIKit)
- **iOS Target**: iOS 17+
- **State Management**: `@Observable` macro (iOS 17), `@State`, `@Environment`
- **Persistence**: CoreData
- **Concurrency**: Async/Await + AsyncThrowingStream (for streaming)
- **AI**: Claude API + OpenAI API (user provides own API keys, stored in Keychain)
- **Architecture**: MVVM + Clean Architecture

---

## Architecture

### Layer Rules (strict — no cross-layer skipping)
```
Presentation  →  Domain  ←  Data
(Views/VMs)      (Entities, UseCases, Repository Protocols)   (CoreData, API, Keychain)
```
- **Presentation**: SwiftUI Views + `@Observable` ViewModels. No business logic. No direct CoreData access.
- **Domain**: Pure Swift. Zero framework imports. Entities, UseCases, Repository protocols.
- **Data**: Implements Domain protocols. Owns CoreData stack, URLSession, Keychain.
- **AI Harness**: Lives in `Core/AIHarness/`. It is infrastructure — used by Domain UseCases via protocol injection.

### Folder Structure
```
ThreadAI/
├── App/
│   ├── ThreadAIApp.swift
│   └── AppDependencies.swift          # Composition root — wires all dependencies
│
├── Core/
│   ├── AIHarness/
│   │   ├── Protocols/
│   │   │   ├── AIProvider.swift
│   │   │   └── StreamingProvider.swift
│   │   ├── Models/
│   │   │   ├── AIMessage.swift
│   │   │   ├── AIRequest.swift
│   │   │   ├── AIResponse.swift
│   │   │   └── AIModel.swift
│   │   ├── Providers/
│   │   │   ├── ClaudeProvider.swift
│   │   │   └── OpenAIProvider.swift
│   │   └── AIHarnessService.swift
│   │
│   ├── Domain/
│   │   ├── Entities/
│   │   │   ├── Conversation.swift
│   │   │   ├── Message.swift
│   │   │   └── Bookmark.swift
│   │   ├── UseCases/
│   │   │   ├── SendMessageUseCase.swift
│   │   │   ├── CreateSubThreadUseCase.swift
│   │   │   ├── BuildContextChainUseCase.swift
│   │   │   └── BookmarkMessageUseCase.swift
│   │   └── Repositories/
│   │       ├── ConversationRepository.swift   # protocol
│   │       └── MessageRepository.swift        # protocol
│   │
│   └── Data/
│       ├── CoreData/
│       │   ├── PersistenceController.swift
│       │   ├── ThreadAI.xcdatamodeld
│       │   ├── CDConversation+Mapping.swift
│       │   └── CDMessage+Mapping.swift
│       ├── Repositories/
│       │   ├── ConversationRepositoryImpl.swift
│       │   └── MessageRepositoryImpl.swift
│       └── Keychain/
│           └── KeychainService.swift
│
├── Features/
│   ├── ConversationList/
│   │   ├── Views/
│   │   └── ViewModels/
│   ├── Chat/
│   │   ├── Views/
│   │   └── ViewModels/
│   ├── Bookmarks/
│   │   ├── Views/
│   │   └── ViewModels/
│   └── Settings/
│       ├── Views/
│       └── ViewModels/
│
└── Shared/
    ├── UI/
    │   ├── Components/
    │   ├── Modifiers/
    │   └── Theme/
    │       ├── AppColors.swift
    │       ├── AppTypography.swift
    │       └── AppSpacing.swift
    └── Extensions/
```

---

## AI Harness

### Core Protocol
```swift
protocol AIProvider {
    var id: String { get }
    var availableModels: [AIModel] { get }
    func send(_ request: AIRequest) async throws -> AIResponse
    func stream(_ request: AIRequest) -> AsyncThrowingStream<String, Error>
}
```

### Context Chain for Sub-Threads
When a sub-thread sends a message, `BuildContextChainUseCase` walks the ancestry:
```
[grandparent messages up to fork] + [parent messages up to fork] + [sub-thread messages]
```
This is recursive and handles arbitrary nesting depth. The assembled context array is passed to the AI provider. Token limit truncation (keep most recent N parent messages) is a V1.1 concern.

### Adding a New Provider
1. Create `Core/AIHarness/Providers/YourProvider.swift`
2. Conform to `AIProvider`
3. Register in `AppDependencies.swift`
Nothing else changes.

---

## Thread / Sub-Thread Model

- **Conversation** = a top-level chat or a sub-thread. Same entity.
- `parentConversationID: UUID?` — nil means top-level
- `forkMessageID: UUID?` — the message in the parent where this sub-thread was spawned
- A message with `spawnedThreadID: UUID?` set renders as an inline thread card in the chat
- Sub-threads appear nested under their parent in the conversation list

---

## SwiftUI Rules

### Hard Limits
- **No SwiftUI view file may exceed 400 lines.** If it grows beyond this, extract sub-components immediately.
- Each extracted component lives in its own file inside the same feature's `Views/` folder.
- ViewModels may not import SwiftUI (use primitives and domain types only).

### State Management
- Use `@Observable` (iOS 17 macro) for ViewModels — not `ObservableObject`/`@Published`.
- `@State` for local, ephemeral view state only.
- `@Environment` for dependency injection of services into views.
- Never put business logic in a View.

### Animations
- All interactive elements use spring animations: `.spring(response: 0.35, dampingFraction: 0.7)`
- Haptic feedback on: send message, create thread, bookmark, long-press actions.
- Typing indicator uses continuous looping animation.
- Message bubbles animate in with `.transition(.asymmetric(insertion: .push(from: .bottom), removal: .opacity))`

---

## CoreData Rules
- All CoreData access happens in `Data/Repositories/` only. Never access `NSManagedObjectContext` from a ViewModel or View.
- Map `NSManagedObject` → Domain Entity in the `+Mapping` extension files.
- Use background context for writes; main context for reads.

---

## Code Quality Rules
- No force unwraps (`!`) except in tests.
- No `print()` statements in production code — use `Logger` (OSLog).
- All async functions must handle errors — no silent `try?` swallowing.
- API keys are never logged, never stored in UserDefaults — Keychain only.
- No hardcoded strings for UI text — use a `Strings` enum or `LocalizedStringKey`.

---

## Available Claude Skills

| Skill | Command | What it does |
|-------|---------|--------------|
| Scaffold Feature | `/scaffold-feature <name>` | Creates a full feature module with Views/ and ViewModels/ folders and boilerplate |
| Scaffold Provider | `/scaffold-provider <name>` | Creates a new AIProvider conformance with streaming stub |
| Security Scan | `/security-scan` | Scans for hardcoded API keys, passwords, credential leaks, and open-source safety issues |
| Build | `/build` | Runs `xcodebuild` and reports errors |
| Test | `/test` | Runs the test suite |

Skills are defined in `.claude/commands/`.

---

## Build Order (reference)
1. AI Harness (protocols → Claude provider → OpenAI provider)
2. CoreData schema + Domain entities
3. Repository layer (protocols + implementations)
4. UseCases (SendMessage, BuildContextChain, CreateSubThread, BookmarkMessage)
5. Chat UI (input bar, message bubbles, streaming cursor)
6. Conversation list + sub-thread cards inline
7. Sub-thread creation flow
8. Bookmarks tab
9. Settings (API key entry, model picker)
10. Animations, haptics, polish
