import SwiftUI

struct MessageListView: View {

    let messages: [ChatMessage]
    let streamingState: AssistantConversation.StreamingState
    var showToolActivity: Bool = true
    var showIterationCapBanner: Bool = false
    var onPickPrompt: (String) -> Void = { _ in }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AssistantSpacing.large) {
                if messages.isEmpty {
                    EmptyStateView(onPick: onPickPrompt)
                }
                ForEach(messages) { message in
                    MessageBubble(message: message,
                                  showToolActivity: showToolActivity)
                        .id(message.id)
                }
                if streamingState == .sending {
                    TypingIndicator()
                        .padding(.leading, AssistantSpacing.medium)
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
        .defaultScrollAnchor(.bottom)
        .scrollDismissesKeyboard(.interactively)
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
