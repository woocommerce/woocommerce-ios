import StoreDesignSystem
import SwiftUI

/// Shown when the site doesn't have any active coupons for a time range.
/// Contains a placeholder image and text.
struct StoreMostActiveCouponsEmptyView: View {
    var body: some View {
        VStack(alignment: .center, spacing: StoreSpacing.s5) {
            Image(uiImage: .couponsImage)
                .accessibilityHidden(true)
            Text(Localization.text)
                .storeTextStyle(.bodyLarge)
                .foregroundStyle(.storeOnSurface)
                .multilineTextAlignment(.center)
        }
        .padding(StorePadding.p5)
        .frame(maxWidth: .infinity)
    }
}

private extension StoreMostActiveCouponsEmptyView {
    enum Localization {
        static let text = NSLocalizedString(
            "mostActiveCouponsEmptyView.text",
            value: "No coupon usage during this period",
            comment: "Default text for Most active coupons dashboard card when no data exists for a given period."
        )
    }
}

#Preview {
    StoreMostActiveCouponsEmptyView()
}
