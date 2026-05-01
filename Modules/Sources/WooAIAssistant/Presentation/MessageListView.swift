import SwiftUI

struct MessageListView: View {

    let messages: [ChatMessage]
    let streamingState: AssistantConversation.StreamingState
    var showToolActivity: Bool = true
    var showIterationCapBanner: Bool = false
    var inputFocused: Bool = false
    var onPickPrompt: (String) -> Void = { _ in }

    private static let bottomAnchor = "scroll-bottom"

    var body: some View {
        ScrollViewReader { proxy in
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

                    Color.clear
                        .frame(height: 1)
                        .id(Self.bottomAnchor)
                }
                .padding(.horizontal, AssistantSpacing.large)
                .padding(.top, AssistantSpacing.large)
                .padding(.bottom, AssistantSpacing.medium)
            }
            .scrollDismissesKeyboard(.interactively)
            .onAppear { scrollToBottom(proxy: proxy, animated: false) }
            .onChange(of: messages.count) { _, _ in scrollToBottom(proxy: proxy) }
            .onChange(of: messages.last?.segments.last?.fingerprint) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: inputFocused) { _, focused in
                if focused { scrollToBottom(proxy: proxy) }
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool = true) {
        if animated {
            withAnimation(.smooth(duration: AssistantMotion.snap)) {
                proxy.scrollTo(Self.bottomAnchor, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(Self.bottomAnchor, anchor: .bottom)
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
