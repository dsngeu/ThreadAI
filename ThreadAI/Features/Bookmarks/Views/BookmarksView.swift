import SwiftUI

struct BookmarksView: View {
    @Environment(AppDependencies.self) private var dependencies
    @State private var viewModel: BookmarksViewModel?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Bookmarks")
                .navigationDestination(for: Conversation.self) { conversation in
                    ChatView(viewModel: ChatViewModel(conversation: conversation, dependencies: dependencies))
                }
                .alert("Error", isPresented: errorBinding) {
                    Button("OK") { viewModel?.clearError() }
                } message: {
                    Text(viewModel?.errorMessage ?? "")
                }
        }
        .task {
            let vm = BookmarksViewModel(dependencies: dependencies)
            viewModel = vm
            await vm.onAppear()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if let vm = viewModel {
            if vm.isLoading {
                loadingView
            } else if vm.bookmarks.isEmpty {
                emptyStateView
            } else {
                bookmarkList(vm: vm)
            }
        }
    }

    // MARK: - List

    private func bookmarkList(vm: BookmarksViewModel) -> some View {
        List {
            ForEach(vm.bookmarks) { item in
                Group {
                    if let conversation = item.conversation {
                        NavigationLink(value: conversation) {
                            BookmarkRowView(item: item, onRemove: { vm.removeBookmark(item) })
                        }
                    } else {
                        BookmarkRowView(item: item, onRemove: { vm.removeBookmark(item) })
                    }
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        vm.removeBookmark(item)
                    } label: {
                        Label("Remove", systemImage: "bookmark.slash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .refreshable { await vm.loadBookmarks() }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: vm.bookmarks.count)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.xxl) {
            ZStack {
                Circle()
                    .fill(AppColors.accentSubtle)
                    .frame(width: 100, height: 100)
                Circle()
                    .fill(AppColors.accentMuted)
                    .frame(width: 72, height: 72)
                Image(systemName: "bookmark")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(AppColors.accent)
                    .symbolEffect(.pulse, options: .repeating)
            }

            VStack(spacing: AppSpacing.sm) {
                Text("No Bookmarks Yet")
                    .font(AppTypography.title3)
                    .foregroundStyle(AppColors.textPrimary)

                Text("Long-press any message in a chat and tap Bookmark to save it here.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xxxl)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView()
                .tint(AppColors.accent)
            Text("Loading…")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Bindings

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel?.errorMessage != nil },
            set: { if !$0 { viewModel?.clearError() } }
        )
    }
}
