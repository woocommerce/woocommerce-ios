import Foundation
import Yosemite

final class RevenueReportCardViewModel: AnalyticsReportCardProtocol {
    let title: String = Localization.title

    var leadingMetric: AnalyticsReportCardMetric

    var trailingMetric: AnalyticsReportCardMetric

    var isRedacted: Bool = false

    var showSyncError: Bool

    let syncErrorMessage: String = Localization.noRevenue

    var reportViewModel: AnalyticsReportLinkViewModel?

    init(currentOrderStats: OrderStatsV4?,
         previousOrderStats: OrderStatsV4?,
         timeRange: AnalyticsHubTimeRangeSelection.SelectionType,
         usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter,
         storeAdminURL: String? = ServiceLocator.stores.sessionManager.defaultSite?.adminURL) {
        leadingMetric = RevenueReportCardViewModel.createLeadingMetric(currentPeriodStats: currentOrderStats, previousPeriodStats: previousOrderStats)
        trailingMetric = RevenueReportCardViewModel.createTrailingMetric(currentPeriodStats: currentOrderStats, previousPeriodStats: previousOrderStats)
        showSyncError = currentOrderStats == nil || previousOrderStats == nil
        reportViewModel = RevenueReportCardViewModel.createReportViewModel(timeRange: timeRange,
                                                                  storeAdminURL: storeAdminURL,
                                                                  usageTracksEventEmitter: usageTracksEventEmitter)
    }
}

private extension RevenueReportCardViewModel {
    static func createLeadingMetric(currentPeriodStats: OrderStatsV4?, previousPeriodStats: OrderStatsV4?) -> AnalyticsReportCardMetric {
        AnalyticsReportCardMetric(title: Localization.leadingTitle,
                                  value: StatsDataTextFormatter.createTotalRevenueText(orderStats: currentPeriodStats,
                                                                                       selectedIntervalIndex: nil),
                                  delta: StatsDataTextFormatter.createTotalRevenueDelta(from: previousPeriodStats, to: currentPeriodStats),
                                  chartData: StatsIntervalDataParser.getChartData(for: .totalRevenue, from: currentPeriodStats))
    }

    static func createTrailingMetric(currentPeriodStats: OrderStatsV4?, previousPeriodStats: OrderStatsV4?) -> AnalyticsReportCardMetric {
        AnalyticsReportCardMetric(title: Localization.trailingTitle,
                                  value: StatsDataTextFormatter.createNetRevenueText(orderStats: currentPeriodStats),
                                  delta: StatsDataTextFormatter.createNetRevenueDelta(from: previousPeriodStats, to: currentPeriodStats),
                                  chartData: StatsIntervalDataParser.getChartData(for: .netRevenue, from: currentPeriodStats))
    }

    static func createReportViewModel(timeRange: AnalyticsHubTimeRangeSelection.SelectionType,
                                      storeAdminURL: String?,
                                      usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter) -> AnalyticsReportLinkViewModel? {
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
