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
        let deleteURL = "\(siteAddress)/?rest_route=/wp/v2/users/me/application-passwords/\(uuid)"
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
        let introspectURL = "\(siteAddress)/?rest_route=/wp/v2/users/me/application-passwords/introspect"
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
        return "\(siteAddress)/?rest_route=/wp/v2/users/me/application-passwords/\(uuid)"
    }

    func introspectURL() -> String {
        return "\(siteAddress)/?rest_route=/wp/v2/users/me/application-passwords/introspect"
    }
}
