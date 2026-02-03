import XCTest
import Yosemite
import Networking
import NetworkingCore
@testable import WooCommerce

final class WPComConnectionSetupHandlerTests: XCTestCase {
    private var handlerObserver: MockWPComConnectionSetupHandlerDelegate!
    private var mockPluginChecker: MockPluginVersionChecker!
    private var mockStores: MockStoresManager!

    @MainActor
    override func setUp() {
        super.setUp()
        handlerObserver = MockWPComConnectionSetupHandlerDelegate()
        mockPluginChecker = MockPluginVersionChecker()
        mockStores = MockStoresManager(sessionManager: SessionManager.makeForTesting())
    }

    override func tearDown() {
        handlerObserver = nil
        mockPluginChecker = nil
        mockStores = nil
        super.tearDown()
    }

    @MainActor
    func test_no_credentials_completes_setup_with_compatible_plugin() {
        // Given
        let expectation = expectation(description: "Setup completes")
        mockPluginChecker.result = .compatible
        handlerObserver.onSetupComplete = { expectation.fulfill() }

        // When
        let handler = givenHandler(wpcomCredentials: nil)
        handler.start()

        // Then
        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(handlerObserver.lastStatusForStep(.connect), .success)
        XCTAssertEqual(handlerObserver.lastStatusForStep(.checkPlugin), .success)
        XCTAssertTrue(handlerObserver.setupDidCompleteCalled)
    }

    @MainActor
    func test_connection_failure_stops_flow() {
        // Given
        let expectation = expectation(description: "Connection fails")
        mockJetpackConnectionActions(shouldFail: true)
        handlerObserver.onStepUpdate = { step, status in
            if step == .connect, case .failure = status {
                expectation.fulfill()
            }
        }

        // When
        let handler = givenHandler(wpcomCredentials: Credentials(authToken: "test"))
        handler.start()

        // Then
        waitForExpectations(timeout: 1.0)
        XCTAssertFalse(handlerObserver.updatedSteps.contains(.checkPlugin))
    }

    @MainActor
    func test_plugin_incompatible_triggers_failure_and_retry_succeeds() {
        // Given - plugin is incompatible
        let failExpectation = expectation(description: "Plugin check fails")
        mockPluginChecker.result = .incompatible(currentVersion: "9.0.0", requiredVersion: "10.4.3")
        handlerObserver.onStepUpdate = { step, status in
            if step == .checkPlugin, case .failure = status {
                failExpectation.fulfill()
            }
        }

        let handler = givenHandler(wpcomCredentials: nil)
        handler.start()
        waitForExpectations(timeout: 1.0)
        XCTAssertFalse(handlerObserver.setupDidCompleteCalled)

        // When - retry with compatible plugin
        let successExpectation = expectation(description: "Retry succeeds")
        mockPluginChecker.result = .compatible
        handlerObserver.onSetupComplete = { successExpectation.fulfill() }

        handler.retry()

        // Then
        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(handlerObserver.setupDidCompleteCalled)
    }

    // MARK: - Helpers

    @MainActor
    private func givenHandler(wpcomCredentials: Credentials?) -> WPComConnectionSetupHandler {
        let handler = WPComConnectionSetupHandler(
            siteURL: "https://test.com",
            wpcomCredentials: wpcomCredentials,
            pluginChecker: mockPluginChecker,
            stores: mockStores
        )
        handler.delegate = handlerObserver
        return handler
    }

    @MainActor
    private func mockJetpackConnectionActions(shouldFail: Bool = false) {
        mockStores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            self.handleJetpackAction(action, shouldFail: shouldFail)
        }
    }

    private func handleJetpackAction(_ action: JetpackConnectionAction, shouldFail: Bool) {
        switch action {
        case .fetchJetpackConnectionData(let completion):
            if shouldFail {
                completion(.failure(MockError.anyError))
            } else {
                let connectedUser = JetpackUser.fake().copy(isConnected: true, wpcomUser: .fake())
                let connectionData = JetpackConnectionData.fake().copy(currentUser: connectedUser)
                completion(.success(connectionData))
            }
        case .registerSite(let completion):
            completion(.success(12345))
        case .provisionConnection(let completion):
            completion(.success(JetpackConnectionProvisionResponse(userId: 1, scope: "test", secret: "test")))
        case .finalizeConnection(_, _, _, _, let completion):
            completion(.success(()))
        default:
            break
        }
    }
}
