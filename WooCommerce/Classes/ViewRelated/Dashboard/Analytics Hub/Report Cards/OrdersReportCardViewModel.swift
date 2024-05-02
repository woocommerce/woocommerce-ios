import Foundation
import Yosemite

final class OrdersReportCardViewModel: AnalyticsReportCardProtocol {
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

// MARK: AnalyticsReportCardProtocol conformance

extension OrdersReportCardViewModel {

    var title: String {
        Localization.title
    }

    // MARK: Total Orders metric

    var leadingTitle: String {
        Localization.leadingTitle
    }

    var leadingValue: String {
        isRedacted ? "$1000" : StatsDataTextFormatter.createOrderCountText(orderStats: currentPeriodStats, selectedIntervalIndex: nil)
    }

    var leadingDelta: DeltaPercentage? {
        isRedacted ? DeltaPercentage(string: "0%", direction: .zero)
        : StatsDataTextFormatter.createDelta(for: .totalOrders, from: previousPeriodStats, to: currentPeriodStats)
    }

    var leadingChartData: [Double] {
        isRedacted ? [] : StatsIntervalDataParser.getChartData(for: .totalOrders, from: currentPeriodStats)
    }

    // MARK: Average Order Value metric

    var trailingTitle: String {
        Localization.trailingTitle
    }

    var trailingValue: String {
        isRedacted ? "$1000" : StatsDataTextFormatter.createAverageOrderValueText(orderStats: currentPeriodStats)
    }

    var trailingDelta: DeltaPercentage? {
        isRedacted ? DeltaPercentage(string: "0%", direction: .zero)
        : StatsDataTextFormatter.createDelta(for: .averageOrderValue, from: previousPeriodStats, to: currentPeriodStats)
    }

    var trailingChartData: [Double] {
        isRedacted ? [] : StatsIntervalDataParser.getChartData(for: .averageOrderValue, from: currentPeriodStats)
    }

    var showSyncError: Bool {
        isRedacted ? false : currentPeriodStats == nil || previousPeriodStats == nil
    }

    var syncErrorMessage: String {
        Localization.noOrders
    }

    var reportViewModel: AnalyticsReportLinkViewModel? {
        guard let url = AnalyticsWebReport.getUrl(for: .orders, timeRange: timeRange, storeAdminURL: storeAdminURL) else {
            return nil
        }
        return AnalyticsReportLinkViewModel(reportType: .orders,
                                            period: timeRange,
                                            webViewTitle: Localization.reportTitle,
                                            reportURL: url,
                                            usageTracksEventEmitter: usageTracksEventEmitter)
    }
}

// MARK: Constants
private extension OrdersReportCardViewModel {
    enum Localization {
        static let title = NSLocalizedString("ORDERS", comment: "Title for order analytics section in the Analytics Hub")
        static let leadingTitle = NSLocalizedString("Total Orders", comment: "Label for total number of orders in the Analytics Hub")
        static let trailingTitle = NSLocalizedString("Average Order Value", comment: "Label for average value of orders in the Analytics Hub")
        static let noOrders = NSLocalizedString("Unable to load order analytics",
                                                comment: "Text displayed when there is an error loading order stats data.")
        static let reportTitle = NSLocalizedString("analyticsHub.orderCard.reportTitle",
                                                   value: "Orders Report",
                                                   comment: "Title for the orders analytics report linked in the Analytics Hub")
    }
}
