import XCTest
import Yosemite
@testable import WooCommerce
@testable import Yosemite

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

    func test_tasksForDisplay_returns_first_3_incomplete_tasks_when_isExpanded_is_false() async {
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

    func test_tasksForDisplay_returns_first_3_incomplete_tasks_when_view_all_button_is_visible_in_collapsed_mode() async {
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

    func test_tasksForDisplay_contains_launch_store_and_store_name_task_for_WPCOM_site_under_free_trial() async {
        // Given
        sessionManager.defaultSite = .fake().copy(plan: freeTrialPlanSlug, isWordPressComStore: true)
        sessionManager.defaultRoles = [.administrator]
        mockLoadOnboardingTasks(result: .success([
            .init(isComplete: false, type: .addFirstProduct),
        ]))

        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: true,
                                           stores: stores,
                                           defaults: defaults)
        // When
        await sut.reloadTasks()

        // Then
        XCTAssertTrue(sut.tasksForDisplay.filter({ $0.task.type == .launchStore}).isNotEmpty)
        XCTAssertNotNil(sut.tasksForDisplay.first(where: { $0.task.type == .storeName }))
    }

    func test_tasksForDisplay_does_not_contain_launch_store_and_store_name_task_for_non_WPCOM_site() async {
        // Given
        sessionManager.defaultSite = .fake().copy(isWordPressComStore: false)
        sessionManager.defaultRoles = [.administrator]
        mockLoadOnboardingTasks(result: .success([
            .init(isComplete: false, type: .addFirstProduct),
        ]))

        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: true,
                                           stores: stores,
                                           defaults: defaults)
        // When
        await sut.reloadTasks()

        // Then
        XCTAssertTrue(sut.tasksForDisplay.filter({ $0.task.type == .launchStore}).isEmpty)
        XCTAssertNil(sut.tasksForDisplay.first(where: { $0.task.type == .storeName }))
    }

    func test_tasksForDisplay_does_not_contain_launch_store_task_and_store_name_for_WPCOM_site_not_under_free_trial() async {
        // Given
        sessionManager.defaultSite = .fake().copy(plan: "ecommerce-plan", isWordPressComStore: true)
        sessionManager.defaultRoles = [.administrator]
        mockLoadOnboardingTasks(result: .success([
            .init(isComplete: false, type: .addFirstProduct),
        ]))

        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: true,
                                           stores: stores,
                                           defaults: defaults)
        // When
        await sut.reloadTasks()

        // Then
        XCTAssertTrue(sut.tasksForDisplay.filter({ $0.task.type == .launchStore}).isEmpty)
        XCTAssertNil(sut.tasksForDisplay.first(where: { $0.task.type == .storeName }))
    }

    func test_tasksForDisplay_is_sorted_when_launch_store_and_store_name_tasks_get_manually_added_for_WPCOM_site_under_free_trial() async {
        // Given
        sessionManager.defaultSite = .fake().copy(name: WooConstants.defaultStoreName, plan: freeTrialPlanSlug, isWordPressComStore: true)
        sessionManager.defaultRoles = [.administrator]
        mockLoadOnboardingTasks(result: .success([
            .init(isComplete: false, type: .addFirstProduct),
            .init(isComplete: false, type: .customizeDomains),
        ]))

        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: true,
                                           stores: stores,
                                           defaults: defaults)
        // When
        await sut.reloadTasks()

        // Then
        XCTAssertEqual(sut.tasksForDisplay.map({ $0.task }), [.init(isComplete: false, type: .storeName),
                                                              .init(isComplete: false, type: .addFirstProduct),
                                                              .init(isComplete: false, type: .launchStore),
                                                              .init(isComplete: false, type: .customizeDomains)])
    }

    func test_launch_store_task_is_marked_as_complete_for_already_public_store() async throws {
        // Given
        sessionManager.defaultSite = .fake().copy(plan: freeTrialPlanSlug, isWordPressComStore: true, isPublic: true)
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

    func test_launch_store_task_is_not_marked_as_complete_for_non_public_store() async throws {
        // Given
        sessionManager.defaultSite = .fake().copy(plan: freeTrialPlanSlug, isWordPressComStore: true, isPublic: false)
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

    func test_tasks_other_than_launchStore_type_are_not_marked_as_complete_for_already_public_store_with_default_name() async {
        // Given
        sessionManager.defaultSite = .fake().copy(name: WooConstants.defaultStoreName, plan: freeTrialPlanSlug, isWordPressComStore: true, isPublic: true)
        mockLoadOnboardingTasks(result: .success([
            .init(isComplete: false, type: .storeDetails),
            .init(isComplete: false, type: .addFirstProduct),
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

    func test_store_name_task_is_marked_as_complete_for_free_trial_site_with_custom_name() async throws {
        // Given
        sessionManager.defaultSite = .fake().copy(name: "Test", plan: freeTrialPlanSlug, isWordPressComStore: true)
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
        let storeNameTask = try XCTUnwrap(sut.tasksForDisplay.first(where: { $0.task.type == .storeName }))
        XCTAssertTrue(storeNameTask.isComplete)
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
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: true,
                                           stores: stores,
                                           defaults: defaults)
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
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: false,
                                           stores: stores,
                                           defaults: defaults)
        // When
        await sut.reloadTasks()

        // Then
        XCTAssertTrue(sut.shouldShowViewAllButton)
    }

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

    func test_it_loads_previously_loaded_data_when_loading_tasks_fails() async {
        // Given
        let initialTasks: [StoreOnboardingTask] = [
            .init(isComplete: false, type: .addFirstProduct),
            .init(isComplete: false, type: .launchStore),
            .init(isComplete: true, type: .customizeDomains),
            .init(isComplete: false, type: .payments)
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

    func test_it_sends_network_request_when_completedAllStoreOnboardingTasks_is_nil() async {
        // Given
        let tasks: [StoreOnboardingTask] = [
            .init(isComplete: false, type: .storeDetails),
            .init(isComplete: false, type: .addFirstProduct),
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

    @MainActor
    func test_the_badge_text_is_nil_for_all_tasks_when_productDescriptionAIFromStoreOnboarding_feature_is_disabled() async {
        // Given
        stores.updateDefaultStore(storeID: 6)
        stores.updateDefaultStore(.fake().copy(siteID: 6, isWordPressComStore: true))
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: true,
                                           stores: stores,
                                           defaults: defaults,
                                           featureFlagService: MockFeatureFlagService(isProductDescriptionAIFromStoreOnboardingEnabled: false))
        let tasks: [StoreOnboardingTask] = [
            .init(isComplete: false, type: .storeDetails),
            .init(isComplete: false, type: .addFirstProduct),
            .init(isComplete: false, type: .launchStore),
            .init(isComplete: true, type: .customizeDomains),
            .init(isComplete: false, type: .payments)
        ]
        mockLoadOnboardingTasks(result: .success(tasks))

        // When
        await sut.reloadTasks()

        // Then
        XCTAssertEqual(sut.tasksForDisplay.count, 5)
        sut.tasksForDisplay.forEach { taskViewModel in
            XCTAssertNil(taskViewModel.badgeText)
        }
    }

    @MainActor
    func test_the_badge_text_is_not_nil_for_addFirstProduct_task_when_store_is_wpcom() async {
        // Given
        stores.updateDefaultStore(storeID: 6)
        stores.updateDefaultStore(.fake().copy(siteID: 6, isWordPressComStore: true))
        let featureFlagService = MockFeatureFlagService(isProductDescriptionAIEnabled: true,
                                                        isProductDescriptionAIFromStoreOnboardingEnabled: true)
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: true,
                                           stores: stores,
                                           defaults: defaults,
                                           featureFlagService: featureFlagService)
        let tasks: [StoreOnboardingTask] = [
            .init(isComplete: false, type: .storeDetails),
            .init(isComplete: false, type: .addFirstProduct),
            .init(isComplete: true, type: .customizeDomains),
            .init(isComplete: false, type: .payments)
        ]
        mockLoadOnboardingTasks(result: .success(tasks))

        // When
        await sut.reloadTasks()

        // Then
        XCTAssertEqual(sut.tasksForDisplay.count, 4)
        sut.tasksForDisplay.forEach { taskViewModel in
            switch taskViewModel.task.type {
            case .addFirstProduct:
                XCTAssertEqual(taskViewModel.badgeText, StoreOnboardingTaskViewModel.Localization.AddFirstProduct.badgeText)
            default:
                XCTAssertNil(taskViewModel.badgeText)
            }
        }
    }

    @MainActor
    func test_the_badge_text_is_not_nil_for_addFirstProduct_task_when_store_is_not_wpcom() async {
        // Given
        stores.updateDefaultStore(storeID: 6)
        stores.updateDefaultStore(.fake().copy(siteID: 6, isWordPressComStore: false))
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: true,
                                           stores: stores,
                                           defaults: defaults,
                                           featureFlagService: MockFeatureFlagService(isProductDescriptionAIFromStoreOnboardingEnabled: true))
        let tasks: [StoreOnboardingTask] = [
            .init(isComplete: false, type: .storeDetails),
            .init(isComplete: false, type: .addFirstProduct),
            .init(isComplete: false, type: .launchStore),
            .init(isComplete: true, type: .customizeDomains),
            .init(isComplete: false, type: .payments)
        ]
        mockLoadOnboardingTasks(result: .success(tasks))

        // When
        await sut.reloadTasks()

        // Then
        XCTAssertTrue(sut.tasksForDisplay.count == 5)
        sut.tasksForDisplay.forEach { taskViewModel in
            XCTAssertNil(taskViewModel.badgeText)
        }
    }

    // MARK: completedAllStoreOnboardingTasks user defaults

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

    // MARK: - `shouldShowInDashboard``

    func test_shouldShowInDashboard_is_false_when_no_tasks_available_due_to_network_error() async {
        // Given
        mockLoadOnboardingTasks(result: .failure(MockError()))
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: false,
                                           stores: stores,
                                           defaults: defaults)
        // When
        await sut.reloadTasks()

        // Then
        XCTAssertFalse(sut.shouldShowInDashboard)
    }

    func test_shouldShowInDashboard_is_false_when_no_tasks_received_in_success_response() async {
        // Given
        mockLoadOnboardingTasks(result: .success([]))
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: false,
                                           stores: stores,
                                           defaults: defaults)
        // When
        await sut.reloadTasks()

        // Then
        XCTAssertFalse(sut.shouldShowInDashboard)
    }

    func test_shouldShowInDashboard_is_true_when_pending_tasks_received_in_response() async {
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
        XCTAssertTrue(sut.shouldShowInDashboard)
    }

    func test_shouldShowInDashboard_is_false_when_all_tasks_are_complete() async {
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
        XCTAssertFalse(sut.shouldShowInDashboard)
    }

    func test_shouldShowInDashboard_is_false_when_user_has_opted_to_hide_the_list() async {
        // Given
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: false,
                                           stores: stores,
                                           defaults: defaults)

        // When
        defaults[UserDefaults.Key.shouldHideStoreOnboardingTaskList] = true

        // Then
        XCTAssertFalse(sut.shouldShowInDashboard)
    }

    // MARK: - hideTaskList

    func test_hideTaskList_updates_userdefaults() async {
        // Given
        defaults[UserDefaults.Key.shouldHideStoreOnboardingTaskList] = nil
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: false,
                                           stores: stores,
                                           defaults: defaults)

        // When
        sut.hideTaskList()

        // Then
        XCTAssertTrue(try XCTUnwrap(defaults[UserDefaults.Key.shouldHideStoreOnboardingTaskList] as? Bool))
    }

    func test_hideTaskList_tracks_hide_list_event() async throws {
        // Given
        let tasks: [StoreOnboardingTask] = [
            .init(isComplete: false, type: .addFirstProduct),
            .init(isComplete: true, type: .storeDetails),
            .init(isComplete: false, type: .launchStore),
            .init(isComplete: false, type: .customizeDomains),
            .init(isComplete: false, type: .payments)
        ]
        mockLoadOnboardingTasks(result: .success(tasks))
        defaults[UserDefaults.Key.shouldHideStoreOnboardingTaskList] = nil
        let sut = StoreOnboardingViewModel(siteID: 0,
                                           isExpanded: false,
                                           stores: stores,
                                           defaults: defaults,
                                           analytics: analytics)
        await sut.reloadTasks()

        // When
        sut.hideTaskList()

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "store_onboarding_hide_list"}))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["source"] as? String, "onboarding_list")
        XCTAssertTrue(try XCTUnwrap(eventProperties["hide"] as? Bool))
        XCTAssertEqual(eventProperties["pending_tasks"] as? String, "add_domain,launch_site,payments,products")
    }

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
