import XCTest
@testable import Networking
@testable import NetworkingCore
import KeychainAccess

/// OneTimeApplicationPasswordUseCase Unit Tests
///
final class OneTimeApplicationPasswordUseCaseTests: XCTestCase {
    private var mockSession: MockURLSession!
    private var storage: MockApplicationPasswordStorage!
    private let siteAddress = "https://test.com"

    override func setUp() {
        super.setUp()
        mockSession = MockURLSession()
        storage = MockApplicationPasswordStorage()
    }

    override func tearDown() {
        mockSession = nil
        storage = nil
        WordPressRESTAPIRootCache.shared.reset()
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func test_init_with_application_password_saves_password_to_storage() {
        // Given
        let password = createTestPassword(username: "testuser", password: "secret123", uuid: "test-uuid")

        // When
        let sut = createSUT(password: password)

        // Then
        XCTAssertEqual(sut.applicationPassword?.wpOrgUsername, "testuser")
        XCTAssertEqual(sut.applicationPassword?.uuid, "test-uuid")
        XCTAssertEqual(storage.applicationPassword?.wpOrgUsername, "testuser")
        XCTAssertEqual(storage.applicationPassword?.uuid, "test-uuid")
    }

    func test_init_without_application_password_has_nil_password() {
        // When
        let sut = createSUT()

        // Then
        XCTAssertNil(sut.applicationPassword)
    }

    // MARK: - Generate Password Tests

    func test_generateNewPassword_throws_notSupported_error() async {
        // Given
        let sut = createSUT()

        // When/Then
        do {
            _ = try await sut.generateNewPassword()
            XCTFail("Expected notSupported error to be thrown")
        } catch {
            XCTAssertEqual(error as? ApplicationPasswordUseCaseError, .notSupported)
        }
    }

    // MARK: - Validate Password Tests

    func test_validateApplicationPassword_returns_valid_when_introspection_succeeds() async throws {
        // Given
        simulateIntrospectResponse(uuid: "test-uuid")
        let sut = createSUT(password: createTestPassword())

        // When
        let result = try await sut.validateApplicationPassword()

        // Then
        guard case .valid = result else {
            return XCTFail("Expected valid application password")
        }
        XCTAssertEqual(mockSession.requestCount, 1)
        XCTAssertEqual(mockSession.lastRequest?.url?.absoluteString, introspectURL())
        XCTAssertEqual(mockSession.lastRequest?.value(forHTTPHeaderField: "Authorization"), "Basic dGVzdHVzZXI6c2VjcmV0")
    }

    func test_validateApplicationPassword_normalizes_HTTP_site_address_to_HTTPS() async throws {
        // Given
        simulateIntrospectResponse(uuid: "test-uuid")
        let sut = createSUT(password: createTestPassword(), siteAddress: "http://test.com")

        // When
        _ = try await sut.validateApplicationPassword()

        // Then
        XCTAssertEqual(mockSession.lastRequest?.url?.absoluteString, introspectURL())
    }

    func test_validateApplicationPassword_throws_notSupported_when_password_is_missing() async {
        // Given
        let sut = createSUT()

        // When/Then
        do {
            _ = try await sut.validateApplicationPassword()
            XCTFail("Expected notSupported error to be thrown")
        } catch {
            XCTAssertEqual(error as? ApplicationPasswordUseCaseError, .notSupported)
        }
    }

    func test_validateApplicationPassword_returns_invalid_when_introspection_returns_unauthorized_status() async throws {
        // Given
        mockSession.simulateResponse(for: introspectURL(), statusCode: 401)
        let sut = createSUT(password: createTestPassword())

        // When
        let result = try await sut.validateApplicationPassword()

        // Then
        guard case .invalid(let error) = result else {
            return XCTFail("Expected invalid application password")
        }
        XCTAssertEqual((error as? NetworkError)?.responseCode, 401)
    }

    func test_validateApplicationPassword_returns_invalid_when_introspection_returns_incorrect_password_code() async throws {
        // Given
        let response = try JSONSerialization.data(withJSONObject: ["code": "incorrect_password"])
        mockSession.simulateResponse(for: introspectURL(), data: response, statusCode: 400)
        let sut = createSUT(password: createTestPassword())

        // When
        let result = try await sut.validateApplicationPassword()

        // Then
        guard case .invalid(let error) = result else {
            return XCTFail("Expected invalid application password")
        }
        XCTAssertEqual((error as? NetworkError)?.errorCode, "incorrect_password")
    }

    func test_validateApplicationPassword_throws_when_introspection_fails_with_unrelated_server_error() async throws {
        // Given
        mockSession.simulateResponse(for: introspectURL(), statusCode: 500)
        let sut = createSUT(password: createTestPassword())

        // When
        var thrownError: NetworkError?
        do {
            _ = try await sut.validateApplicationPassword()
        } catch {
            thrownError = error as? NetworkError
        }

        // Then
        XCTAssertEqual(thrownError?.responseCode, 500)
    }

    // MARK: - Delete Password Tests

    func test_deletePassword_locally_true_removes_from_storage_and_calls_api() async throws {
        // Given
        let deleteUUID = "fetched-uuid-456"
        simulateIntrospectResponse(uuid: deleteUUID)
        simulateDeleteResponse(for: deleteUUID)

        let password = createTestPassword(uuid: "original-uuid")
        let sut = createSUT(password: password)

        // Verify password is initially present
        XCTAssertNotNil(sut.applicationPassword)

        // When
        try await sut.deletePassword(locally: true)

        // Then
        XCTAssertNil(storage.applicationPassword)
        XCTAssertEqual(mockSession.requestCount, 2)
        XCTAssertEqual(mockSession.lastRequest?.url?.absoluteString, deleteURL(for: deleteUUID))
        XCTAssertEqual(mockSession.lastRequest?.httpMethod, "DELETE")
        XCTAssertEqual(mockSession.lastRequest?.value(forHTTPHeaderField: "Authorization"), "Basic dGVzdHVzZXI6c2VjcmV0")
    }

    func test_deletePassword_locally_false_fetches_uuid_from_introspect_endpoint_and_does_not_remove_from_storage() async throws {
        // Given
        let deleteUUID = "fetched-uuid-456"
        simulateIntrospectResponse(uuid: deleteUUID)
        simulateDeleteResponse(for: deleteUUID)

        let password = createTestPassword(uuid: "original-uuid")
        let sut = createSUT(password: password)

        // When
        try await sut.deletePassword(locally: false)

        // Then
        XCTAssertNotNil(storage.applicationPassword) // Password should still be in storage
        XCTAssertEqual(mockSession.requestCount, 2)
        // Check introspect call
        XCTAssertEqual(mockSession.responses.keys.contains(introspectURL()), true)
        // Check delete call
        XCTAssertEqual(mockSession.responses.keys.contains(deleteURL(for: deleteUUID)), true)
    }

    // MARK: - Discovery Tests

    func test_deletePassword_when_discovery_returns_wp_json_root_then_uses_wp_json_url() async throws {
        // Given
        let deleteUUID = "fetched-uuid-456"
        let wpJsonRoot = "https://test.com/wp-json/"
        let introspectURL = "\(wpJsonRoot)wp/v2/users/me/application-passwords/introspect"
        let deleteURL = "\(wpJsonRoot)wp/v2/users/me/application-passwords/\(deleteUUID)"
        let introspectResponse = """
        {
            "uuid": "\(deleteUUID)",
            "name": "test-password"
        }
        """.data(using: .utf8)!
        mockSession.simulateResponse(for: introspectURL, data: introspectResponse)
        mockSession.simulateResponse(for: deleteURL, data: Data())

        let password = createTestPassword(uuid: "original-uuid")
        let sut = OneTimeApplicationPasswordUseCase(
            applicationPassword: password,
            siteAddress: siteAddress,
            injectedStorage: storage,
            session: mockSession,
            discovery: { _ in wpJsonRoot }
        )

        // When
        try await sut.deletePassword(locally: true)

        // Then
        XCTAssertNil(storage.applicationPassword)
        XCTAssertEqual(mockSession.lastRequest?.url?.absoluteString, deleteURL)
    }

    func test_deletePassword_when_discovery_returns_HTTP_root_then_uses_HTTPS_url() async throws {
        // Given
        let deleteUUID = "fetched-uuid-456"
        simulateIntrospectResponse(uuid: deleteUUID)
        simulateDeleteResponse(for: deleteUUID)
        let sut = OneTimeApplicationPasswordUseCase(
            applicationPassword: createTestPassword(),
            siteAddress: siteAddress,
            injectedStorage: storage,
            session: mockSession,
            discovery: { _ in "http://test.com/wp-json/" }
        )

        // When
        try await sut.deletePassword(locally: true)

        // Then
        XCTAssertEqual(mockSession.lastRequest?.url?.absoluteString, deleteURL(for: deleteUUID))
    }

    func test_deletePassword_when_discovery_returns_rest_route_root_then_uses_rest_route_url() async throws {
        // Given
        let deleteUUID = "fetched-uuid-789"
        let restRouteRoot = "https://test.com/?rest_route=/"
        let introspectURL = "https://test.com/?rest_route=/wp/v2/users/me/application-passwords/introspect"
        let deleteURL = "https://test.com/?rest_route=/wp/v2/users/me/application-passwords/\(deleteUUID)"
        let introspectResponse = """
        {
            "uuid": "\(deleteUUID)",
            "name": "test-password"
        }
        """.data(using: .utf8)!
        mockSession.simulateResponse(for: introspectURL, data: introspectResponse)
        mockSession.simulateResponse(for: deleteURL, data: Data())

        let password = createTestPassword(uuid: "original-uuid")
        let sut = OneTimeApplicationPasswordUseCase(
            applicationPassword: password,
            siteAddress: siteAddress,
            injectedStorage: storage,
            session: mockSession,
            discovery: { _ in restRouteRoot }
        )

        // When
        try await sut.deletePassword(locally: true)

        // Then
        XCTAssertNil(storage.applicationPassword)
        XCTAssertEqual(mockSession.lastRequest?.url?.absoluteString, deleteURL)
    }

    // MARK: - Authentication Header Tests

    func test_deletePassword_sets_correct_authorization_header() async throws {
        // Given
        let username = "testuser"
        let passwordValue = "testpassword"
        let deleteUUID = "fetched-uuid-456"
        simulateIntrospectResponse(uuid: deleteUUID)
        simulateDeleteResponse(for: deleteUUID)

        let password = createTestPassword(username: username, password: passwordValue, uuid: "original-uuid")
        let sut = createSUT(password: password)

        // When
        try await sut.deletePassword(locally: true)

        // Then
        let expectedAuth = Data("\(username):\(passwordValue)".utf8).base64EncodedString()
        XCTAssertEqual(mockSession.lastRequest?.value(forHTTPHeaderField: "Authorization"), "Basic \(expectedAuth)")
        XCTAssertEqual(mockSession.lastRequest?.value(forHTTPHeaderField: "Accept"), "application/json")
        XCTAssertEqual(mockSession.lastRequest?.value(forHTTPHeaderField: "User-Agent"), UserAgent.defaultUserAgent)
        XCTAssertEqual(mockSession.lastRequest?.httpShouldHandleCookies, false)
    }
}

// MARK: - Helper Methods
private extension OneTimeApplicationPasswordUseCaseTests {
    func createSUT(password: ApplicationPassword? = nil, siteAddress: String? = nil) -> OneTimeApplicationPasswordUseCase {
        return OneTimeApplicationPasswordUseCase(
            applicationPassword: password,
            siteAddress: siteAddress ?? self.siteAddress,
            injectedStorage: storage,
            session: mockSession,
            discovery: { _ in nil }
        )
    }

