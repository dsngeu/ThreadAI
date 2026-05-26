import SwiftUI

struct ThreadsListSheet: View {
    let threads: [Conversation]
    let onSelect: (Conversation) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(threads) { thread in
                    Button { onSelect(thread) } label: {
                        threadRow(thread)
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Threads")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func threadRow(_ thread: Conversation) -> some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AppColors.accentMuted)
                    .frame(width: 40, height: 40)
                Image(systemName: "arrow.triangle.branch")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppColors.accent)
            }

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(thread.title)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: AppSpacing.xs) {
                    Text("\(thread.messageCount) message\(thread.messageCount == 1 ? "" : "s")")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textTertiary)

                    Text("·")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textTertiary)

                    Text(thread.createdAt.formatted(.relative(presentation: .named)))
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColors.textTertiary)
        }
        .padding(.vertical, AppSpacing.sm)
        .padding(.horizontal, AppSpacing.md)
        .background(AppColors.backgroundElevated, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
