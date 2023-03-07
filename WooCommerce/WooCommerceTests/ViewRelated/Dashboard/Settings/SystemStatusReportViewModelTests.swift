import XCTest
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

}