    func simulateDeleteResponse(for uuid: String) {
        let deleteURL = "\(siteAddress)/wp-json/wp/v2/users/me/application-passwords/\(uuid)"
        let deleteResponse = """
        {
            "data": {
                "deleted": true
            }
        }
        """.data(using: .utf8)!
        mockSession.simulateResponse(for: deleteURL, data: deleteResponse)
    }

    func simulateIntrospectResponse(uuid: String, name: String = "test-password") {
        let introspectURL = "\(siteAddress)/wp-json/wp/v2/users/me/application-passwords/introspect"
        let introspectResponse = """
        {
            "uuid": "\(uuid)",
            "name": "\(name)"
        }
        """.data(using: .utf8)!
        mockSession.simulateResponse(for: introspectURL, data: introspectResponse)
    }

    func createTestPassword(username: String = "testuser", password: String = "secret", uuid: String = "test-uuid") -> ApplicationPassword {
        return ApplicationPassword(wpOrgUsername: username, password: .init(password), uuid: uuid)
    }

    func deleteURL(for uuid: String) -> String {
        return "\(siteAddress)/wp-json/wp/v2/users/me/application-passwords/\(uuid)"
    }

    func introspectURL() -> String {
        return "\(siteAddress)/wp-json/wp/v2/users/me/application-passwords/introspect"
    }
}
