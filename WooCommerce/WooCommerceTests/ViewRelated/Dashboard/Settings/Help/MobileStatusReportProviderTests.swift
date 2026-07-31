import Testing
import Foundation
@testable import WooCommerce

/// The report is a text artifact, so it is pinned by comparing the whole thing: that catches an omitted field, a
/// lost section and a broken scope in one assertion, which per-field tests do not.
///
@MainActor
struct MobileStatusReportProviderTests {

    @Test func report_contents() async {
        // Given, When
        let report = await makeProvider().generateReport()

        // Then
        #expect(report == """
        ### Mobile Status Report generated via the WooCommerce iOS app ###
        Scopes: (app-wide) values cover the whole app on this device. (selected store: ...) values cover only the named store.
        Field reference: https://github.com/woocommerce/woocommerce-ios/blob/trunk/docs/mobile-status-report.md

        ## App (app-wide)
        Version: 21.3 (2103003)
        Build: appStore

        ## Device (app-wide)
        Model: iPhone17,1
        OS: iOS 18.4
        Free space: 12.40 GB
        Screen: 393x852 pt (phone)
        Device locale: en-US
        App language: en-GB
        """)
    }
}

// MARK: - Helpers

private extension MobileStatusReportProviderTests {

    func makeProvider() -> MobileStatusReportProvider {
        MobileStatusReportProvider(systemSnapshot: { .fixture() })
    }
}

private extension MobileStatusReportSystemSnapshot {
    static func fixture() -> Self {
        MobileStatusReportSystemSnapshot(version: "21.3 (2103003)",
                                         build: "appStore",
                                         model: "iPhone17,1",
                                         os: "iOS 18.4",
                                         freeSpace: "12.40 GB",
                                         screen: "393x852 pt (phone)",
                                         deviceLocale: "en-US",
                                         appLanguage: "en-GB")
    }
}
