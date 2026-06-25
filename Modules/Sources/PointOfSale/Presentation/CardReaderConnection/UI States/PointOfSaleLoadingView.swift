import SwiftUI
import enum Yosemite.POSCatalogSyncProgress
import struct WooFoundationCore.WooAnalyticsEvent

struct PointOfSaleLoadingView: View {
    @Environment(\.posAnalytics) private var analytics

    private let catalogSyncState: POSCatalogSyncViewState?
    private let onExit: (() -> Void)?

    init(catalogSyncState: POSCatalogSyncViewState? = nil, onExit: (() -> Void)? = nil) {
        self.catalogSyncState = catalogSyncState
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
                    Spacer().frame(height: POSSpacing.xLarge)
                    Text(Localization.syncingCatalogTitle)
                        .font(.posHeadingBold)
                    if let progressText {
                        Text(progressText)
                            .font(.posBodyMediumRegular())
                            .foregroundStyle(Color.posOnSurfaceVariantLowest)
                            .padding(.top, POSSpacing.small)
                    }
                    Spacer()
                    VStack(spacing: POSSpacing.medium) {
                        Button {
                            analytics.track(event: WooAnalyticsEvent.LocalCatalog.downloadingScreenExitPosTapped())
                            onExit?()
                        } label: {
                            Text(Localization.syncingCatalogExitButtonTitle)
                                .font(.posBodySmallRegular(underline: true))
                                .foregroundStyle(Color.posOnSurface)
                        }

                        syncingCatalogHintView
                    }
                    .padding(.bottom, POSPadding.xLarge)
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
    PointOfSaleLoadingView(catalogSyncState: POSCatalogSyncViewState()) {}
}

#Preview("Catalog Sync Progress") {
    PointOfSaleLoadingView(catalogSyncState: POSCatalogSyncViewState(progress: .itemCount(processed: 131, total: 4512))) {}
}

private extension PointOfSaleLoadingView {
    var isCatalogSyncing: Bool {
        catalogSyncState != nil
    }

    var progressText: String? {
        guard let progress = catalogSyncState?.progress else {
            return nil
        }

        switch progress {
        case .preparing:
            return Localization.syncingCatalogPreparing
        case .itemCount(let processed, let total):
            return String.localizedStringWithFormat(Localization.syncingCatalogProgressFormat, processed, total)
        }
    }

    var syncingCatalogHintView: some View {
        VStack(spacing: POSSpacing.xSmall) {
            Text(Localization.syncingCatalogHint)
            Text(Localization.syncingCatalogSubtitle)
        }
        .font(.posBodyMediumRegular())
        .foregroundStyle(Color.posOnSurfaceVariantLowest)
        .padding(.horizontal, POSPadding.xLarge)
    }

    struct Localization {
        static let syncingCatalogTitle = NSLocalizedString(
            "pointOfSale.catalogLoadingView.title",
            value: "Syncing catalog",
            comment: "A title of a full screen view that is displayed while the POS catalog is being synced."
        )

        static let syncingCatalogPreparing = NSLocalizedString(
            "pointOfSale.catalogLoadingView.preparing",
            value: "Preparing catalog...",
            comment: "Progress text shown while the POS catalog is being prepared before item counts are available."
        )

        static let syncingCatalogProgressFormat = NSLocalizedString(
            "pointOfSale.catalogLoadingView.itemCountFormat",
            value: "%1$ld of %2$ld items",
            comment: "Progress text for POS catalog sync. %1$ld is the number of catalog items processed, %2$ld is the total number of catalog items."
        )

        static let syncingCatalogExitButtonTitle = NSLocalizedString(
            "pointOfSale.catalogLoadingView.exitButton.title",
            value: "Exit POS",
            comment: "A button that exits POS."
        )

        static let syncingCatalogHint = NSLocalizedString(
            "pointOfSale.catalogLoadingView.hint",
            value: "Catalog syncing may take a few minutes.",
            comment: "A hint within a full screen loading view for POS catalog."
        )

        static let syncingCatalogSubtitle = NSLocalizedString(
            "pointOfSale.catalogLoadingView.backgroundSyncSubtitle",
            value: "You can leave and syncing will continue in the background.",
            comment: "A description shown below the Exit POS button while the POS catalog is syncing."
        )
    }
}
