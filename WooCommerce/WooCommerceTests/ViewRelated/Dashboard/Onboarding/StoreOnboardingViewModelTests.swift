import XCTest
import Yosemite
@testable import WooCommerce

final class StoreOnboardingViewModelTests: XCTestCase {
    private var stores: MockStoresManager!

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: SessionManager.makeForTesting())
    }

    override func tearDown() {
        stores = nil
        super.tearDown()
    }

    // MARK: - `numberOfTasksCompleted``

    func test_numberOfTasksCompleted_returns_correct_count() async {
        // Given
        mockLoadOnboardingTasks(result: .success([
            .init(isComplete: true, type: .addFirstProduct),
            .init(isComplete: true, type: .launchStore),
            .init(isComplete: false, type: .customizeDomains),
            .init(isComplete: false, type: .payments)
        ]))
        let sut = StoreOnboardingViewModel(isExpanded: true,
                                           siteID: 0,
                                           stores: stores)
        // When
        await sut.reloadTasks()

        // Then
        XCTAssertEqual(sut.numberOfTasksCompleted, 2)
    }

    // MARK: - `tasksForDisplay``

    func test_tasksForDisplay_returns_first_3_incomplete_tasks_when_isExpanded_is_false() async {
        // Given
        mockLoadOnboardingTasks(result: .success([
            .init(isComplete: false, type: .addFirstProduct),
            .init(isComplete: false, type: .launchStore),
            .init(isComplete: false, type: .customizeDomains),
            .init(isComplete: false, type: .payments)
        ]))
        let sut = StoreOnboardingViewModel(isExpanded: false,
                                           siteID: 0,
                                           stores: stores)
        // When
        await sut.reloadTasks()

        // Then
        XCTAssertEqual(sut.tasksForDisplay.count, 3)
    }

    func test_tasksForDisplay_returns_all_tasks_when_isExpanded_is_true() async {
        // Given
        mockLoadOnboardingTasks(result: .success([
            .init(isComplete: false, type: .addFirstProduct),
            .init(isComplete: false, type: .launchStore),
            .init(isComplete: true, type: .customizeDomains),
            .init(isComplete: false, type: .payments)
        ]))
        let sut = StoreOnboardingViewModel(isExpanded: true,
                                           siteID: 0,
                                           stores: stores)
        // When
        await sut.reloadTasks()

        // Then
        XCTAssertEqual(sut.tasksForDisplay.count, 4)
    }

    // MARK: - Loading tasks

    func test_it_loads_previously_loaded_data_when_loading_tasks_fails() async {
        // Given
        let initialTasks: [StoreOnboardingTask] = [
            .init(isComplete: false, type: .addFirstProduct),
            .init(isComplete: false, type: .launchStore),
            .init(isComplete: true, type: .customizeDomains),
            .init(isComplete: false, type: .payments)
        ]
        mockLoadOnboardingTasks(result: .success(initialTasks))
        let sut = StoreOnboardingViewModel(isExpanded: true,
                                           siteID: 0,
                                           stores: stores)
        // When
        await sut.reloadTasks()

        // Then
        XCTAssertEqual(sut.tasksForDisplay.map({ $0.task }), initialTasks)

        // When
        mockLoadOnboardingTasks(result: .failure(MockError()))

        // Then
        XCTAssertEqual(sut.tasksForDisplay.map({ $0.task }), initialTasks)
    }

    func test_it_filters_out_unsupported_tasks_from_response() async {
        // Given
        let initialTasks: [StoreOnboardingTask] = [
            .init(isComplete: false, type: .addFirstProduct),
            .init(isComplete: false, type: .launchStore),
            .init(isComplete: true, type: .customizeDomains),
            .init(isComplete: false, type: .payments)
        ]

        let tasks = initialTasks + [(.init(isComplete: true, type: .unsupported("")))]
        mockLoadOnboardingTasks(result: .success(tasks))
        let sut = StoreOnboardingViewModel(isExpanded: true,
                                           siteID: 0,
                                           stores: stores)
        // When
        await sut.reloadTasks()

        // Then
        XCTAssertEqual(sut.tasksForDisplay.map({ $0.task }), initialTasks)
    }
}

private extension StoreOnboardingViewModelTests {
    func mockLoadOnboardingTasks(result: Result<[StoreOnboardingTask], Error>) {
        stores.whenReceivingAction(ofType: StoreOnboardingTasksAction.self) { action in
            guard case let .loadOnboardingTasks(_, completion) = action else {
                return XCTFail()
            }
            completion(result)
        }
    }

    final class MockError: Error { }
}
