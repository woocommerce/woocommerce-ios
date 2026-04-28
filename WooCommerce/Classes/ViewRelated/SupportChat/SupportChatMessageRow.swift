import SwiftUI

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

    enum TypingIndicator {
        static let dotSize: CGFloat = 8
        static let dotSpacing: CGFloat = 4
        static let dotCount: Int = 3
        static let animationDuration: CGFloat = 0.5
        static let animationOffset: CGFloat = -4
        static let delayMultiplier: Double = 0.15
    }
}

/// A chat bubble component that displays a single message.
///
struct SupportChatMessageRow: View {
    let message: SupportChatViewModel.ChatMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: UIScreen.main.bounds.width * (1 - SupportChatLayout.maxBubbleWidthRatio))
            }

            messageText
                .padding(SupportChatLayout.bubblePadding)
                .background(bubbleBackground)
                .foregroundColor(bubbleForeground)
                .cornerRadius(SupportChatLayout.bubbleCornerRadius)

            if message.role == .assistant {
                Spacer(minLength: UIScreen.main.bounds.width * (1 - SupportChatLayout.maxBubbleWidthRatio))
            }
        }
    }

    @ViewBuilder
    private var messageText: some View {
        switch message.role {
        case .user:
            Text(message.content)
        case .assistant:
            Text(.init(message.content))
        }
    }

    private var bubbleBackground: Color {
        switch message.role {
        case .user:
            return Color(.accent)
        case .assistant:
            return Color(.systemGray5)
        }
    }

    private var bubbleForeground: Color {
        switch message.role {
        case .user:
            return .white
        case .assistant:
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
            .background(Color(.systemGray5))
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
    SupportChatMessageRow(
        message: .init(role: .user, content: "How do I fix my connection issue?")
    )
    .padding()
}

#Preview("Assistant Message") {
    SupportChatMessageRow(
        message: .init(role: .assistant, content: "I can help you troubleshoot your connection. Let's start by checking a few things.")
    )
    .padding()
}

#Preview("Typing Indicator") {
    TypingIndicatorRow()
        .padding()
}
