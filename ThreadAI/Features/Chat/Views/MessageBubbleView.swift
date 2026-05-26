import SwiftUI

struct MessageBubbleView: View {
    let message: Message
    let subThread: Conversation?
    let onBookmark: () -> Void
    let onCreateThread: () -> Void

    @State private var showTimestamp = false

    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: AppSpacing.xs) {
            HStack(alignment: .bottom, spacing: AppSpacing.sm) {
                if message.isUser {
                    Spacer(minLength: 48)
                    userBubble
                } else {
                    aiBubble
                    Spacer(minLength: 48)
                }
            }

            if let thread = subThread {
                HStack {
                    if message.isUser { Spacer(minLength: 48) }
                    NavigationLink(value: thread) {
                        ThreadCardView(thread: thread)
                    }
                    .buttonStyle(.plain)
                    if !message.isUser { Spacer(minLength: 48) }
                }
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { showTimestamp.toggle() }
        }
        .contextMenu { contextMenuItems }
    }

    // MARK: - Bubbles

    private var userBubble: some View {
        VStack(alignment: .trailing, spacing: AppSpacing.xxs) {
            Text(message.content)
                .font(AppTypography.messageBubble)
                .foregroundStyle(.white)
                .padding(.horizontal, AppSpacing.bubblePaddingH)
                .padding(.vertical, AppSpacing.bubblePaddingV)
                .background(AppColors.userBubbleGradient, in: UserBubbleShape())
                .shadow(color: AppColors.shadowLight, radius: 4, y: 2)

            timestampRow
        }
    }

    private var aiBubble: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            MarkdownContentView(content: message.content)
                .padding(.horizontal, AppSpacing.bubblePaddingH)
                .padding(.vertical, AppSpacing.bubblePaddingV)
                .background(AppColors.aiBubble, in: AIBubbleShape())
                .shadow(color: AppColors.shadowLight, radius: 3, y: 1)
            timestampRow
        }
    }

    @ViewBuilder
    private var timestampRow: some View {
        if showTimestamp || message.isBookmarked {
            HStack(spacing: AppSpacing.xs) {
                if showTimestamp {
                    Text(message.timestamp.formatted(.relative(presentation: .named)))
                        .font(AppTypography.messageTimestamp)
                        .foregroundStyle(AppColors.textTertiary)
                }
                if message.isBookmarked {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(AppColors.accent)
                }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.85, anchor: message.isUser ? .trailing : .leading)))
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private var contextMenuItems: some View {
        Button {
            UIPasteboard.general.string = message.content
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Label("Copy", systemImage: "doc.on.doc")
        }

        Button { onBookmark() } label: {
            Label(
                message.isBookmarked ? "Remove Bookmark" : "Bookmark",
                systemImage: message.isBookmarked ? "bookmark.slash" : "bookmark"
            )
        }

        Divider()

        Button { onCreateThread() } label: {
            Label("Create Thread", systemImage: "arrow.triangle.branch")
        }
    }
}

// MARK: - Bubble Shapes

private struct UserBubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.addRoundedRect(in: rect, cornerRadii: .init(
                topLeading: 20, bottomLeading: 20, bottomTrailing: 6, topTrailing: 20
            ))
        }
    }
}

private struct AIBubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.addRoundedRect(in: rect, cornerRadii: .init(
                topLeading: 6, bottomLeading: 20, bottomTrailing: 20, topTrailing: 20
            ))
        }
    }
}
