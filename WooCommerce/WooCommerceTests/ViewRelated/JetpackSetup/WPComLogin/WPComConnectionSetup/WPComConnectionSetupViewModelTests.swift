import XCTest
@testable import WooCommerce

@MainActor
final class WPComConnectionSetupViewModelTests: XCTestCase {

    // MARK: - Initial State Tests

    func test_initial_steps_are_set_with_notStarted_status() {
        // Given
        let handler = MockSetupHandler()
        let viewModel = WPComConnectionSetupViewModel(
            storeName: "Test Store",
            handler: handler,
            onDismiss: {},
            onGoToStore: {},
            onUpdatePlugin: {}
        )

        // Then
        XCTAssertEqual(viewModel.steps.count, 3)
        XCTAssertEqual(viewModel.steps[0].status, .notStarted)
        XCTAssertEqual(viewModel.steps[1].status, .notStarted)
        XCTAssertEqual(viewModel.steps[2].status, .notStarted)
    }

    func test_initial_primaryButtonTitle_is_goToMyStore() {
        // Given
        let handler = MockSetupHandler()
        let viewModel = WPComConnectionSetupViewModel(
            storeName: "Test Store",
            handler: handler,
            onDismiss: {},
            onGoToStore: {},
            onUpdatePlugin: {}
        )

        // Then
        XCTAssertEqual(viewModel.primaryButtonTitle, "Go to My Store")
    }

    func test_initial_primaryButton_is_disabled() {
        // Given
        let handler = MockSetupHandler()
        let viewModel = WPComConnectionSetupViewModel(
            storeName: "Test Store",
            handler: handler,
            onDismiss: {},
            onGoToStore: {},
            onUpdatePlugin: {}
        )

        // Then
        XCTAssertFalse(viewModel.isPrimaryButtonEnabled)
    }

    func test_initial_secondaryButton_is_hidden() {
        // Given
        let handler = MockSetupHandler()
        let viewModel = WPComConnectionSetupViewModel(
            storeName: "Test Store",
            handler: handler,
            onDismiss: {},
            onGoToStore: {},
            onUpdatePlugin: {}
        )

        // Then
        XCTAssertFalse(viewModel.isShowingSecondaryButton)
    }

    // MARK: - Delegate Callback Tests

    func test_stepDidUpdate_updates_step_status() {
        // Given
        let handler = MockSetupHandler()
        let viewModel = WPComConnectionSetupViewModel(
            storeName: "Test Store",
            handler: handler,
            onDismiss: {},
            onGoToStore: {},
            onUpdatePlugin: {}
        )

        // When
        viewModel.stepDidUpdate(.connect, status: .running)

        // Then
        XCTAssertEqual(viewModel.steps[0].status, .running)
    }

    func test_stepDidUpdate_with_success_updates_step_status() {
        // Given
        let handler = MockSetupHandler()
        let viewModel = WPComConnectionSetupViewModel(
            storeName: "Test Store",
            handler: handler,
            onDismiss: {},
            onGoToStore: {},
            onUpdatePlugin: {}
        )

        // When
        viewModel.stepDidUpdate(.connect, status: .success)

        // Then
        XCTAssertEqual(viewModel.steps[0].status, .success)
    }

    func test_stepDidUpdate_with_failure_enables_primaryButton() {
        // Given
        let handler = MockSetupHandler()
        let viewModel = WPComConnectionSetupViewModel(
            storeName: "Test Store",
            handler: handler,
            onDismiss: {},
            onGoToStore: {},
            onUpdatePlugin: {}
        )

        // When
        viewModel.stepDidUpdate(.connect, status: .failure(reason: "Error"))

        // Then
        XCTAssertTrue(viewModel.isPrimaryButtonEnabled)
    }

    func test_connection_failure_shows_tryAgain_button() {
        // Given
        let handler = MockSetupHandler()
        let viewModel = WPComConnectionSetupViewModel(
            storeName: "Test Store",
            handler: handler,
            onDismiss: {},
            onGoToStore: {},
            onUpdatePlugin: {}
        )

        // When
        viewModel.stepDidUpdate(.connect, status: .failure(reason: "Error"))

        // Then
        XCTAssertEqual(viewModel.primaryButtonTitle, "Try again")
        XCTAssertFalse(viewModel.isShowingSecondaryButton) // No secondary button for connection failure
    }

    func test_plugin_check_failure_shows_updatePlugin_button_and_secondary_tryAgain() {
        // Given
        let handler = MockSetupHandler()
        let viewModel = WPComConnectionSetupViewModel(
            storeName: "Test Store",
            handler: handler,
            onDismiss: {},
            onGoToStore: {},
            onUpdatePlugin: {}
        )

        // When
        viewModel.stepDidUpdate(.checkPlugin, status: .failure(reason: "Plugin outdated"))

        // Then
        XCTAssertEqual(viewModel.primaryButtonTitle, "Update plugin")
        XCTAssertTrue(viewModel.isShowingSecondaryButton)
        XCTAssertEqual(viewModel.secondaryButtonTitle, "Try again")
    }

