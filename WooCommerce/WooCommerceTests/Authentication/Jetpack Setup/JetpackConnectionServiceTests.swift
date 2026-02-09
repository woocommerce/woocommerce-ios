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

    func test_connect_completes_full_flow() async throws {
        // Given
        let service = JetpackConnectionService(stores: stores)
        let connectionData = JetpackConnectionData.fake().copy(isRegistered: false)

        var triggeredRegister = false
        var triggeredProvision = false
        var triggeredFinalize = false
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .registerSite(let completion):
                triggeredRegister = true
                completion(.success(123))
            case .provisionConnection(let completion):
                triggeredProvision = true
                completion(.success(JetpackConnectionProvisionResponse(userId: 1, scope: "admin", secret: "secret")))
            case let .finalizeConnection(_, _, _, _, completion):
                triggeredFinalize = true
                completion(.success(()))
            default:
                break
            }
        }

        // When
        try await service.connect(with: connectionData, siteURL: testURL, credentials: credentials)

        // Then
        XCTAssertTrue(triggeredRegister)
        XCTAssertTrue(triggeredProvision)
        XCTAssertTrue(triggeredFinalize)
    }

    func test_connect_skips_register_when_registered_with_blogID() async throws {
        // Given
        let service = JetpackConnectionService(stores: stores)
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
            default:
                break
            }
        }

        // When
        try await service.connect(with: connectionData, siteURL: testURL, credentials: credentials)

        // Then
        XCTAssertFalse(triggeredRegister)
    }

    func test_connect_throws_on_provision_failure() async {
        // Given
        let service = JetpackConnectionService(stores: stores)
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
            try await service.connect(with: connectionData, siteURL: testURL, credentials: credentials)
            XCTFail("Expected error to be thrown")
        } catch {
            // Then
            XCTAssertEqual((error as NSError).code, 500)
        }
    }
}
