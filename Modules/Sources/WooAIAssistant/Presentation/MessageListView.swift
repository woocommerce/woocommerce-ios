import SwiftUI

struct MessageListView: View {

    let messages: [ChatMessage]
    let streamingState: AssistantConversation.StreamingState
    var showToolActivity: Bool = true
    var showIterationCapBanner: Bool = false
    var onPickPrompt: (String) -> Void = { _ in }

    private static let bottomSentinelID = "scroll-sentinel-bottom"
    private static let anchorThreshold: CGFloat = 80

    @State private var isAtBottom: Bool = true
    @State private var unreadCount: Int = 0

    var body: some View {
        GeometryReader { outer in
            ScrollViewReader { proxy in
                ZStack(alignment: .bottom) {
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

                            GeometryReader { sentinel in
                                Color.clear.preference(
                                    key: BottomDistanceKey.self,
                                    value: sentinel.frame(in: .global).minY - outer.frame(in: .global).maxY
                                )
                            }
                            .frame(height: 1)
                            .id(Self.bottomSentinelID)
                        }
                        .padding(.horizontal, AssistantSpacing.large)
                        .padding(.top, AssistantSpacing.large)
                        .padding(.bottom, AssistantSpacing.medium)
                        .contentShape(Rectangle())
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onPreferenceChange(BottomDistanceKey.self) { distance in
                        let nowAtBottom = distance < Self.anchorThreshold
                        if nowAtBottom { unreadCount = 0 }
                        isAtBottom = nowAtBottom
                    }
                    .onChange(of: messages.count) { _, _ in
                        handleNewContent(proxy: proxy, isNewMessage: true)
                    }
                    .onChange(of: messages.last?.segments.last?.fingerprint) { _, _ in
                        handleNewContent(proxy: proxy, isNewMessage: false)
                    }
                    .onAppear {
                        proxy.scrollTo(Self.bottomSentinelID, anchor: .bottom)
                    }

                    if let pillCount = effectivePillCount {
                        NewMessagesPill(count: pillCount) {
                            unreadCount = 0
                            scrollToBottom(proxy: proxy)
                        }
                        .padding(.bottom, AssistantSpacing.medium)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.smooth(duration: AssistantMotion.transition), value: unreadCount)
                .animation(.smooth(duration: AssistantMotion.transition), value: isAtBottom)
            }
        }
    }

    private func handleNewContent(proxy: ScrollViewProxy, isNewMessage: Bool) {
        if isAtBottom {
            scrollToBottom(proxy: proxy)
        } else if isNewMessage {
            unreadCount += 1
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.smooth(duration: AssistantMotion.snap)) {
            proxy.scrollTo(Self.bottomSentinelID, anchor: .bottom)
        }
    }

    private var effectivePillCount: Int? {
        guard unreadCount > 0, !isAtBottom else { return nil }
        return unreadCount
    }
}

private struct BottomDistanceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct NewMessagesPill: View {

    let count: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AssistantSpacing.xSmall) {
                Image(systemName: "arrow.down")
                    .font(.system(size: 12, weight: .semibold))
                Text(label)
                    .font(.assistantBodyEmphasized)
            }
            .padding(.horizontal, AssistantSpacing.medium)
            .padding(.vertical, AssistantSpacing.medium)
            .frame(minHeight: 44)
            .foregroundStyle(Color.assistantOnAccent)
            .background(
                Capsule().fill(Color(.accent))
            )
            .shadow(color: Color.black.opacity(0.18), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var label: String {
        if count == 1 {
            return Localization.singular
        }
        return String(format: Localization.plural, count)
    }

    private enum Localization {
        static let singular = NSLocalizedString(
            "assistantChat.scroll.newMessage.singular",
            value: "1 new message",
            comment: "Pill shown above the input bar when one new message arrived while scrolled up"
        )
        static let plural = NSLocalizedString(
            "assistantChat.scroll.newMessage.plural",
            value: "%1$d new messages",
            comment: "Pill shown above the input bar when multiple new messages arrived while scrolled up. %1$d is the count."
        )
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
