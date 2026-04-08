import XCTest
import Yosemite
@testable import WooCommerce

@MainActor
final class JetpackConnectionServiceTests: XCTestCase {
    private let testURL = "https://example.com"
    private let testEmail = "user@example.com"
    private let credentials = Credentials.wpcom(username: "test", authToken: "secret", siteAddress: "https://example.com")

    private var stores: MockStoresManager!

    /// Connection data representing a fully-connected user with email.
    private var connectedData: JetpackConnectionData {
        .fake().copy(currentUser: .fake().copy(isConnected: true, wpcomUser: DotcomUser.fake().copy(email: testEmail)))
    }

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .makeForTesting())
    }

    override func tearDown() {
        stores = nil
        super.tearDown()
    }

    // MARK: - evaluateAndConnect

    func test_evaluateAndConnect_returns_alreadyConnected_when_user_has_email() async throws {
        // Given
        let service = makeService()
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { [connectedData] action in
            if case .fetchJetpackConnectionData(_, let completion) = action {
                completion(.success(connectedData))
            }
        }

        // When
        let outcome = try await service.evaluateAndConnect(siteURL: testURL, credentials: credentials)

        // Then
        guard case .alreadyConnected(let email) = outcome else {
            return XCTFail("Expected .alreadyConnected, got \(outcome)")
        }
        XCTAssertEqual(email, testEmail)
    }

    func test_evaluateAndConnect_performs_native_connect_when_isRegistered_is_true() async throws {
        try await assertNativeConnect(
            initialData: .fake().copy(isRegistered: true, blogID: 123),
            expectsRegister: false
        )
    }

    func test_evaluateAndConnect_registers_site_when_isRegistered_is_false() async throws {
        try await assertNativeConnect(
            initialData: .fake().copy(isRegistered: false),
            expectsRegister: true
        )
    }

    func test_evaluateAndConnect_returns_webViewRequired_when_isRegistered_nil_and_plugin_installed() async throws {
        // Given
        let service = makeService()
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .fetchJetpackConnectionData(_, let completion):
                completion(.success(.fake().copy(isRegistered: nil)))
            case .retrieveJetpackPluginDetails(_, let completion):
                completion(.success(.fake()))
            default:
                break
            }
        }

        // When
        let outcome = try await service.evaluateAndConnect(siteURL: testURL, credentials: credentials)

        // Then
        guard case .webViewRequired = outcome else {
            return XCTFail("Expected .webViewRequired, got \(outcome)")
        }
    }

    func test_evaluateAndConnect_performs_native_connect_when_isRegistered_nil_and_plugin_not_found() async throws {
        try await assertNativeConnect(
            initialData: .fake().copy(isRegistered: nil, connectionOwner: "owner"),
            expectsRegister: true
        ) { action in
            if case .retrieveJetpackPluginDetails(_, let completion) = action {
                completion(.failure(NSError(domain: "Test", code: 404)))
            }
        }
    }

    func test_evaluateAndConnect_throws_when_plugin_check_fails_with_non_404() async {
        // Given
        let service = makeService()
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .fetchJetpackConnectionData(_, let completion):
                completion(.success(.fake().copy(isRegistered: nil)))
            case .retrieveJetpackPluginDetails(_, let completion):
                completion(.failure(NSError(domain: "Test", code: 500)))
            default:
                break
            }
        }

        // When
        do {
            _ = try await service.evaluateAndConnect(siteURL: testURL, credentials: credentials)
            XCTFail("Expected error to be thrown")
        } catch {
            // Then
            XCTAssertEqual((error as NSError).code, 500)
        }
    }

    // MARK: - verifyConnection

    func test_verifyConnection_retries_then_succeeds() async throws {
        // Given
        let service = makeService()
        let noEmailData = JetpackConnectionData.fake().copy(currentUser: .fake().copy(isConnected: true, wpcomUser: nil))

        var fetchCount = 0
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { [connectedData] action in
            if case .fetchJetpackConnectionData(_, let completion) = action {
                fetchCount += 1
                completion(.success(fetchCount <= 2 ? noEmailData : connectedData))
            }
        }

        // When
        let email = try await service.verifyConnection()

        // Then
        XCTAssertEqual(email, testEmail)
        XCTAssertEqual(fetchCount, 3)
    }

    func test_verifyConnection_throws_after_max_retries() async {
        // Given
        let service = makeService()
        let noEmailData = JetpackConnectionData.fake().copy(currentUser: .fake().copy(isConnected: true, wpcomUser: nil))

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            if case .fetchJetpackConnectionData(_, let completion) = action {
                completion(.success(noEmailData))
            }
        }

        // When
        do {
            _ = try await service.verifyConnection()
            XCTFail("Expected error to be thrown")
        } catch {
            // Then
            XCTAssertTrue(error is JetpackConnectionServiceError)
        }
    }

    func test_verifyConnection_retries_on_fetch_error_then_succeeds() async throws {
        // Given
        let service = makeService()

        var fetchCount = 0
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { [connectedData] action in
            if case .fetchJetpackConnectionData(_, let completion) = action {
                fetchCount += 1
                if fetchCount == 1 {
                    completion(.failure(NSError(domain: "Test", code: -1001)))
                } else {
                    completion(.success(connectedData))
                }
            }
        }

        // When
        let email = try await service.verifyConnection()

        // Then
        XCTAssertEqual(email, testEmail)
        XCTAssertEqual(fetchCount, 2)
    }
}

// MARK: - Helpers
private extension JetpackConnectionServiceTests {
    func makeService(maxRetryCount: Int = 2) -> JetpackConnectionService {
        JetpackConnectionService(siteID: 0, stores: stores, maxRetryCount: maxRetryCount, delayBeforeRetry: 0)
    }

    /// Asserts that `evaluateAndConnect` performs a full native connection flow.
    /// - Parameters:
    ///   - initialData: The connection data returned on the first fetch.
    ///   - expectsRegister: Whether `registerSite` should be triggered.
    ///   - extraHandler: Optional handler for additional actions (e.g. `retrieveJetpackPluginDetails`).
    func assertNativeConnect(
        initialData: JetpackConnectionData,
        expectsRegister: Bool,
        extraHandler: ((JetpackConnectionAction) -> Void)? = nil
    ) async throws {
        let service = makeService()
        var triggeredRegister = false
        var fetchCount = 0
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { [connectedData] action in
            switch action {
            case .fetchJetpackConnectionData(_, let completion):
                fetchCount += 1
                completion(.success(fetchCount == 1 ? initialData : connectedData))
            case .registerSite(let completion):
                triggeredRegister = true
                completion(.success(456))
            case .provisionConnection(let completion):
                completion(.success(JetpackConnectionProvisionResponse(userId: 1, scope: "admin", secret: "secret")))
            case let .finalizeConnection(_, _, _, _, completion):
                completion(.success(()))
            default:
                extraHandler?(action)
            }
        }

        let outcome = try await service.evaluateAndConnect(siteURL: testURL, credentials: credentials)

        guard case .connected(let email) = outcome else {
            return XCTFail("Expected .connected, got \(outcome)")
        }
        XCTAssertEqual(email, testEmail)
        XCTAssertEqual(triggeredRegister, expectsRegister)
    }
}
