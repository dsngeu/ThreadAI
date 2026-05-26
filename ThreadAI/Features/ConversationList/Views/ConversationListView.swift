import SwiftUI

struct ConversationListView: View {
    @Environment(AppDependencies.self) private var dependencies
    @State private var viewModel: ConversationListViewModel?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("ThreadAI")
                .navigationDestination(for: Conversation.self) { conversation in
                    ChatView(viewModel: ChatViewModel(conversation: conversation, dependencies: dependencies))
                }
                .toolbar { toolbarContent }
                .searchable(
                    text: searchBinding,
                    placement: .navigationBarDrawer(displayMode: .automatic),
                    prompt: "Search conversations"
                )
                .alert("New Conversation", isPresented: showCreateConversation) {
                    TextField("Topic name", text: newTopicBinding)
                    Button("Cancel", role: .cancel) { viewModel?.newTopicName = "" }
                    Button("Create") { createFromTopic() }
                } message: {
                    Text("What do you want to talk about?")
                }
                .alert("Error", isPresented: errorBinding) {
                    Button("OK") { viewModel?.clearError() }
                } message: {
                    Text(viewModel?.errorMessage ?? "")
                }
        }
        .task {
            let vm = ConversationListViewModel(dependencies: dependencies)
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
            } else if vm.conversations.isEmpty {
                emptyStateView(vm: vm)
            } else {
                conversationList(vm: vm)
            }
        }
    }

    // MARK: - List

    private func conversationList(vm: ConversationListViewModel) -> some View {
        let items = vm.filteredConversations
        return List {
            let pinned = items.filter(\.isPinned)
            if !pinned.isEmpty {
                Section {
                    ForEach(pinned) { conversation in
                        conversationRow(conversation, vm: vm)
                    }
                } header: {
                    SectionHeaderView(title: "Pinned", icon: "pin.fill")
                }
            }

            let unpinned = items.filter { !$0.isPinned }
            if !unpinned.isEmpty {
                Section {
                    ForEach(unpinned) { conversation in
                        conversationRow(conversation, vm: vm)
                    }
                    .onDelete { vm.delete(at: $0) }
                } header: {
                    SectionHeaderView(
                        title: pinned.isEmpty ? "Conversations" : "Recent",
                        icon: pinned.isEmpty ? "bubble.left.and.bubble.right" : "clock"
                    )
                }
            }
        }
        .listStyle(.plain)
        .refreshable { await vm.loadConversations() }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: items.count)
    }

    private func conversationRow(_ conversation: Conversation, vm: ConversationListViewModel) -> some View {
        NavigationLink(value: conversation) {
            ConversationRowView(
                conversation: conversation,
                subThreads: vm.subThreads[conversation.id] ?? []
            )
        }
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        .listRowSeparator(.hidden)
        .swipeActions(edge: .leading) {
            Button {
                vm.togglePin(conversation: conversation)
            } label: {
                Label(
                    conversation.isPinned ? "Unpin" : "Pin",
                    systemImage: conversation.isPinned ? "pin.slash" : "pin"
                )
            }
            .tint(AppColors.accent)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                vm.delete(conversation: conversation)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Empty State

    private func emptyStateView(vm: ConversationListViewModel) -> some View {
        VStack(spacing: AppSpacing.xxl) {
            ZStack {
                Circle()
                    .fill(AppColors.accentSubtle)
                    .frame(width: 100, height: 100)
                Circle()
                    .fill(AppColors.accentMuted)
                    .frame(width: 72, height: 72)
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(AppColors.accent)
                    .symbolEffect(.pulse, options: .repeating)
            }

            VStack(spacing: AppSpacing.sm) {
                Text("No Conversations Yet")
                    .font(AppTypography.title3)
                    .foregroundStyle(AppColors.textPrimary)

                Text("Start a conversation and organize your chats into focused threads.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xxxl)
            }

            Button {
                vm.showCreateConversation = true
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                Label("New Conversation", systemImage: "plus")
                    .font(AppTypography.headline)
                    .padding(.horizontal, AppSpacing.xxl)
                    .padding(.vertical, AppSpacing.md + 2)
                    .foregroundStyle(.white)
                    .background(AppColors.userBubbleGradient, in: Capsule())
            }
            .buttonStyle(SpringButtonStyle())
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

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                viewModel?.showCreateConversation = true
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                Image(systemName: "square.and.pencil")
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.accent)
            }
        }
    }

    // MARK: - Bindings

    private var searchBinding: Binding<String> {
        Binding(
            get: { viewModel?.searchText ?? "" },
            set: { viewModel?.searchText = $0 }
        )
    }

    private var showCreateConversation: Binding<Bool> {
        Binding(
            get: { viewModel?.showCreateConversation ?? false },
            set: { viewModel?.showCreateConversation = $0 }
        )
    }

    private var newTopicBinding: Binding<String> {
        Binding(
            get: { viewModel?.newTopicName ?? "" },
            set: { viewModel?.newTopicName = $0 }
        )
    }

    private func createFromTopic() {
        guard let vm = viewModel else { return }
        let name = vm.newTopicName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        vm.newTopicName = ""
        Task { await vm.createConversation(title: name, model: .gpt4o, systemPrompt: nil) }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel?.errorMessage != nil },
            set: { if !$0 { viewModel?.clearError() } }
        )
    }
}

// MARK: - Section Header

private struct SectionHeaderView: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(title.uppercased())
                .font(AppTypography.sectionHeader)
        }
        .foregroundStyle(AppColors.textTertiary)
    }
}
