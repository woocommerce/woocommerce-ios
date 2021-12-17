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

    /// Whether fetching system status report failed
    ///
    @Published private(set) var errorFetchingReport: Bool = false

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores
    }

    func fetchReport() {
        errorFetchingReport = false
        let action = SystemStatusAction.fetchSystemStatusReport(siteID: siteID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let status):
                self.statusReport = self.formatReport(with: status)
            case .failure:
                self.errorFetchingReport = true
            }
        }
        stores.dispatch(action)
    }
}

private extension SystemStatusReportViewModel {
    func formatReport(with systemStatus: SystemStatus) -> String {
        // TODO: handle formatting
        return "### WordPress Environment ###"
    }
}
