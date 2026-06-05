import SwiftUI

struct ARTapHintCard: View {
    var body: some View {
        ARGlassCard {
            ARHintRow(
                iconName: "hand.tap",
                label: Localization.hint
            )
        }
    }
}

private extension ARTapHintCard {
    enum Localization {
        static let hint = NSLocalizedString(
            "parcelFitting.coaching.tapHint",
            value: "Tap on the surface to place the fitting box",
            comment: "Hint telling the user to tap a detected surface to place the fitting box in AR")
    }
}
