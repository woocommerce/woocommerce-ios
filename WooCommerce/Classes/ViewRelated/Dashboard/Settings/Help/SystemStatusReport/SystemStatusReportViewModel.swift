import Foundation
import Yosemite

/// View model for `SystemStatusReportView`
///
final class SystemStatusReportViewModel: ObservableObject {
    /// ID of the site to fetch system status report for
    ///
    private let siteID: Int64

    /// Stores to handle fetching system status
    ///
    private let stores: StoresManager

    /// Formatted system status report to be displayed on-screen
    ///
    @Published private(set) var statusReport: String = ""

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores
    }

    func fetchReport() {
        let action = SystemStatusAction.fetchSystemStatusReport(siteID: siteID) { result in
            // TODO
        }
        stores.dispatch(action)
    }
}
