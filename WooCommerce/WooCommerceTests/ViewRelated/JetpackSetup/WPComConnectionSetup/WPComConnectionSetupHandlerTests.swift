import XCTest
@testable import WooCommerce

final class WPComConnectionSetupHandlerTests: XCTestCase {
    private var handlerObserver: MockHandlerDelegate!
    private var mockConnectionService: MockConnectionService!
    private var mockPluginChecker: MockPluginChecker!

    @MainActor
    override func setUp() {
        super.setUp()
        handlerObserver = MockHandlerDelegate()
        mockConnectionService = MockConnectionService()
        mockPluginChecker = MockPluginChecker()
    }

    override func tearDown() {
        handlerObserver = nil
        mockConnectionService = nil
        mockPluginChecker = nil
        super.tearDown()
    }

    @MainActor
    func test_start_triggers_connection_step_running() async {
        // Given
        mockConnectionService.delay = 1.0  // Slow down so we can observe the running state
        let handler = givenHandler()

        // When
        handler.start()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertTrue(handlerObserver.updatedSteps.contains(.connect))
        XCTAssertEqual(handlerObserver.lastStatusForStep(.connect), .running)
    }

    @MainActor
    func test_successful_connection_triggers_plugin_check() async {
        // Given
        mockConnectionService.shouldSucceed = true
        mockPluginChecker.result = .compatible
        let handler = givenHandler()

        // When
        handler.start()
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Then
        XCTAssertTrue(handlerObserver.updatedSteps.contains(.connect))
        XCTAssertTrue(handlerObserver.updatedSteps.contains(.checkPlugin))
    }

    @MainActor
    func test_connection_failure_does_not_proceed_to_plugin_check() async {
        // Given
        mockConnectionService.shouldSucceed = false
        mockPluginChecker.result = .compatible
        let handler = givenHandler()

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

    @MainActor
    func test_plugin_compatible_triggers_setupDidComplete() async {
        // Given
        mockConnectionService.shouldSucceed = true
        mockPluginChecker.result = .compatible
        let handler = givenHandler()

        // When
        handler.start()
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Then
        XCTAssertTrue(handlerObserver.setupDidCompleteCalled)
    }

    @MainActor
    func test_plugin_incompatible_triggers_failure() async {
        // Given
        mockConnectionService.shouldSucceed = true
        mockPluginChecker.result = .incompatible(currentVersion: "9.0.0", requiredVersion: "10.4.3")
        let handler = givenHandler()

        // When
        handler.start()
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Then
        if case .failure = handlerObserver.lastStatusForStep(.checkPlugin) {
            // Expected
        } else {
            XCTFail("Expected failure status for checkPlugin step")
        }
        XCTAssertFalse(handlerObserver.setupDidCompleteCalled)
    }

    @MainActor
    func test_retry_restarts_from_failed_step() async {
        // Given
        mockConnectionService.shouldSucceed = false
        mockPluginChecker.result = .compatible
        let handler = givenHandler()

        // First attempt - fails
        handler.start()
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Now make it succeed
        mockConnectionService.shouldSucceed = true

        // When - retry
        handler.retry()
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Then - should have reached plugin check
        XCTAssertTrue(handlerObserver.updatedSteps.contains(.checkPlugin))
    }

    @MainActor
    func test_cancel_stops_ongoing_task() async {
        // Given
        mockConnectionService.shouldSucceed = true
        mockConnectionService.delay = 1.0
        mockPluginChecker.result = .compatible
        let handler = givenHandler()

        // When
        handler.start()
        try? await Task.sleep(nanoseconds: 100_000_000)
        handler.cancel()
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Then - should not have completed setup since we cancelled during connection
        XCTAssertFalse(handlerObserver.setupDidCompleteCalled)
    }

    @MainActor
    private func givenHandler() -> WPComConnectionSetupHandler {
        let handler = WPComConnectionSetupHandler(
            connectionService: mockConnectionService,
            pluginChecker: mockPluginChecker
        )
        handler.delegate = handlerObserver
        return handler
    }
}
