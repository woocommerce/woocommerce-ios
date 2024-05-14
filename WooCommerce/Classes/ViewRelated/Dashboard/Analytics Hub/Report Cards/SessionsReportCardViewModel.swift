import Foundation
import Yosemite
import protocol WooFoundation.Analytics

final class SessionsReportCardViewModel: AnalyticsReportCardProtocol {
    private let siteID: Int64
    private let stores: StoresManager
    private let analytics: Analytics
    private let noticePresenter: NoticePresenter

    /// Delay to allow the backend to process enabling the Jetpack Stats module.
    /// Defaults to 0.5 seconds.
    private let backendProcessingDelay: UInt64

    /// Order stats for the current period
    ///
    private var currentOrderStats: OrderStatsV4?

    /// Site Summary Stats for the current period
    ///
    private var siteStats: SiteSummaryStats?

    /// Selected time range
    ///
    private var timeRange: AnalyticsHubTimeRangeSelection.SelectionType

    /// Whether the Jetpack Stats module is disabled
    ///
    private var isJetpackStatsDisabled: Bool

    /// User is an administrator on the store
    ///
    private let userIsAdmin: Bool

    /// Whether to show the call to action to enable Jetpack Stats.
    ///
    var showJetpackStatsCTA: Bool {
        isJetpackStatsDisabled && userIsAdmin
    }

    /// Whether sessions data is available to display; `false` if the time range is custom.
    ///
    var isSessionsDataAvailable: Bool {
        if case .custom = timeRange {
            return false
        } else {
            return true
        }
    }

    /// Indicates if the values should be hidden (for loading state)
    ///
    var isRedacted: Bool

    /// Callback if site stats data needs to be updated
    ///
    var updateSiteStatsData: (() async -> Void)

    init(siteID: Int64,
         currentOrderStats: OrderStatsV4?,
         siteStats: SiteSummaryStats?,
         timeRange: AnalyticsHubTimeRangeSelection.SelectionType,
         isJetpackStatsDisabled: Bool,
         isRedacted: Bool = false,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         noticePresenter: NoticePresenter = ServiceLocator.noticePresenter,
         backendProcessingDelay: UInt64 = 500_000_000,
         updateSiteStatsData: @escaping () async -> Void) {
        self.siteID = siteID
        self.currentOrderStats = currentOrderStats
        self.siteStats = siteStats
        self.timeRange = timeRange
        self.isJetpackStatsDisabled = isJetpackStatsDisabled
        self.userIsAdmin = stores.sessionManager.defaultRoles.contains(.administrator)
        self.isRedacted = isRedacted
        self.stores = stores
        self.analytics = analytics
        self.noticePresenter = noticePresenter
        self.backendProcessingDelay = backendProcessingDelay
        self.updateSiteStatsData = updateSiteStatsData
    }
}

// MARK: Jetpack Stats
extension SessionsReportCardViewModel {
    /// Tracks when the call to action to enable Jetpack Stats is shown.
    ///
    func trackJetpackStatsCTAShown() {
        analytics.track(event: .AnalyticsHub.jetpackStatsCTAShown())
    }

    /// Enables the Jetpack Stats module on the store and requests new stats data
    ///
    @MainActor
    func enableJetpackStats() async {
        analytics.track(event: .AnalyticsHub.jetpackStatsCTATapped())

        do {
            try await remoteEnableJetpackStats()
            // Wait for backend to enable the module (it is not ready for stats to be requested immediately after a success response)
            try await Task.sleep(nanoseconds: backendProcessingDelay)
            await updateSiteStatsData()
        } catch {
            noticePresenter.enqueue(notice: .init(title: Localization.statsCTAError))
            DDLogError("⚠️ Error enabling Jetpack Stats: \(error)")
        }
    }

    @MainActor
    /// Makes the remote request to enable the Jetpack Stats module on the site.
    ///
    private func remoteEnableJetpackStats() async throws {
        try await withCheckedThrowingContinuation { continuation in
            let action = JetpackSettingsAction.enableJetpackModule(.stats, siteID: siteID) { [weak self] result in
                switch result {
                case .success:
                    self?.isJetpackStatsDisabled = false
                    self?.analytics.track(event: .AnalyticsHub.enableJetpackStatsSuccess())
                    continuation.resume()
                case let .failure(error):
                    self?.isJetpackStatsDisabled = true
                    self?.analytics.track(event: .AnalyticsHub.enableJetpackStatsFailed(error: error))
                    continuation.resume(throwing: error)
                }
            }
            stores.dispatch(action)
        }
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
        static let statsCTAError = NSLocalizedString("analyticsHub.jetpackStatsCTA.errorNotice",
                                                     value: "We couldn't enable Jetpack Stats on your store",
                                                     comment: "Error shown when Jetpack Stats can't be enabled in the Analytics Hub.")
    }
}

// MARK: - Methods for rendering a SwiftUI Preview
//
extension SessionsReportCardViewModel {
    static func sampleOrderStats() -> OrderStatsV4 {
        let sampleTotals = OrderStatsV4Totals(totalOrders: 5,
                                              totalItemsSold: 5,
                                              grossRevenue: 500,
                                              netRevenue: 500,
                                              averageOrderValue: 100)
        return OrderStatsV4(siteID: 123,
                            granularity: .daily,
                            totals: sampleTotals,
                            intervals: [OrderStatsV4Interval(interval: "Hour",
                                                             dateStart: "Day",
                                                             dateEnd: "Day",
                                                             subtotals: sampleTotals)])
    }

    static func sampleSiteStats() -> SiteSummaryStats {
        SiteSummaryStats(siteID: 123,
                         date: "Day",
                         period: .day,
                         visitors: 8,
                         views: 40)
    }
}
