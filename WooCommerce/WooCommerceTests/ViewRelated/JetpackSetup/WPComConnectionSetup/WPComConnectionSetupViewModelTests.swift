import XCTest
@testable import WooCommerce

@MainActor
final class WPComConnectionSetupViewModelTests: XCTestCase {
    private var mockHandler: MockWPComConnectionSetupHandler!
    private var dismissCalled = false
    private var goToStoreCalled = false
    private var updatePluginCalled = false

    override func setUp() {
        super.setUp()
        mockHandler = MockWPComConnectionSetupHandler()
    }

    override func tearDown() {
        mockHandler = nil
        super.tearDown()
    }

    func test_initial_state() {
        let viewModel = givenViewModel()

        XCTAssertEqual(viewModel.steps.count, 3)
        XCTAssertTrue(viewModel.steps.allSatisfy { $0.status == .notStarted })
        XCTAssertEqual(viewModel.primaryButtonTitle, "Go to My Store")
        XCTAssertFalse(viewModel.isPrimaryButtonEnabled)
        XCTAssertFalse(viewModel.isShowingSecondaryButton)
    }

    func test_stepDidUpdate_updates_status_correctly() {
        let viewModel = givenViewModel()

        viewModel.stepDidUpdate(.connect, status: .running)
        XCTAssertEqual(viewModel.steps[0].status, .running)

        viewModel.stepDidUpdate(.connect, status: .success)
        XCTAssertEqual(viewModel.steps[0].status, .success)

        viewModel.stepDidUpdate(.checkPlugin, status: .failure(reason: "Error"))
        XCTAssertEqual(viewModel.steps[1].status, .failure(reason: "Error"))
        XCTAssertTrue(viewModel.isPrimaryButtonEnabled)
    }

    func test_connection_failure_shows_tryAgain_button() {
        let viewModel = givenViewModel()

        viewModel.stepDidUpdate(.connect, status: .failure(reason: "Error"))

        XCTAssertEqual(viewModel.primaryButtonTitle, "Try again")
        XCTAssertFalse(viewModel.isShowingSecondaryButton)
    }

    func test_plugin_failure_shows_updatePlugin_and_tryAgain_buttons() {
        let viewModel = givenViewModel()

        viewModel.stepDidUpdate(.checkPlugin, status: .failure(reason: "Plugin outdated"))

        XCTAssertEqual(viewModel.primaryButtonTitle, "Update plugin")
        XCTAssertTrue(viewModel.isShowingSecondaryButton)
        XCTAssertEqual(viewModel.secondaryButtonTitle, "Try again")
    }

    func test_setupDidComplete_updates_state() {
        let viewModel = givenViewModel()

        viewModel.setupDidComplete()

        XCTAssertTrue(viewModel.isPrimaryButtonEnabled)
        XCTAssertTrue(viewModel.isShowingDoneButton)
        XCTAssertEqual(viewModel.primaryButtonTitle, "Go to My Store")
    }

    func test_primaryButtonTapped_actions() {
        // When completed - goes to store
        var viewModel = givenViewModel()
        viewModel.setupDidComplete()
        viewModel.primaryButtonTapped()
        XCTAssertTrue(goToStoreCalled)

        // When connection failed - retries
        goToStoreCalled = false
        mockHandler = MockWPComConnectionSetupHandler()
        viewModel = givenViewModel()
        viewModel.stepDidUpdate(.connect, status: .failure(reason: "Error"))
        viewModel.primaryButtonTapped()
        XCTAssertTrue(mockHandler.retryCalled)

        // When plugin failed - updates plugin
        mockHandler = MockWPComConnectionSetupHandler()
        viewModel = givenViewModel()
        viewModel.stepDidUpdate(.checkPlugin, status: .failure(reason: "Plugin outdated"))
        viewModel.primaryButtonTapped()
        XCTAssertTrue(updatePluginCalled)
    }

    func test_dismiss_actions() {
        let viewModel = givenViewModel()

        viewModel.cancelTapped()
        XCTAssertTrue(mockHandler.cancelCalled)
        XCTAssertTrue(dismissCalled)

        dismissCalled = false
        viewModel.doneTapped()
        XCTAssertTrue(dismissCalled)
    }

    private func givenViewModel() -> WPComConnectionSetupViewModel {
        WPComConnectionSetupViewModel(
            storeName: "Test Store",
            handler: mockHandler,
            onDismiss: { [weak self] in self?.dismissCalled = true },
            onGoToStore: { [weak self] in self?.goToStoreCalled = true },
            onUpdatePlugin: { [weak self] in self?.updatePluginCalled = true }
        )
    }
}
