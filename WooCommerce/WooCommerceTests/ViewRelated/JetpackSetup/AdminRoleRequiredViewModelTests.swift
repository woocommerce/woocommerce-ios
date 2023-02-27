import XCTest
@testable import WooCommerce
@testable import Yosemite

final class AdminRoleRequiredViewModelTests: XCTestCase {

    func test_username_is_correct() {
        // Given
        let testUsername = "Test"
        let sessionManager = MockSessionManager()
        sessionManager.defaultCredentials = .wporg(username: testUsername, password: "secret", siteAddress: "https://test.com")
        let stores = DefaultStoresManager(sessionManager: sessionManager)
        let viewModel = AdminRoleRequiredViewModel(siteID: 123, stores: stores)

        // When
        let username = viewModel.username

        // Then
        assertEqual(testUsername, username)
    }

    func test_roleName_is_correct() {
        // Given
        let sessionManager = MockSessionManager()
        sessionManager.defaultRoles = [.shopManager]
        let stores = DefaultStoresManager(sessionManager: sessionManager)
        let viewModel = AdminRoleRequiredViewModel(siteID: 123, stores: stores)

        // When
        let roleName = viewModel.roleName

        // Then
        assertEqual(NSLocalizedString("Shop Manager", comment: "User's Shop Manager role."), roleName)
    }
}
