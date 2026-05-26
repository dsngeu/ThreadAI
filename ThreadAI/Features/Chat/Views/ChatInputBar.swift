import SwiftUI

struct ChatInputBar: View {
    @Binding var text: String
    let isStreaming: Bool
    let onSend: () -> Void
    let onStop: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: AppSpacing.md) {
            textField
            actionButton
        }
        .padding(.horizontal, AppSpacing.inputBarPadding)
        .padding(.vertical, AppSpacing.md)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(AppColors.subtleBorder)
                        .frame(height: 0.5)
                }
                .ignoresSafeArea(.container, edges: .bottom)
        }
    }

    // MARK: - Subviews

    private var textField: some View {
        TextField("Message", text: $text, axis: .vertical)
            .font(AppTypography.body)
            .lineLimit(1...6)
            .focused($isFocused)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AppColors.backgroundSecondary)
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        isFocused ? AppColors.accent.opacity(0.4) : AppColors.subtleBorder,
                        lineWidth: isFocused ? 1.5 : 0.5
                    )
            }
            .animation(.easeOut(duration: 0.2), value: isFocused)
            .onSubmit {
                if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    onSend()
                }
            }
    }

    private var actionButton: some View {
        Button {
            if isStreaming {
                onStop()
            } else {
                isFocused = false
                onSend()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(buttonFill)
                    .frame(width: 40, height: 40)
                    .shadow(color: canSend ? AppColors.accent.opacity(0.3) : .clear, radius: 6, y: 2)

                Image(systemName: isStreaming ? "stop.fill" : "arrow.up")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .buttonStyle(SpringButtonStyle())
        .disabled(!isStreaming && !canSend)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isStreaming)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: canSend)
    }

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var buttonFill: AnyShapeStyle {
        if isStreaming {
            AnyShapeStyle(Color.red)
        } else if canSend {
            AnyShapeStyle(AppColors.userBubbleGradient)
        } else {
            AnyShapeStyle(AppColors.accent.opacity(0.3))
        }
    }
}

// MARK: - Spring Button Style

struct SpringButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
