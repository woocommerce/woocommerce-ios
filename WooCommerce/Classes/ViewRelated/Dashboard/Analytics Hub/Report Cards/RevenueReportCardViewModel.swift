import Foundation
import Yosemite

final class RevenueReportCardViewModel: AnalyticsReportCardProtocol {
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

extension RevenueReportCardViewModel {

    var title: String {
        Localization.title
    }

    // MARK: Total Revenue metric

    var leadingTitle: String {
        Localization.leadingTitle
    }

    var leadingValue: String {
        isRedacted ? "$1000" : StatsDataTextFormatter.createTotalRevenueText(orderStats: currentPeriodStats, selectedIntervalIndex: nil)
    }

    var leadingDelta: DeltaPercentage? {
        isRedacted ? DeltaPercentage(string: "0%", direction: .zero)
        : StatsDataTextFormatter.createDelta(for: .grossRevenue, from: previousPeriodStats, to: currentPeriodStats)
    }

    var leadingChartData: [Double] {
        isRedacted ? [] : StatsIntervalDataParser.getChartData(for: OrderStatsV4Totals.TotalData.grossRevenue, from: currentPeriodStats)
    }

    // MARK: Net Revenue metric

    var trailingTitle: String {
        Localization.trailingTitle
    }

    var trailingValue: String {
        isRedacted ? "$1000" : StatsDataTextFormatter.createNetRevenueText(orderStats: currentPeriodStats)
    }

    var trailingDelta: DeltaPercentage? {
        isRedacted ? DeltaPercentage(string: "0%", direction: .zero)
        : StatsDataTextFormatter.createDelta(for: .netRevenue, from: previousPeriodStats, to: currentPeriodStats)
    }

    var trailingChartData: [Double] {
        isRedacted ? [] : StatsIntervalDataParser.getChartData(for: .netRevenue, from: currentPeriodStats)
    }

    var showSyncError: Bool {
        isRedacted ? false : currentPeriodStats == nil || previousPeriodStats == nil
    }

    var syncErrorMessage: String {
        Localization.noRevenue
    }

    var reportViewModel: AnalyticsReportLinkViewModel? {
        guard let url = AnalyticsWebReport.getUrl(for: .revenue, timeRange: timeRange, storeAdminURL: storeAdminURL) else {
            return nil
        }
        return AnalyticsReportLinkViewModel(reportType: .revenue,
                                            period: timeRange,
                                            webViewTitle: Localization.reportTitle,
                                            reportURL: url,
                                            usageTracksEventEmitter: usageTracksEventEmitter)
    }
}

// MARK: Constants
private extension RevenueReportCardViewModel {
    enum Localization {
        static let title = NSLocalizedString("REVENUE", comment: "Title for revenue analytics section in the Analytics Hub")
        static let leadingTitle = NSLocalizedString("Total Sales", comment: "Label for total sales (gross revenue) in the Analytics Hub")
        static let trailingTitle = NSLocalizedString("Net Sales", comment: "Label for net sales (net revenue) in the Analytics Hub")
        static let noRevenue = NSLocalizedString("Unable to load revenue analytics",
                                                 comment: "Text displayed when there is an error loading revenue stats data.")
        static let reportTitle = NSLocalizedString("analyticsHub.revenueCard.reportTitle",
                                                   value: "Revenue Report",
                                                   comment: "Title for the revenue analytics report linked in the Analytics Hub")
    }
}
