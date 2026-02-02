import XCTest
@testable import WooCommerce

final class WPComConnectionSetupHandlerTests: XCTestCase {

    // MARK: - Start Tests

    @MainActor
    func test_start_triggers_connection_step_running() async {
        // Given
        let mockDelegate = MockHandlerDelegate()
        let mockConnectionService = MockConnectionService()
        let mockPluginChecker = MockPluginChecker()

        let handler = WPComConnectionSetupHandler(
            connectionService: mockConnectionService,
            pluginChecker: mockPluginChecker
        )
        handler.delegate = mockDelegate

        // When
        handler.start()

        // Give the task time to start
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertTrue(mockDelegate.updatedSteps.contains(.connect))
        XCTAssertEqual(mockDelegate.lastStatusForStep(.connect), .running)
    }

    @MainActor
    func test_successful_connection_triggers_plugin_check() async {
        // Given
        let mockDelegate = MockHandlerDelegate()
        let mockConnectionService = MockConnectionService(shouldSucceed: true)
        let mockPluginChecker = MockPluginChecker(result: .compatible)

        let handler = WPComConnectionSetupHandler(
            connectionService: mockConnectionService,
            pluginChecker: mockPluginChecker
        )
        handler.delegate = mockDelegate

        // When
        handler.start()

        // Give tasks time to complete
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Then
        XCTAssertTrue(mockDelegate.updatedSteps.contains(.connect))
        XCTAssertTrue(mockDelegate.updatedSteps.contains(.checkPlugin))
    }

    @MainActor
    func test_connection_failure_does_not_proceed_to_plugin_check() async {
        // Given
        let mockDelegate = MockHandlerDelegate()
        let mockConnectionService = MockConnectionService(shouldSucceed: false)
        let mockPluginChecker = MockPluginChecker(result: .compatible)

        let handler = WPComConnectionSetupHandler(
            connectionService: mockConnectionService,
            pluginChecker: mockPluginChecker
        )
        handler.delegate = mockDelegate

        // When
        handler.start()

        // Give tasks time to complete
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Then
        XCTAssertTrue(mockDelegate.updatedSteps.contains(.connect))
        XCTAssertFalse(mockDelegate.updatedSteps.contains(.checkPlugin))
        if case .failure = mockDelegate.lastStatusForStep(.connect) {
            // Expected
        } else {
            XCTFail("Expected failure status for connect step")
        }
    }

    @MainActor
    func test_plugin_compatible_triggers_setupDidComplete() async {
        // Given
        let mockDelegate = MockHandlerDelegate()
        let mockConnectionService = MockConnectionService(shouldSucceed: true)
        let mockPluginChecker = MockPluginChecker(result: .compatible)

        let handler = WPComConnectionSetupHandler(
            connectionService: mockConnectionService,
            pluginChecker: mockPluginChecker
        )
        handler.delegate = mockDelegate

        // When
        handler.start()

        // Give tasks time to complete
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Then
        XCTAssertTrue(mockDelegate.setupDidCompleteCalled)
    }

    @MainActor
    func test_plugin_incompatible_triggers_failure() async {
        // Given
        let mockDelegate = MockHandlerDelegate()
        let mockConnectionService = MockConnectionService(shouldSucceed: true)
        let mockPluginChecker = MockPluginChecker(result: .incompatible(currentVersion: "9.0.0", requiredVersion: "10.4.3"))

        let handler = WPComConnectionSetupHandler(
            connectionService: mockConnectionService,
            pluginChecker: mockPluginChecker
        )
        handler.delegate = mockDelegate

        // When
        handler.start()

        // Give tasks time to complete
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Then
        if case .failure = mockDelegate.lastStatusForStep(.checkPlugin) {
            // Expected
        } else {
            XCTFail("Expected failure status for checkPlugin step")
        }
        XCTAssertFalse(mockDelegate.setupDidCompleteCalled)
    }

    // MARK: - Retry Tests

    @MainActor
    func test_retry_restarts_from_failed_step() async {
        // Given
        let mockDelegate = MockHandlerDelegate()
        var connectionAttempts = 0
        let mockConnectionService = MockConnectionService(shouldSucceed: false)
        let mockPluginChecker = MockPluginChecker(result: .compatible)

        let handler = WPComConnectionSetupHandler(
            connectionService: mockConnectionService,
            pluginChecker: mockPluginChecker
        )
        handler.delegate = mockDelegate

        // First attempt - fails
        handler.start()
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Now make it succeed
        mockConnectionService.shouldSucceed = true

        // When - retry
        handler.retry()
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Then - should have reached plugin check
        XCTAssertTrue(mockDelegate.updatedSteps.contains(.checkPlugin))
    }

    // MARK: - Cancel Tests

    @MainActor
    func test_cancel_stops_ongoing_task() async {
        // Given
        let mockDelegate = MockHandlerDelegate()
        let mockConnectionService = MockConnectionService(shouldSucceed: true, delay: 1.0)
        let mockPluginChecker = MockPluginChecker(result: .compatible)

        let handler = WPComConnectionSetupHandler(
            connectionService: mockConnectionService,
            pluginChecker: mockPluginChecker
        )
        handler.delegate = mockDelegate

        // When
        handler.start()
        try? await Task.sleep(nanoseconds: 100_000_000) // Give it time to start
        handler.cancel()
        try? await Task.sleep(nanoseconds: 500_000_000) // Wait to see if it continued

        // Then - should not have completed setup since we cancelled during connection
        XCTAssertFalse(mockDelegate.setupDidCompleteCalled)
    }
}

// MARK: - Mock Delegate

@MainActor
private final class MockHandlerDelegate: WPComConnectionSetupHandlerDelegate {
    private(set) var updatedSteps: Set<SetupStep> = []
    private(set) var stepStatuses: [SetupStep: WPComConnectionSetupStep.Status] = [:]
    private(set) var setupDidCompleteCalled = false

    func stepDidUpdate(_ step: SetupStep, status: WPComConnectionSetupStep.Status) {
        updatedSteps.insert(step)
        stepStatuses[step] = status
    }

    func setupDidComplete() {
        setupDidCompleteCalled = true
    }

    func lastStatusForStep(_ step: SetupStep) -> WPComConnectionSetupStep.Status? {
        stepStatuses[step]
    }
}

// MARK: - Mock Services

private final class MockConnectionService: WPComConnectionServiceProtocol {
    var shouldSucceed: Bool
    let delay: TimeInterval

    init(shouldSucceed: Bool = true, delay: TimeInterval = 0) {
        self.shouldSucceed = shouldSucceed
        self.delay = delay
    }

    func connect() async throws {
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        if !shouldSucceed {
            throw MockError.connectionFailed
        }
    }
}

private final class MockPluginChecker: PluginCompatibilityCheckerProtocol {
    let result: PluginCompatibilityResult
    var shouldThrow = false

    init(result: PluginCompatibilityResult) {
        self.result = result
    }

    func checkCompatibility() async throws -> PluginCompatibilityResult {
        if shouldThrow {
            throw MockError.pluginCheckFailed
        }
        return result
    }
}

private enum MockError: Error {
    case connectionFailed
    case pluginCheckFailed
}
