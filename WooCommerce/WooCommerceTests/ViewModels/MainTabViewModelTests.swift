import XCTest
import TestKit

@testable import WooCommerce

import Yosemite

/// Test cases for `MainTabViewModel`.
final class MainTabViewModelTests: XCTestCase {

    func test_onViewDidAppear_will_save_the_installation_date() throws {
        // Given
        let storesManager = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        storesManager.reset()

        let viewModel = MainTabViewModel(storesManager: storesManager)

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

    func test_when_user_is_not_logged_in_then_onViewDidAppear_will_not_save_the_installation_date() throws {
        // Given
        let storesManager = MockStoresManager(sessionManager: .makeForTesting(authenticated: false))
        storesManager.reset()

        let viewModel = MainTabViewModel(storesManager: storesManager)

        assertEmpty(storesManager.receivedActions)

        // When
        viewModel.onViewDidAppear()

        // Then
        XCTAssertEqual(storesManager.receivedActions.count, 0)
    }
}
