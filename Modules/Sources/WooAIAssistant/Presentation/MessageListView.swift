import SwiftUI

struct MessageListView: View {

    let messages: [ChatMessage]
    let streamingState: AssistantConversation.StreamingState
    var showToolActivity: Bool = true
    var showIterationCapBanner: Bool = false
    var onPickPrompt: (String) -> Void = { _ in }

    @StateObject private var scrollController = ChatScrollController()
    @State private var lastTickTime: Date = .distantPast

    var body: some View {
        if messages.isEmpty {
            EmptyStateView(onPick: onPickPrompt)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else {
            ZStack(alignment: .bottomTrailing) {
                ChatScrollView(controller: scrollController) {
                    LazyVStack(alignment: .leading, spacing: AssistantSpacing.large) {
                        ForEach(messages) { message in
                            MessageBubble(message: message, showToolActivity: showToolActivity)
                                .id(message.id)
                        }
                        if isAssistantTyping {
                            TypingIndicator()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        if case .failed(let reason) = streamingState {
                            ErrorBanner(reason: reason)
                        }
                        if case .outcomeUnknown(let reason) = streamingState {
                            OutcomeUnknownBanner(reason: reason)
                        }
                        if showIterationCapBanner {
                            IterationCapBanner()
                        }
                    }
                    .padding(.horizontal, AssistantSpacing.large)
                    .padding(.top, AssistantSpacing.large)
                    .padding(.bottom, AssistantSpacing.medium)
                }
                if !scrollController.isNearBottom {
                    JumpToLatestChip {
                        scrollController.scrollToBottom(animated: true)
                    }
                    .padding(.trailing, AssistantSpacing.large)
                    .padding(.bottom, AssistantSpacing.large)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.2), value: scrollController.isNearBottom)
            .onChange(of: lastSegmentSignature) { _, _ in
                let now = Date()
                if now.timeIntervalSince(lastTickTime) < 0.03 { return }
                lastTickTime = now
                guard scrollController.isNearBottom else { return }
                scrollController.scrollToBottom(animated: false)
            }
            .onChange(of: messages.count) { oldCount, newCount in
                guard newCount > oldCount else { return }
                let userJustSent = messages.suffix(newCount - oldCount).contains { $0.role == .user }
                if userJustSent || scrollController.isNearBottom {
                    scrollController.scrollToBottom(animated: false)
                }
            }
            .onAppear {
                scrollController.scrollToBottom(animated: false)
            }
        }
    }

    private var isAssistantTyping: Bool {
        streamingState == .sending
    }

    private var lastSegmentSignature: String {
        guard let last = messages.last else { return "" }
        return last.segments.map(\.fingerprint).joined(separator: "|")
    }
}

#if DEBUG
#Preview("Empty") {
    AssistantChatView.preview(.empty)
}

#Preview("Multi-turn") {
    AssistantChatView.preview(.multiTurn)
}

#Preview("Failed mid-stream") {
    AssistantChatView.preview(.failedMidStream)
}
#endif
