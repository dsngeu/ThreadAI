Create a new feature module for ThreadAI following the MVVM + Clean Architecture structure.

Arguments: $ARGUMENTS (feature name in PascalCase, e.g. "Chat", "Bookmarks")

Create the following files for the feature named $ARGUMENTS:

1. `ThreadAI/Features/$ARGUMENTS/Views/$ARGUMENTS View.swift`
   - SwiftUI View conforming to View protocol
   - @Environment(AppDependencies.self) for dependency access
   - Uses $ARGUMENTS ViewModel via @State
   - Max 400 lines — extract sub-components as needed

2. `ThreadAI/Features/$ARGUMENTS/ViewModels/$ARGUMENTS ViewModel.swift`
   - @Observable @MainActor final class
   - No SwiftUI imports
   - Exposes state properties and async methods
   - Injects domain use cases via init

3. `ThreadAITests/Features/$ARGUMENTS/$ARGUMENTS ViewModelTests.swift`
   - Uses Swift Testing framework (import Testing)
   - @Suite("$ARGUMENTS ViewModel") struct
   - Uses MockAIProvider and MockKeychainService where needed
   - Tests all public state transitions and error paths

Rules:
- No business logic in Views
- No CoreData access in ViewModels
- All async operations use async/await
- Spring animations: .spring(response: 0.35, dampingFraction: 0.7)
- Haptics via UIImpactFeedbackGenerator where interactions happen
