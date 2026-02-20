import XCTest
import Yosemite
@testable import WooCommerce

@MainActor
final class WPComConnectionSetupHandlerTests: XCTestCase {

    private let testSiteURL = "https://example.com"

    private var mockConnectionService: MockJetpackConnectionService!
    private var mockPluginVersionChecker: MockPluginVersionChecker!
    private var mockPushNotesManager: MockPushNotificationsManager!
    private var delegateSpy: MockWPComConnectionSetupHandlerDelegate!

    override func setUp() {
        super.setUp()
        mockConnectionService = MockJetpackConnectionService()
        mockPluginVersionChecker = MockPluginVersionChecker()
        mockPushNotesManager = MockPushNotificationsManager()
        delegateSpy = MockWPComConnectionSetupHandlerDelegate()
    }

    override func tearDown() {
        mockConnectionService = nil
        mockPluginVersionChecker = nil
        mockPushNotesManager = nil
        delegateSpy = nil
        super.tearDown()
    }

    // MARK: - start() Tests

    func test_start_marks_connect_step_as_running_then_success() async throws {
        // Given
        let handler = makeHandler(siteAlreadyConnected: false)

        // When
        handler.start()
        await delegateSpy.waitForStepUpdate(count: 4)

        // Then
        XCTAssertGreaterThanOrEqual(delegateSpy.stepUpdates.count, 2)
        XCTAssertEqual(delegateSpy.stepUpdates[0].step, .connect)
        XCTAssertEqual(delegateSpy.stepUpdates[0].status, .running)
        XCTAssertEqual(delegateSpy.stepUpdates[1].step, .connect)
        XCTAssertEqual(delegateSpy.stepUpdates[1].status, .success)
    }

    func test_start_with_siteAlreadyConnected_skips_connect_step() async throws {
        // Given
        let handler = makeHandler(siteAlreadyConnected: true)

        // When
        handler.start()
        await delegateSpy.waitForStepUpdate(count: 3)

        // Then
        XCTAssertEqual(mockConnectionService.establishSiteConnectionCallCount, 0)
        XCTAssertFalse(delegateSpy.stepUpdates.contains { $0.step == .connect && $0.status == .running })
    }

    func test_start_with_connection_failure_marks_connect_step_as_failure() async throws {
        // Given
        mockConnectionService.establishSiteConnectionResult = .failure(NSError(domain: "Test", code: -1))
        let handler = makeHandler(siteAlreadyConnected: false)

        // When
        handler.start()
        await delegateSpy.waitForStepUpdate(count: 2)

        // Then
        XCTAssertGreaterThanOrEqual(delegateSpy.stepUpdates.count, 2)
        XCTAssertEqual(delegateSpy.stepUpdates[0].status, .running)
        assertFailureStatus(delegateSpy.stepUpdates[1].status)
    }

    // MARK: - retry() Tests

    func test_retry_after_connection_failure_restarts_connection() async throws {
        // Given
        mockConnectionService.establishSiteConnectionResult = .failure(NSError(domain: "Test", code: -1))
        let handler = makeHandler(siteAlreadyConnected: false)
        handler.start()
        await delegateSpy.waitForStepUpdate(count: 2)

        // Reset for retry
        mockConnectionService.establishSiteConnectionResult = .success(())
        delegateSpy.stepUpdates.removeAll()

        // When
        handler.retry()
        await delegateSpy.waitForStepUpdate(count: 4)

        // Then
        XCTAssertEqual(delegateSpy.stepUpdates[0].step, .connect)
        XCTAssertEqual(delegateSpy.stepUpdates[0].status, .running)
        XCTAssertEqual(delegateSpy.stepUpdates[1].step, .connect)
        XCTAssertEqual(delegateSpy.stepUpdates[1].status, .success)
    }

    // MARK: - Plugin Version Check Tests

