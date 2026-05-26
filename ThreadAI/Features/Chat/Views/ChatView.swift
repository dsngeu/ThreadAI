import SwiftUI

struct ChatView: View {
    @State var viewModel: ChatViewModel

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                messageList
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.huge)
            }
            .defaultScrollAnchor(.bottom)
            .scrollDismissesKeyboard(.interactively)
            .scrollIndicators(.hidden)
            .background(AppColors.background)
            .onChange(of: viewModel.messages.count) {
                scrollToBottom(proxy: proxy)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                ChatInputBar(
                    text: $viewModel.inputText,
                    isStreaming: viewModel.isStreaming,
                    onSend: viewModel.send,
                    onStop: viewModel.stopStreaming
                )
            }
        }
        .navigationTitle(viewModel.conversation.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Conversation.self) { conversation in
            ChatView(viewModel: ChatViewModel(
                conversation: conversation,
                dependencies: viewModel.dependencies
            ))
        }
        .navigationDestination(item: $viewModel.navigateToThread) { thread in
            ChatView(viewModel: ChatViewModel(
                conversation: thread,
                dependencies: viewModel.dependencies
            ))
        }
        .toolbar {
            modelPickerToolbar
            threadsToolbar
        }
        .task { await viewModel.onAppear() }
        .sheet(isPresented: $viewModel.showCreateSubThread) {
            CreateSubThreadSheet(
                parentModel: viewModel.conversation.model,
                onCreate: { title, model, systemPrompt in
                    await viewModel.createSubThread(title: title, model: model, systemPrompt: systemPrompt)
                }
            )
        }
        .sheet(isPresented: $viewModel.showThreadsList) {
            ThreadsListSheet(
                threads: viewModel.threadsList,
                onSelect: { thread in
                    viewModel.showThreadsList = false
                    viewModel.navigateToThread = thread
                }
            )
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.clearError() } }
        )) {
            Button("OK") { viewModel.clearError() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Model Picker

    @ToolbarContentBuilder
    private var modelPickerToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                ForEach(AIModel.openAIModels) { model in
                    Button {
                        viewModel.changeModel(to: model)
                    } label: {
                        Label(
                            model.displayName,
                            systemImage: viewModel.conversation.model == model ? "checkmark" : ""
                        )
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: modelIcon(for: viewModel.conversation.model))
                        .font(.system(size: 10, weight: .semibold))
                    Text(viewModel.conversation.model.displayName)
                        .font(AppTypography.caption)
                        .fontWeight(.semibold)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                }
                .foregroundStyle(AppColors.accent)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs + 2)
                .background(AppColors.accentMuted, in: Capsule())
            }
            .disabled(viewModel.isStreaming)
        }
    }

    // MARK: - Threads Toolbar

    @ToolbarContentBuilder
    private var threadsToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if !viewModel.threadsList.isEmpty {
                Button {
                    viewModel.showThreadsList = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.branch")
                            .font(.system(size: 11, weight: .semibold))
                        Text("\(viewModel.threadsList.count)")
                            .font(AppTypography.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(AppColors.accent)
                    .padding(.horizontal, AppSpacing.sm + 2)
                    .padding(.vertical, AppSpacing.xs + 2)
                    .background(AppColors.accentMuted, in: Capsule())
                }
            }
        }
    }

    // MARK: - Message List

    private var messageList: some View {
        LazyVStack(spacing: AppSpacing.bubbleSpacing) {
            ForEach(viewModel.messages) { message in
                MessageBubbleView(
                    message: message,
                    subThread: message.spawnedThreadID.flatMap { viewModel.subThreadConversations[$0] },
                    onBookmark: { viewModel.toggleBookmark(messageID: message.id) },
                    onCreateThread: { viewModel.startCreateSubThread(fromMessage: message.id) }
                )
                .id(message.id)
                .transition(.asymmetric(
                    insertion: .push(from: .bottom).combined(with: .opacity),
                    removal: .opacity
                ))
            }

            StreamingSection(viewModel: viewModel)

            Color.clear
                .frame(height: 1)
                .id("streamAnchor")
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.messages.count)
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            proxy.scrollTo("streamAnchor", anchor: .bottom)
        }
    }

    private func modelIcon(for model: AIModel) -> String {
        switch model.provider {
        case .claude: "sparkles"
        case .openAI: "wand.and.stars"
        }
    }
}

// MARK: - Streaming Section (isolated observation)

private struct StreamingSection: View {
    let viewModel: ChatViewModel

    var body: some View {
        if viewModel.isStreaming {
            if viewModel.streamingContent.isEmpty {
                TypingIndicatorView().id("typing").transition(.opacity)
            } else {
                StreamingBubbleView(content: viewModel.streamingContent).id("streaming")
            }
        }
    }
}
