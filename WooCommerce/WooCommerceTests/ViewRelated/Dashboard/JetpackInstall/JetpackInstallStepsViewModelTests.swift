import XCTest
@testable import WooCommerce
@testable import Yosemite

final class JetpackInstallStepsViewModelTests: XCTestCase {

    private let testSiteID: Int64 = 1232

    func test_startInstallation_dispatches_installSitePlugin_action() {
        // Given
        let storesManager = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = JetpackInstallStepsViewModel(siteID: testSiteID, stores: storesManager)

        // When
        var installedSiteID: Int64?
        storesManager.whenReceivingAction(ofType: SitePluginAction.self) { action in
            switch action {
            case .installSitePlugin(let siteID, _, _):
                installedSiteID = siteID
            default:
                break
            }
        }
        viewModel.startInstallation()

        // Then
        XCTAssertEqual(installedSiteID, testSiteID)
    }

}
