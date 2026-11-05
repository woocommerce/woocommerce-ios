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
                            .storeTextStyle(.titleMedium.emphasized)
                        Text(Localization.subtitle)
                            .storeTextStyle(.bodyMedium)
                            .foregroundStyle(.storeOnSurface)
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
                    Button(Localization.hideButton, action: hideAction)
                }
                .padding(.top, StorePadding.p3)
                .padding(.trailing, StorePadding.p3)
            }
        }
    }
}

private extension StoreConnectWPComCard {
    typealias Localization = ConnectWPComCard.Localization

    enum Layout {
        static let iconSize: CGFloat = 35
    }
}
