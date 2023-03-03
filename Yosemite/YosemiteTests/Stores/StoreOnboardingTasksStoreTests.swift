import XCTest
@testable import Networking
@testable import Yosemite

final class StoreOnboardingTasksStoreTests: XCTestCase {
    /// Mock Dispatcher.
    private var dispatcher: Dispatcher!

    /// Mock Storage: InMemory.
    private var storageManager: MockStorageManager!

    /// Mock Network: Allows us to inject predefined responses.
    private var network: MockNetwork!

    private var remote: MockStoreOnboardingTasksRemote!
    private var store: StoreOnboardingTasksStore!

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
        remote = MockStoreOnboardingTasksRemote()
        store = StoreOnboardingTasksStore(dispatcher: dispatcher,
                                          storageManager: storageManager,
                                          network: network,
                                          remote: remote)
    }

    override func tearDown() {
        store = nil
        remote = nil
        network = nil
        storageManager = nil
        dispatcher = nil
        super.tearDown()
    }


    // MARK: - `loadOnboardingTasks`

    func test_loadOnboardingTasks_returns_tasks_on_success() throws {
        // Given
        remote.whenLoadingOnboardingTasks(thenReturn: .success([.init(isComplete: true, type: .launchStore)]))

        // When
        let result: Result<[StoreOnboardingTask], Error> = waitFor { promise in
            let action = StoreOnboardingTasksAction.loadOnboardingTasks(siteID: 0) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let tasks = try XCTUnwrap(result.get())
        XCTAssertEqual(tasks, [.init(isComplete: true, type: .launchStore)])
    }

    func test_loadOnboardingTasks_returns_error_on_failure() throws {
        // Given
        remote.whenLoadingOnboardingTasks(thenReturn: .failure(NetworkError.timeout))

        // When
        let result: Result<[StoreOnboardingTask], Error> = waitFor { promise in
            let action = StoreOnboardingTasksAction.loadOnboardingTasks(siteID: 0) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? NetworkError, .timeout)
    }
}
