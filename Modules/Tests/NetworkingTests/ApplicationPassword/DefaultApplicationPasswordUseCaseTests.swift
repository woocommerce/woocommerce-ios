import XCTest
@testable import Networking
@testable import NetworkingCore
import Alamofire
import KeychainAccess

/// DefaultApplicationPasswordUseCase Unit Tests
///
final class DefaultApplicationPasswordUseCaseTests: XCTestCase {
    /// Mock Network: Allows us to inject predefined responses!
    ///
    private var network: MockNetwork!

    /// URL suffixes
    ///
    private enum URLSuffix {
        static let applicationPassword = "users/me/application-passwords"
        static let userDetails = "wp/v2/users/me"
    }

    private static let keychainServiceName = "com.automattic.woocommerce.tests"

    override func setUp() {
        super.setUp()
        network = MockNetwork(useResponseQueue: true)
    }

    override func tearDown() {
        network = nil
        super.tearDown()
    }

    func test_password_is_generated_with_correct_values_upon_success_response() async throws {
        // Given
        network.simulateResponse(requestUrlSuffix: URLSuffix.applicationPassword,
                                 filename: "generate-application-password-using-wporg-creds-success")
        let username = "demo"
        let siteAddress = "https://test.com"
        let sut = DefaultApplicationPasswordUseCase(type: .wporg(username: username,
                                                                  password: "qeWOhQ5RUV8W",
                                                                  siteAddress: siteAddress),
                                                    network: network)

        // When
        let password = try await sut.generateNewPassword()

        // Then
        XCTAssertEqual(password.password.secretValue, "passwordvalue")
        XCTAssertEqual(password.wpOrgUsername, username)
    }

    func test_applicationPasswordsDisabled_error_is_thrown_if_generating_password_fails_with_501_error() async throws {
        // Given
        let error = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 501))
        network.simulateError(requestUrlSuffix: URLSuffix.applicationPassword, error: error)
        let username = "demo"
        let siteAddress = "https://test.com"
        let sut = DefaultApplicationPasswordUseCase(type: .wporg(username: username,
                                                                  password: "qeWOhQ5RUV8W",
                                                                  siteAddress: siteAddress),
                                                    network: network)

        // When
        var failure: ApplicationPasswordUseCaseError?
        do {
            let _ = try await sut.generateNewPassword()
        } catch {
            failure = error as? ApplicationPasswordUseCaseError
        }

        // Then
        XCTAssertTrue(failure == .applicationPasswordsDisabled)
    }

    func test_unauthorizedRequest_error_is_thrown_if_generating_password_fails_with_401_error() async throws {
        // Given
        let error = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 401))
        network.simulateError(requestUrlSuffix: URLSuffix.applicationPassword, error: error)
        let username = "demo"
        let siteAddress = "https://test.com"
        let sut = DefaultApplicationPasswordUseCase(type: .wporg(username: username,
                                                                  password: "qeWOhQ5RUV8W",
                                                                  siteAddress: siteAddress),
                                                    network: network)

        // When
        var failure: ApplicationPasswordUseCaseError?
        do {
            let _ = try await sut.generateNewPassword()
        } catch {
            failure = error as? ApplicationPasswordUseCaseError
        }

        // Then
        XCTAssertTrue(failure == .unauthorizedRequest)
    }

    func test_password_is_generated_with_correct_values_upon_success_response_when_authenticated_with_wpcom() async throws {
        // Given
        network.simulateResponse(requestUrlSuffix: URLSuffix.applicationPassword,
                                 filename: "generate-application-password-using-wporg-creds-success")
        network.simulateResponse(requestUrlSuffix: URLSuffix.userDetails, filename: "user-complete")
        let sut = DefaultApplicationPasswordUseCase(type: .wpcom(siteID: 123), network: network)

        // When
        let password = try await sut.generateNewPassword()

        // Then
        XCTAssertEqual(password.password.secretValue, "passwordvalue")
        XCTAssertEqual(password.wpOrgUsername, "test-username")
    }

    func test_applicationPasswordsDisabled_error_is_thrown_if_generating_password_fails_with_501_error_when_authenticated_with_wpcom() async throws {
        // Given
        let error = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 501))
        network.simulateError(requestUrlSuffix: URLSuffix.applicationPassword, error: error)
        network.simulateResponse(requestUrlSuffix: URLSuffix.userDetails, filename: "user-complete")
        let sut = DefaultApplicationPasswordUseCase(type: .wpcom(siteID: 123), network: network)

        // When
        var failure: ApplicationPasswordUseCaseError?
        do {
            let _ = try await sut.generateNewPassword()
        } catch {
            failure = error as? ApplicationPasswordUseCaseError
        }

        // Then
        XCTAssertTrue(failure == .applicationPasswordsDisabled)
    }

    func test_unauthorizedRequest_error_is_thrown_if_generating_password_fails_with_401_error_when_authenticated_with_wpcom() async throws {
        // Given
        let error = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 401))
        network.simulateError(requestUrlSuffix: URLSuffix.applicationPassword, error: error)
        network.simulateResponse(requestUrlSuffix: URLSuffix.userDetails, filename: "user-complete")
        let sut = DefaultApplicationPasswordUseCase(type: .wpcom(siteID: 123), network: network)

        // When
        var failure: ApplicationPasswordUseCaseError?
        do {
            let _ = try await sut.generateNewPassword()
        } catch {
            failure = error as? ApplicationPasswordUseCaseError
        }

        // Then
        XCTAssertTrue(failure == .unauthorizedRequest)
    }

    func test_delete_application_password_with_locally_false_does_not_clear_storage() async throws {
        // Given
        let storage = MockApplicationPasswordStorage()
        let sut = DefaultApplicationPasswordUseCase(
            type: .wpcom(siteID: 123),
            network: network,
            passwordName: "test-name",
            storage: storage
        )

        let uuid = "8ffe00cb-f903-49f9-a3e7-7674fb90fd1b"
        let password = ApplicationPassword(wpOrgUsername: "test", password: .init("secret"), uuid: uuid)
        storage.saveApplicationPassword(password)

        network.simulateResponse(
            requestUrlSuffix: URLSuffix.applicationPassword,
            filename: "get-application-passwords-success-with-data"
        )
        network.simulateResponse(
            requestUrlSuffix: URLSuffix.applicationPassword + "/" + uuid,
            filename: "delete-application-password-success"
        )

        // When
        try await sut.deletePassword(locally: false)

        // Then
        XCTAssertEqual(storage.applicationPassword, password)
    }

    func test_delete_application_password_with_locally_true_clears_storage() async throws {
        // Given
        let storage = MockApplicationPasswordStorage()
        let sut = DefaultApplicationPasswordUseCase(type: .wpcom(siteID: 123), network: network, storage: storage)

        let uuid = "4567-8901-2345-6789"
        storage.saveApplicationPassword(ApplicationPassword(wpOrgUsername: "testuser", password: .init("password123"), uuid: uuid))

        network.simulateResponse(
            requestUrlSuffix: "users/me/application-passwords/\(uuid)",
            filename: "delete-application-password-success"
        )

        // When
        try await sut.deletePassword(locally: true)

        // Then
        XCTAssertNil(storage.applicationPassword)
    }

}
