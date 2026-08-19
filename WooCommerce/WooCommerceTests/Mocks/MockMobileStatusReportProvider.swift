@testable import WooCommerce

/// Mock for `MobileStatusReportProviding`: hands back a canned report and records the site addresses it was
/// asked to generate for.
final class MockMobileStatusReportProvider: MobileStatusReportProviding {

    /// The report every `generateReport` call returns.
    var report = "Mock mobile status report"

    /// The `siteAddress` of every `generateReport` call, in order.
    private(set) var generateReportSiteAddresses: [String?] = []

    func generateReport(siteAddress: String?) async -> String {
        generateReportSiteAddresses.append(siteAddress)
        return report
    }
}
