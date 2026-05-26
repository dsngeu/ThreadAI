import SwiftUI

struct StreamingBubbleView: View {
    let content: String
    @State private var cursorVisible = true

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: 0) {
                Text(content)
                    .font(AppTypography.messageBubble)
                    .foregroundStyle(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }
            .padding(.horizontal, AppSpacing.bubblePaddingH)
            .padding(.vertical, AppSpacing.bubblePaddingV)
            .background(AppColors.aiBubble, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(alignment: .bottomTrailing) {
                cursor
                    .padding(.trailing, AppSpacing.sm)
                    .padding(.bottom, AppSpacing.sm)
            }

            Spacer(minLength: 48)
        }
        .onAppear { startCursorBlink() }
    }

    private var cursor: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(AppColors.accent)
            .frame(width: 2.5, height: 18)
            .opacity(cursorVisible ? 1 : 0)
    }

    private func startCursorBlink() {
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            cursorVisible = false
        }
    }
}
