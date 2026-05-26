import SwiftUI

struct BookmarkRowView: View {
    let item: BookmarkedItem
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppColors.accent)

                Text(item.conversationTitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Text(item.message.timestamp.formatted(.relative(presentation: .named)))
                    .font(AppTypography.caption2)
                    .foregroundStyle(AppColors.textTertiary)
            }

            Text(item.message.bookmarkTitle ?? item.message.content.prefix(80).description)
                .font(AppTypography.headline)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(2)

            Text(item.message.content)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            HStack(spacing: AppSpacing.xs) {
                Image(systemName: item.message.isUser ? "person.fill" : "sparkles")
                    .font(.system(size: 9, weight: .semibold))
                Text(item.message.isUser ? "You" : "AI")
                    .font(AppTypography.caption2)
            }
            .foregroundStyle(AppColors.textTertiary)
        }
        .padding(.vertical, AppSpacing.sm)
        .padding(.horizontal, AppSpacing.md)
        .background(AppColors.backgroundElevated, in: RoundedRectangle(cornerRadius: AppSpacing.cardRadius, style: .continuous))
        .contentShape(Rectangle())
    }
}
