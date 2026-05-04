import SwiftUI

struct TypingIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: AssistantSpacing.xSmall) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.assistantMuted)
                    .frame(width: 6, height: 6)
                    .opacity(animating ? 1.0 : 0.4)
                    .animation(
                        .easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.15),
                        value: animating
                    )
            }
        }
        .padding(.horizontal, AssistantSpacing.medium)
        .padding(.vertical, AssistantSpacing.small)
        .background(Color.assistantBubbleAssistant)
        .clipShape(RoundedRectangle(cornerRadius: AssistantRadius.bubble))
        .accessibilityLabel(Localization.typing)
        .onAppear { animating = true }
    }

    private enum Localization {
        static let typing = NSLocalizedString(
            "assistant.typing.indicator",
            value: "Assistant is typing",
            comment: "Accessibility label for typing indicator"
        )
    }
}

#if DEBUG
#Preview("In chat") {
    AssistantChatView.preview(.assistantTyping)
}

#Preview("Standalone") {
    TypingIndicator()
        .padding()
}
#endif
