import XCTest
import Yosemite
@testable import WooCommerce

final class AccountCreationFormViewModelTests: XCTestCase {
    private var stores: MockStoresManager!
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!
    private var viewModel: AccountCreationFormViewModel!

    override func setUp() {
        super.setUp()

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

    // MARK: - `submitButtonEnabled`

    func test_submitButtonEnabled_is_false_after_entering_invalid_email() {
        // When
        viewModel.email = "notanemail@woocom"

        // Then
        waitUntil {
            self.viewModel.submitButtonEnabled == false
        }
    }

    func test_submitButtonEnabled_is_true_after_entering_valid_email_and_shouldShowPasswordField_is_false() {
        // When
        viewModel.email = "notanemail@woo.com"
        XCTAssertFalse(viewModel.shouldShowPasswordField)

        // Then
        waitUntil {
            self.viewModel.submitButtonEnabled == true
        }
    }

    func test_submitButtonEnabled_is_false_after_entering_password_less_than_minimum_length() async {
        // Given
        viewModel.email = "notanemail@woo.com"

        // First submission to check account existence
        mockAccountCreationFailure(error: .invalidPassword(message: ""))
        try? await viewModel.createAccount()

        // When
        viewModel.password = "minim"

        // Then
        waitUntil {
            self.viewModel.submitButtonEnabled == false
        }
    }

    func test_submitButtonEnabled_is_true_after_entering_password_of_minimum_length() async {
        // Given
        viewModel.email = "notanemail@woo.com"

        // First submission to check account existence
        mockAccountCreationFailure(error: .invalidPassword(message: ""))
        try? await viewModel.createAccount()

        // When
        viewModel.password = "minimu"

        // Then
        waitUntil {
            self.viewModel.submitButtonEnabled == true
        }
    }

    // MARK: - `createAccount`

    func test_createAccount_updates_existingEmailFound_correctly_if_account_exists() async {
        // Given
        mockAccountCreationFailure(error: .emailExists)
        viewModel.email = "notanemail@woo.com"

        // When
        try? await viewModel.createAccount()

        // Then
        XCTAssertFalse(viewModel.shouldShowPasswordField)
        XCTAssertTrue(viewModel.existingEmailFound)
    }

    func test_createAccount_updates_existingEmailFound_correctly_if_account_does_not_exist() async {
        // Given
        mockAccountCreationFailure(error: .invalidPassword(message: ""))
        viewModel.email = "notanemail@woo.com"

        // When
        try? await viewModel.createAccount()

        // Then
        XCTAssertTrue(viewModel.shouldShowPasswordField)
        XCTAssertFalse(viewModel.existingEmailFound)
    }

    func test_createAccount_success_sets_state_to_authenticated() async {
        // Given
        mockAccountCreationSuccess(result: .init(authToken: "token", username: "username"))
        XCTAssertFalse(stores.isAuthenticated)

        // When
        try? await viewModel.createAccount()

        // Then
        XCTAssertTrue(stores.isAuthenticated)
    }

    func test_createAccount_password_failure_the_first_time_sets_shouldShowPasswordField_to_true() async {
        // Given
        mockAccountCreationFailure(error: .invalidPassword(message: ""))
        XCTAssertFalse(stores.isAuthenticated)
        XCTAssertNil(viewModel.passwordErrorMessage)

        // When
        try? await viewModel.createAccount()

        // Then
        XCTAssertFalse(stores.isAuthenticated)
        XCTAssertNil(viewModel.passwordErrorMessage)
        XCTAssertTrue(viewModel.shouldShowPasswordField)
    }

    func test_createAccount_password_failure_the_second_time_sets_passwordErrorMessage() async {
        // Given
        XCTAssertFalse(stores.isAuthenticated)
        XCTAssertNil(viewModel.passwordErrorMessage)

        // First submission to check account existence
        mockAccountCreationFailure(error: .invalidPassword(message: ""))
        try? await viewModel.createAccount()

        // When
        mockAccountCreationFailure(error: .invalidPassword(message: "too complex to guess"))
        try? await viewModel.createAccount()

        // Then
        XCTAssertFalse(stores.isAuthenticated)
        XCTAssertEqual(viewModel.passwordErrorMessage, "too complex to guess")
    }

    func test_createAccount_invalidEmail_failure_sets_emailErrorMessage() async {
        // Given
        mockAccountCreationFailure(error: .invalidEmail)
        XCTAssertNil(viewModel.emailErrorMessage)

        // When
        try? await viewModel.createAccount()

        // Then
        XCTAssertNotNil(viewModel.emailErrorMessage)
    }

    func test_existingEmailFound_is_cleared_after_changing_email_input() async {
        // Given
        mockAccountCreationFailure(error: .invalidPassword(message: ""))

        // First submission to check account existence
        mockAccountCreationFailure(error: .invalidPassword(message: ""))
        try? await viewModel.createAccount()

        // When
        try? await viewModel.createAccount()
        viewModel.email = "real@woo.com"

        // Then
        waitUntil {
            self.viewModel.existingEmailFound == false
        }
    }

    func test_passwordErrorMessage_is_cleared_after_changing_password_input() async {
        // Given
        mockAccountCreationFailure(error: .invalidPassword(message: "too complex to guess"))
        try? await viewModel.createAccount()

        // When
        mockAccountCreationFailure(error: .invalidPassword(message: ""))
        try? await viewModel.createAccount()
        viewModel.password = "mysecret"

        // Then
        waitUntil {
            self.viewModel.passwordErrorMessage == nil
        }
    }

    func test_emailErrorMessage_is_cleared_after_changing_email_input() async {
        // Given
        mockAccountCreationFailure(error: .invalidEmail)

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
        // First submission to check account existence
        mockAccountCreationFailure(error: .invalidPassword(message: ""))
        try? await viewModel.createAccount()

        // When
        mockAccountCreationSuccess(result: .init(authToken: "", username: ""))
        try? await viewModel.createAccount()

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents, ["signup_submitted", "signup_failed", "signup_submitted", "signup_success"])
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
