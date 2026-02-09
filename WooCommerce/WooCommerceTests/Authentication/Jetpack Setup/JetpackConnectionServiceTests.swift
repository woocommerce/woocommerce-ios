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

    // MARK: - Tests

    func test_connect_returns_email_on_success() async throws {
        // Given
        let service = JetpackConnectionService(stores: stores, maxRetryCount: 2, retryDelay: 0)
        let connectionData = JetpackConnectionData.fake().copy(isRegistered: false)

        var fetchCount = 0
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .registerSite(let completion):
                completion(.success(123))
            case .provisionConnection(let completion):
                completion(.success(JetpackConnectionProvisionResponse(userId: 1, scope: "admin", secret: "secret")))
            case let .finalizeConnection(_, _, _, _, completion):
                completion(.success(()))
            case .fetchJetpackConnectionData(let completion):
                fetchCount += 1
                let data = JetpackConnectionData.fake().copy(
                    currentUser: .fake().copy(isConnected: true, wpcomUser: DotcomUser.fake().copy(email: "test@mail.com"))
                )
                completion(.success(data))
            default:
                break
            }
        }

        // When
        let email = try await service.connect(with: connectionData, siteURL: testURL, credentials: credentials)

        // Then
        XCTAssertEqual(email, "test@mail.com")
        XCTAssertEqual(fetchCount, 1) // Verify step fetched once
    }

    func test_connect_skips_register_when_registered_with_blogID() async throws {
        // Given
        let service = JetpackConnectionService(stores: stores, maxRetryCount: 2, retryDelay: 0)
        let connectionData = JetpackConnectionData.fake().copy(isRegistered: true, blogID: 456)

        var triggeredRegister = false
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .registerSite:
                triggeredRegister = true
            case .provisionConnection(let completion):
                completion(.success(JetpackConnectionProvisionResponse(userId: 1, scope: "admin", secret: "secret")))
            case let .finalizeConnection(_, _, _, _, completion):
                completion(.success(()))
            case .fetchJetpackConnectionData(let completion):
                let data = JetpackConnectionData.fake().copy(
                    currentUser: .fake().copy(isConnected: true, wpcomUser: DotcomUser.fake().copy(email: "test@mail.com"))
                )
                completion(.success(data))
            default:
                break
            }
        }

        // When
        let email = try await service.connect(with: connectionData, siteURL: testURL, credentials: credentials)

        // Then
        XCTAssertEqual(email, "test@mail.com")
        XCTAssertFalse(triggeredRegister)
    }

    func test_connect_throws_on_provision_failure() async {
        // Given
        let service = JetpackConnectionService(stores: stores, maxRetryCount: 2, retryDelay: 0)
        let connectionData = JetpackConnectionData.fake().copy(isRegistered: true, blogID: 123)
        let expectedError = NSError(domain: "Test", code: 500)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .provisionConnection(let completion):
                completion(.failure(expectedError))
            default:
                break
            }
        }

        // When
        do {
            _ = try await service.connect(with: connectionData, siteURL: testURL, credentials: credentials)
            XCTFail("Expected error to be thrown")
        } catch {
            // Then
            XCTAssertEqual((error as NSError).code, 500)
        }
    }

    func test_connect_throws_verificationFailed_after_max_retries() async {
        // Given
        let service = JetpackConnectionService(stores: stores, maxRetryCount: 2, retryDelay: 0)
        let connectionData = JetpackConnectionData.fake().copy(isRegistered: true, blogID: 123)

        var fetchCount = 0
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .provisionConnection(let completion):
                completion(.success(JetpackConnectionProvisionResponse(userId: 1, scope: "admin", secret: "secret")))
            case let .finalizeConnection(_, _, _, _, completion):
                completion(.success(()))
            case .fetchJetpackConnectionData(let completion):
                fetchCount += 1
                // Always return no wpcomUser
                completion(.success(.fake().copy(currentUser: .fake().copy(isConnected: true, wpcomUser: nil))))
            default:
                break
            }
        }

        // When
        do {
            _ = try await service.connect(with: connectionData, siteURL: testURL, credentials: credentials)
            XCTFail("Expected verificationFailed error")
        } catch {
            // Then
            XCTAssertTrue(error is JetpackConnectionServiceError)
            XCTAssertEqual(fetchCount, 3) // initial + 2 retries
        }
    }
}
