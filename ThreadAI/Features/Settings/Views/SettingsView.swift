import SwiftUI

struct SettingsView: View {
    @Environment(AppDependencies.self) private var dependencies
    @State private var viewModel: SettingsViewModel?
    @State private var editingProvider: AIProviderType?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    settingsForm(vm: vm)
                        .sheet(item: $editingProvider) { provider in
                            APIKeyEntrySheet(
                                provider: provider,
                                currentStatus: vm.status(for: provider),
                                onSave: { key in await vm.saveAndValidate(key, for: provider) },
                                onDelete: { vm.deleteKey(for: provider) }
                            )
                            .onDisappear { vm.refreshStatuses() }
                        }
                } else {
                    ProgressView()
                        .tint(AppColors.accent)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Settings")
        }
        .task {
            guard viewModel == nil else { return }
            viewModel = SettingsViewModel(
                keychainService: dependencies.keychainService,
                aiHarnessService: dependencies.aiHarnessService
            )
        }
    }

    // MARK: - Form

    private func settingsForm(vm: SettingsViewModel) -> some View {
        List {
            apiKeysSection(vm: vm)
            aboutSection
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - API Keys Section

    private func apiKeysSection(vm: SettingsViewModel) -> some View {
        Section {
            apiKeyRow(provider: .openAI, vm: vm)
        } header: {
            SectionLabel(title: "API Keys", icon: "key.fill")
        } footer: {
            Text("Keys are stored in the iOS Keychain and never leave your device.")
                .font(AppTypography.caption)
        }
    }

    private func apiKeyRow(provider: AIProviderType, vm: SettingsViewModel) -> some View {
        let status = vm.status(for: provider)
        return Button {
            editingProvider = provider
        } label: {
            HStack(spacing: AppSpacing.md) {
                providerIcon(for: provider)

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(provider.displayName)
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColors.textPrimary)

                    HStack(spacing: AppSpacing.xs) {
                        if status.isValidating {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Circle()
                                .fill(statusColor(status))
                                .frame(width: 7, height: 7)
                        }
                        Text(status.displayLabel)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: status.isSet ? "pencil" : "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.accent)
            }
            .padding(.vertical, AppSpacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func providerIcon(for provider: AIProviderType) -> some View {
        ZStack {
            Circle()
                .fill(AppColors.avatarGradient)
                .frame(width: 38, height: 38)
            Image(systemName: provider == .claude ? "sparkles" : "wand.and.stars")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    private func statusColor(_ status: SettingsViewModel.KeyStatus) -> Color {
        switch status.color {
        case .secondary: AppColors.textTertiary
        case .accent:    AppColors.accent
        case .success:   AppColors.success
        case .error:     AppColors.error
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section {
            LabeledContent("Version", value: appVersion)
            LabeledContent("Build", value: buildNumber)
        } header: {
            SectionLabel(title: "About", icon: "info.circle.fill")
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }
}

// MARK: - Section Label

private struct SectionLabel: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(title)
                .font(AppTypography.sectionHeader)
        }
        .foregroundStyle(AppColors.textTertiary)
    }
}
