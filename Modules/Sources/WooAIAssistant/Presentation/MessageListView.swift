import SwiftUI

struct MessageListView: View {

    let messages: [ChatMessage]
    let streamingState: AssistantConversation.StreamingState
    var showToolActivity: Bool = true
    var showIterationCapBanner: Bool = false
    var onPickPrompt: (String) -> Void = { _ in }

    @State private var bottomVisibleID: ChatMessage.ID?

    var body: some View {
        if messages.isEmpty {
            emptyState
        } else {
            scrollableMessages
        }
    }

    private var emptyState: some View {
        EmptyStateView(onPick: onPickPrompt)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var scrollableMessages: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: AssistantSpacing.large) {
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
                    Color.clear.frame(height: 1).id("bottom-anchor")
                }
                .padding(.horizontal, AssistantSpacing.large)
                .padding(.top, AssistantSpacing.large)
                .padding(.bottom, AssistantSpacing.medium)
                .scrollTargetLayout()
            }
            .defaultScrollAnchor(.bottom)
            .trackBottomVisibleMessage(id: $bottomVisibleID)
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: messages.count) { _, _ in
                guard isPinnedToBottom else { return }
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo("bottom-anchor", anchor: .bottom)
                }
            }
            .onChange(of: lastSegmentFingerprint) { _, _ in
                guard isPinnedToBottom else { return }
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo("bottom-anchor", anchor: .bottom)
                }
            }
        }
    }

    private var lastSegmentFingerprint: String {
        guard let last = messages.last else { return "" }
        return last.segments.map(\.fingerprint).joined(separator: "|")
    }

    // iOS 17.0-17.3 lacks scrollPosition(id:anchor:); on those versions we fall
    // back to always scrolling because the at-bottom signal is unavailable.
    private var isPinnedToBottom: Bool {
        guard #available(iOS 17.4, *) else { return true }
        guard let bottomVisibleID else { return true }
        return bottomVisibleID == messages.last?.id
    }
}

private extension View {
    @ViewBuilder
    func trackBottomVisibleMessage(id: Binding<ChatMessage.ID?>) -> some View {
        if #available(iOS 17.4, *) {
            self.scrollPosition(id: id, anchor: .bottom)
        } else {
            self
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
