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
                        .storeTextStyle(.titleLarge.strong)
                    Text(Localization.subtitle)
                        .storeTextStyle(.bodyLarge)
                }
                .foregroundStyle(.storeOnSurface)
                .multilineTextAlignment(.center)

                if let url {
                    // ShareLink cannot use StoreButton directly. This label mirrors the medium filled button
                    // until StoreDesignSystem exposes a link-compatible public button style.
                    ShareLink(item: url) {
                        Text(Localization.share)
                            .storeTextStyle(.labelLarge.emphasized)
                            .foregroundStyle(.storeOnPrimary)
                            .padding(.horizontal, StorePadding.p5)
                            .padding(.vertical, StorePadding.p6)
                            .background(Color.storePrimary)
                            .clipShape(.rect(cornerRadius: StoreRadius.extraLarge))
                    }
                }
            }
            .padding(StorePadding.p5)
            .frame(maxWidth: .infinity)
        }
    }
}

private extension StoreDashboardShareStoreCard {
    enum Localization {
        static let title = NSLocalizedString(
            "storeDashboardShareStoreCard.title",
            value: "Get the word out!",
            comment: "Title of the Share Store dashboard card."
        )
        static let subtitle = NSLocalizedString(
            "storeDashboardShareStoreCard.subtitle",
            value: "Use email or social media to spread the word about your store.",
            comment: "Description of the Share Store dashboard card."
        )
        static let share = NSLocalizedString(
            "storeDashboardShareStoreCard.share",
            value: "Share Your Store",
            comment: "Button that opens the system share sheet for a store."
        )
    }
}