    func test_start_with_connection_success_chains_to_plugin_check_success() async throws {
        // Given
        mockPluginVersionChecker.result = .success(.compatible)
        let handler = makeHandler()

        // When
        handler.start()
        await delegateSpy.waitForStepUpdate(count: 4)

        // Then
        XCTAssertEqual(delegateSpy.stepUpdates[2].step, .checkPlugin)
        XCTAssertEqual(delegateSpy.stepUpdates[2].status, .running)
        XCTAssertEqual(delegateSpy.stepUpdates[3].step, .checkPlugin)
        XCTAssertEqual(delegateSpy.stepUpdates[3].status, .success)
    }

    func test_start_with_siteAlreadyConnected_starts_plugin_check() async throws {
        // Given
        mockPluginVersionChecker.result = .success(.compatible)
        let handler = makeHandler(siteAlreadyConnected: true)

        // When
        handler.start()
        await delegateSpy.waitForStepUpdate(count: 3)

        // Then
        XCTAssertEqual(delegateSpy.stepUpdates[1].step, .checkPlugin)
        XCTAssertEqual(delegateSpy.stepUpdates[1].status, .running)
        XCTAssertEqual(delegateSpy.stepUpdates[2].step, .checkPlugin)
        XCTAssertEqual(delegateSpy.stepUpdates[2].status, .success)
    }

    func test_plugin_check_incompatible_marks_step_as_failure_with_outdated_message() async throws {
        // Given
        mockPluginVersionChecker.result = .success(.incompatible(currentVersion: "10.3.4", requiredVersion: "10.5.3"))
        let handler = makeHandler(siteAlreadyConnected: true)

        // When
        handler.start()
        await delegateSpy.waitForStepUpdate(count: 3)

        // Then
        XCTAssertEqual(delegateSpy.stepUpdates[2].step, .checkPlugin)
        XCTAssertEqual(delegateSpy.stepUpdates[2].status, .failure(error: .outdatedPlugin(version: "10.3.4")))
    }

    func test_plugin_check_error_marks_step_as_failure_with_generic_error() async throws {
        // Given
        mockPluginVersionChecker.result = .failure(NSError(domain: "Test", code: -1))
        let handler = makeHandler(siteAlreadyConnected: true)

        // When
        handler.start()
        await delegateSpy.waitForStepUpdate(count: 3)

        // Then
        XCTAssertEqual(delegateSpy.stepUpdates[2].step, .checkPlugin)
        assertFailureStatus(delegateSpy.stepUpdates[2].status)
    }

    func test_retry_after_plugin_check_failure_restarts_plugin_check() async throws {
        // Given
        mockPluginVersionChecker.result = .failure(NSError(domain: "Test", code: -1))
        let handler = makeHandler(siteAlreadyConnected: true)
        handler.start()
        await delegateSpy.waitForStepUpdate(count: 3)

        // Reset for retry
        mockPluginVersionChecker.result = .success(.compatible)
        delegateSpy.stepUpdates.removeAll()

        // When
        handler.retry()
        await delegateSpy.waitForStepUpdate(count: 2)

        // Then
        XCTAssertGreaterThanOrEqual(delegateSpy.stepUpdates.count, 2)
        XCTAssertEqual(delegateSpy.stepUpdates[0].status, .running)
        XCTAssertEqual(delegateSpy.stepUpdates[1].step, .checkPlugin)
        XCTAssertEqual(delegateSpy.stepUpdates[1].status, .success)
    }

    // MARK: - Plugin + Push Registration Tests

    func test_start_with_compatible_plugin_triggers_push_registration_and_completes_on_success() async throws {
        // Given
        mockPluginVersionChecker.result = .success(.compatible)
        mockPushNotesManager.registerDeviceAndWaitForTokenAcceptanceResult = .success(1)
        let handler = makeHandler(siteAlreadyConnected: true)

        // When
        handler.start()
        await delegateSpy.waitForStepUpdate(count: 5)

        // Then
        XCTAssertTrue(delegateSpy.stepUpdates.contains { $0.step == .enablePush && $0.status == .running })
        XCTAssertTrue(delegateSpy.stepUpdates.contains { $0.step == .enablePush && $0.status == .success })
        XCTAssertTrue(delegateSpy.setupCompleteCalled)
    }

