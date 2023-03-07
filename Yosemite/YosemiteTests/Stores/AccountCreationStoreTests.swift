import Networking
import XCTest
@testable import Yosemite

final class AccountCreationStoreTests: XCTestCase {
    private var remote: MockAccountRemote!
    private var store: AccountCreationStore!

    override func setUp() {
        super.setUp()
        remote = MockAccountRemote()
        store = AccountCreationStore(dotcomClientID: "", dotcomClientSecret: "", remote: remote, dispatcher: .init())
    }

    override func tearDown() {
        store = nil
        remote = nil
        super.tearDown()
    }

    func test_createAccount_returns_result_on_success() throws {
        // Given
        remote.whenLoadingUsernameSuggestions(thenReturn: .success(["woo", "zoo"]))
        remote.whenCreatingAccount(thenReturn: .success(.init(authToken: "auth", username: "voo")))

        // When
        let result: Result<CreateAccountResult, CreateAccountError> = waitFor { promise in
            let action = AccountCreationAction.createAccount(email: "test@woo.com", password: "wow") { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        let data = try XCTUnwrap(result.get())
        XCTAssertEqual(data, .init(authToken: "auth", username: "voo"))
    }

    func test_createAccount_returns_invalidUsername_error_when_username_suggestions_are_empty() throws {
        // Given
        remote.whenLoadingUsernameSuggestions(thenReturn: .success([]))

        // When
        let result: Result<CreateAccountResult, CreateAccountError> = waitFor { promise in
            let action = AccountCreationAction.createAccount(email: "test@woo.com", password: "wow") { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error, .invalidUsername)
    }

    func test_createAccount_returns_invalidUsername_error_when_loadUsernameSuggestions_fails() throws {
        // Given
        remote.whenLoadingUsernameSuggestions(thenReturn: .failure(NetworkError.notFound))

        // When
        let result: Result<CreateAccountResult, CreateAccountError> = waitFor { promise in
            let action = AccountCreationAction.createAccount(email: "test@woo.com", password: "wow") { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error, .invalidUsername)
    }

    func test_createAccount_returns_error_from_remote_on_failure() throws {
        // Given
        remote.whenLoadingUsernameSuggestions(thenReturn: .success(["woo", "zoo"]))
        remote.whenCreatingAccount(thenReturn: .failure(.emailExists))

        // When
        let result: Result<CreateAccountResult, CreateAccountError> = waitFor { promise in
            let action = AccountCreationAction.createAccount(email: "test@woo.com", password: "wow") { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error, .emailExists)
    }
}
