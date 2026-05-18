import SwiftUI

struct ARTapHintCard: View {
    var body: some View {
        ARGlassCard {
            ARHintRow(
                iconName: "hand.tap",
                label: Text(Localization.action).fontWeight(.semibold) +
                       Text(" ") +
                       Text(Localization.description).foregroundColor(.white.opacity(0.62))
            )
        }
    }
}

private extension ARTapHintCard {
    enum Localization {
        static let action = NSLocalizedString(
            "parcelFitting.coaching.tapHint.action",
            value: "Tap on the surface",
            comment: "Bold part of the hint telling the user to tap a surface to place the fitting box")
        static let description = NSLocalizedString(
            "parcelFitting.coaching.tapHint.description",
            value: "to place the fitting box",
            comment: "Regular part of the hint following the bold 'Tap on the surface' text")
    }
}
