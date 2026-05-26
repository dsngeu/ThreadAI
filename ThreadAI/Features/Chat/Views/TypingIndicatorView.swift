import SwiftUI

struct TypingIndicatorView: View {
    @State private var animating = false

    var body: some View {
        HStack(alignment: .bottom, spacing: AppSpacing.sm) {
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(AppColors.textTertiary)
                        .frame(width: 7, height: 7)
                        .scaleEffect(animating ? 1.0 : 0.6)
                        .opacity(animating ? 1.0 : 0.4)
                        .animation(
                            .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: animating
                        )
                }
            }
            .padding(.horizontal, AppSpacing.bubblePaddingH)
            .padding(.vertical, AppSpacing.bubblePaddingV + 2)
            .background(AppColors.aiBubble, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: AppColors.shadowLight, radius: 3, y: 1)

            Spacer(minLength: 48)
        }
        .onAppear { animating = true }
    }
}

// MARK: - AI Avatar

struct AIAvatarView: View {
    var size: CGFloat = 30

    var body: some View {
        ZStack {
            Circle()
                .fill(AppColors.avatarGradient)
                .frame(width: size, height: size)
            Image(systemName: "sparkles")
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}
