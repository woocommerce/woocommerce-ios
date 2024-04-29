import XCTest
import Yosemite
@testable import WooCommerce
import WordPressAuthenticator

final class AccountCreationFormViewModelTests: XCTestCase {
    private var stores: MockStoresManager!
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!
    private var viewModel: AccountCreationFormViewModel!

    override func setUp() {
        super.setUp()

        WordPressAuthenticator.initializeAuthenticator()

        stores = MockStoresManager(sessionManager: SessionManager.makeForTesting())
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        viewModel = .init(debounceDuration: 0, stores: stores, analytics: analytics, onExistingEmail: { _ in }, completionHandler: {})
    }

    override func tearDown() {
        viewModel = nil
        analytics = nil
        analyticsProvider = nil
        stores = nil
        super.tearDown()
    }

    // MARK: - `isEmailValid`

    func test_isEmailValid_is_false_after_entering_invalid_email() {
        // When
        viewModel.email = "notanemail@woocom"

        // Then
        waitUntil {
            self.viewModel.isEmailValid == false
        }
    }

    func test_isEmailValid_is_true_after_entering_valid_email() {
        // When
        viewModel.email = "notanemail@woocommerce.com"

        // Then
        waitUntil {
            self.viewModel.isEmailValid == true
        }
    }

    // MARK: - `isPasswordValid`

    func test_isPasswordValid_is_false_after_entering_password_less_than_minimum_length() {
        // When
        viewModel.password = "minim"

        // Then
        waitUntil {
            self.viewModel.isPasswordValid == false
        }
    }

    func test_isPasswordValid_is_true_after_entering_password_of_minimum_length() {
        // When
        viewModel.password = "minimu"

        // Then
        waitUntil {
            self.viewModel.isPasswordValid == true
        }
    }

    // MARK: - `createAccount`

    @MainActor
    func test_createAccount_success_sets_state_to_authenticated() async {
        // Given
        mockAccountCreationSuccess(result: .init(authToken: "token", username: "username"))
        XCTAssertFalse(stores.isAuthenticated)

        // When
        await viewModel.createAccount()

        // Then
        XCTAssertTrue(stores.isAuthenticated)
    }

    @MainActor
    func test_createAccount_password_failure_sets_passwordErrorMessage() async {
        // Given
        mockAccountCreationFailure(error: .invalidPassword(message: "too complex to guess"))
        XCTAssertFalse(stores.isAuthenticated)
        XCTAssertNil(viewModel.passwordErrorMessage)

        // When
        viewModel.transitionToPasswordField()
        await viewModel.createAccount()

        // Then
        XCTAssertFalse(stores.isAuthenticated)
        XCTAssertEqual(viewModel.passwordErrorMessage, "too complex to guess")
    }

    @MainActor
    func test_createAccount_invalidEmail_failure_sets_emailErrorMessage() async {
        // Given
        mockAccountCreationFailure(error: .invalidEmail)
        XCTAssertNil(viewModel.emailErrorMessage)

        // When
        await viewModel.createAccount()

        // Then
        XCTAssertNotNil(viewModel.emailErrorMessage)
    }

    @MainActor
    func test_shouldTransitionToPasswordField_is_updated_to_true_when_account_creation_fails_with_invalidPassword() async {
        // Given
        mockAccountCreationFailure(error: .invalidPassword(message: ""))
        viewModel.email = "test@example.com"
        XCTAssertFalse(viewModel.shouldTransitionToPasswordField)

        // When
        await viewModel.createAccount()

        // Then
        XCTAssertNil(viewModel.emailErrorMessage)
        XCTAssertTrue(viewModel.shouldTransitionToPasswordField)
    }

    func test_transitionToPasswordField_updates_currentField_to_password() {
        // Given
        viewModel = .init(debounceDuration: 0, stores: stores, analytics: analytics, onExistingEmail: { _ in }, completionHandler: {})
        XCTAssertEqual(viewModel.currentField, .email)

        // When
        viewModel.transitionToPasswordField()

        // Then
        XCTAssertEqual(viewModel.currentField, .password)
    }

    @MainActor
    func test_passwordErrorMessage_is_cleared_after_changing_password_input() async {
        // Given
        mockAccountCreationFailure(error: .invalidPassword(message: "too complex to guess"))

        // When
        await viewModel.createAccount()
        viewModel.password = "simple password"

        // Then
        waitUntil {
            self.viewModel.passwordErrorMessage == nil
        }
    }

    @MainActor
    func test_emailErrorMessage_is_cleared_after_changing_email_input() async {
        // Given
        mockAccountCreationFailure(error: .emailExists)

        // When
        await viewModel.createAccount()
        viewModel.email = "real@woocommerce.com"

        // Then
        waitUntil {
            self.viewModel.emailErrorMessage == nil
        }
    }

    // MARK: - analytics

    @MainActor
    func test_createAccount_success_tracks_expected_events() async {
        // Given
        mockAccountCreationSuccess(result: .init(authToken: "", username: ""))

        // When
        await viewModel.createAccount()

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents, ["signup_submitted", "signup_success"])
    }

    @MainActor
    func test_createAccount_failure_tracks_expected_events() async {
        // Given
        mockAccountCreationFailure(error: .emailExists)

        // When
        await viewModel.createAccount()

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents, ["signup_submitted", "signup_failed"])
    }

    @MainActor
    func test_createAccount_failure_with_invalid_password_is_not_tracked_if_currentField_is_email() async {
        // Given
        mockAccountCreationFailure(error: .invalidPassword(message: nil))
        viewModel.email = "test@example.com"

        // When
        await viewModel.createAccount()

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents, ["signup_submitted"])
    }

    @MainActor
    func test_createAccount_failure_with_invalid_password_is_tracked_if_currentField_is_password() async {
        // Given
        mockAccountCreationFailure(error: .invalidPassword(message: nil))
        viewModel.email = "test@example.com"

        // When
        viewModel.transitionToPasswordField()
        await viewModel.createAccount()

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents, ["signup_submitted", "signup_failed"])
    }
}

private extension AccountCreationFormViewModelTests {
    func mockAccountCreationSuccess(result: CreateAccountResult) {
        stores.whenReceivingAction(ofType: AccountCreationAction.self) { action in
            switch action {
            case let .createAccount(_, _, completion):
                completion(.success(result))
            }
        }

        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case let .synchronizeAccount(completion):
                completion(.success(.fake()))
            case let .synchronizeAccountSettings(_, completion):
                completion(.success(.fake()))
            case let .synchronizeSites(_, completion):
                completion(.success(true))
            default:
                break
            }
        }
    }

    func mockAccountCreationFailure(error: CreateAccountError) {
        stores.whenReceivingAction(ofType: AccountCreationAction.self) { action in
            guard case let .createAccount(_, _, completion) = action else {
                return
            }
            completion(.failure(error))
        }
    }
}
