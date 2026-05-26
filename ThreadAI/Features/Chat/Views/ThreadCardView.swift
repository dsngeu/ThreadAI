import SwiftUI

struct ThreadCardView: View {
    let thread: Conversation

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(AppColors.accentMuted)
                    .frame(width: 32, height: 32)
                Image(systemName: "arrow.triangle.branch")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.accent)
            }

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(thread.title)
                    .font(AppTypography.threadCardTitle)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)

                Text("\(thread.messageCount) message\(thread.messageCount == 1 ? "" : "s") · \(thread.model.displayName)")
                    .font(AppTypography.threadCardMeta)
                    .foregroundStyle(AppColors.textTertiary)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppColors.textTertiary)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.md)
        .background(AppColors.backgroundElevated, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(AppColors.subtleBorder, lineWidth: 0.5)
        )
        .shadow(color: AppColors.shadowLight, radius: 3, y: 1)
    }
}
