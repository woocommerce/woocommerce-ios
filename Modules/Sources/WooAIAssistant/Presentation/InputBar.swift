import SwiftUI

struct InputBar: View {

    @Binding var draft: String
    let canSend: Bool
    let isStreaming: Bool
    let pendingConfirmation: Bool
    let onSend: () -> Void
    let onStop: () -> Void

    private static let sendButtonDiameter: CGFloat = 36
    private static let sendButtonHitTarget: CGFloat = 44
    // 4pt centers the 36pt circle inside the 44pt hit target; trailing matches for symmetry.
    private static let sendButtonTrailingPadding: CGFloat = 4

    var body: some View {
        VStack(alignment: .leading, spacing: AssistantSpacing.small) {
            if pendingConfirmation {
                Text(Localization.pendingHint)
                    .font(.assistantCaption)
                    .foregroundStyle(Color.assistantMuted)
                    .padding(.horizontal, AssistantSpacing.medium)
            }

            HStack(alignment: .center, spacing: AssistantSpacing.medium) {
                TextField(Localization.placeholder, text: $draft, axis: .vertical)
                    .font(.assistantBody)
                    .lineLimit(1...6)
                    .padding(.leading, AssistantSpacing.large)
                    .padding(.vertical, AssistantSpacing.medium)

                Button(action: actionTapped) {
                    Image(systemName: glyph)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(buttonForeground)
                        .frame(width: Self.sendButtonDiameter,
                               height: Self.sendButtonDiameter)
                        .background(buttonBackground)
                        .clipShape(Circle())
                        .contentTransition(.symbolEffect(.replace))
                        .frame(width: Self.sendButtonHitTarget,
                               height: Self.sendButtonHitTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.trailing, Self.sendButtonTrailingPadding)
                .disabled(buttonDisabled)
                .accessibilityLabel(showsStop ? Localization.stop : Localization.send)
            }
            .background(pillBackground)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.assistantSurfaceBorder, lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 1)
        }
        .padding(.horizontal, AssistantSpacing.large)
        .padding(.top, AssistantSpacing.medium)
        .padding(.bottom, AssistantSpacing.medium)
    }

    private var showsStop: Bool {
        isStreaming && !pendingConfirmation
    }

    private var glyph: String {
        showsStop ? "stop.fill" : "arrow.up"
    }

    private var buttonBackground: Color {
        if showsStop { return Color(.accent) }
        if canSend && !draftIsEmpty { return Color(.accent) }
        return Color.assistantSurfaceElevated
    }

    private var buttonForeground: Color {
        if showsStop { return Color.assistantOnAccent }
        if canSend && !draftIsEmpty { return Color.assistantOnAccent }
        return Color.assistantMuted
    }

    private var buttonDisabled: Bool {
        if showsStop { return false }
        if pendingConfirmation { return true }
        if !canSend { return true }
        return draftIsEmpty
    }

    private var draftIsEmpty: Bool {
        draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var pillBackground: Color {
        // Dark mode steps up from the chat's true-black background so the pill stays visible.
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? .secondarySystemBackground : .systemBackground
        })
    }

    private func actionTapped() {
        if showsStop {
            onStop()
        } else if !draftIsEmpty {
            onSend()
        }
    }

    private enum Localization {
        static let placeholder = NSLocalizedString(
            "assistantChat.input.placeholder",
            value: "Ask about your store",
            comment: "Placeholder shown in the AI Assistant chat input field"
        )
        static let send = NSLocalizedString(
            "assistantChat.input.send.accessibility",
            value: "Send message",
            comment: "Accessibility label for the AI Assistant chat send button"
        )
        static let stop = NSLocalizedString(
            "assistantChat.input.stop.accessibility",
            value: "Stop response",
            comment: "Accessibility label for the AI Assistant chat stop button"
        )
        static let pendingHint = NSLocalizedString(
            "assistantChat.input.pendingHint",
            value: "Resolve the pending change above.",
            comment: "Hint shown above the input bar when a confirmation is pending"
        )
    }
}

#if DEBUG
#Preview("Idle (in chat)") {
    AssistantChatView.preview(.empty)
}

#Preview("Streaming (in chat)") {
    AssistantChatView.preview(.assistantStreamingText)
}

#Preview("Pending confirmation (in chat)") {
    AssistantChatView.preview(.pendingConfirmation)
}
#endif
