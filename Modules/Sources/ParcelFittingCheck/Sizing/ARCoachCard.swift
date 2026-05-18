import SwiftUI

struct ARCoachCard: View {
    let onDismiss: () -> Void

    var body: some View {
        ARGlassCard {
            VStack(alignment: .leading, spacing: 0) {
                header
                ARHintRow(iconName: "hand.draw", label: Localization.drag)
                    .padding(.vertical, 8)
                separator
                ARHintRow(iconName: "arrow.trianglehead.counterclockwise.rotate.90", label: Localization.twist)
                    .padding(.vertical, 8)
                separator
                ARHintRow(iconName: "hand.pinch", label: Localization.pinch)
                    .padding(.vertical, 8)
            }
        }
    }

    private var header: some View {
        HStack {
            Text(Localization.title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(5)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(Localization.dismiss)
        }
        .padding(.bottom, 4)
    }

    private var separator: some View {
        Divider().overlay(Color.white.opacity(0.06))
    }
}

private extension ARCoachCard {
    enum Localization {
        static let title = NSLocalizedString(
            "parcelFitting.coaching.title",
            value: "Fit the box around your package",
            comment: "Title for the AR coaching card that teaches gesture controls")
        static let drag = NSLocalizedString(
            "parcelFitting.coaching.drag.hint",
            value: "Drag to move the box",
            comment: "Hint explaining the drag gesture to move the AR fitting box")
        static let twist = NSLocalizedString(
            "parcelFitting.coaching.twist.hint",
            value: "Twist with two fingers to rotate",
            comment: "Hint explaining the two-finger twist gesture to rotate the AR fitting box")
        static let pinch = NSLocalizedString(
            "parcelFitting.coaching.pinch.hint",
            value: "Pinch an axis to resize that side",
            comment: "Hint explaining the pinch gesture to resize one side of the AR fitting box")
        static let dismiss = NSLocalizedString(
            "parcelFitting.coaching.dismiss.accessibilityLabel",
            value: "Dismiss",
            comment: "Accessibility label for the dismiss button on the AR coaching card")
    }
}
