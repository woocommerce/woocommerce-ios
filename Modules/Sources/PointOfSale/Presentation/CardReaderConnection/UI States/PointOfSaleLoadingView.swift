import SwiftUI
import struct WooFoundationCore.WooAnalyticsEvent

struct PointOfSaleLoadingView: View {
    @Environment(\.posAnalytics) private var analytics

    private let isCatalogSyncing: Bool
    private let onExit: (() -> Void)?

    init(isCatalogSyncing: Bool = false, onExit: (() -> Void)? = nil) {
        self.isCatalogSyncing = isCatalogSyncing
        self.onExit = onExit
    }

    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            VStack(alignment: .center) {
                Spacer()
                ProgressView()
                    .progressViewStyle(POSProgressViewStyle())

                if isCatalogSyncing {
                    Spacer().frame(height: POSSpacing.large * 2)
                    Text(Localization.syncingTitle)
                        .font(.posHeadingBold)
                    Spacer()
                    VStack(spacing: POSSpacing.medium) {
                        Button {
                            analytics.track(event: WooAnalyticsEvent.LocalCatalog.downloadingScreenExitPosTapped())
                            onExit?()
                        } label: {
                            Text(Localization.exitButtonTitle)
                                .font(.posBodySmallBold(underline: true))
                                .foregroundStyle(Color.posOnSurface)
                        }

                        Text(Localization.exitButtonDescription)
                            .font(.posCaptionRegular)
                            .foregroundStyle(Color.posOnSurfaceVariantLowest)
                    }
                    .padding(.bottom, POSPadding.large)
                } else {
                    Spacer()
                }
            }
            .multilineTextAlignment(.center)
            Spacer()
        }
        .background(Color.posSurface)
        .task {
            if isCatalogSyncing {
                analytics.track(event: WooAnalyticsEvent.LocalCatalog.downloadingScreenShown())
            }
        }
    }
}

#Preview {
    PointOfSaleLoadingView()
}

#Preview("Catalog Syncing") {
    PointOfSaleLoadingView(isCatalogSyncing: true) {}
}

private extension PointOfSaleLoadingView {
    struct Localization {
        static let syncingTitle = NSLocalizedString(
            "pointOfSale.catalogLoadingView.title",
            value: "Syncing catalog",
            comment: "A title of a full screen view that is displayed while the POS catalog is being synced."
        )

        static let exitButtonTitle = NSLocalizedString(
            "pointOfSale.catalogLoadingView.exitButton.title",
            value: "Exit POS",
            comment: "A button that exits POS."
        )

        static let exitButtonDescription = NSLocalizedString(
            "pointOfSale.catalogLoadingView.exitButton.description",
            value: "Syncing will continue in the background.",
            comment: "A description within a full screen loading view for POS catalog."
        )
    }
}
