import Foundation
import protocol WooFoundation.Analytics

/// A view model for `AnalyticsReportLink`, which opens an authenticated webview to show an analytics report in wp-admin.
final class AnalyticsReportLinkViewModel: WPAdminWebViewModel {
    /// Type of report being linked to
    ///
    let reportType: AnalyticsWebReport.ReportType

    /// Selected time range for the report
    ///
    let period: AnalyticsHubTimeRangeSelection.SelectionType

    private let analytics: Analytics
    private let usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter

    init(reportType: AnalyticsWebReport.ReportType,
         period: AnalyticsHubTimeRangeSelection.SelectionType,
         webViewTitle: String,
         reportURL: URL,
         usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter,
         analytics: Analytics = ServiceLocator.analytics) {
        self.reportType = reportType
        self.period = period
        self.analytics = analytics
        self.usageTracksEventEmitter = usageTracksEventEmitter
        super.init(title: webViewTitle, initialURL: reportURL)
    }

    /// Action to take when the report webview is opened
    ///
    func onWebViewOpen(at interactionTime: Date = Date()) {
        analytics.track(event: .AnalyticsHub.viewFullReportTapped(for: reportType, period: period))
        usageTracksEventEmitter.interacted(at: interactionTime)
    }
}
