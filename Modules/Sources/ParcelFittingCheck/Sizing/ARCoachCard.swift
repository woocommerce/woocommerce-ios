import SwiftUI

struct ARCoachCard: View {
    let onDismiss: () -> Void

    private let hints: [Hint] = [
        Hint(iconName: "hand.draw", label: Localization.drag),
        Hint(iconName: "arrow.trianglehead.counterclockwise.rotate.90", label: Localization.twist),
        Hint(iconName: "hand.pinch", label: Localization.pinch),
    ]

    var body: some View {
        ARGlassCard {
            VStack(alignment: .leading, spacing: 0) {
                header
                ForEach(Array(hints.enumerated()), id: \.element.iconName) { index, hint in
                    if index > 0 {
                        separator
                    }
                    hintRow(hint)
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Text(Localization.title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white)
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(Constants.dismissButtonOpacity))
                    .padding(Constants.dismissButtonPadding)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(Localization.dismiss)
        }
        .padding(.bottom, Constants.headerBottomPadding)
    }

    private func hintRow(_ hint: Hint) -> some View {
        ARHintRow(iconName: hint.iconName, label: hint.label)
            .padding(.vertical, Constants.rowVerticalPadding)
    }

    private var separator: some View {
        Divider().overlay(Color.white.opacity(Constants.separatorOpacity))
    }
}

private extension ARCoachCard {
    struct Hint {
        let iconName: String
        let label: String
    }

    enum Constants {
        static let dismissButtonOpacity: Double = 0.55
        static let dismissButtonPadding: CGFloat = 5
        static let headerBottomPadding: CGFloat = 4
        static let rowVerticalPadding: CGFloat = 8
        static let separatorOpacity: Double = 0.06
    }

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
