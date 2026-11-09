import StoreDesignSystem
import SwiftUI

/// Shown when the site doesn't have any active coupons for a time range.
/// Contains a placeholder image and text.
struct StoreMostActiveCouponsEmptyView: View {
    var body: some View {
        VStack(alignment: .center, spacing: StoreSpacing.s5) {
            Image(uiImage: .couponsImage)
                .accessibilityHidden(true)
            Text(MostActiveCouponsEmptyView.Localization.text)
                .storeTextStyle(.bodyLarge)
                .foregroundStyle(.storeOnSurface)
                .multilineTextAlignment(.center)
        }
        .padding(StorePadding.p5)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    StoreMostActiveCouponsEmptyView()
}
