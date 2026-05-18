import SwiftUI

struct ARCoachCard: View {
    let onDismiss: () -> Void

    var body: some View {
        ARGlassCard {
            VStack(alignment: .leading, spacing: 0) {
                header
                gestureRow(icon: "hand.draw", bold: Localization.drag, regular: Localization.dragDescription)
                hairline
                gestureRow(icon: "arrow.trianglehead.counterclockwise.rotate.90", bold: Localization.twist, regular: Localization.twistDescription)
                hairline
                gestureRow(icon: "hand.pinch", bold: Localization.pinch, regular: Localization.pinchDescription)
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
                    .frame(width: 22, height: 22)
            }
            .accessibilityLabel(Localization.dismiss)
        }
        .padding(.bottom, 4)
    }

    private func gestureRow(icon: String, bold: String, regular: String) -> some View {
        ARHintRow(iconName: icon, boldText: bold, regularText: regular)
            .padding(.vertical, 8)
    }

    private var hairline: some View {
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
            "parcelFitting.coaching.drag",
            value: "Drag",
            comment: "Bold verb for the drag gesture hint in AR coaching")
        static let dragDescription = NSLocalizedString(
            "parcelFitting.coaching.drag.description",
            value: "to move the box",
            comment: "Description following 'Drag' in AR coaching gesture hint")
        static let twist = NSLocalizedString(
            "parcelFitting.coaching.twist",
            value: "Twist",
            comment: "Bold verb for the twist/rotate gesture hint in AR coaching")
        static let twistDescription = NSLocalizedString(
            "parcelFitting.coaching.twist.description",
            value: "with two fingers to rotate",
            comment: "Description following 'Twist' in AR coaching gesture hint")
        static let pinch = NSLocalizedString(
            "parcelFitting.coaching.pinch",
            value: "Pinch",
            comment: "Bold verb for the pinch/resize gesture hint in AR coaching")
        static let pinchDescription = NSLocalizedString(
            "parcelFitting.coaching.pinch.description",
            value: "an axis to resize that side",
            comment: "Description following 'Pinch' in AR coaching gesture hint")
        static let dismiss = NSLocalizedString(
            "parcelFitting.coaching.dismiss.accessibilityLabel",
            value: "Dismiss",
            comment: "Accessibility label for the dismiss button on the AR coaching card")
    }
}
