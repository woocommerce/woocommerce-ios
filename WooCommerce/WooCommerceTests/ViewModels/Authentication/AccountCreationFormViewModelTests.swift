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
        viewModel = .init(debounceDuration: 0, stores: stores, analytics: analytics)
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
        viewModel.email = "notanemail@woo.com"

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

    func test_createAccount_success_sets_state_to_authenticated() async {
        // Given
        mockAccountCreationSuccess(result: .init(authToken: "token", username: "username"))
        XCTAssertFalse(stores.isAuthenticated)

        do {
            // When
            try await viewModel.createAccount()

            // Then
            XCTAssertTrue(stores.isAuthenticated)

        } catch {
            XCTFail("Function should not throw an error")
        }
    }

    func test_createAccount_password_failure_sets_passwordErrorMessage() async {
        // Given
        mockAccountCreationFailure(error: .invalidPassword(message: "too complex to guess"))
        XCTAssertFalse(stores.isAuthenticated)
        XCTAssertNil(viewModel.passwordErrorMessage)

        do {
            try await viewModel.createAccount()

            XCTFail("Function should have thrown an error")
        } catch {
            XCTAssertFalse(stores.isAuthenticated)
            XCTAssertEqual(viewModel.passwordErrorMessage, "too complex to guess")
        }
    }

    func test_createAccount_invalidEmail_failure_sets_emailErrorMessage() async {
        // Given
        mockAccountCreationFailure(error: .invalidEmail)
        XCTAssertNil(viewModel.emailErrorMessage)

        do {
            try await viewModel.createAccount()

            XCTFail("Function should have thrown an error")
        } catch {
            // Then
            XCTAssertNotNil(viewModel.emailErrorMessage)
        }
    }

    func test_passwordErrorMessage_is_cleared_after_changing_password_input() async {
        // Given
        mockAccountCreationFailure(error: .invalidPassword(message: "too complex to guess"))

        // When
        try? await viewModel.createAccount()
        viewModel.password = "simple password"

        // Then
        waitUntil {
            self.viewModel.passwordErrorMessage == nil
        }
    }

    func test_emailErrorMessage_is_cleared_after_changing_email_input() async {
        // Given
        mockAccountCreationFailure(error: .emailExists)

        // When
        try? await viewModel.createAccount()
        viewModel.email = "real@woo.com"

        // Then
        waitUntil {
            self.viewModel.emailErrorMessage == nil
        }
    }

    // MARK: - analytics

    func test_createAccount_success_tracks_expected_events() async {
        // Given
        mockAccountCreationSuccess(result: .init(authToken: "", username: ""))

        // When
        try? await viewModel.createAccount()

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents, ["signup_submitted", "signup_success"])
    }

    func test_createAccount_failure_tracks_expected_events() async {
        // Given
        mockAccountCreationFailure(error: .emailExists)

        // When
        try? await viewModel.createAccount()

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
