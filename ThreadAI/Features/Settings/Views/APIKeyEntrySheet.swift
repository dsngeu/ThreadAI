import SwiftUI

struct APIKeyEntrySheet: View {
    let provider: AIProviderType
    let currentStatus: SettingsViewModel.KeyStatus
    let onSave: (String) async -> Void
    let onDelete: () -> Void

    @State private var keyText = ""
    @State private var showKey = false
    @State private var isSaving = false
    @Environment(\.dismiss) private var dismiss

    private var placeholderText: String {
        switch provider {
        case .claude:  "sk-ant-..."
        case .openAI:  "sk-..."
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Group {
                            if showKey {
                                TextField(placeholderText, text: $keyText)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            } else {
                                SecureField(placeholderText, text: $keyText)
                            }
                        }
                        .font(AppTypography.code)

                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { showKey.toggle() }
                        } label: {
                            Image(systemName: showKey ? "eye.slash" : "eye")
                                .foregroundStyle(AppColors.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("API Key")
                } footer: {
                    Text("Your key is stored securely in the iOS Keychain and never leaves your device.")
                        .font(AppTypography.caption)
                }

                if currentStatus.isSet {
                    Section {
                        Button(role: .destructive) {
                            onDelete()
                            dismiss()
                        } label: {
                            Label("Remove API Key", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(provider.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .tint(AppColors.accent)
                        .disabled(keyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
            .overlay {
                if isSaving {
                    Color.black.opacity(0.15)
                        .ignoresSafeArea()
                        .overlay(
                            VStack(spacing: AppSpacing.sm) {
                                ProgressView()
                                    .tint(AppColors.accent)
                                Text("Validating…")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                            .padding(AppSpacing.xl)
                            .background(AppColors.backgroundSecondary, in: RoundedRectangle(cornerRadius: 16))
                            .shadow(color: AppColors.shadowMedium, radius: 20, y: 8)
                        )
                }
            }
            .disabled(isSaving)
        }
    }

    private func save() {
        let trimmed = keyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSaving = true
        Task {
            await onSave(trimmed)
            dismiss()
        }
    }
}
