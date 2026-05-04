import SwiftUI

struct JumpToLatestChip: View {

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.down")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Color.accentColor, in: Circle())
                .shadow(color: Color.black.opacity(0.12), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Localization.label)
    }

    private enum Localization {
        static let label = NSLocalizedString(
            "assistant.chat.jumpToLatest",
            value: "Jump to latest message",
            comment: "Accessibility label for the chat jump-to-latest chip"
        )
    }
}

#if DEBUG
#Preview { JumpToLatestChip(action: {}).padding() }
#endif
