import SwiftUI

struct MessageListView: View {

    let messages: [ChatMessage]
    let streamingState: AssistantConversation.StreamingState
    var onPickPrompt: (String) -> Void = { _ in }
    var onSendSuggestion: (String) -> Void = { _ in }

    @Environment(\.assistantConfirmationHandler) private var confirmationHandler
    @Environment(\.assistantExternalNavigation) private var externalNavigation
    @Environment(\.assistantExternalViews) private var externalViews

    @State private var isNearBottom: Bool = true
    @State private var scrollTrigger: Int = 0

    var body: some View {
        Group {
            if messages.isEmpty {
                EmptyStateView(onPick: onSendSuggestion)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            } else {
                ZStack(alignment: .bottomTrailing) {
                    TimelineTableView(messages: messages,
                                      streamingState: streamingState,
                                      isNearBottom: $isNearBottom,
                                      scrollToBottomTrigger: scrollTrigger,
                                      confirmationHandler: confirmationHandler,
                                      externalNavigation: externalNavigation,
                                      externalViews: externalViews)
                    Group {
                        if !isNearBottom {
                            JumpToLatestChip {
                                scrollTrigger += 1
                            }
                            .padding(.trailing, AssistantSpacing.large)
                            .padding(.bottom, AssistantSpacing.large)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .animation(.spring(duration: 0.2), value: isNearBottom)
                }
            }
        }
        // Reset the at-bottom flag when the transcript clears (new chat). Without this,
        // a stale `false` from the previous session leaves the jump-to-latest chip
        // visible on the first message of the new conversation.
        .onChange(of: messages.isEmpty) { _, isEmpty in
            if isEmpty {
                isNearBottom = true
            }
        }
        .onChange(of: messages.count) { oldCount, newCount in
            guard newCount > oldCount else { return }
            let userJustSent = messages.suffix(newCount - oldCount).contains { $0.role == .user }
            if userJustSent || isNearBottom {
                scrollTrigger += 1
            }
        }
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
