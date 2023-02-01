import XCTest
import Yosemite
import enum Alamofire.AFError
@testable import WooCommerce

final class SiteCredentialLoginUseCaseTests: XCTestCase {

    func test_onLoading_is_triggered_appropriately_when_login_starts() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        var isLoading = false
        let useCase = SiteCredentialLoginUseCase(siteURL: "https://test.com", stores: stores)

        // When
        useCase.setupHandlers(onLoading: { isLoading = $0 },
                              onLoginSuccess: {},
                              onLoginFailure: { _ in })
        useCase.handleLogin(username: "test", password: "secret")

        // Then
        XCTAssertTrue(isLoading)
    }

    func test_onLoading_and_onLoginFailure_are_triggered_appropriately_when_login_fails() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        var isLoading = false
        var error: Error?
        let expectedError = NSError(domain: "Test", code: 1)
        let useCase = SiteCredentialLoginUseCase(siteURL: "https://test.com",
                                                 stores: stores)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(let completion):
                let error = expectedError
                completion(.failure(error))
            default:
                break
            }
        }

        // When
        useCase.setupHandlers(onLoading: { isLoading = $0 },
                              onLoginSuccess: {},
                              onLoginFailure: { error = $0 })
        useCase.handleLogin(username: "test", password: "secret")

        // Then
        XCTAssertFalse(isLoading)
        let loginError = try XCTUnwrap(error as? SiteCredentialLoginError)
        XCTAssertEqual(loginError.underlyingError, expectedError)
    }

    func test_onLoading_and_onLoginSuccess_are_triggered_appropriately_when_login_succeeds() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        var isLoading = false
        var isSuccess = false
        let useCase = SiteCredentialLoginUseCase(siteURL: "https://test.com",
                                                 stores: stores)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(let completion):
                completion(.success(SitePlugin.fake()))
            default:
                break
            }
        }

        // When
        useCase.setupHandlers(onLoading: { isLoading = $0 },
                              onLoginSuccess: { isSuccess = true },
                              onLoginFailure: { _ in })
        useCase.handleLogin(username: "test", password: "secret")

        // Then
        XCTAssertFalse(isLoading)
        XCTAssertTrue(isSuccess)
    }

    func test_authentication_and_successHandler_are_triggered_when_fetching_plugin_succeeds() {
        // Given
        var successHandlerTriggered = false
        var error: Error?
        var triggeredAuthentication = false
        let siteURL = "https://test.com"
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let useCase = SiteCredentialLoginUseCase(siteURL: siteURL,
                                                 stores: stores)
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .authenticate:
                triggeredAuthentication = true
            case .retrieveJetpackPluginDetails(let completion):
                completion(.success(SitePlugin.fake()))
            default:
                break
            }
        }

        // When
        useCase.setupHandlers(onLoading: { _ in },
                              onLoginSuccess: { successHandlerTriggered = true },
                              onLoginFailure: { error = $0 })
        useCase.handleLogin(username: "test", password: "secret")

        // Then
        XCTAssertNil(error)
        XCTAssertTrue(triggeredAuthentication)
        XCTAssertTrue(successHandlerTriggered)
    }

    func test_authentication_and_successHandler_are_triggered_when_fetching_plugin_fails_with_404() {
        // Given
        var successHandlerTriggered = false
        var error: Error?
        var triggeredAuthentication = false
        let siteURL = "https://test.com"
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let useCase = SiteCredentialLoginUseCase(siteURL: siteURL,
                                                 stores: stores)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .authenticate:
                triggeredAuthentication = true
            case .retrieveJetpackPluginDetails(let completion):
                let error = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 404))
                completion(.failure(error))
            default:
                break
            }
        }

        // When
        useCase.setupHandlers(onLoading: { _ in },
                              onLoginSuccess: { successHandlerTriggered = true },
                              onLoginFailure: { error = $0 })
        useCase.handleLogin(username: "test", password: "secret")

        // Then
        XCTAssertNil(error)
        XCTAssertTrue(triggeredAuthentication)
        XCTAssertTrue(successHandlerTriggered)
    }

    func test_authentication_and_successHandler_are_triggered_when_fetching_plugin_fails_with_403() {
        // Given
        var successHandlerTriggered = false
        var triggeredAuthentication = false
        var error: Error?
        let siteURL = "https://test.com"
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let useCase = SiteCredentialLoginUseCase(siteURL: siteURL,
                                                 stores: stores)
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .authenticate:
                triggeredAuthentication = true
            case .retrieveJetpackPluginDetails(let completion):
                let error = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 403))
                completion(.failure(error))
            default:
                break
            }
        }

        // When
        useCase.setupHandlers(onLoading: { _ in },
                              onLoginSuccess: { successHandlerTriggered = true },
                              onLoginFailure: { error = $0 })
        useCase.handleLogin(username: "test", password: "secret")

        // Then
        XCTAssertNil(error)
        XCTAssertTrue(triggeredAuthentication)
        XCTAssertTrue(successHandlerTriggered)
    }

    func test_error_is_correct_when_login_fails_with_incorrect_credentials() throws {
        // Given
        var successHandlerTriggered = false
        var error: Error?
        let siteURL = "https://test.com"
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let useCase = SiteCredentialLoginUseCase(siteURL: siteURL,
                                                 stores: stores)
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .retrieveJetpackPluginDetails(let completion):
                let error = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 401))
                completion(.failure(error))
            default:
                break
            }
        }

        // When
        useCase.setupHandlers(onLoading: { _ in },
                              onLoginSuccess: { successHandlerTriggered = true },
                              onLoginFailure: { error = $0 })
        useCase.handleLogin(username: "test", password: "secret")

        // Then
        let loginError = try XCTUnwrap(error as? SiteCredentialLoginError)
        XCTAssertEqual(loginError.underlyingError.code, 401)
        XCTAssertFalse(successHandlerTriggered)
    }
}
