import XCTest
@testable import Networking
@testable import Yosemite
@testable import WooCommerce

final class SystemStatusReportViewModelTests: XCTestCase {

    private let testSiteID: Int64 = 1232

    func test_errorFetchingReport_is_true_if_fetchingReport_fails() {
        // Given
        let storesManager = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = SystemStatusReportViewModel(siteID: testSiteID, stores: storesManager)

        // When
        var fetchedSiteID: Int64?
        storesManager.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case .fetchSystemStatusReport(let siteID, let onCompletion):
                fetchedSiteID = siteID
                onCompletion(.failure(NSError(domain: "Not Found", code: 404)))
            default:
                break
            }
        }
        viewModel.fetchReport()

        // Then
        XCTAssertEqual(fetchedSiteID, testSiteID)
        XCTAssertTrue(viewModel.errorFetchingReport)
    }

    func test_formatReport_when_database_table_has_nil_values_then_displays_null_values() {
        // Given
        let report = SystemStatusReport(
            activePlugins: [],
            inactivePlugins: [],
            environment: nil,
            database: .init(
                wcDatabaseVersion: "10.7.0",
                databasePrefix: "wp_",
                databaseTables: .init(
                    woocommerce: [:],
                    other: [
                        "wp_wsm_uniqueVisitors": .init(data: nil, index: nil, engine: nil)
                    ]
                ),
                databaseSize: .init(data: 150.56, index: 114.66)
            ),
            dropinPlugins: [],
            mustUsePlugins: [],
            theme: nil,
            settings: nil,
            pages: [],
            postTypeCounts: [],
            security: nil
        )

        // When
        let formattedReport = SystemStatusReportViewModel.formatReport(with: report)

        // Then
        XCTAssertTrue(formattedReport.contains("wp_wsm_uniqueVisitors: Data: null + Index: null + Engine: null"))
    }
}
