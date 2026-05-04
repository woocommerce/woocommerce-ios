import SwiftUI

struct TypingIndicator: View {

    var body: some View {
        HStack(spacing: AssistantSpacing.xSmall) {
            ForEach(0..<3, id: \.self) { _ in
                Circle()
                    .fill(Color.assistantMuted)
                    .frame(width: 6, height: 6)
                    .opacity(0.6)
            }
        }
        .padding(.horizontal, AssistantSpacing.medium)
        .padding(.vertical, AssistantSpacing.small)
        .background(Color.assistantBubbleAssistant)
        .clipShape(RoundedRectangle(cornerRadius: AssistantRadius.bubble))
        .accessibilityLabel(Localization.typing)
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
