import SwiftUI

struct CreateSubThreadSheet: View {
    let parentModel: AIModel
    let onCreate: (String, AIModel, String?) async -> Void

    @State private var title = ""
    @State private var systemPrompt = ""
    @State private var showSystemPrompt = false
    @State private var isCreating = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Thread Title") {
                    TextField("What's this thread about?", text: $title)
                        .submitLabel(.done)
                }

                Section {
                    Toggle("Custom System Prompt", isOn: $showSystemPrompt.animation())
                    if showSystemPrompt {
                        TextEditor(text: $systemPrompt)
                            .font(AppTypography.body)
                            .frame(minHeight: 80)
                    }
                } header: {
                    Text("System Prompt")
                } footer: {
                    Text("Optional. Overrides the parent conversation's system prompt for this thread.")
                        .font(AppTypography.caption)
                }
            }
            .navigationTitle("New Thread")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { createThread() }
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

    private func createThread() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        let prompt = showSystemPrompt ? systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines) : nil
        isCreating = true
        Task {
            await onCreate(trimmedTitle, parentModel, prompt.flatMap { $0.isEmpty ? nil : $0 })
            dismiss()
        }
    }
}
