import XCTest
import protocol WooFoundation.Analytics
@testable import WooCommerce

@MainActor
final class WPComConnectionSetupViewModelTests: XCTestCase {

    private var mockHandler: MockWPComConnectionSetupHandler!
    private var dismissCalled: Bool!
    private var goToStoreCalled: Bool!
    private var updatePluginCalled: Bool!

    override func setUp() {
        super.setUp()
        mockHandler = MockWPComConnectionSetupHandler()
        dismissCalled = false
        goToStoreCalled = false
        updatePluginCalled = false
    }

    override func tearDown() {
        mockHandler = nil
        dismissCalled = nil
        goToStoreCalled = nil
        updatePluginCalled = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_initial_state_has_three_steps_and_disabled_button() {
        // Given
        let viewModel = makeViewModel()

        // Then
        XCTAssertEqual(viewModel.steps.count, 3)
        XCTAssertEqual(viewModel.primaryButtonTitle, "Go to My Store")
        XCTAssertFalse(viewModel.isPrimaryButtonEnabled)
        XCTAssertFalse(viewModel.isShowingSecondaryButton)
        XCTAssertFalse(viewModel.isShowingDoneButton)
    }

    // MARK: - Delegate Update Tests

    func test_stepDidUpdate_updates_step_status() {
        // Given
        let viewModel = makeViewModel()

        // When
        mockHandler.simulateStepUpdate(.checkPlugin, status: .running)

        // Then
        XCTAssertEqual(viewModel.steps[0].status, .running)
    }

    func test_connection_failure_shows_tryAgain_button() {
        // Given
        let viewModel = makeViewModel()

        // When
        mockHandler.simulateStepUpdate(.connect, status: .failure(error: .generic(reason: "Connection failed")))

        // Then
        XCTAssertEqual(viewModel.primaryButtonTitle, "Try again")
        XCTAssertTrue(viewModel.isPrimaryButtonEnabled)
        XCTAssertFalse(viewModel.isShowingSecondaryButton)
    }

    func test_plugin_failure_outdated_shows_updatePlugin_and_tryAgain_buttons() {
        // Given
        let viewModel = makeViewModel()

        // When
        mockHandler.simulateStepUpdate(.checkPlugin, status: .failure(error: .outdatedPlugin(version: "10.3.4")))

        // Then
        XCTAssertEqual(viewModel.primaryButtonTitle, "Update plugin")
        XCTAssertTrue(viewModel.isPrimaryButtonEnabled)
        XCTAssertTrue(viewModel.isShowingSecondaryButton)
        XCTAssertEqual(viewModel.secondaryButtonTitle, "Try again")
    }

    func test_plugin_failure_other_shows_tryAgain_button() {
        // Given
        let viewModel = makeViewModel()

        // When
        mockHandler.simulateStepUpdate(.checkPlugin, status: .failure(error: .generic(reason: "Network error")))

        // Then
        XCTAssertEqual(viewModel.primaryButtonTitle, "Try again")
        XCTAssertTrue(viewModel.isPrimaryButtonEnabled)
        XCTAssertFalse(viewModel.isShowingSecondaryButton)
    }

    func test_setupDidComplete_enables_goToMyStore_button() {
        // Given
        let viewModel = makeViewModel()

        // When
        mockHandler.simulateSetupComplete()

        // Then
        XCTAssertEqual(viewModel.primaryButtonTitle, "Go to My Store")
        XCTAssertTrue(viewModel.isPrimaryButtonEnabled)
        XCTAssertTrue(viewModel.isShowingDoneButton)
    }

    // MARK: - Button Action Tests

    func test_primaryButtonTapped_on_completed_calls_goToStore() {
        // Given
        let viewModel = makeViewModel()
        mockHandler.simulateSetupComplete()

        // When
        viewModel.primaryButtonTapped()

        // Then
        XCTAssertTrue(goToStoreCalled)
    }

    func test_primaryButtonTapped_on_plugin_failure_outdated_calls_updatePlugin() {
        // Given
        let viewModel = makeViewModel()
        mockHandler.simulateStepUpdate(.checkPlugin, status: .failure(error: .outdatedPlugin(version: "10.3.4")))

        // When
        viewModel.primaryButtonTapped()

        // Then
        XCTAssertTrue(updatePluginCalled)
    }

    func test_primaryButtonTapped_on_plugin_failure_other_retries() {
        // Given
        let viewModel = makeViewModel()
        mockHandler.simulateStepUpdate(.checkPlugin, status: .failure(error: .generic(reason: "Network error")))

        // When
        viewModel.primaryButtonTapped()

        // Then
        XCTAssertEqual(mockHandler.retryCallCount, 1)
    }

    // MARK: - Dismiss Tests

    func test_cancelTapped_calls_handler_cancel_and_dismiss() {
        // Given
        let viewModel = makeViewModel()

        // When
        viewModel.cancelTapped()

        // Then
        XCTAssertEqual(mockHandler.cancelCallCount, 1)
        XCTAssertTrue(dismissCalled)
    }

    func test_doneTapped_calls_dismiss() {
        // Given
        let viewModel = makeViewModel()

        // When
        viewModel.doneTapped()

        // Then
        XCTAssertTrue(dismissCalled)
    }

    // MARK: - setPluginOutdatedState Tests

    func test_setPluginOutdatedState_sets_checkPlugin_to_failure() {
        // Given
        let viewModel = makeViewModel()

        // When
        viewModel.setPluginOutdatedState(version: "10.4.0")

        // Then
        XCTAssertEqual(viewModel.steps[0].status, .failure(error: .outdatedPlugin(version: "10.4.0")))
        XCTAssertEqual(viewModel.steps[1].status, .notStarted)
        XCTAssertEqual(viewModel.steps[2].status, .notStarted)
    }

    func test_setPluginOutdatedState_shows_updatePlugin_primary_and_tryAgain_secondary() {
        // Given
        let viewModel = makeViewModel()

        // When
        viewModel.setPluginOutdatedState(version: "10.4.0")

        // Then
        XCTAssertEqual(viewModel.primaryButtonTitle, "Update plugin")
        XCTAssertTrue(viewModel.isPrimaryButtonEnabled)
        XCTAssertTrue(viewModel.isShowingSecondaryButton)
        XCTAssertEqual(viewModel.secondaryButtonTitle, "Try again")
    }

    func test_onAppear_does_not_call_handler_start_after_setPluginOutdatedState() {
        // Given
        let viewModel = makeViewModel()
        viewModel.setPluginOutdatedState(version: "10.4.0")

        // When
        viewModel.onAppear()

        // Then
        XCTAssertEqual(mockHandler.startCallCount, 0)
    }

    func test_onAppear_calls_handler_start_when_in_initial_state() {
        // Given
        let viewModel = makeViewModel()

        // When
        viewModel.onAppear()

        // Then
        XCTAssertEqual(mockHandler.startCallCount, 1)
    }

    // MARK: - Analytics: stepDidUpdate

    func test_stepDidUpdate_tracks_correct_analytics_events() {
        // When step succeeds, then tracks flow_success with correct step
        do {
            let provider = MockAnalyticsProvider()
            let analytics = WooAnalytics(analyticsProvider: provider)
            let viewModel = makeViewModel(analytics: analytics)
            withExtendedLifetime(viewModel) {
                mockHandler.simulateStepUpdate(.connect, status: .success)

                assertEqual(provider, eventName: "push_notifications_setup_flow_success", property: "step", expected: "connect_wpcom")
            }
        }

        do {
            let provider = MockAnalyticsProvider()
            let analytics = WooAnalytics(analyticsProvider: provider)
            let viewModel = makeViewModel(analytics: analytics)
            withExtendedLifetime(viewModel) {
                mockHandler.simulateStepUpdate(.enablePush, status: .success)

                assertEqual(provider, eventName: "push_notifications_setup_flow_success", property: "step", expected: "enable_push_notifications")
            }
        }

        // When step fails, then tracks flow_error with correct step
        do {
            let provider = MockAnalyticsProvider()
            let analytics = WooAnalytics(analyticsProvider: provider)
            let viewModel = makeViewModel(analytics: analytics)
            withExtendedLifetime(viewModel) {
                mockHandler.simulateStepUpdate(.checkPlugin, status: .failure(error: .generic(reason: "Network error")))

                assertEqual(provider, eventName: "push_notifications_setup_flow_error", property: "step", expected: "plugin_compatibility")
            }
        }
    }

    // MARK: - Analytics: button taps

    func test_buttonTapped_tracks_correct_analytics_events() {
        // When completed and primary tapped, then tracks go_to_my_store
        do {
            let provider = MockAnalyticsProvider()
            let analytics = WooAnalytics(analyticsProvider: provider)
            let viewModel = makeViewModel(analytics: analytics)
            mockHandler.simulateSetupComplete()

            viewModel.primaryButtonTapped()

            assertEqual(provider, eventName: "push_notifications_setup_flow_button_tap", property: "button_label", expected: "go_to_my_store")
        }

        // When connection failed and primary tapped, then tracks try_again
        do {
            let provider = MockAnalyticsProvider()
            let analytics = WooAnalytics(analyticsProvider: provider)
            let viewModel = makeViewModel(analytics: analytics)
            mockHandler.simulateStepUpdate(.connect, status: .failure(error: .generic(reason: "Connection failed")))

            viewModel.primaryButtonTapped()

            assertEqual(provider, eventName: "push_notifications_setup_flow_button_tap", property: "button_label", expected: "try_again")
        }

        // When plugin outdated and primary tapped, then tracks update_plugin
        do {
            let provider = MockAnalyticsProvider()
            let analytics = WooAnalytics(analyticsProvider: provider)
            let viewModel = makeViewModel(analytics: analytics)
            mockHandler.simulateStepUpdate(.checkPlugin, status: .failure(error: .outdatedPlugin(version: "10.3.4")))

            viewModel.primaryButtonTapped()

            assertEqual(provider, eventName: "push_notifications_setup_flow_button_tap", property: "button_label", expected: "update_plugin")
        }

        // When secondary button tapped, then tracks try_again
        do {
            let provider = MockAnalyticsProvider()
            let analytics = WooAnalytics(analyticsProvider: provider)
            let viewModel = makeViewModel(analytics: analytics)

            viewModel.secondaryButtonTapped()

            assertEqual(provider, eventName: "push_notifications_setup_flow_button_tap", property: "button_label", expected: "try_again")
        }
    }

    // MARK: - Analytics: close events

    func test_dismissal_tracks_flow_close_event() {
        // When cancel tapped, then tracks flow close
        do {
            let provider = MockAnalyticsProvider()
            let analytics = WooAnalytics(analyticsProvider: provider)
            let viewModel = makeViewModel(analytics: analytics)

            viewModel.cancelTapped()

            XCTAssertTrue(provider.receivedEvents.contains("push_notifications_setup_flow_close"))
        }

        // When done tapped, then tracks flow close
        do {
            let provider = MockAnalyticsProvider()
            let analytics = WooAnalytics(analyticsProvider: provider)
            let viewModel = makeViewModel(analytics: analytics)

            viewModel.doneTapped()

            XCTAssertTrue(provider.receivedEvents.contains("push_notifications_setup_flow_close"))
        }
    }

    // MARK: - Helpers

    private func assertEqual(_ provider: MockAnalyticsProvider, eventName: String, property: String, expected: String) {
        let index = provider.receivedEvents.firstIndex(of: eventName)
        XCTAssertNotNil(index)
        if let index {
            XCTAssertEqual(provider.receivedProperties[index][property] as? String, expected)
        }
    }

    private func makeViewModel(analytics: Analytics = ServiceLocator.analytics) -> WPComConnectionSetupViewModel {
        WPComConnectionSetupViewModel(
            storeName: "Test Store",
            handler: mockHandler,
            analytics: analytics,
            onDismiss: { [weak self] in self?.dismissCalled = true },
            onGoToStore: { [weak self] in self?.goToStoreCalled = true },
            onUpdatePlugin: { [weak self] in self?.updatePluginCalled = true }
        )
    }
}

// MARK: - WPComConnectionSetupStep.Status Equatable

extension WPComConnectionSetupStep.Status: Equatable {
    public static func == (lhs: WPComConnectionSetupStep.Status, rhs: WPComConnectionSetupStep.Status) -> Bool {
        switch (lhs, rhs) {
        case (.notStarted, .notStarted),
             (.running, .running),
             (.success, .success):
            return true
        case let (.failure(lhsError), .failure(rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}
