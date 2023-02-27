import XCTest
@testable import WooCommerce
@testable import Yosemite

@MainActor
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

    func test_reloadRoles_returns_true_if_user_has_admin_role() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: false))
        stores.whenReceivingAction(ofType: UserAction.self) { action in
            switch action {
            case .retrieveUser(_, let onCompletion):
                let user = User.fake().copy(roles: [User.Role.administrator.rawValue])
                onCompletion(.success(user))
            }
        }
        let viewModel = AdminRoleRequiredViewModel(siteID: 123, stores: stores)

        // When
        let result = try await viewModel.reloadRoles()

        // Then
        XCTAssertTrue(result)
    }

    func test_reloadRoles_returns_false_if_user_does_not_have_admin_role() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: false))
        stores.whenReceivingAction(ofType: UserAction.self) { action in
            switch action {
            case .retrieveUser(_, let onCompletion):
                let user = User.fake().copy(roles: [User.Role.shopManager.rawValue])
                onCompletion(.success(user))
            }
        }
        let viewModel = AdminRoleRequiredViewModel(siteID: 123, stores: stores)

        // When
        let result = try await viewModel.reloadRoles()

        // Then
        XCTAssertFalse(result)
    }

    func test_reloadRoles_relays_error_if_the_fetch_fails() async {
        // Given
        let expectedError = NSError(domain: "Test", code: 500, userInfo: nil)
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: false))
        stores.whenReceivingAction(ofType: UserAction.self) { action in
            switch action {
            case .retrieveUser(_, let onCompletion):
                onCompletion(.failure(expectedError))
            }
        }
        let viewModel = AdminRoleRequiredViewModel(siteID: 123, stores: stores)

        // When
        var caughtError: NSError?
        do {
            _ = try await viewModel.reloadRoles()
        } catch {
            caughtError = error as NSError
        }

        // Then
        assertEqual(expectedError, caughtError)
    }
}
