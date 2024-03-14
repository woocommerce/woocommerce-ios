import Foundation
import Yosemite

final class SessionsReportCardViewModel: AnalyticsReportCardProtocol {

    /// Order stats for the current period
    ///
    private var currentOrderStats: OrderStatsV4?

    /// Site Summary Stats for the current period
    ///
    private var siteStats: SiteSummaryStats?

    /// Indicates if the values should be hidden (for loading state)
    ///
    var isRedacted: Bool

    init(currentOrderStats: OrderStatsV4?,
         siteStats: SiteSummaryStats?,
         isRedacted: Bool = false) {
        self.currentOrderStats = currentOrderStats
        self.siteStats = siteStats
        self.isRedacted = isRedacted
    }

    func redact() {
        isRedacted = true
    }

    /// Updates the stats used in the card metrics.
    ///
    func update(currentOrderStats: OrderStatsV4?, siteStats: SiteSummaryStats?) {
        self.currentOrderStats = currentOrderStats
        self.siteStats = siteStats
        isRedacted = false
    }
}

// MARK: AnalyticsReportCardProtocol conformance

extension SessionsReportCardViewModel {

    var title: String {
        Localization.title
    }

    // MARK: Views metric

    var leadingTitle: String {
        Localization.leadingTitle
    }

    var leadingValue: String {
        isRedacted ? "1000" : StatsDataTextFormatter.createViewsCountText(siteStats: siteStats)
    }

    var leadingDelta: DeltaPercentage? {
        nil
    }

    var leadingChartData: [Double] {
        []
    }

    // MARK: Conversion Rate metric

    var trailingTitle: String {
        Localization.trailingTitle
    }

    var trailingValue: String {
        isRedacted ? "1000%" : StatsDataTextFormatter.createConversionRateText(orderStats: currentOrderStats, siteStats: siteStats)
    }

    var trailingDelta: DeltaPercentage? {
        nil
    }

    var trailingChartData: [Double] {
        []
    }

    var showSyncError: Bool {
        isRedacted ? false : currentOrderStats == nil || siteStats == nil
    }

    var syncErrorMessage: String {
        Localization.noSessions
    }

    var reportViewModel: AnalyticsReportLinkViewModel? {
        nil
    }
}

// MARK: Constants
private extension SessionsReportCardViewModel {
    enum Localization {
        static let title = NSLocalizedString("SESSIONS", comment: "Title for sessions section in the Analytics Hub")
        static let leadingTitle = NSLocalizedString("Views", comment: "Label for total store views in the Analytics Hub")
        static let trailingTitle = NSLocalizedString("Conversion Rate", comment: "Label for the conversion rate (orders per visitor) in the Analytics Hub")
        static let noSessions = NSLocalizedString("Unable to load session analytics",
                                                  comment: "Text displayed when there is an error loading session stats data.")
    }
}
