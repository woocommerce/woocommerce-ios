import StoreDesignSystem
import SwiftUI

struct StoreConnectWPComCard: View {
    @ScaledMetric(relativeTo: .body) private var iconSize = Layout.iconSize

    let setupAction: () -> Void
    let hideAction: () -> Void

    var body: some View {
        StoreDashboardCardSurface {
            Button(action: setupAction) {
                HStack(alignment: .top, spacing: StoreSpacing.s5) {
                    Image(uiImage: .connectWPComImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: iconSize, height: iconSize)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: StoreSpacing.s3) {
                        Text(Localization.title)
                            .storeTextStyle(.titleLarge.strong)
                        Text(Localization.subtitle)
                            .storeTextStyle(.bodyLarge)
                            .foregroundStyle(.storeOnSurfaceVariant)
                    }
                    .foregroundStyle(.storeOnSurface)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Color.clear
                        .frame(width: StoreSize.minimumTapTarget, height: StoreSize.minimumTapTarget)
                }
                .padding(StorePadding.p5)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .overlay(alignment: .topTrailing) {
                StoreDashboardCardOverflowMenu {
                    Button(Localization.hide, action: hideAction)
                }
                .padding(.top, StorePadding.p3)
                .padding(.trailing, StorePadding.p3)
            }
        }
    }
}

private extension StoreConnectWPComCard {
    enum Layout {
        static let iconSize: CGFloat = 35
    }

    enum Localization {
        static let title = NSLocalizedString(
            "storeConnectWPComCard.title",
            value: "Never miss a new order",
            comment: "Title of the dashboard card for enabling push notifications with WordPress.com."
        )
        static let subtitle = NSLocalizedString(
            "storeConnectWPComCard.subtitle",
            value: "Enable push notifications to stay on top of new orders and reviews.",
            comment: "Description of the dashboard card for enabling push notifications with WordPress.com."
        )
        static let hide = NSLocalizedString(
            "storeConnectWPComCard.hide",
            value: "Hide this content",
            comment: "Menu action that hides the WordPress.com connection card."
        )
    }
}
