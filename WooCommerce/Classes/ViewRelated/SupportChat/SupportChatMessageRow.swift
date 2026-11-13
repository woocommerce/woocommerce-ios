import SwiftUI
import enum Yosemite.SupportChatRole

/// Shared layout constants for the support chat UI.
///
enum SupportChatLayout {
    static let bubbleCornerRadius: CGFloat = 16
    static let bubblePadding: CGFloat = 12
    static let maxBubbleWidthRatio: CGFloat = 0.75
    static let messageSpacing: CGFloat = 12
    static let inputSpacing: CGFloat = 12
    static let bannerSpacing: CGFloat = 8
    static let sendButtonSize: CGFloat = 20
    static let disabledOpacity: CGFloat = 0.5
    static let failedBubbleOpacity: CGFloat = 0.6
    static let failedIconSpacing: CGFloat = 6

    enum TypingIndicator {
        static let dotSize: CGFloat = 8
        static let dotSpacing: CGFloat = 4
        static let dotCount: Int = 3
        static let animationDuration: CGFloat = 0.5
        static let animationOffset: CGFloat = -4
        static let delayMultiplier: Double = 0.15
    }
}

/// Maximum bubble width for a message list of the given width.
///
extension SupportChatLayout {
    static func maxBubbleWidth(in containerWidth: CGFloat) -> CGFloat {
        containerWidth * maxBubbleWidthRatio
    }
}

/// A chat bubble component that displays a single text message.
///
struct SupportChatMessageRow: View {
    let role: SupportChatRole
    let text: String
    /// When `true`, the bubble is rendered with reduced opacity and a red exclamation
    /// icon next to it, signalling the message failed to send.
    var failed: Bool = false
    /// Width of the message list the row is laid out in.
    let containerWidth: CGFloat

    var body: some View {
        HStack(spacing: SupportChatLayout.failedIconSpacing) {
            if role == .user {
                Spacer(minLength: oppositeSideSpacing)

                if failed {
                    failedIndicator
                }
            }

            messageText
                .padding(SupportChatLayout.bubblePadding)
                .background(bubbleBackground)
                .foregroundColor(bubbleForeground)
                .cornerRadius(SupportChatLayout.bubbleCornerRadius)
                .opacity(failed ? SupportChatLayout.failedBubbleOpacity : 1.0)

            if role == .bot {
                Spacer(minLength: oppositeSideSpacing)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var oppositeSideSpacing: CGFloat {
        containerWidth - SupportChatLayout.maxBubbleWidth(in: containerWidth)
    }

    @ViewBuilder
    private var messageText: some View {
        switch role {
        case .user:
            Text(text)
        case .bot, .unknown:
            Text(.init(text))
        }
    }

    private var failedIndicator: some View {
        Image(systemName: "exclamationmark.circle.fill")
            .foregroundColor(.red)
            .accessibilityHidden(true)
    }

    private var accessibilityLabel: String {
        guard failed, role == .user else { return text }
        return String.localizedStringWithFormat(
            NSLocalizedString(
                "supportChatMessageRow.failedAccessibilityLabel",
                value: "Not sent. %1$@",
                comment: "VoiceOver label for a user chat message that failed to send. %1$@ is the message text."
            ),
            text
        )
    }

    private var bubbleBackground: Color {
        switch role {
        case .user:
            return Color(.accent)
        case .bot, .unknown:
            return Color(.listForeground(modal: false))
        }
    }

    private var bubbleForeground: Color {
        switch role {
        case .user:
            return .white
        case .bot, .unknown:
            return Color(.label)
        }
    }
}

/// A typing indicator shown while the bot is generating a response.
///
struct TypingIndicatorRow: View {
    @State private var animationOffset: CGFloat = 0

    private typealias Layout = SupportChatLayout.TypingIndicator

    var body: some View {
        HStack {
            HStack(spacing: Layout.dotSpacing) {
                ForEach(0..<Layout.dotCount, id: \.self) { index in
                    Circle()
                        .frame(width: Layout.dotSize, height: Layout.dotSize)
                        .foregroundColor(Color(.systemGray3))
                        .offset(y: animationOffset(for: index))
                }
            }
            .padding(SupportChatLayout.bubblePadding)
            .background(Color(.listForeground(modal: false)))
            .cornerRadius(SupportChatLayout.bubbleCornerRadius)

            Spacer()
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: Layout.animationDuration).repeatForever(autoreverses: true)) {
                animationOffset = Layout.animationOffset
            }
        }
    }

    private func animationOffset(for index: Int) -> CGFloat {
        let delay = Double(index) * Layout.delayMultiplier
        return animationOffset * cos(delay * .pi)
    }
}

#Preview("User Message") {
    GeometryReader { geometry in
        SupportChatMessageRow(
            role: .user,
            text: "How do I fix my connection issue?",
            containerWidth: geometry.size.width
        )
        .padding()
    }
}

#Preview("Failed User Message") {
    GeometryReader { geometry in
        SupportChatMessageRow(
            role: .user,
            text: "I cannot load products in the app",
            failed: true,
            containerWidth: geometry.size.width
        )
        .padding()
    }
}

#Preview("Assistant Message") {
    GeometryReader { geometry in
        SupportChatMessageRow(
            role: .bot,
            text: "I can help you troubleshoot your connection. Let's start by checking a few things.",
            containerWidth: geometry.size.width
        )
        .padding()
    }
}

#Preview("Typing Indicator") {
    TypingIndicatorRow()
        .padding()
}