    func test_start_with_compatible_plugin_marks_push_step_as_failure_on_registration_error() async throws {
        // Given
        mockPluginVersionChecker.result = .success(.compatible)
        mockPushNotesManager.registerDeviceAndWaitForTokenAcceptanceResult = .failure(NSError(domain: "Test", code: -1))
        let handler = makeHandler(siteAlreadyConnected: true)

        // When
        handler.start()

        // Wait for all steps including the async push registration failure
        await delegateSpy.waitForStepUpdate(count: 5, timeout: 5.0)

        // Then
        XCTAssertTrue(delegateSpy.stepUpdates.contains { $0.step == .enablePush && $0.status == .running })
        let pushUpdates = delegateSpy.stepUpdates.filter { $0.step == .enablePush }
        XCTAssertEqual(pushUpdates.count, 2, "Expected enablePush.running and enablePush.failure, got: \(pushUpdates.map { $0.status })")
        assertFailureStatus(pushUpdates.last?.status)
        XCTAssertFalse(delegateSpy.setupCompleteCalled)
    }

    func test_start_with_incompatible_plugin_marks_check_plugin_failure() async throws {
        // Given
        mockPluginVersionChecker.result = .success(.incompatible(currentVersion: "10.5.0", requiredVersion: "10.5.3"))
        let handler = makeHandler(siteAlreadyConnected: true)

        // When
        handler.start()
        await delegateSpy.waitForStepUpdate(count: 3)

        // Then
        let failureUpdate = delegateSpy.stepUpdates.first { update in
            if case .failure = update.status {
                return update.step == .checkPlugin
            }
            return false
        }
        XCTAssertNotNil(failureUpdate)
    }

    // MARK: - Helpers

    private func makeHandler(siteAlreadyConnected: Bool = false) -> WPComConnectionSetupHandler {
        let handler = WPComConnectionSetupHandler(
            siteID: 123,
            siteURL: testSiteURL,
            siteAlreadyConnected: siteAlreadyConnected,
            stores: MockStoresManager(sessionManager: .makeForTesting()),
            jetpackConnectionService: mockConnectionService,
            pluginVersionChecker: mockPluginVersionChecker,
            pushNotesManager: mockPushNotesManager
        )
        handler.delegate = delegateSpy
        return handler
    }

    private func assertFailureStatus(_ status: WPComConnectionSetupStep.Status?, file: StaticString = #filePath, line: UInt = #line) {
        guard let status else {
            XCTFail("Status is nil", file: file, line: line)
            return
        }
        if case .failure = status {
            // Expected
        } else {
            XCTFail("Expected .failure but got \(status)", file: file, line: line)
        }
    }
}

// MARK: - Mock Delegate

@MainActor
private final class MockWPComConnectionSetupHandlerDelegate: WPComConnectionSetupHandlerDelegate {
    struct StepUpdate {
        let step: SetupStep
        let status: WPComConnectionSetupStep.Status
    }

    var stepUpdates: [StepUpdate] = []
    var setupCompleteCalled = false

    func stepDidUpdate(_ step: SetupStep, status: WPComConnectionSetupStep.Status) {
        stepUpdates.append(StepUpdate(step: step, status: status))
    }

    func setupDidComplete() {
        setupCompleteCalled = true
    }

    /// Polls until the expected number of step updates are received.
    func waitForStepUpdate(count: Int, timeout: TimeInterval = 2.0) async {
        let deadline = Date().addingTimeInterval(timeout)
        while stepUpdates.count < count, Date() < deadline {
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
    }
}
