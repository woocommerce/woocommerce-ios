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

        XCTAssertEqual(sut.tasksForDisplay[0].task.type, .addFirstProduct)
        XCTAssertEqual(sut.tasksForDisplay[1].task.type, .launchStore)
        XCTAssertEqual(sut.tasksForDisplay[2].task.type, .customizeDomains)
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

    func test_tasksForDisplay_returns_first_3_incomplete_tasks_when_view_all_button_is_visible_in_collapsed_mode() async {
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
        XCTAssertTrue(sut.shouldShowViewAllButton)

        XCTAssertEqual(sut.tasksForDisplay.count, 3)

        XCTAssertEqual(sut.tasksForDisplay[0].task.type, .addFirstProduct)
        XCTAssertEqual(sut.tasksForDisplay[1].task.type, .launchStore)
        XCTAssertEqual(sut.tasksForDisplay[2].task.type, .customizeDomains)
    }

    func test_tasksForDisplay_returns_all_tasks_when_view_all_button_is_hidden_in_collapsed_mode() async {
        // Given
        mockLoadOnboardingTasks(result: .success([
            .init(isComplete: false, type: .addFirstProduct),
            .init(isComplete: false, type: .launchStore)
        ]))
        let sut = StoreOnboardingViewModel(isExpanded: false,
                                           siteID: 0,
                                           stores: stores)
        // When
        await sut.reloadTasks()

        // Then
        XCTAssertFalse(sut.shouldShowViewAllButton)

        XCTAssertEqual(sut.tasksForDisplay.count, 2)
        XCTAssertEqual(sut.tasksForDisplay[0].task.type, .addFirstProduct)
        XCTAssertEqual(sut.tasksForDisplay[1].task.type, .launchStore)
    }

    // MARK: - shouldShowViewAllButton

    func test_view_all_button_is_hidden_in_expanded_mode() async {
        // Given
        mockLoadOnboardingTasks(result: .success([
            .init(isComplete: false, type: .addFirstProduct),
            .init(isComplete: false, type: .launchStore),
            .init(isComplete: false, type: .customizeDomains),
            .init(isComplete: false, type: .payments)
        ]))
        let sut = StoreOnboardingViewModel(isExpanded: true,
                                           siteID: 0,
                                           stores: stores)
        // When
        await sut.reloadTasks()

        // Then
        XCTAssertFalse(sut.shouldShowViewAllButton)
    }

    func test_view_all_button_is_visible_in_collapsed_mode() async {
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
        XCTAssertTrue(sut.shouldShowViewAllButton)
    }

    func test_view_all_button_is_hidden_when_view_is_redacted_while_loading() async {
        // Given
        let sut = StoreOnboardingViewModel(isExpanded: false,
                                           siteID: 0,
                                           stores: stores)

        stores.whenReceivingAction(ofType: StoreOnboardingTasksAction.self) { action in
            guard case let .loadOnboardingTasks(_, completion) = action else {
                return XCTFail()
            }

            // Then
            XCTAssertTrue(sut.isRedacted)
            XCTAssertFalse(sut.shouldShowViewAllButton)
            completion(.success([]))
        }

        // When
        await sut.reloadTasks()
    }

    func test_view_all_button_is_visible_after_view_is_loaded_and_unredacted() async {
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
        XCTAssertFalse(sut.isRedacted)
        XCTAssertTrue(sut.shouldShowViewAllButton)
    }

    func test_view_all_button_is_visible_when_task_count_is_greater_than_2() async {
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
        XCTAssertTrue(sut.shouldShowViewAllButton)
    }

    func test_view_all_button_is_hidden_when_task_count_is_less_than_3() async {
        // Given
        mockLoadOnboardingTasks(result: .success([
            .init(isComplete: false, type: .addFirstProduct),
            .init(isComplete: false, type: .launchStore)
        ]))
        let sut = StoreOnboardingViewModel(isExpanded: false,
                                           siteID: 0,
                                           stores: stores)
        // When
        await sut.reloadTasks()

        // Then
        XCTAssertFalse(sut.shouldShowViewAllButton)
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

    // MARK: completedAllStoreOnboardingTasks user defaults

    func test_completedAllStoreOnboardingTasks_is_nil_when_there_are_pending_tasks() async throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let tasks: [StoreOnboardingTask] = [
            .init(isComplete: false, type: .addFirstProduct),
            .init(isComplete: false, type: .launchStore),
            .init(isComplete: true, type: .customizeDomains),
            .init(isComplete: false, type: .payments)
        ]
        mockLoadOnboardingTasks(result: .success(tasks))
        let sut = StoreOnboardingViewModel(isExpanded: true,
                                           siteID: 0,
                                           stores: stores,
                                           defaults: defaults)
        // When
        await sut.reloadTasks()

        // Then
        XCTAssertNil(defaults[UserDefaults.Key.completedAllStoreOnboardingTasks])
    }

    func test_completedAllStoreOnboardingTasks_is_true_when_there_are_no_pending_tasks() async throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let tasks: [StoreOnboardingTask] = [
            .init(isComplete: true, type: .addFirstProduct),
            .init(isComplete: true, type: .launchStore),
            .init(isComplete: true, type: .customizeDomains),
            .init(isComplete: true, type: .payments)
        ]
        mockLoadOnboardingTasks(result: .success(tasks))
        let sut = StoreOnboardingViewModel(isExpanded: true,
                                           siteID: 0,
                                           stores: stores,
                                           defaults: defaults)
        // When
        await sut.reloadTasks()

        // Then
        XCTAssertTrue(try XCTUnwrap(defaults[UserDefaults.Key.completedAllStoreOnboardingTasks] as? Bool))
    }

    func test_completedAllStoreOnboardingTasks_is_not_changed_when_tasks_request_fails() async throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        mockLoadOnboardingTasks(result: .failure(MockError()))
        let sut = StoreOnboardingViewModel(isExpanded: true,
                                           siteID: 0,
                                           stores: stores,
                                           defaults: defaults)
        // Then
        XCTAssertNil(defaults[UserDefaults.Key.completedAllStoreOnboardingTasks])

        // When
        await sut.reloadTasks()

        // Then
        XCTAssertNil(defaults[UserDefaults.Key.completedAllStoreOnboardingTasks])
    }

    func test_completedAllStoreOnboardingTasks_is_not_changed_when_tasks_request_returns_empty_array() async throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        mockLoadOnboardingTasks(result: .success([]))
        let sut = StoreOnboardingViewModel(isExpanded: true,
                                           siteID: 0,
                                           stores: stores,
                                           defaults: defaults)
        // Then
        XCTAssertNil(defaults[UserDefaults.Key.completedAllStoreOnboardingTasks])

        // When
        await sut.reloadTasks()

        // Then
        XCTAssertNil(defaults[UserDefaults.Key.completedAllStoreOnboardingTasks])
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