    func test_setupDidComplete_enables_primaryButton_and_shows_doneButton() {
        // Given
        let handler = MockSetupHandler()
        let viewModel = WPComConnectionSetupViewModel(
            storeName: "Test Store",
            handler: handler,
            onDismiss: {},
            onGoToStore: {},
            onUpdatePlugin: {}
        )

        // When
        viewModel.setupDidComplete()

        // Then
        XCTAssertTrue(viewModel.isPrimaryButtonEnabled)
        XCTAssertTrue(viewModel.isShowingDoneButton)
        XCTAssertEqual(viewModel.primaryButtonTitle, "Go to My Store")
    }

    // MARK: - Button Action Tests

    func test_onAppear_calls_handler_start() {
        // Given
        let handler = MockSetupHandler()
        let viewModel = WPComConnectionSetupViewModel(
            storeName: "Test Store",
            handler: handler,
            onDismiss: {},
            onGoToStore: {},
            onUpdatePlugin: {}
        )

        // When
        viewModel.onAppear()

        // Then
        XCTAssertTrue(handler.startCalled)
    }

    func test_primaryButtonTapped_when_completed_calls_onGoToStore() {
        // Given
        var goToStoreCalled = false
        let handler = MockSetupHandler()
        let viewModel = WPComConnectionSetupViewModel(
            storeName: "Test Store",
            handler: handler,
            onDismiss: {},
            onGoToStore: { goToStoreCalled = true },
            onUpdatePlugin: {}
        )

        viewModel.setupDidComplete()

        // When
        viewModel.primaryButtonTapped()

        // Then
        XCTAssertTrue(goToStoreCalled)
    }

    func test_primaryButtonTapped_when_connection_failed_calls_handler_retry() {
        // Given
        let handler = MockSetupHandler()
        let viewModel = WPComConnectionSetupViewModel(
            storeName: "Test Store",
            handler: handler,
            onDismiss: {},
            onGoToStore: {},
            onUpdatePlugin: {}
        )

        viewModel.stepDidUpdate(.connect, status: .failure(reason: "Error"))

        // When
        viewModel.primaryButtonTapped()

        // Then
        XCTAssertTrue(handler.retryCalled)
    }

    func test_primaryButtonTapped_when_plugin_failed_calls_onUpdatePlugin() {
        // Given
        var updatePluginCalled = false
        let handler = MockSetupHandler()
        let viewModel = WPComConnectionSetupViewModel(
            storeName: "Test Store",
            handler: handler,
            onDismiss: {},
            onGoToStore: {},
            onUpdatePlugin: { updatePluginCalled = true }
        )

        viewModel.stepDidUpdate(.checkPlugin, status: .failure(reason: "Plugin outdated"))

        // When
        viewModel.primaryButtonTapped()

        // Then
        XCTAssertTrue(updatePluginCalled)
    }

    func test_secondaryButtonTapped_calls_handler_retry() {
        // Given
        let handler = MockSetupHandler()
        let viewModel = WPComConnectionSetupViewModel(
            storeName: "Test Store",
            handler: handler,
            onDismiss: {},
            onGoToStore: {},
            onUpdatePlugin: {}
        )

        viewModel.stepDidUpdate(.checkPlugin, status: .failure(reason: "Plugin outdated"))

        // When
        viewModel.secondaryButtonTapped()

        // Then
        XCTAssertTrue(handler.retryCalled)
    }

    func test_cancelTapped_calls_handler_cancel_and_onDismiss() {
        // Given
        var dismissCalled = false
        let handler = MockSetupHandler()
        let viewModel = WPComConnectionSetupViewModel(
            storeName: "Test Store",
            handler: handler,
            onDismiss: { dismissCalled = true },
            onGoToStore: {},
            onUpdatePlugin: {}
        )

        // When
        viewModel.cancelTapped()

        // Then
        XCTAssertTrue(handler.cancelCalled)
        XCTAssertTrue(dismissCalled)
    }

    func test_doneTapped_calls_onDismiss() {
        // Given
        var dismissCalled = false
        let handler = MockSetupHandler()
        let viewModel = WPComConnectionSetupViewModel(
            storeName: "Test Store",
            handler: handler,
            onDismiss: { dismissCalled = true },
            onGoToStore: {},
            onUpdatePlugin: {}
        )

        // When
        viewModel.doneTapped()

        // Then
        XCTAssertTrue(dismissCalled)
    }
}

// MARK: - Mock Handler

private final class MockSetupHandler: WPComConnectionSetupHandlerProtocol {
    weak var delegate: WPComConnectionSetupHandlerDelegate?

    private(set) var startCalled = false
    private(set) var retryCalled = false
    private(set) var cancelCalled = false

    func start() {
        startCalled = true
    }

    func retry() {
        retryCalled = true
    }

    func cancel() {
        cancelCalled = true
    }
}
