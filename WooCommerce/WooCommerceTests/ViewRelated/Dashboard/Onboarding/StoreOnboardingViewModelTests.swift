import XCTest
import Yosemite
@testable import WooCommerce
final class StoreOnboardingViewModelTests: XCTestCase {
    private var stores: MockStoresManager!
    private var defaults: UserDefaults!
    private let placeholderTaskCount = 3
    private let freeTrialID = "1052"
    private var sessionManager: SessionManager!
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!
    private let freeTrialPlanSlug = "ecommerce-trial-bundle-monthly"

    override func setUpWithError() throws {
        try super.setUpWithError()
        let uuid = UUID().uuidString
        defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        sessionManager = .makeForTesting(authenticated: true)
        stores = MockStoresManager(sessionManager: sessionManager)
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    override func tearDown() {
        stores = nil
        sessionManager = nil
        defaults = nil
        analytics = nil
        analyticsProvider = nil
        super.tearDown()
    }

    // MARK: - `numberOfTasksCompleted``

    @MainActor
    func test_numberOfTasksCompleted_returns_correct_count() async {
        // Given
        mockLoadOnboardingTasks(result: .success([
            .init(isComplete: true, type: .addFirstProduct),
            .init(isComplete: true, type: .launchStore),
            .init(isComplete: false, type: .customizeDomains),
            .init(isComplete: false, type: .payments)
        ]))
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: true,
                                           stores: stores,
                                           defaults: defaults)
        // When
        await sut.reloadTasks()

        // Then
        XCTAssertEqual(sut.numberOfTasksCompleted, 2)
    }

    // MARK: - `tasksForDisplay``
    @MainActor
    func test_tasksForDisplay_returns_first_3_incomplete_tasks_including_wcpay_when_isExpanded_is_false() async {
        // Given
        mockLoadOnboardingTasks(result: .success([
            .init(isComplete: false, type: .addFirstProduct),
            .init(isComplete: false, type: .launchStore),
            .init(isComplete: false, type: .customizeDomains),
            .init(isComplete: false, type: .woocommercePayments)
        ]))
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: false,
                                           stores: stores,
                                           defaults: defaults)
        // When
        await sut.reloadTasks()

        // Then
        XCTAssertEqual(sut.tasksForDisplay.count, 3)

