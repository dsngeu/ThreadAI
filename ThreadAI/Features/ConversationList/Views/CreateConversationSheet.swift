import SwiftUI

struct CreateConversationSheet: View {
    let onCreate: (String, AIModel, String?) async -> Void

    @State private var title = ""
    @State private var selectedModel: AIModel = .gpt4o
    @State private var systemPrompt = ""
    @State private var showSystemPrompt = false
    @State private var isCreating = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Conversation Title") {
                    TextField("What do you want to talk about?", text: $title)
                        .submitLabel(.done)
                }

                Section("Model") {
                    Picker("Model", selection: $selectedModel) {
                        ForEach(AIModel.openAIModels) { model in
                            Text(model.displayName).tag(model)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(AppColors.accent)
                }

                Section {
                    Toggle("Custom System Prompt", isOn: $showSystemPrompt.animation())
                    if showSystemPrompt {
                        TextEditor(text: $systemPrompt)
                            .font(AppTypography.body)
                            .frame(minHeight: 100)
                    }
                } header: {
                    Text("System Prompt")
                } footer: {
                    Text("Optional. Sets the AI's role and behaviour for this conversation.")
                        .font(AppTypography.caption)
                }
            }
            .navigationTitle("New Conversation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { createConversation() }
                        .fontWeight(.semibold)
                        .tint(AppColors.accent)
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCreating)
                }
            }
            .disabled(isCreating)
            .overlay {
                if isCreating {
                    Color.black.opacity(0.1)
                        .ignoresSafeArea()
                        .overlay(ProgressView().tint(AppColors.accent))
                }
            }
        }
    }

    private func createConversation() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        let prompt = showSystemPrompt ? systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines) : nil
        isCreating = true
        Task {
            await onCreate(trimmedTitle, selectedModel, prompt.flatMap { $0.isEmpty ? nil : $0 })
            dismiss()
        }
    }
}
