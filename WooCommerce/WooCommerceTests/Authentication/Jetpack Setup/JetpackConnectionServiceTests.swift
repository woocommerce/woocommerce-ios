import XCTest
import Yosemite
@testable import WooCommerce

@MainActor
final class JetpackConnectionServiceTests: XCTestCase {
    private let testURL = "https://example.com"
    private let credentials = Credentials.wpcom(username: "test", authToken: "secret", siteAddress: "https://example.com")

    private var stores: MockStoresManager!

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
        let service = JetpackConnectionService(stores: stores, delayBeforeRetry: 0)
        let data = JetpackConnectionData.fake().copy(
            currentUser: .fake().copy(isConnected: true, wpcomUser: DotcomUser.fake().copy(email: "user@example.com"))
        )

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .fetchJetpackConnectionData(let completion):
                completion(.success(data))
            default:
                break
            }
        }

        // When
        let outcome = try await service.evaluateAndConnect(siteURL: testURL, credentials: credentials)

        // Then
        guard case .alreadyConnected(let email) = outcome else {
            return XCTFail("Expected .alreadyConnected, got \(outcome)")
        }
        XCTAssertEqual(email, "user@example.com")
    }

    func test_evaluateAndConnect_performs_native_connect_when_isRegistered_is_true() async throws {
        // Given
        let service = JetpackConnectionService(stores: stores, delayBeforeRetry: 0)
        let initialData = JetpackConnectionData.fake().copy(isRegistered: true, blogID: 123)
        let verifiedData = JetpackConnectionData.fake().copy(
            currentUser: .fake().copy(isConnected: true, wpcomUser: DotcomUser.fake().copy(email: "user@example.com"))
        )

        var triggeredRegister = false
        var fetchCount = 0
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .fetchJetpackConnectionData(let completion):
                fetchCount += 1
                if fetchCount == 1 {
                    completion(.success(initialData))
                } else {
                    completion(.success(verifiedData))
                }
            case .registerSite:
                triggeredRegister = true
            case .provisionConnection(let completion):
                completion(.success(JetpackConnectionProvisionResponse(userId: 1, scope: "admin", secret: "secret")))
            case let .finalizeConnection(_, _, _, _, completion):
                completion(.success(()))
            default:
                break
            }
        }

        // When
        let outcome = try await service.evaluateAndConnect(siteURL: testURL, credentials: credentials)

        // Then
        guard case .connected(let email) = outcome else {
            return XCTFail("Expected .connected, got \(outcome)")
        }
        XCTAssertEqual(email, "user@example.com")
        XCTAssertFalse(triggeredRegister)
    }

    func test_evaluateAndConnect_registers_site_when_isRegistered_is_false() async throws {
        // Given
        let service = JetpackConnectionService(stores: stores, delayBeforeRetry: 0)
        let initialData = JetpackConnectionData.fake().copy(isRegistered: false)
        let verifiedData = JetpackConnectionData.fake().copy(
            currentUser: .fake().copy(isConnected: true, wpcomUser: DotcomUser.fake().copy(email: "user@example.com"))
        )

        var triggeredRegister = false
        var fetchCount = 0
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .fetchJetpackConnectionData(let completion):
                fetchCount += 1
                if fetchCount == 1 {
                    completion(.success(initialData))
                } else {
                    completion(.success(verifiedData))
                }
            case .registerSite(let completion):
                triggeredRegister = true
                completion(.success(456))
            case .provisionConnection(let completion):
                completion(.success(JetpackConnectionProvisionResponse(userId: 1, scope: "admin", secret: "secret")))
            case let .finalizeConnection(_, _, _, _, completion):
                completion(.success(()))
            default:
                break
            }
        }

        // When
        let outcome = try await service.evaluateAndConnect(siteURL: testURL, credentials: credentials)

        // Then
        guard case .connected(let email) = outcome else {
            return XCTFail("Expected .connected, got \(outcome)")
        }
        XCTAssertEqual(email, "user@example.com")
        XCTAssertTrue(triggeredRegister)
    }

    func test_evaluateAndConnect_returns_webViewRequired_when_isRegistered_nil_and_plugin_installed() async throws {
        // Given
        let service = JetpackConnectionService(stores: stores, delayBeforeRetry: 0)
        let data = JetpackConnectionData.fake().copy(isRegistered: nil)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .fetchJetpackConnectionData(let completion):
                completion(.success(data))
            case .retrieveJetpackPluginDetails(let completion):
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
        // Given
        let service = JetpackConnectionService(stores: stores, delayBeforeRetry: 0)
        let initialData = JetpackConnectionData.fake().copy(isRegistered: nil, connectionOwner: "owner")
        let verifiedData = JetpackConnectionData.fake().copy(
            currentUser: .fake().copy(isConnected: true, wpcomUser: DotcomUser.fake().copy(email: "user@example.com"))
        )

        var fetchCount = 0
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .fetchJetpackConnectionData(let completion):
                fetchCount += 1
                if fetchCount == 1 {
                    completion(.success(initialData))
                } else {
                    completion(.success(verifiedData))
                }
            case .retrieveJetpackPluginDetails(let completion):
                completion(.failure(NSError(domain: "Test", code: 404)))
            case .registerSite(let completion):
                completion(.success(789))
            case .provisionConnection(let completion):
                completion(.success(JetpackConnectionProvisionResponse(userId: 1, scope: "admin", secret: "secret")))
            case let .finalizeConnection(_, _, _, _, completion):
                completion(.success(()))
            default:
                break
            }
        }

        // When
        let outcome = try await service.evaluateAndConnect(siteURL: testURL, credentials: credentials)

        // Then
        guard case .connected(let email) = outcome else {
            return XCTFail("Expected .connected, got \(outcome)")
        }
        XCTAssertEqual(email, "user@example.com")
    }

    func test_evaluateAndConnect_throws_when_plugin_check_fails_with_non_404() async {
        // Given
        let service = JetpackConnectionService(stores: stores, delayBeforeRetry: 0)
        let data = JetpackConnectionData.fake().copy(isRegistered: nil)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .fetchJetpackConnectionData(let completion):
                completion(.success(data))
            case .retrieveJetpackPluginDetails(let completion):
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
        let service = JetpackConnectionService(stores: stores, maxRetryCount: 2, delayBeforeRetry: 0)
        let noEmailData = JetpackConnectionData.fake().copy(
            currentUser: .fake().copy(isConnected: true, wpcomUser: nil)
        )
        let emailData = JetpackConnectionData.fake().copy(
            currentUser: .fake().copy(isConnected: true, wpcomUser: DotcomUser.fake().copy(email: "user@example.com"))
        )

        var fetchCount = 0
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .fetchJetpackConnectionData(let completion):
                fetchCount += 1
                if fetchCount <= 2 {
                    completion(.success(noEmailData))
                } else {
                    completion(.success(emailData))
                }
            default:
                break
            }
        }

        // When
        let email = try await service.verifyConnection()

        // Then
        XCTAssertEqual(email, "user@example.com")
        XCTAssertEqual(fetchCount, 3)
    }

    func test_verifyConnection_throws_after_max_retries() async {
        // Given
        let service = JetpackConnectionService(stores: stores, maxRetryCount: 2, delayBeforeRetry: 0)
        let noEmailData = JetpackConnectionData.fake().copy(
            currentUser: .fake().copy(isConnected: true, wpcomUser: nil)
        )

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .fetchJetpackConnectionData(let completion):
                completion(.success(noEmailData))
            default:
                break
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
        let service = JetpackConnectionService(stores: stores, maxRetryCount: 2, delayBeforeRetry: 0)
        let emailData = JetpackConnectionData.fake().copy(
            currentUser: .fake().copy(isConnected: true, wpcomUser: DotcomUser.fake().copy(email: "user@example.com"))
        )

        var fetchCount = 0
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .fetchJetpackConnectionData(let completion):
                fetchCount += 1
                if fetchCount == 1 {
                    completion(.failure(NSError(domain: "Test", code: -1001)))
                } else {
                    completion(.success(emailData))
                }
            default:
                break
            }
        }

        // When
        let email = try await service.verifyConnection()

        // Then
        XCTAssertEqual(email, "user@example.com")
        XCTAssertEqual(fetchCount, 2)
    }
}
