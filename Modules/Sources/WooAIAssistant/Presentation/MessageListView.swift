import SwiftUI

struct MessageListView: View {

    let messages: [ChatMessage]
    let streamingState: AssistantConversation.StreamingState
    var showToolActivity: Bool = true
    var showIterationCapBanner: Bool = false
    var inputFocused: Bool = false
    var onPickPrompt: (String) -> Void = { _ in }

    @State private var isPinnedToBottom: Bool = true
    @State private var viewportHeight: CGFloat = 0

    private static let bottomAnchor = "scroll-bottom"
    private static let scrollSpace = "assistantMessageList"
    private static let pinnedThreshold: CGFloat = 60

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
                        .background(bottomMarkerProbe)
                }
                .padding(.horizontal, AssistantSpacing.large)
                .padding(.top, AssistantSpacing.large)
                .padding(.bottom, AssistantSpacing.medium)
            }
            .background(viewportProbe)
            .coordinateSpace(name: Self.scrollSpace)
            .onPreferenceChange(BottomDistancePreferenceKey.self) { distance in
                guard viewportHeight > 0 else { return }
                isPinnedToBottom = distance <= Self.pinnedThreshold
            }
            .scrollDismissesKeyboard(.interactively)
            .onAppear { scrollToBottom(proxy: proxy, animated: false) }
            .onChange(of: messages.count) { _, _ in
                if isPinnedToBottom { scrollToBottom(proxy: proxy) }
            }
            .onChange(of: messages.last?.segments.last?.fingerprint) { _, _ in
                if isPinnedToBottom { scrollToBottom(proxy: proxy) }
            }
            .onChange(of: inputFocused) { _, focused in
                if focused { scrollToBottom(proxy: proxy) }
            }
        }
    }

    private var viewportProbe: some View {
        GeometryReader { geometry in
            Color.clear
                .preference(key: ViewportHeightPreferenceKey.self, value: geometry.size.height)
        }
        .onPreferenceChange(ViewportHeightPreferenceKey.self) { height in
            viewportHeight = height
        }
    }

    private var bottomMarkerProbe: some View {
        GeometryReader { geometry in
            let frame = geometry.frame(in: .named(Self.scrollSpace))
            Color.clear
                .preference(key: BottomDistancePreferenceKey.self,
                            value: max(0, frame.maxY - viewportHeight))
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

private struct ViewportHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct BottomDistancePreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
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
