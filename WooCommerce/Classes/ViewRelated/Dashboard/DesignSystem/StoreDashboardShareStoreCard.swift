import StoreDesignSystem
import SwiftUI

struct StoreDashboardShareStoreCard: View {
    let url: URL?

    var body: some View {
        StoreDashboardCardSurface {
            VStack(spacing: StoreSpacing.s5) {
                Image(uiImage: .launchImage)
                    .accessibilityHidden(true)

                VStack(spacing: StoreSpacing.s3) {
                    Text(Localization.title)
                        .storeTextStyle(.titleMedium.emphasized)
                    Text(Localization.subtitle)
                        .storeTextStyle(.titleMedium)
                }
                .foregroundStyle(.storeOnSurface)
                .multilineTextAlignment(.center)

                if let url {
                    // ShareLink cannot use StoreButton directly. This label mirrors the small filled button
                    // until StoreDesignSystem exposes a link-compatible public button style.
                    ShareLink(item: url) {
                        Text(Localization.shareButtonLabel)
                            .storeTextStyle(.labelMedium.emphasized)
                            .foregroundStyle(.storeOnPrimary)
                            .padding(.vertical, StorePadding.p3)
                            .padding(.horizontal, StorePadding.p5)
                            .background(Color.storePrimary)
                            .clipShape(.rect(cornerRadius: StoreRadius.large))
                    }
                }
            }
            .padding(StorePadding.p5)
            .frame(maxWidth: .infinity)
        }
    }
}

private extension StoreDashboardShareStoreCard {
    typealias Localization = DashboardView.Localization.ShareStoreCard
}

#Preview("Share store") {
    StoreDashboardShareStoreCard(url: URL(string: "https://woocommerce.com"))
        .padding(StorePadding.p5)
        .background(Color.storeSurfaceDim)
}
