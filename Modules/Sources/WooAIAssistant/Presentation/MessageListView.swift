import SwiftUI

struct MessageListView: View {

    let messages: [ChatMessage]
    let streamingState: AssistantConversation.StreamingState
    var onPickPrompt: (String) -> Void = { _ in }
    var onSendSuggestion: (String) -> Void = { _ in }

    @StateObject private var scrollController = ChatScrollController()
    @State private var lastTickTime: Date = .distantPast

    var body: some View {
        if messages.isEmpty {
            EmptyStateView(onPick: onSendSuggestion)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        } else {
            ZStack(alignment: .bottomTrailing) {
                ChatScrollView(controller: scrollController) {
                    LazyVStack(alignment: .leading, spacing: AssistantSpacing.large) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
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
        Self.shouldShowLoadingIndicator(messages: messages, streamingState: streamingState)
    }

    /// Dots represent active work between turns. They must be hidden whenever
    /// the agentic loop is paused on a pending confirmation, regardless of the
    /// underlying `StreamingState`, because the assistant is waiting on the
    /// merchant rather than generating a response.
    static func shouldShowLoadingIndicator(messages: [ChatMessage],
                                           streamingState: AssistantConversation.StreamingState) -> Bool {
        guard !messages.hasPendingConfirmation else { return false }
        switch streamingState {
        case .sending:
            return true
        case .idle, .streaming, .failed, .outcomeUnknown:
            return false
        }
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
