<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS%2017%2B-blue?style=for-the-badge&logo=apple" />
  <img src="https://img.shields.io/badge/Swift-5.9%2B-orange?style=for-the-badge&logo=swift" />
  <img src="https://img.shields.io/badge/UI-SwiftUI-teal?style=for-the-badge" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" />
</p>

<h1 align="center">ThreadAI</h1>

<p align="center">
  <b>A production-quality iOS AI chat app with branching sub-thread conversations.</b><br/>
  Powered by OpenAI — use your own API key.
</p>

---

## What Makes ThreadAI Different

Most AI chat apps are linear. ThreadAI is not.

You can **fork any message into a sub-thread**, where the parent conversation is carried forward as context. Sub-threads can be nested arbitrarily deep. This lets you explore multiple directions from a single message without losing any history.

---

## Features

### Thread-Based Conversations
- Start a top-level conversation with any supported model
- **Fork any message into a sub-thread** — parent context is automatically included
- Sub-threads are displayed as inline cards inside the parent chat
- Unlimited nesting depth with full context chain built recursively
- Browse all sub-threads of a conversation from the thread list sheet

### AI Model Support
| Provider | Models | Context Window |
|----------|--------|----------------|
| OpenAI | GPT-4o, GPT-4o mini | 128k tokens |

- Switch model mid-conversation from the chat toolbar
- Streaming responses with a live blinking cursor
- Stop generation at any time with the stop button
- API key validated before saving (live test request)

### Real-Time Streaming
- Responses stream token-by-token with smooth buffered rendering
- Typing indicator while waiting for the first token
- Animated blinking cursor during generation
- Cancel streaming at any time — partial response is preserved

### Markdown Rendering
- Full markdown support: headers, bold, italic, bullet lists, ordered lists, blockquotes
- Syntax-highlighted **code blocks** with language label and one-tap copy
- Inline code formatting
- Text selection enabled on all message content

### Bookmarks
- Bookmark any message with a long-press context menu
- Bookmarks are given an auto-generated short title
- Dedicated Bookmarks tab shows all saved messages across conversations
- Tap a bookmark to navigate directly back to its conversation

### Conversation Management
- Pin conversations to keep them at the top of the list
- Search conversations by title
- Swipe to delete individual conversations or sub-threads
- Create conversations with an optional custom system prompt
- Sub-threads displayed inline under their parent in the conversation list

### Settings & Security
- Enter and validate your OpenAI API key
- Key stored in the iOS **Keychain** — never in UserDefaults or logs
- API key status: Not Set / Validating / Valid / Invalid
- Validation makes a real 1-token test request before saving

---

## Architecture

ThreadAI follows **MVVM + Clean Architecture** with strict layer separation.

```
Presentation  →  Domain  ←  Data
(Views / VMs)    (Entities, UseCases, Protocols)   (CoreData, URLSession, Keychain)
```

| Layer | Responsibility |
|-------|---------------|
| **Presentation** | SwiftUI Views + `@Observable` ViewModels. No business logic. |
| **Domain** | Pure Swift. Entities, UseCases, Repository protocols. Zero framework imports. |
| **Data** | Implements Domain protocols. Owns CoreData, URLSession, Keychain. |
| **AI Harness** | Provider abstraction (`AIProvider` protocol) used by UseCases via injection. |

### Key Use Cases
- `SendMessageUseCase` — sends a message and handles the streaming response
- `BuildContextChainUseCase` — recursively walks thread ancestry to assemble the full context
- `CreateSubThreadUseCase` — forks a sub-thread from a message, carrying parent context
- `BookmarkMessageUseCase` — bookmarks a message with a generated title

### Adding a New AI Provider
1. Create `Core/AIHarness/Providers/YourProvider.swift`
2. Conform to `AIProvider`
3. Register in `AppDependencies.swift`

Nothing else changes.

---

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Language | Swift 5.9+ |
| UI | SwiftUI (no UIKit) |
| iOS Target | iOS 17+ |
| State | `@Observable` macro |
| Persistence | CoreData |
| Concurrency | Async/Await + AsyncThrowingStream |
| Security | Keychain Services |
| Networking | URLSession with SSE streaming |

---

## Getting Started

### Requirements
- Xcode 15+
- iOS 17+ device or simulator
- An [OpenAI API key](https://platform.openai.com)

### Installation
```bash
git clone git@github.com:dsngeu/ThreadAI.git
cd ThreadAI
open ThreadAI.xcodeproj
```

Build and run on your device or simulator. No package manager setup needed — there are no third-party dependencies.

### Adding Your API Key
1. Open the app and go to the **Settings** tab
2. Tap **OpenAI API Key**
3. Paste your key and tap **Validate & Save**
4. A live test confirms the key works before it is stored

Keys are stored in the iOS Keychain and are never logged or transmitted anywhere other than OpenAI's API.

---

## Project Structure

```
ThreadAI/
├── App/                        # Entry point and dependency wiring
├── Core/
│   ├── AIHarness/              # AIProvider protocol + OpenAI implementation
│   ├── Domain/                 # Entities, UseCases, Repository protocols
│   └── Data/                   # CoreData stack, repository implementations, Keychain
├── Features/
│   ├── ConversationList/       # Conversation list with search, pin, sub-thread preview
│   ├── Chat/                   # Streaming chat, markdown, code blocks, thread forking
│   ├── Bookmarks/              # Saved messages browser
│   └── Settings/               # API key management
└── Shared/
    └── UI/
        ├── Components/         # MarkdownContentView, CodeBlockView
        └── Theme/              # AppColors, AppTypography, AppSpacing
```

---

## Design Principles

- **No force unwraps** in production code
- **No `print()` statements** — OSLog only
- **No silent error swallowing** — all async functions surface errors
- **No hardcoded strings** — `LocalizedStringKey` throughout
- **View files capped at 400 lines** — components are extracted when views grow
- **ViewModels never import SwiftUI** — they expose only primitives and domain types

---

## License

MIT — see [LICENSE](LICENSE).

---

<p align="center">Built with Swift + SwiftUI · No third-party dependencies · Your keys, your data</p>
