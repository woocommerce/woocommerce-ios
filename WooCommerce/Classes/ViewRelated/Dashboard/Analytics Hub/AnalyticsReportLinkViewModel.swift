import Foundation

/// A view model for `AnalyticsReportLink`, which opens an authenticated webview to show an analytics report in wp-admin.
final class AnalyticsReportLinkViewModel: WPAdminWebViewModel {
    /// Type of report being linked to
    ///
    let reportType: AnalyticsWebReport.ReportType

    /// Selected time range for the report
    ///
    let period: AnalyticsHubTimeRangeSelection.SelectionType

    private let analytics: Analytics

    init(reportType: AnalyticsWebReport.ReportType,
         period: AnalyticsHubTimeRangeSelection.SelectionType,
         webViewTitle: String,
         reportURL: URL,
         analytics: Analytics = ServiceLocator.analytics) {
        self.reportType = reportType
        self.period = period
        self.analytics = analytics
        super.init(title: webViewTitle, initialURL: reportURL)
    }

    /// Action to take when the report webview is opened
    ///
    func onWebViewOpen() {
        // no-op
    }
}
