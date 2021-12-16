import Foundation

/// View model for `SystemStatusReportView`
///
final class SystemStatusReportViewModel: ObservableObject {
    /// ID of the site to fetch system status report for
    ///
    private let siteID: Int64

    /// Formatted system status report to be displayed on-screen
    ///
    @Published private(set) var statusReport: String = ""

    init(siteID: Int64) {
        self.siteID = siteID
    }
}
