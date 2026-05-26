import SwiftUI

struct ConversationRowView: View {
    let conversation: Conversation
    let subThreads: [Conversation]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            mainRow
            if !subThreads.isEmpty {
                subThreadList
            }
        }
        .padding(.vertical, AppSpacing.sm)
        .padding(.horizontal, AppSpacing.md)
        .background(AppColors.backgroundElevated, in: RoundedRectangle(cornerRadius: AppSpacing.cardRadius, style: .continuous))
    }

    // MARK: - Main row

    private var mainRow: some View {
        HStack(spacing: AppSpacing.md) {
            modelBadge

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack(spacing: AppSpacing.xs) {
                    if conversation.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AppColors.accent)
                    }
                    Text(conversation.title)
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)
                }
                metaLine
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                Text(conversation.updatedAt.formatted(.relative(presentation: .named)))
                    .font(AppTypography.caption2)
                    .foregroundStyle(AppColors.textTertiary)

                if conversation.messageCount > 0 {
                    Text("\(conversation.messageCount)")
                        .font(AppTypography.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppColors.accentMuted, in: Capsule())
                }
            }
        }
    }

    private var modelBadge: some View {
        ZStack {
            Circle()
                .fill(AppColors.avatarGradient)
                .frame(width: 44, height: 44)
            Image(systemName: providerIcon(for: conversation.model))
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    private var metaLine: some View {
        HStack(spacing: AppSpacing.xs) {
            Text(conversation.model.displayName)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textTertiary)

            if !subThreads.isEmpty {
                Text("·")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textTertiary)

                HStack(spacing: 2) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 9, weight: .semibold))
                    Text("\(subThreads.count)")
                        .font(AppTypography.caption)
                }
                .foregroundStyle(AppColors.accent)
            }
        }
    }

    // MARK: - Sub-thread list

    private var subThreadList: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            ForEach(subThreads.prefix(3)) { thread in
                NavigationLink(value: thread) {
                    subThreadRow(thread)
                }
                .buttonStyle(.plain)
            }
            if subThreads.count > 3 {
                Text("+\(subThreads.count - 3) more")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textTertiary)
                    .padding(.leading, AppSpacing.xl)
            }
        }
        .padding(.leading, AppSpacing.xl + AppSpacing.md)
    }

    private func subThreadRow(_ thread: Conversation) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppColors.accent)

            Text(thread.title)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(1)

            Spacer(minLength: 0)

            Text("\(thread.messageCount)")
                .font(AppTypography.caption2)
                .foregroundStyle(AppColors.textTertiary)
                .monospacedDigit()
        }
        .padding(.vertical, AppSpacing.xs + 2)
        .padding(.horizontal, AppSpacing.md)
        .background(AppColors.backgroundSecondary, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Helpers

    private func providerIcon(for model: AIModel) -> String {
        switch model.provider {
        case .claude:  "sparkles"
        case .openAI:  "wand.and.stars"
        }
    }
}
