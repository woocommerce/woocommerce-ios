import Foundation
import class UIKit.UIColor
import Yosemite

/// Analytics Hub Product Bundles Card ViewModel.
/// Used to transmit product bundles analytics data.
///
final class AnalyticsBundlesReportCardViewModel {
    /// Product bundle stats for the current period
    ///
    private var currentPeriodStats: ProductBundleStats?

    /// Product bundle stats for the previous period
    ///
    private var previousPeriodStats: ProductBundleStats?

    /// List of the current top bundles sold.
    ///
    private var bundlesSoldReport: [ProductsReportItem]?

    /// Selected time range
    ///
    private var timeRange: AnalyticsHubTimeRangeSelection.SelectionType

    /// Analytics Usage Tracks Event Emitter
    ///
    private let usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter

    /// Store admin URL
    ///
    private let storeAdminURL: String?

    /// Indicates if the values should be hidden (for loading state)
    ///
    var isRedacted: Bool

    init(currentPeriodStats: ProductBundleStats?,
         previousPeriodStats: ProductBundleStats?,
         bundlesSoldReport: [ProductsReportItem]?,
         timeRange: AnalyticsHubTimeRangeSelection.SelectionType,
         isRedacted: Bool = false,
         usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter,
         storeAdminURL: String? = ServiceLocator.stores.sessionManager.defaultSite?.adminURL) {
        self.currentPeriodStats = currentPeriodStats
        self.previousPeriodStats = previousPeriodStats
        self.bundlesSoldReport = bundlesSoldReport
        self.timeRange = timeRange
        self.isRedacted = isRedacted
        self.usageTracksEventEmitter = usageTracksEventEmitter
        self.storeAdminURL = storeAdminURL
    }
}

extension AnalyticsBundlesReportCardViewModel {

    /// Card Title
    ///
    var title: String {
        Localization.title
    }

    // MARK: Bundles Sold Stats

    /// Bundles Sold Title
    ///
    var bundlesSoldTitle: String {
        Localization.bundlesSold
    }

    /// Bundles Sold Value
    ///
    var bundlesSold: String {
        isRedacted ? "1000" : StatsDataTextFormatter.createBundlesSoldText(bundleStats: currentPeriodStats)
    }

    /// Bundles Sold Delta Percentage
    ///
    var delta: DeltaPercentage {
        isRedacted ? DeltaPercentage(string: "0%", direction: .zero)
        : StatsDataTextFormatter.createDelta(for: .totalItemsSold, from: previousPeriodStats, to: currentPeriodStats)
    }

    /// Indicates if there was an error loading stats part of the card.
    ///
    var showStatsError: Bool {
        isRedacted ? false : currentPeriodStats == nil || previousPeriodStats == nil
    }

    /// Error message if there was an error loading stats part of the card.
    ///
    var statsErrorMessage: String {
        Localization.noBundles
    }

    // MARK: Bundles Sold Report

    /// Bundles Solds data to render.
    ///
    var bundlesSoldData: [TopPerformersRow.Data] {
        isRedacted ? [.init(imageURL: nil, name: "Product Name", details: "Net Sales", value: "$5678")] : bundlesSoldRows(from: bundlesSoldReport)
    }

    /// Indicates if there was an error loading items sold part of the card.
    ///
    var showBundlesSoldError: Bool {
        isRedacted ? false : bundlesSoldReport == nil
    }

    /// Error message if there was an error loading items sold part of the card.
    ///
    var bundlesSoldErrorMessage: String {
        Localization.noBundlesSold
    }

    /// View model for the web analytics report link
    ///
    var reportViewModel: AnalyticsReportLinkViewModel? {
        guard let url = AnalyticsWebReport.getUrl(for: .bundles, timeRange: timeRange, storeAdminURL: storeAdminURL) else {
            return nil
        }
        return AnalyticsReportLinkViewModel(reportType: .bundles,
                                            period: timeRange,
                                            webViewTitle: Localization.reportTitle,
                                            reportURL: url,
                                            usageTracksEventEmitter: usageTracksEventEmitter)
    }

    /// Helper functions to create `TopPerformersRow.Data` items rom the provided `ProductsReportItem`.
    ///
    private func bundlesSoldRows(from bundlesSold: [ProductsReportItem]?) -> [TopPerformersRow.Data] {
        guard let bundlesSold else {
            return []
        }

        return bundlesSold.map { bundle in
            TopPerformersRow.Data(imageURL: URL(string: bundle.imageUrl ?? ""),
                                  name: bundle.productName,
                                  details: Localization.netSales(value: bundle.totalString),
                                  value: bundle.quantity.description)
        }
    }
}

/// Convenience extension to create an `AnalyticsItemsSoldCard` from a view model.
///
extension AnalyticsTopPerformersCard {
    init(bundlesViewModel: AnalyticsBundlesReportCardViewModel) {
        // Header with stats
        self.title = bundlesViewModel.title
        self.statTitle = bundlesViewModel.bundlesSoldTitle
        self.statValue = bundlesViewModel.bundlesSold
        self.delta = bundlesViewModel.delta.string
        self.deltaBackgroundColor = bundlesViewModel.delta.direction.deltaBackgroundColor
        self.deltaTextColor = bundlesViewModel.delta.direction.deltaTextColor
        self.isStatsRedacted = bundlesViewModel.isRedacted
        self.showStatsError = bundlesViewModel.showStatsError
        self.statsErrorMessage = bundlesViewModel.statsErrorMessage
        self.reportViewModel = bundlesViewModel.reportViewModel

        // Top performers list
        self.topPerformersTitle = bundlesViewModel.title
        self.topPerformersData = bundlesViewModel.bundlesSoldData
        self.isTopPerformersRedacted = bundlesViewModel.isRedacted
        self.showTopPerformersError = bundlesViewModel.showBundlesSoldError
        self.topPerformersErrorMessage = bundlesViewModel.bundlesSoldErrorMessage
    }
}

// MARK: Constants
private extension AnalyticsBundlesReportCardViewModel {
    enum Localization {
        static let reportTitle = NSLocalizedString("analyticsHub.bundlesCard.reportTitle",
                                                   value: "Product Bundles Report",
                                                   comment: "Title for the product bundles analytics report linked in the Analytics Hub")
        static let title = NSLocalizedString("Bundles", comment: "Title for the product bundles card on the analytics hub screen.").localizedUppercase
        static let bundlesSold = NSLocalizedString("Bundles Sold",
                                                   comment: "Title for the bundles sold column on the product bundles card on the analytics hub screen.")
        static let noBundles = NSLocalizedString("Unable to load product bundle analytics",
                                                 comment: "Text displayed when there is an error loading product bundles stats data.")
        static let noBundlesSold = NSLocalizedString("Unable to load product bundles sold analytics",
                                                     comment: "Text displayed when there is an error loading product bundles sold stats data.")
        static func netSales(value: String) -> String {
            String.localizedStringWithFormat(NSLocalizedString("Net sales: %@", comment: "Label for the total sales of a product in the Analytics Hub"),
                                             value)
        }
    }
}