        XCTAssertEqual(sut.tasksForDisplay[0].task.type, .addFirstProduct)
        XCTAssertEqual(sut.tasksForDisplay[1].task.type, .woocommercePayments)
        XCTAssertEqual(sut.tasksForDisplay[2].task.type, .launchStore)
    }

    @MainActor
    func test_tasksForDisplay_returns_first_3_incomplete_tasks_not_including_payments_when_isExpanded_is_false() async {
        // Given
        mockLoadOnboardingTasks(result: .success([
            .init(isComplete: false, type: .addFirstProduct),
            .init(isComplete: false, type: .launchStore),
            .init(isComplete: false, type: .customizeDomains),
            .init(isComplete: false, type: .payments)
        ]))
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: false,
                                           stores: stores,
                                           defaults: defaults)
        // When
        await sut.reloadTasks()

        // Then
        XCTAssertEqual(sut.tasksForDisplay.count, 3)

        XCTAssertEqual(sut.tasksForDisplay[0].task.type, .addFirstProduct)
        XCTAssertEqual(sut.tasksForDisplay[1].task.type, .launchStore)
        XCTAssertEqual(sut.tasksForDisplay[2].task.type, .customizeDomains)
    }

    @MainActor
    func test_tasksForDisplay_returns_all_tasks_when_isExpanded_is_true() async {
        // Given
        mockLoadOnboardingTasks(result: .success([
            .init(isComplete: false, type: .addFirstProduct),
            .init(isComplete: false, type: .launchStore),
            .init(isComplete: true, type: .customizeDomains),
            .init(isComplete: false, type: .payments)
        ]))
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: true,
                                           stores: stores,
                                           defaults: defaults)
        // When
        await sut.reloadTasks()

        // Then
        XCTAssertEqual(sut.tasksForDisplay.count, 4)
    }

    @MainActor
    func test_tasksForDisplay_returns_first_3_incomplete_tasks_when_view_all_button_is_visible_in_collapsed_mode() async {
        // Given
        mockLoadOnboardingTasks(result: .success([
            .init(isComplete: false, type: .addFirstProduct),
            .init(isComplete: false, type: .launchStore),
            .init(isComplete: false, type: .customizeDomains),
            .init(isComplete: false, type: .woocommercePayments)
        ]))
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: false,
                                           stores: stores,
                                           defaults: defaults)
        // When
        await sut.reloadTasks()

        // Then
        XCTAssertTrue(sut.shouldShowViewAllButton)

        XCTAssertEqual(sut.tasksForDisplay.count, 3)

        XCTAssertEqual(sut.tasksForDisplay[0].task.type, .addFirstProduct)
        XCTAssertEqual(sut.tasksForDisplay[1].task.type, .woocommercePayments)
        XCTAssertEqual(sut.tasksForDisplay[2].task.type, .launchStore)
    }

    @MainActor
    func test_tasksForDisplay_returns_all_tasks_when_view_all_button_is_hidden_in_collapsed_mode() async {
        // Given
        mockLoadOnboardingTasks(result: .success([
            .init(isComplete: false, type: .addFirstProduct),
            .init(isComplete: false, type: .launchStore)
        ]))
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: false,
                                           stores: stores,
                                           defaults: defaults)
        // When
        await sut.reloadTasks()

        // Then
        XCTAssertFalse(sut.shouldShowViewAllButton)

        XCTAssertEqual(sut.tasksForDisplay.count, 2)
        XCTAssertEqual(sut.tasksForDisplay[0].task.type, .addFirstProduct)
        XCTAssertEqual(sut.tasksForDisplay[1].task.type, .launchStore)
    }

    @MainActor
    func test_launch_store_task_is_marked_as_complete_for_already_public_store() async throws {
        // Given
        sessionManager.defaultSite = .fake().copy(plan: freeTrialPlanSlug, isWordPressComStore: true, visibility: .publicSite)
        mockLoadOnboardingTasks(result: .success([
            .init(isComplete: false, type: .addFirstProduct),
            .init(isComplete: false, type: .launchStore)
        ]))

        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: true,
                                           stores: stores,
                                           defaults: defaults)
        // When
        await sut.reloadTasks()

        // Then
        let launchStoreTask = try XCTUnwrap(sut.tasksForDisplay.filter({ $0.task.type == .launchStore}).first)
        XCTAssertTrue(launchStoreTask.isComplete)
    }

    @MainActor
    func test_launch_store_task_is_not_marked_as_complete_for_non_public_store() async throws {
        // Given
        sessionManager.defaultSite = .fake().copy(plan: freeTrialPlanSlug, isWordPressComStore: true, visibility: .privateSite)
        mockLoadOnboardingTasks(result: .success([
            .init(isComplete: false, type: .addFirstProduct),
            .init(isComplete: false, type: .launchStore)
        ]))

        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: true,
                                           stores: stores,
                                           defaults: defaults)
        // When
        await sut.reloadTasks()

        // Then
        let launchStoreTask = try XCTUnwrap(sut.tasksForDisplay.filter({ $0.task.type == .launchStore}).first)
        XCTAssertFalse(launchStoreTask.isComplete)
    }

    @MainActor
    func test_tasks_other_than_launchStore_type_are_not_marked_as_complete_for_already_public_store_with_default_name() async {
        // Given
        sessionManager.defaultSite = .fake().copy(name: WooConstants.defaultStoreName, plan: freeTrialPlanSlug, isWordPressComStore: true, visibility: .publicSite)
        mockLoadOnboardingTasks(result: .success([
            .init(isComplete: false, type: .addFirstProduct),
            .init(isComplete: false, type: .storeDetails),
            .init(isComplete: false, type: .customizeDomains),
            .init(isComplete: false, type: .payments),
            .init(isComplete: false, type: .woocommercePayments),
        ]))

        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: true,
                                           stores: stores,
                                           defaults: defaults)
        // When
        await sut.reloadTasks()

        // Then
        XCTAssertTrue(sut.tasksForDisplay.filter({ $0.task.isComplete}).isEmpty)
    }

    // MARK: - shouldShowViewAllButton
    @MainActor
    func test_view_all_button_is_hidden_in_expanded_mode() async {
        // Given
        mockLoadOnboardingTasks(result: .success([
            .init(isComplete: false, type: .addFirstProduct),
            .init(isComplete: false, type: .launchStore),
            .init(isComplete: false, type: .customizeDomains),
            .init(isComplete: false, type: .payments)
        ]))
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: true,
                                           stores: stores,
                                           defaults: defaults)
        // When
        await sut.reloadTasks()

        // Then
        XCTAssertFalse(sut.shouldShowViewAllButton)
    }

    @MainActor
    func test_view_all_button_is_visible_in_collapsed_mode() async {
        // Given
        mockLoadOnboardingTasks(result: .success([
            .init(isComplete: false, type: .addFirstProduct),
            .init(isComplete: false, type: .launchStore),
            .init(isComplete: false, type: .customizeDomains),
            .init(isComplete: false, type: .payments)
        ]))
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: false,
                                           stores: stores,
                                           defaults: defaults)
        // When
        await sut.reloadTasks()

        // Then
        XCTAssertTrue(sut.shouldShowViewAllButton)
    }

    @MainActor
    func test_view_all_button_is_hidden_when_view_is_redacted_while_loading() async {
        // Given
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: false,
                                           stores: stores,
                                           defaults: defaults)

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

    @MainActor
    func test_view_all_button_is_visible_after_view_is_loaded_and_unredacted() async {
        // Given
        mockLoadOnboardingTasks(result: .success([
            .init(isComplete: false, type: .addFirstProduct),
            .init(isComplete: false, type: .launchStore),
            .init(isComplete: false, type: .customizeDomains),
            .init(isComplete: false, type: .payments)
        ]))
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: false,
                                           stores: stores,
                                           defaults: defaults)
        // When
        await sut.reloadTasks()

        // Then
        XCTAssertFalse(sut.isRedacted)
        XCTAssertTrue(sut.shouldShowViewAllButton)
    }

    @MainActor
    func test_view_all_button_is_visible_when_task_count_is_greater_than_3() async {
        // Given
        mockLoadOnboardingTasks(result: .success([
            .init(isComplete: false, type: .addFirstProduct),
            .init(isComplete: false, type: .launchStore),
            .init(isComplete: false, type: .customizeDomains),
            .init(isComplete: false, type: .payments)
        ]))
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: false,
                                           stores: stores,
                                           defaults: defaults)
        // When
        await sut.reloadTasks()

        // Then
        XCTAssertTrue(sut.shouldShowViewAllButton)
    }

    @MainActor
    func test_view_all_button_is_hidden_when_task_count_is_3() async {
        // Given
        mockLoadOnboardingTasks(result: .success([
            .init(isComplete: false, type: .addFirstProduct),
            .init(isComplete: false, type: .launchStore),
            .init(isComplete: false, type: .customizeDomains)
        ]))
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: false,
                                           stores: stores,
                                           defaults: defaults)
        // When
        await sut.reloadTasks()

        // Then
        XCTAssertFalse(sut.shouldShowViewAllButton)
    }

    @MainActor
    func test_view_all_button_is_hidden_when_task_count_is_less_than_3() async {
        // Given
        mockLoadOnboardingTasks(result: .success([
            .init(isComplete: false, type: .addFirstProduct),
            .init(isComplete: false, type: .launchStore)
        ]))
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: false,
                                           stores: stores,
                                           defaults: defaults)
        // When
        await sut.reloadTasks()

        // Then
        XCTAssertFalse(sut.shouldShowViewAllButton)
    }

    // MARK: - isRedacted
    @MainActor
    func test_view_is_redacted_while_loading_tasks() async {
        // Given
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: false,
                                           stores: stores,
                                           defaults: defaults)

        stores.whenReceivingAction(ofType: StoreOnboardingTasksAction.self) { action in
            guard case let .loadOnboardingTasks(_, completion) = action else {
                return XCTFail()
            }

            // Then
            XCTAssertTrue(sut.isRedacted)
            completion(.success([]))
        }

        // When
        await sut.reloadTasks()
    }

    @MainActor
    func test_view_is_unredacted_after_finishing_loading_tasks_successfully() async {
        // Given
        mockLoadOnboardingTasks(result: .success([
            .init(isComplete: false, type: .addFirstProduct),
            .init(isComplete: false, type: .launchStore),
            .init(isComplete: false, type: .customizeDomains),
            .init(isComplete: false, type: .payments)
        ]))
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: false,
                                           stores: stores,
                                           defaults: defaults)
        // When
        await sut.reloadTasks()

        // Then
        XCTAssertFalse(sut.isRedacted)
    }

    @MainActor
    func test_view_is_unredacted_after_failing_to_load_tasks() async {
        // Given
        mockLoadOnboardingTasks(result: .failure(MockError()))
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: false,
                                           stores: stores,
                                           defaults: defaults)
        // When
        await sut.reloadTasks()

        // Then
        XCTAssertFalse(sut.isRedacted)
    }

    // MARK: - Loading tasks
    @MainActor
    func test_it_loads_previously_loaded_data_when_loading_tasks_fails() async {
        // Given
        let initialTasks: [StoreOnboardingTask] = [
            .init(isComplete: false, type: .addFirstProduct),
            .init(isComplete: false, type: .woocommercePayments),
            .init(isComplete: false, type: .launchStore),
            .init(isComplete: true, type: .customizeDomains)
        ]
        mockLoadOnboardingTasks(result: .success(initialTasks))
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: true,
                                           stores: stores,
                                           defaults: defaults)
        // When
        await sut.reloadTasks()

        // Then
        XCTAssertEqual(sut.tasksForDisplay.map({ $0.task }), initialTasks)

        // When
        mockLoadOnboardingTasks(result: .failure(MockError()))
        await sut.reloadTasks()

        // Then
        XCTAssertEqual(sut.tasksForDisplay.map({ $0.task }), initialTasks)
    }

    @MainActor
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
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: true,
                                           stores: stores,
                                           defaults: defaults)
        // When
        await sut.reloadTasks()

        // Then
        XCTAssertEqual(sut.tasksForDisplay.map({ $0.task }), initialTasks)
    }

    @MainActor
    func test_it_does_not_send_network_request_when_completedAllStoreOnboardingTasks_is_true() async {
        // Given
        defaults[UserDefaults.Key.completedAllStoreOnboardingTasks] = true
        let tasks: [StoreOnboardingTask] = [
            .init(isComplete: false, type: .addFirstProduct),
            .init(isComplete: false, type: .launchStore),
            .init(isComplete: true, type: .customizeDomains),
            .init(isComplete: false, type: .payments)
        ]
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: false,
                                           stores: stores,
                                           defaults: defaults)
        // Then
        XCTAssertTrue(sut.tasksForDisplay.count == placeholderTaskCount)

        // When
        mockLoadOnboardingTasks(result: .success(tasks))
        await sut.reloadTasks()

        // Then
        XCTAssertTrue(sut.tasksForDisplay.count == placeholderTaskCount)
    }

    @MainActor
    func test_it_sends_network_request_when_completedAllStoreOnboardingTasks_is_nil() async {
        // Given
        let tasks: [StoreOnboardingTask] = [
            .init(isComplete: false, type: .addFirstProduct),
            .init(isComplete: false, type: .storeDetails),
            .init(isComplete: false, type: .launchStore),
            .init(isComplete: true, type: .customizeDomains),
            .init(isComplete: false, type: .payments)
        ]
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: true,
                                           stores: stores,
                                           defaults: defaults)
        // Then
        XCTAssertTrue(sut.tasksForDisplay.count == placeholderTaskCount)

        // When
        mockLoadOnboardingTasks(result: .success(tasks))
        await sut.reloadTasks()

        // Then
        XCTAssertTrue(sut.tasksForDisplay.count == 5)
    }

    // MARK: completedAllStoreOnboardingTasks user defaults
    @MainActor
    func test_completedAllStoreOnboardingTasks_is_nil_when_there_are_pending_tasks() async {
        // Given
        let tasks: [StoreOnboardingTask] = [
            .init(isComplete: false, type: .addFirstProduct),
            .init(isComplete: false, type: .launchStore),
            .init(isComplete: true, type: .customizeDomains),
            .init(isComplete: false, type: .payments)
        ]
        mockLoadOnboardingTasks(result: .success(tasks))
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: true,
                                           stores: stores,
                                           defaults: defaults)
        // When
        await sut.reloadTasks()

        // Then
        XCTAssertNil(defaults[UserDefaults.Key.completedAllStoreOnboardingTasks])
    }

    @MainActor
    func test_completedAllStoreOnboardingTasks_is_true_when_there_are_no_pending_tasks() async {
        // Given
        let tasks: [StoreOnboardingTask] = [
            .init(isComplete: true, type: .addFirstProduct),
            .init(isComplete: true, type: .launchStore),
            .init(isComplete: true, type: .customizeDomains),
            .init(isComplete: true, type: .payments)
        ]
        mockLoadOnboardingTasks(result: .success(tasks))
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: true,
                                           stores: stores,
                                           defaults: defaults)
        // When
        await sut.reloadTasks()

        // Then
        XCTAssertTrue(try XCTUnwrap(defaults[UserDefaults.Key.completedAllStoreOnboardingTasks] as? Bool))
    }

    @MainActor
    func test_completedAllStoreOnboardingTasks_is_not_changed_when_tasks_request_fails() async {
        // Given
        mockLoadOnboardingTasks(result: .failure(MockError()))
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: true,
                                           stores: stores,
                                           defaults: defaults)
        // Then
        XCTAssertNil(defaults[UserDefaults.Key.completedAllStoreOnboardingTasks])

        // When
        await sut.reloadTasks()

        // Then
        XCTAssertNil(defaults[UserDefaults.Key.completedAllStoreOnboardingTasks])
    }

    @MainActor
    func test_completedAllStoreOnboardingTasks_is_not_changed_when_tasks_request_returns_empty_array() async {
        // Given
        mockLoadOnboardingTasks(result: .success([]))
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: true,
                                           stores: stores,
                                           defaults: defaults)
        // Then
        XCTAssertNil(defaults[UserDefaults.Key.completedAllStoreOnboardingTasks])

        // When
        await sut.reloadTasks()

        // Then
        XCTAssertNil(defaults[UserDefaults.Key.completedAllStoreOnboardingTasks])
    }

    // MARK: - canShowInDashboard
    @MainActor
    func test_canShowInDashboard_is_false_when_no_tasks_available_due_to_network_error() async {
        // Given
        mockLoadOnboardingTasks(result: .failure(MockError()))
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: false,
                                           stores: stores,
                                           defaults: defaults)
        // When
        await sut.reloadTasks()

        // Then
        XCTAssertFalse(sut.canShowInDashboard)
    }

    @MainActor
    func test_canShowInDashboard_is_false_when_no_tasks_received_in_success_response() async {
        // Given
        mockLoadOnboardingTasks(result: .success([]))
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: false,
                                           stores: stores,
                                           defaults: defaults)
        // When
        await sut.reloadTasks()

        // Then
        XCTAssertFalse(sut.canShowInDashboard)
    }

    @MainActor
    func test_canShowInDashboard_is_true_when_pending_tasks_received_in_response() async {
        // Given
        let tasks: [StoreOnboardingTask] = [
            .init(isComplete: false, type: .addFirstProduct),
            .init(isComplete: true, type: .launchStore),
            .init(isComplete: false, type: .customizeDomains),
            .init(isComplete: true, type: .payments)
        ]
        mockLoadOnboardingTasks(result: .success(tasks))
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: false,
                                           stores: stores,
                                           defaults: defaults)

        // When
        await sut.reloadTasks()

        // Then
        XCTAssertTrue(sut.canShowInDashboard)
    }

    @MainActor
    func test_canShowInDashboard_is_false_when_all_tasks_are_complete() async {
        // Given
        let tasks: [StoreOnboardingTask] = [
            .init(isComplete: true, type: .addFirstProduct),
            .init(isComplete: true, type: .launchStore),
            .init(isComplete: true, type: .customizeDomains),
            .init(isComplete: true, type: .payments)
        ]
        mockLoadOnboardingTasks(result: .success(tasks))
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: false,
                                           stores: stores,
                                           defaults: defaults)

        // When
        await sut.reloadTasks()

        // Then
        XCTAssertFalse(sut.canShowInDashboard)
    }

    @MainActor
    func test_reloadTasks_notifies_waitingTimeTracker_when_completedAllStoreOnboardingTasks_is_true() async {
        // Given
        defaults[UserDefaults.Key.completedAllStoreOnboardingTasks] = true
        let tracker = AppStartupWaitingTimeTracker(analyticsService: analytics)
        XCTAssert(tracker.startupActionsPending.contains(.loadOnboardingTasks))
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: false,
                                           stores: stores,
                                           defaults: defaults,
                                           waitingTimeTracker: tracker)

        // When
        await sut.reloadTasks()

        // Then
        XCTAssertFalse(tracker.startupActionsPending.contains(.loadOnboardingTasks))
    }

    @MainActor
    func test_reloadTasks_ends_waitingTimeTracker_when_fetching_tasks_fails() async {
        // Given
        mockLoadOnboardingTasks(result: .failure(MockError()))
        let tracker = AppStartupWaitingTimeTracker(analyticsService: analytics)
        XCTAssert(tracker.startupActionsPending.contains(.loadOnboardingTasks))
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: false,
                                           stores: stores,
                                           defaults: defaults,
                                           waitingTimeTracker: tracker)

        // When
        await sut.reloadTasks()

        // Then
        XCTAssert(tracker.startupActionsPending.isEmpty)
    }

    @MainActor
    func test_reloadTasks_notifies_waitingTimeTracker_when_fetching_tasks_succeeds() async {
        // Given
        let tasks: [StoreOnboardingTask] = [
            .init(isComplete: true, type: .addFirstProduct),
            .init(isComplete: true, type: .launchStore),
            .init(isComplete: true, type: .customizeDomains),
            .init(isComplete: true, type: .payments)
        ]
        mockLoadOnboardingTasks(result: .success(tasks))
        let tracker = AppStartupWaitingTimeTracker(analyticsService: analytics)
        XCTAssert(tracker.startupActionsPending.contains(.loadOnboardingTasks))
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: false,
                                           stores: stores,
                                           defaults: defaults,
                                           waitingTimeTracker: tracker)

        // When
        await sut.reloadTasks()

        // Then
        XCTAssertFalse(tracker.startupActionsPending.contains(.loadOnboardingTasks))
    }

    @MainActor
    func test_hideTaskList_triggers_tracking_event() throws {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let viewModel = StoreOnboardingViewModel(siteID: 123, isExpanded: false, analytics: analytics)

        // When
        viewModel.hideTaskList()

        // Then
        let index = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "dynamic_dashboard_hide_card_tapped" }))
        let properties = analyticsProvider.receivedProperties[index] as? [String: AnyHashable]
        XCTAssertEqual(properties?["type"], "store_setup")
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
