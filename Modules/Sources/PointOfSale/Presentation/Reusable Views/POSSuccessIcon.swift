import SwiftUI

struct POSSuccessIcon: View {
    @Environment(\.posLayoutScale) private var layoutScale

    var body: some View {
        ZStack {
            Circle()
                .frame(width: iconSize, height: iconSize)
                .foregroundColor(.posSuccess)

            // Compact uses the SF Symbol checkmark to match the rest of the
            // compact prototype iconography. Regular keeps the brand asset with
            // its original glyph weight and proportions.
            if layoutScale == .compact {
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
        layoutScale == .compact ? Constants.compactIconSize : Constants.regularIconSize
    }

    private var checkmarkSize: CGFloat {
        // Compact keeps the SF-Symbol-sized 28pt; regular restores the design's
        // 52pt brand-asset width that #17092's drift had bumped to 64pt.
        layoutScale == .compact ? Constants.compactCheckmarkSize : Constants.regularCheckmarkSize
    }
}

private extension POSSuccessIcon {
    enum Constants {
        static let regularIconSize: CGFloat = 165
        static let regularCheckmarkSize: CGFloat = 52
        static let compactIconSize: CGFloat = 72
        static let compactCheckmarkSize: CGFloat = 28
    }
}

#if DEBUG
#Preview {
    POSSuccessIcon()
}
#endif
