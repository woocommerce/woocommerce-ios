import SwiftUI

struct JumpToLatestChip: View {

    let onTap: () -> Void

    private static let diameter: CGFloat = 36

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "chevron.down")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.assistantOnAccent)
                .frame(width: Self.diameter, height: Self.diameter)
                .background(Color(.accent))
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Localization.accessibility)
    }

    private enum Localization {
        static let accessibility = NSLocalizedString(
            "assistantChat.jumpToLatest.accessibility",
            value: "Jump to latest message",
            comment: "Accessibility label for the floating chip that scrolls the AI Assistant chat to the latest message"
        )
    }
}

#if DEBUG
#Preview {
    JumpToLatestChip(onTap: {})
        .padding()
}
#endif
