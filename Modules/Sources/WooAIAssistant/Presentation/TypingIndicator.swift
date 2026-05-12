import SwiftUI

struct TypingIndicator: View {

    private static let cyclePeriod: Double = 1.0
    private static let dotPhaseOffset: Double = 0.18

    @State private var revealed: Bool = false

    var body: some View {
        // Drive opacity from the current time so the wave never desyncs the way
        // .delay + .repeatForever does on some iOS releases.
        TimelineView(.animation) { context in
            let elapsed = context.date.timeIntervalSinceReferenceDate
            HStack(spacing: AssistantSpacing.xSmall) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.assistantMuted)
                        .frame(width: 6, height: 6)
                        .opacity(opacity(elapsed: elapsed, index: index))
                }
            }
        }
        .padding(.vertical, AssistantSpacing.xSmall)
        .opacity(revealed ? 1 : 0)
        .animation(.easeOut(duration: 0.12), value: revealed)
        .onAppear { revealed = true }
        .accessibilityLabel(Localization.typing)
    }

    private func opacity(elapsed: Double, index: Int) -> Double {
        let phase = elapsed - Double(index) * Self.dotPhaseOffset
        let normalized = (sin(phase * 2 * .pi / Self.cyclePeriod) + 1) / 2
        return 0.35 + 0.65 * normalized
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
