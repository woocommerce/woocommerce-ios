import XCTest
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
        mockHandler.simulateStepUpdate(.connect, status: .running)

        // Then
        XCTAssertEqual(viewModel.steps[0].status, .running)
    }

    func test_connection_failure_shows_tryAgain_button() {
        // Given
        let viewModel = makeViewModel()

        // When
        mockHandler.simulateStepUpdate(.connect, status: .failure(reason: "Connection failed"))

        // Then
        XCTAssertEqual(viewModel.primaryButtonTitle, "Try again")
        XCTAssertTrue(viewModel.isPrimaryButtonEnabled)
        XCTAssertFalse(viewModel.isShowingSecondaryButton)
    }

    func test_plugin_failure_shows_updatePlugin_and_tryAgain_buttons() {
        // Given
        let viewModel = makeViewModel()

        // When
        mockHandler.simulateStepUpdate(.checkPlugin, status: .failure(reason: "Plugin outdated"))

        // Then
        XCTAssertEqual(viewModel.primaryButtonTitle, "Update plugin")
        XCTAssertTrue(viewModel.isPrimaryButtonEnabled)
        XCTAssertTrue(viewModel.isShowingSecondaryButton)
        XCTAssertEqual(viewModel.secondaryButtonTitle, "Try again")
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

    func test_primaryButtonTapped_on_plugin_failure_calls_updatePlugin() {
        // Given
        let viewModel = makeViewModel()
        mockHandler.simulateStepUpdate(.checkPlugin, status: .failure(reason: "Plugin outdated"))

        // When
        viewModel.primaryButtonTapped()

        // Then
        XCTAssertTrue(updatePluginCalled)
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

    // MARK: - Helpers

    private func makeViewModel() -> WPComConnectionSetupViewModel {
        WPComConnectionSetupViewModel(
            storeName: "Test Store",
            handler: mockHandler,
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
        case let (.failure(lhsReason), .failure(rhsReason)):
            return lhsReason == rhsReason
        default:
            return false
        }
    }
}
