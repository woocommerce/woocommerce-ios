import XCTest

@testable import WooCommerce

import Yosemite

/// Test cases for `MainTabViewModel`.
final class MainTabViewModelTests: XCTestCase {

    private var storesManager: MockupStoresManager!
    private var featureFlagService: MockFeatureFlagService!

    override func setUp() {
        super.setUp()

        var sessionManager = SessionManager.testingInstance
        sessionManager.defaultCredentials = Credentials(authToken: "")

        storesManager = MockupStoresManager(sessionManager: sessionManager)
        featureFlagService = MockFeatureFlagService(isInAppFeedbackOn: true)
    }

    override func tearDown() {
        featureFlagService = nil
        storesManager = nil
        super.tearDown()
    }

    func test_onViewDidAppear_will_save_the_installation_date() throws {
        // Given
        let viewModel = MainTabViewModel(storesManager: storesManager, featureFlagService: featureFlagService)

        assertEmpty(storesManager.receivedActions)

        // When
        viewModel.onViewDidAppear()

        // Then
        XCTAssertEqual(storesManager.receivedActions.count, 1)

        let action = try XCTUnwrap(storesManager.receivedActions.first as? AppSettingsAction)
        switch action {
        case let .setInstallationDateIfNecessary(date, _):
            let interval = abs(date.timeIntervalSince(Date()))
            XCTAssertLessThanOrEqual(interval, 100)
        default:
            XCTFail("Expected action to be .setInstallationDateIfNecessary")
        }
    }
}
