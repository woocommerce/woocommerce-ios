import SwiftUI

struct POSSuccessIcon: View {
    @Environment(\.posLayoutScale) private var layoutScale

    var body: some View {
        ZStack {
            Circle()
                .frame(width: iconSize, height: iconSize)
                .foregroundColor(.posSuccess)

            // Phone uses the SF Symbol checkmark to match the rest of the
            // phone-prototype iconography. iPad keeps the brand asset (its
            // glyph weight + proportions are what the design ships) — gating
            // the swap on `.phone` so this PR stays scoped to phone polish.
            if layoutScale == .phone {
                Image(systemName: "checkmark")
                    .font(.system(size: checkmarkSize, weight: .bold))
                    .foregroundColor(.posOnSuccess)
                    .accessibilityHidden(true)
            } else {
                PointOfSaleAssets.successCheck.image
                    .renderingMode(.template)
                    .foregroundColor(.posOnSuccess)
                    .frame(width: checkmarkSize)
                    .accessibilityHidden(true)
            }
        }
    }

    private var iconSize: CGFloat {
        layoutScale == .phone ? Constants.phoneIconSize : Constants.tabletIconSize
    }

    private var checkmarkSize: CGFloat {
        // Phone keeps the SF-Symbol-sized 28pt; iPad restores the design's
        // 52pt brand-asset width that #17092's drift had bumped to 64pt.
        layoutScale == .phone ? Constants.phoneCheckmarkSize : Constants.tabletCheckmarkSize
    }
}

private extension POSSuccessIcon {
    enum Constants {
        static let tabletIconSize: CGFloat = 165
        static let tabletCheckmarkSize: CGFloat = 52
        static let phoneIconSize: CGFloat = 72
        static let phoneCheckmarkSize: CGFloat = 28
    }
}

#if DEBUG
#Preview {
    POSSuccessIcon()
}
#endif
