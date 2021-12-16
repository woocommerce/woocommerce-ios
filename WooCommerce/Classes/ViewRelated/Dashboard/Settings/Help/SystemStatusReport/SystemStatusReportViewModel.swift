import Foundation

/// View model for `SystemStatusReportView`
///
final class SystemStatusReportViewModel: ObservableObject {
    /// ID of the site to fetch system status report for
    ///
    private let siteID: Int64

    init(siteID: Int64) {
        self.siteID = siteID
    }
}
