import Foundation
import class UIKit.UIColor
import Yosemite

/// Analytics Hub Products Stats Card ViewModel.
/// Used to transmit analytics products data.
///
final class AnalyticsProductsStatsCardViewModel {
    /// Order stats for the current period
    ///
    private var currentPeriodStats: OrderStatsV4?

    /// Order stats for the previous period
    ///
    private var previousPeriodStats: OrderStatsV4?

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

    init(currentPeriodStats: OrderStatsV4?,
         previousPeriodStats: OrderStatsV4?,
         timeRange: AnalyticsHubTimeRangeSelection.SelectionType,
         isRedacted: Bool = false,
         usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter,
         storeAdminURL: String? = ServiceLocator.stores.sessionManager.defaultSite?.adminURL) {
        self.currentPeriodStats = currentPeriodStats
        self.previousPeriodStats = previousPeriodStats
        self.timeRange = timeRange
        self.isRedacted = isRedacted
        self.usageTracksEventEmitter = usageTracksEventEmitter
        self.storeAdminURL = storeAdminURL
    }
}

/// Analytics Hub Items Sold ViewModel.
/// Used to store top performing products data.
///
final class AnalyticsItemsSoldViewModel {

    /// Stats for the current top items sold.
    ///
    private var itemsSoldStats: TopEarnerStats?

    /// Indicates if the values should be hidden (for loading state)
    ///
    var isRedacted: Bool

    init(itemsSoldStats: TopEarnerStats?,
         isRedacted: Bool = false) {
        self.itemsSoldStats = itemsSoldStats
        self.isRedacted = isRedacted
    }
}

extension AnalyticsProductsStatsCardViewModel {

    /// Card Title
    ///
    var title: String {
        Localization.title
    }

    /// Items Sold Title
    ///
    var itemsSoldTitle: String {
        Localization.itemsSold
    }

    /// Items Sold Value
    ///
    var itemsSold: String {
        isRedacted ? "1000" : StatsDataTextFormatter.createItemsSoldText(orderStats: currentPeriodStats)
    }

    /// Items Sold Delta Percentage
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

    /// Error message to display if there was an error loading stats part of the card.
    ///
    var statsErrorMessage: String {
        Localization.noProducts
    }

    /// View model for the web analytics report link
    ///
    var reportViewModel: AnalyticsReportLinkViewModel? {
        guard let url = AnalyticsWebReport.getUrl(for: .products, timeRange: timeRange, storeAdminURL: storeAdminURL) else {
            return nil
        }
        return AnalyticsReportLinkViewModel(reportType: .products,
                                            period: timeRange,
                                            webViewTitle: Localization.reportTitle,
                                            reportURL: url,
                                            usageTracksEventEmitter: usageTracksEventEmitter)
    }
}

extension AnalyticsItemsSoldViewModel {

    /// Items Solds data to render.
    ///
    var itemsSoldData: [TopPerformersRow.Data] {
        isRedacted ? [.init(imageURL: nil, name: "Product Name", details: "Net Sales", value: "$5678")] : itemSoldRows(from: itemsSoldStats)
    }

    /// Indicates if there was an error loading items sold part of the card.
    ///
    var showItemsSoldError: Bool {
        isRedacted ? false : itemsSoldStats == nil
    }

    /// Error message if there was an error loading items sold part of the card.
    ///
    var itemsSoldErrorMessage: String {
        Localization.noItemsSold
    }

    /// Helper functions to create `TopPerformersRow.Data` items rom the provided `TopEarnerStats`.
    ///
    private func itemSoldRows(from itemSoldStats: TopEarnerStats?) -> [TopPerformersRow.Data] {
        guard let items = itemSoldStats?.items else {
            return []
        }

        return items.map { item in
            TopPerformersRow.Data(imageURL: URL(string: item.imageUrl ?? ""),
                                  name: item.productName ?? "",
                                  details: Localization.netSales(value: item.totalString),
                                  value: "\(item.quantity)")
        }
    }
}

/// Convenience extension to create an `AnalyticsItemsSoldCard` from a view model.
///
extension AnalyticsTopPerformersCard {
    init(statsViewModel: AnalyticsProductsStatsCardViewModel, itemsViewModel: AnalyticsItemsSoldViewModel) {
        // Header with stats
        self.title = statsViewModel.title
        self.statTitle = statsViewModel.itemsSoldTitle
        self.statValue = statsViewModel.itemsSold
        self.delta = statsViewModel.delta.string
        self.deltaBackgroundColor = statsViewModel.delta.direction.deltaBackgroundColor
        self.deltaTextColor = statsViewModel.delta.direction.deltaTextColor
        self.isStatsRedacted = statsViewModel.isRedacted
        self.showStatsError = statsViewModel.showStatsError
        self.statsErrorMessage = statsViewModel.statsErrorMessage
        self.reportViewModel = statsViewModel.reportViewModel

        // Top performers list
        self.topPerformersTitle = statsViewModel.title
        self.topPerformersData = itemsViewModel.itemsSoldData
        self.isTopPerformersRedacted = itemsViewModel.isRedacted
        self.showTopPerformersError = itemsViewModel.showItemsSoldError
        self.topPerformersErrorMessage = itemsViewModel.itemsSoldErrorMessage
    }
}

// MARK: Constants
private extension AnalyticsProductsStatsCardViewModel {
    enum Localization {
        static let reportTitle = NSLocalizedString("analyticsHub.productCard.reportTitle",
                                                   value: "Products Report",
                                                   comment: "Title for the products analytics report linked in the Analytics Hub")
        static let title = NSLocalizedString("Products", comment: "Title for the products card on the analytics hub screen.").localizedUppercase
        static let itemsSold = NSLocalizedString("Items Sold", comment: "Title for the items sold column on the products card on the analytics hub screen.")
        static let noProducts = NSLocalizedString("Unable to load product analytics",
                                                  comment: "Text displayed when there is an error loading product stats data.")
    }
}

private extension AnalyticsItemsSoldViewModel {
    enum Localization {
        static func netSales(value: String) -> String {
            String.localizedStringWithFormat(NSLocalizedString("Net sales: %@", comment: "Label for the total sales of a product in the Analytics Hub"),
                                             value)
        }
        static let noItemsSold = NSLocalizedString("Unable to load product items sold analytics",
                                                   comment: "Text displayed when there is an error loading items sold stats data.")
    }
}
