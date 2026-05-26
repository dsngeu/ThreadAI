import SwiftUI
import UIKit

struct CodeBlockView: View {
    let code: String
    let language: String?
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            codeContent
        }
        .background(AppColors.codeBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(AppColors.subtleBorder, lineWidth: 0.5)
        )
    }

    private var header: some View {
        HStack {
            if let lang = language, !lang.isEmpty {
                Text(lang.lowercased())
                    .font(AppTypography.codeSmall)
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.leading, AppSpacing.md)
            }
            Spacer()
            copyButton
        }
        .padding(.horizontal, AppSpacing.xs)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.codeHeaderBackground)
        .clipShape(UnevenRoundedRectangle(
            topLeadingRadius: 12, bottomLeadingRadius: 0,
            bottomTrailingRadius: 0, topTrailingRadius: 12
        ))
    }

    private var copyButton: some View {
        Button {
            UIPasteboard.general.string = code
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { copied = true }
            Task {
                try? await Task.sleep(for: .seconds(2))
                withAnimation { copied = false }
            }
        } label: {
            Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                .font(AppTypography.codeSmall)
                .foregroundStyle(copied ? AppColors.success : AppColors.textSecondary)
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
    }

    private var codeContent: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(code.trimmingCharacters(in: .newlines))
                .font(AppTypography.code)
                .foregroundStyle(AppColors.codeText)
                .textSelection(.enabled)
                .padding(AppSpacing.md)
        }
    }
}
