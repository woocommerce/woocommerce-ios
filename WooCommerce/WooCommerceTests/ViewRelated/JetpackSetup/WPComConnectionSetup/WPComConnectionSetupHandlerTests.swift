import XCTest
import Yosemite
import Networking
import NetworkingCore
@testable import WooCommerce

final class WPComConnectionSetupHandlerTests: XCTestCase {
    private var handlerObserver: MockHandlerDelegate!
    private var mockPluginChecker: MockPluginChecker!
    private var mockStores: MockStoresManager!

    @MainActor
    override func setUp() {
        super.setUp()
        handlerObserver = MockHandlerDelegate()
        mockPluginChecker = MockPluginChecker()
        mockStores = MockStoresManager(sessionManager: SessionManager.makeForTesting())
    }

    override func tearDown() {
        handlerObserver = nil
        mockPluginChecker = nil
        mockStores = nil
        super.tearDown()
    }

    // MARK: - Connection Step Tests

    @MainActor
    func test_no_credentials_skips_connection_and_proceeds_to_plugin_check() async {
        // Given - no credentials means connection step is skipped
        mockPluginChecker.result = .compatible
        let handler = givenHandler(wpcomCredentials: nil)

        // When
        handler.start()
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Then - connection step succeeds immediately, plugin check runs
        XCTAssertEqual(handlerObserver.lastStatusForStep(.connect), .success)
        XCTAssertTrue(handlerObserver.updatedSteps.contains(.checkPlugin))
        XCTAssertTrue(handlerObserver.setupDidCompleteCalled)
    }

    @MainActor
    func test_with_credentials_triggers_connection_step_running() async {
        // Given
        mockJetpackConnectionActions(delay: 1.0)
        let handler = givenHandler(wpcomCredentials: Credentials(authToken: "test"))

        // When
        handler.start()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertTrue(handlerObserver.updatedSteps.contains(.connect))
        XCTAssertEqual(handlerObserver.lastStatusForStep(.connect), .running)
    }

    @MainActor
    func test_connection_failure_does_not_proceed_to_plugin_check() async {
        // Given
        mockJetpackConnectionActions(shouldFail: true)
        mockPluginChecker.result = .compatible
        let handler = givenHandler(wpcomCredentials: Credentials(authToken: "test"))

        // When
        handler.start()
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Then
        XCTAssertTrue(handlerObserver.updatedSteps.contains(.connect))
        XCTAssertFalse(handlerObserver.updatedSteps.contains(.checkPlugin))
        if case .failure = handlerObserver.lastStatusForStep(.connect) {
            // Expected
        } else {
            XCTFail("Expected failure status for connect step")
        }
    }

    // MARK: - Plugin Check Tests

    @MainActor
    func test_plugin_compatible_triggers_setupDidComplete() async {
        // Given - skip connection by passing nil credentials
        mockPluginChecker.result = .compatible
        let handler = givenHandler(wpcomCredentials: nil)

        // When
        handler.start()
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Then
        XCTAssertTrue(handlerObserver.setupDidCompleteCalled)
        XCTAssertEqual(handlerObserver.lastStatusForStep(.checkPlugin), .success)
    }

    @MainActor
    func test_plugin_incompatible_triggers_failure() async {
        // Given - skip connection by passing nil credentials
        mockPluginChecker.result = .incompatible(currentVersion: "9.0.0", requiredVersion: "10.4.3")
        let handler = givenHandler(wpcomCredentials: nil)

        // When
        handler.start()
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Then
        if case .failure = handlerObserver.lastStatusForStep(.checkPlugin) {
            // Expected
        } else {
            XCTFail("Expected failure status for checkPlugin step")
        }
        XCTAssertFalse(handlerObserver.setupDidCompleteCalled)
    }

    // MARK: - Retry and Cancel Tests

    @MainActor
    func test_retry_restarts_from_failed_step() async {
        // Given - plugin check fails first
        mockPluginChecker.result = .incompatible(currentVersion: "9.0.0", requiredVersion: "10.4.3")
        let handler = givenHandler(wpcomCredentials: nil)

        // First attempt - fails at plugin check
        handler.start()
        try? await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertFalse(handlerObserver.setupDidCompleteCalled)

        // Now make it succeed
        mockPluginChecker.result = .compatible

        // When - retry
        handler.retry()
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Then - should complete
        XCTAssertTrue(handlerObserver.setupDidCompleteCalled)
    }

    @MainActor
    func test_cancel_stops_ongoing_task() async {
        // Given
        mockPluginChecker.result = .compatible
        mockPluginChecker.delay = 1.0
        let handler = givenHandler(wpcomCredentials: nil)

        // When
        handler.start()
        try? await Task.sleep(nanoseconds: 100_000_000)
        handler.cancel()
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Then - should not have completed setup since we cancelled
        XCTAssertFalse(handlerObserver.setupDidCompleteCalled)
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
    private func mockJetpackConnectionActions(shouldFail: Bool = false, delay: TimeInterval = 0) {
        mockStores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            if delay > 0 {
                Task {
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    self.handleJetpackAction(action, shouldFail: shouldFail)
                }
            } else {
                self.handleJetpackAction(action, shouldFail: shouldFail)
            }
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
