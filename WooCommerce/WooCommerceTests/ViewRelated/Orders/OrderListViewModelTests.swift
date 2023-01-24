import XCTest
@testable import WooCommerce
import Yosemite
import Storage
import Combine

/// Tests for `OrderListViewModel`.
///
final class OrderListViewModelTests: XCTestCase {
    /// The `siteID` value doesn't matter.
    private let siteID: Int64 = 1_000_000

    private var storageManager: MockStorageManager!

    private var stores: MockStoresManager!

    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    private var storage: StorageType {
        storageManager.viewStorage
    }

    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.sessionManager.setStoreId(siteID)
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        ServiceLocator.setSelectedSiteSettings(SelectedSiteSettings(stores: stores, storageManager: storageManager))
    }

    override func tearDown() {
        ServiceLocator.setSelectedSiteSettings(SelectedSiteSettings())
        storageManager.reset()
        storageManager = nil
        stores = nil
        analyticsProvider = nil
        analytics = nil

        cancellables.forEach {
            $0.cancel()
        }
        cancellables.removeAll()

        super.tearDown()
    }

    // MARK: - Orders Loading

    func test_given_a_filter_it_loads_the_orders_matching_that_filter_from_the_DB() throws {
        // Arrange
        let filters = FilterOrderListViewModel.Filters(orderStatus: [.processing], dateRange: nil, numberOfActiveFilters: 1)
        let viewModel = OrderListViewModel(siteID: siteID,
                                           storageManager: storageManager,
                                           filters: filters)

        let processingOrders = (0..<10).map { insertOrder(id: $0, status: .processing) }
        let completedOrders = (100..<105).map { insertOrder(id: $0, status: .completed) }

        XCTAssertEqual(storage.countObjects(ofType: StorageOrder.self), processingOrders.count + completedOrders.count)

        // Act
        let snapshot = try activateAndRetrieveSnapshot(of: viewModel)

        // Assert
        XCTAssertTrue(snapshot.numberOfItems > 0)
        XCTAssertEqual(snapshot.numberOfItems, processingOrders.count)

        XCTAssertEqual(viewModel.orderIDs(from: snapshot), processingOrders.orderIDs)
    }

    func test_given_no_filter_it_loads_all_the_today_and_past_orders_from_the_DB() throws {
        // Arrange
        let viewModel = OrderListViewModel(siteID: siteID, storageManager: storageManager, filters: nil)

        let allInsertedOrders = [
            (0..<10).map { insertOrder(id: $0, status: .processing) },
            (100..<105).map { insertOrder(id: $0, status: .completed, dateCreated: Date().adding(days: -2)!) },
            (200..<203).map { insertOrder(id: $0, status: .pending) },
        ].flatMap { $0 }

        XCTAssertEqual(storage.countObjects(ofType: StorageOrder.self), allInsertedOrders.count)

        // Act
        let snapshot = try activateAndRetrieveSnapshot(of: viewModel)

        // Assert
        XCTAssertTrue(snapshot.numberOfItems > 0)
        XCTAssertEqual(snapshot.numberOfItems, allInsertedOrders.count)

        XCTAssertEqual(viewModel.orderIDs(from: snapshot), allInsertedOrders.orderIDs)
    }

    /// Test that all orders including orders dated in the future (dateCreated) will be fetched.
    func test_it_also_loads_future_orders_from_the_DB() throws {

        // Arrange
        let filters = FilterOrderListViewModel.Filters(orderStatus: [.pending], dateRange: nil, numberOfActiveFilters: 1)
        let viewModel = OrderListViewModel(siteID: siteID,
                                           storageManager: storageManager,
                                           filters: filters)

        let expectedOrders = [
            // Future orders
            insertOrder(id: 1_000, status: .pending, dateCreated: Date().adding(days: 1)!),
            insertOrder(id: 1_001, status: .pending, dateCreated: Date().adding(days: 2)!),
            insertOrder(id: 1_002, status: .pending, dateCreated: Date().adding(days: 3)!),
            // Past orders
            insertOrder(id: 4_000, status: .pending, dateCreated: Date().adding(days: -1)!),
            insertOrder(id: 4_001, status: .pending, dateCreated: Date().adding(days: -20)!),
        ]

        // This should be ignored because it is not the same filter
        let ignoredFutureOrder = insertOrder(id: 2_000, status: .cancelled, dateCreated: Date().adding(days: 1)!)

        // Act
        let snapshot = try activateAndRetrieveSnapshot(of: viewModel)

        // Assert
        XCTAssertEqual(snapshot.numberOfItems, expectedOrders.count)

        let orderIDs = viewModel.orderIDs(from: snapshot)
        XCTAssertEqual(orderIDs, expectedOrders.orderIDs)
        XCTAssertFalse(orderIDs.contains(ignoredFutureOrder.orderID))
    }

    /// Orders with dateCreated in the future should be grouped in an "Upcoming" section.
    func test_it_groups_future_orders_in_upcoming_section() throws {
        // Arrange
        let filters = FilterOrderListViewModel.Filters(orderStatus: [.failed], dateRange: nil, numberOfActiveFilters: 1)
        let viewModel = OrderListViewModel(siteID: siteID,
                                           storageManager: storageManager,
                                           filters: filters)

        let expectedOrders = (
            future: [
                insertOrder(id: 1_000, status: .failed, dateCreated: Date().adding(days: 3)!),
                insertOrder(id: 1_001, status: .failed, dateCreated: Date().adding(days: 4)!),
                insertOrder(id: 1_002, status: .failed, dateCreated: Date().adding(days: 5)!),
            ],
            past: [
                insertOrder(id: 4_000, status: .failed, dateCreated: Date().adding(days: -1)!),
            ]
        )

        // Act
        let snapshot = try activateAndRetrieveSnapshot(of: viewModel)

        // Assert
        XCTAssertEqual(snapshot.numberOfSections, 2)

        // The first section should be the Upcoming section
        let sectionID = try XCTUnwrap(snapshot.sectionIdentifiers.first)
        XCTAssertEqual(Age(rawValue: sectionID), .upcoming)

        let sectionTitle = try XCTUnwrap(viewModel.sectionTitleFor(sectionIdentifier: sectionID))
        XCTAssertEqual(sectionTitle, Age(rawValue: sectionID)?.description)

        XCTAssertEqual(snapshot.numberOfItems(inSection: sectionID), expectedOrders.future.count)
    }

    // MARK: - App Activation

    func test_it_requests_a_resynchronization_when_the_app_is_activated() {
        // Arrange
        let notificationCenter = NotificationCenter()
        let viewModel = OrderListViewModel(siteID: siteID, notificationCenter: notificationCenter, filters: nil)

        var resynchronizeRequested = false
        viewModel.onShouldResynchronizeIfViewIsVisible = {
            resynchronizeRequested = true
        }

        viewModel.activate()

        // Act
        notificationCenter.post(name: UIApplication.willResignActiveNotification, object: nil)
        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)

        // Assert
        XCTAssertTrue(resynchronizeRequested)
    }

    func test_given_no_previous_deactivation_it_does_not_request_a_resynchronization_when_the_app_is_activated() {
        // Arrange
        let notificationCenter = NotificationCenter()
        let viewModel = OrderListViewModel(siteID: siteID, notificationCenter: notificationCenter, filters: nil)

        var resynchronizeRequested = false
        viewModel.onShouldResynchronizeIfViewIsVisible = {
            resynchronizeRequested = true
        }

        viewModel.activate()

        // Act
        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)

        // Assert
        XCTAssertFalse(resynchronizeRequested)
    }

    // MARK: - Foreground Notifications

    func test_given_a_new_order_notification_it_requests_a_resynchronization() {
        // Arrange
        let pushNotificationsManager = MockPushNotificationsManager()
        let viewModel = OrderListViewModel(siteID: siteID, pushNotificationsManager: pushNotificationsManager, filters: nil)

        var resynchronizeRequested = false
        viewModel.onShouldResynchronizeIfViewIsVisible = {
            resynchronizeRequested = true
        }

        viewModel.activate()

        // Act
        let notification = PushNotification(noteID: 1, siteID: 1, kind: .storeOrder, title: "", subtitle: "", message: "")
        pushNotificationsManager.sendForegroundNotification(notification)

        // Assert
        XCTAssertTrue(resynchronizeRequested)
    }

    func test_given_a_non_order_notification_it_does_not_request_a_resynchronization() {
        // Arrange
        let pushNotificationsManager = MockPushNotificationsManager()
        let viewModel = OrderListViewModel(siteID: siteID, pushNotificationsManager: pushNotificationsManager, filters: nil)

        var resynchronizeRequested = false
        viewModel.onShouldResynchronizeIfViewIsVisible = {
            resynchronizeRequested = true
        }

        viewModel.activate()

        // Act
        let notification = PushNotification(noteID: 1, siteID: 1, kind: .comment, title: "", subtitle: "", message: "")
        pushNotificationsManager.sendForegroundNotification(notification)

        // Assert
        XCTAssertFalse(resynchronizeRequested)
    }

    // MARK: - Banner visibility

    func test_when_having_no_error_and_orders_banner_should_not_be_shown_shows_nothing() {
        // Given
        let viewModel = OrderListViewModel(siteID: siteID, stores: stores, filters: nil)
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .loadFeedbackVisibility(_, onCompletion):
                onCompletion(.success(false))
            default:
                break
            }
        }
        viewModel.activate()

        // When
        viewModel.updateBannerVisibility()
        viewModel.hideIPPFeedbackBanner = true

        // Then
        waitUntil {
            viewModel.topBanner == .none
        }
    }

    func test_when_having_no_error_and_IPP_banner_should_be_shown_shows_IPP_banner() {
        // Given
        let viewModel = OrderListViewModel(siteID: siteID, stores: stores, filters: nil)
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .loadFeedbackVisibility(.inPersonPayments, onCompletion):
                onCompletion(.success(true))
            default:
                break
            }
        }
        viewModel.activate()

        // When
        viewModel.updateBannerVisibility()
        viewModel.hideIPPFeedbackBanner = false


        // Then
        waitUntil {
            viewModel.topBanner == .IPPFeedback
        }
    }

    func test_when_having_no_error_and_orders_banner_should_be_shown_shows_orders_banner() {
        // Given
        let viewModel = OrderListViewModel(siteID: siteID, stores: stores, filters: nil)
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .loadFeedbackVisibility(_, onCompletion):
                onCompletion(.success(true))
            default:
                break
            }
        }
        viewModel.activate()

        // When
        viewModel.updateBannerVisibility()
        viewModel.hideIPPFeedbackBanner = true

        // Then
        waitUntil {
            viewModel.topBanner == .orderCreation
        }
    }

    func test_when_having_no_error_and_orders_banner_or_IPP_banner_should_be_shown_shows_correct_banner() {
        // Given
        let isIPPFeatureFlagEnabled = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.IPPInAppFeedbackBanner)
        let viewModel = OrderListViewModel(siteID: siteID, stores: stores, filters: nil)

        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .loadFeedbackVisibility(.ordersCreation, onCompletion):
                onCompletion(.success(true))
            default:
                break
            }
        }
        viewModel.activate()

        // When
        viewModel.updateBannerVisibility()

        // Then
        if isIPPFeatureFlagEnabled {
            viewModel.hideIPPFeedbackBanner = false
            waitUntil {
                viewModel.topBanner == .IPPFeedback
            }
        } else {
            waitUntil {
                viewModel.topBanner == .orderCreation
            }
        }
    }

    func test_when_having_no_error_and_orders_banner_visibility_loading_fails_shows_nothing() {
        // Given
        let viewModel = OrderListViewModel(siteID: siteID, stores: stores, filters: nil)
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .loadFeedbackVisibility(_, onCompletion):
                let error = NSError(domain: "Test", code: 503, userInfo: nil)
                onCompletion(.failure(error))
            default:
                break
            }
        }
        viewModel.activate()

        // When
        viewModel.updateBannerVisibility()

        // Then
        waitUntil {
            viewModel.topBanner == .none
        }
    }

    func test_storing_error_shows_error_banner() {
        // Given
        let viewModel = OrderListViewModel(siteID: siteID, filters: nil)
        viewModel.activate()

        // When
        viewModel.updateBannerVisibility()
        viewModel.hasErrorLoadingData = true

        // Then
        waitUntil {
            viewModel.topBanner == .error
        }
    }

    func test_dismissing_banners_does_not_show_banners() {
        // Given
        let viewModel = OrderListViewModel(siteID: siteID, stores: stores, filters: nil)
        viewModel.activate()

        // When
        viewModel.updateBannerVisibility()
        viewModel.hideIPPFeedbackBanner = true
        viewModel.hideOrdersBanners = true

        // Then
        waitUntil {
            viewModel.topBanner == .none
        }
    }

    func test_hiding_orders_banners_still_shows_error_banner() {
        // Given
        let viewModel = OrderListViewModel(siteID: siteID, filters: nil)
        viewModel.activate()

        // When
        viewModel.updateBannerVisibility()
        viewModel.hasErrorLoadingData = true
        viewModel.hideOrdersBanners = true

        // Then
        waitUntil {
            viewModel.topBanner == .error
        }
    }

    // MARK: - Filters Applied
    func test_it_requests_a_resynchronization_when_the_new_filters_are_applied() {
        // Arrange
        let notificationCenter = NotificationCenter()
        let viewModel = OrderListViewModel(siteID: siteID, notificationCenter: notificationCenter, filters: nil)

        var resynchronizeRequested = false
        viewModel.onShouldResynchronizeIfNewFiltersAreApplied = {
            resynchronizeRequested = true
        }

        viewModel.activate()

        // Act
        viewModel.updateFilters(filters: FilterOrderListViewModel.Filters(orderStatus: [.completed], dateRange: nil, numberOfActiveFilters: 1))

        // Assert
        XCTAssertTrue(resynchronizeRequested)
    }

    func test_given_identical_filters_it_does_not_request_a_resynchronization() {
        // Arrange
        let filters = FilterOrderListViewModel.Filters(orderStatus: [.pending], dateRange: nil, numberOfActiveFilters: 0)
        let notificationCenter = NotificationCenter()
        let viewModel = OrderListViewModel(siteID: siteID, notificationCenter: notificationCenter, filters: filters)

        var resynchronizeRequested = false
        viewModel.onShouldResynchronizeIfNewFiltersAreApplied = {
            resynchronizeRequested = true
        }

        viewModel.activate()

        // Act
        viewModel.updateFilters(filters: filters)

        // Assert
        XCTAssertFalse(resynchronizeRequested)
    }

    func test_trackInPersonPaymentsFeedbackBannerShown_tracks_event_and_properties_correctly() {
        // Given
        let expectedEvent = WooAnalyticsStat.inPersonPaymentsBannerShown
        let expectedCampaign = FeatureAnnouncementCampaign.inPersonPaymentsCashOnDelivery
        let expectedSource = WooAnalyticsEvent.InPersonPaymentsFeedbackBanner.Source.orderList.rawValue

        // When
        let viewModel = OrderListViewModel(siteID: siteID, analytics: analytics, filters: nil)
        viewModel.trackInPersonPaymentsFeedbackBannerShown(for: .IPP_COD)

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents.first, expectedEvent.rawValue)
        guard let actualProperties = analyticsProvider.receivedProperties.first(
            where: { $0.keys.contains("source") }) else {
            return XCTFail("Expected properties were not tracked"
            )}
        assertEqual(expectedCampaign.rawValue, actualProperties["campaign"] as? String)
        assertEqual(expectedSource, actualProperties["source"] as? String)
    }

    func test_IPPFeedbackBannerCTATapped_tracks_event_and_properties_correctly() {
        // Given
        let expectedEvent = WooAnalyticsStat.inPersonPaymentsBannerTapped
        let expectedCampaign = FeatureAnnouncementCampaign.inPersonPaymentsCashOnDelivery
        let expectedSource = WooAnalyticsEvent.InPersonPaymentsFeedbackBanner.Source.orderList.rawValue

        // When
        let viewModel = OrderListViewModel(siteID: siteID, analytics: analytics, filters: nil)
        viewModel.IPPFeedbackBannerCTATapped(for: .inPersonPaymentsCashOnDelivery)

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents.first, expectedEvent.rawValue)
        guard let actualProperties = analyticsProvider.receivedProperties.first(
            where: { $0.keys.contains("source") }) else {
            return XCTFail("Expected properties were not tracked"
            )}
        assertEqual(expectedCampaign.rawValue, actualProperties["campaign"] as? String)
        assertEqual(expectedSource, actualProperties["source"] as? String)
    }

    func test_IPPFeedbackBannerDontShowAgainTapped_tracks_dismiss_event_and_properties_correctly() {
        // Given
        let expectedEvent = WooAnalyticsStat.inPersonPaymentsBannerDismissed
        let expectedCampaign = FeatureAnnouncementCampaign.inPersonPaymentsCashOnDelivery
        let expectedSource = WooAnalyticsEvent.InPersonPaymentsFeedbackBanner.Source.orderList.rawValue
        let expectedRemindLater = false

        // When
        let viewModel = OrderListViewModel(siteID: siteID, analytics: analytics, filters: nil)
        viewModel.IPPFeedbackBannerDontShowAgainTapped(for: .inPersonPaymentsCashOnDelivery)

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents.first, expectedEvent.rawValue)
        guard let actualProperties = analyticsProvider.receivedProperties.first(
            where: { $0.keys.contains("source") }) else {
            return XCTFail("Expected properties were not tracked"
            )}
        assertEqual(expectedCampaign.rawValue, actualProperties["campaign"] as? String)
        assertEqual(expectedSource, actualProperties["source"] as? String)
        assertEqual(expectedRemindLater, actualProperties["remind_later"] as? Bool)
    }

    func test_IPPFeedbackBannerRemindMeLaterTapped_tracks_dismiss_event_and_properties_correctly() {
        // Given
        let expectedEvent = WooAnalyticsStat.inPersonPaymentsBannerDismissed
        let expectedCampaign = FeatureAnnouncementCampaign.inPersonPaymentsCashOnDelivery
        let expectedSource = WooAnalyticsEvent.InPersonPaymentsFeedbackBanner.Source.orderList.rawValue
        let expectedRemindLater = true

        // When
        let viewModel = OrderListViewModel(siteID: siteID, analytics: analytics, filters: nil)
        viewModel.IPPFeedbackBannerRemindMeLaterTapped(for: .inPersonPaymentsCashOnDelivery)

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents.first, expectedEvent.rawValue)
        guard let actualProperties = analyticsProvider.receivedProperties.first(
            where: { $0.keys.contains("source") }) else {
            return XCTFail("Expected properties were not tracked"
            )}
        assertEqual(expectedCampaign.rawValue, actualProperties["campaign"] as? String)
        assertEqual(expectedSource, actualProperties["source"] as? String)
        assertEqual(expectedRemindLater, actualProperties["remind_later"] as? Bool)
    }

    func test_IPPFeedbackBannerWasSubmitted_hides_banner_after_being_called() {
        // Given
        let viewModel = OrderListViewModel(siteID: siteID, filters: nil)

        // When
        viewModel.IPPFeedbackBannerWasSubmitted()
        viewModel.hasErrorLoadingData = false
        viewModel.hideOrdersBanners = true

        // Then
        waitUntil {
            viewModel.topBanner == .none
        }
    }

    func test_feedback_status_when_IPPFeedbackBannerWasSubmitted_is_called_then_feedback_status_is_not_nil() {
        // Given
        let viewModel = OrderListViewModel(siteID: siteID, stores: stores, filters: nil)
        var updatedFeedbackStatus: FeedbackSettings.Status?

        // When
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .loadFeedbackVisibility(.inPersonPayments, onCompletion):
                onCompletion(.success(true))
            case let .updateFeedbackStatus(.inPersonPayments, status, onCompletion):
                updatedFeedbackStatus = status
                onCompletion(.success(()))
            default:
                break
            }
        }

        viewModel.activate()
        viewModel.IPPFeedbackBannerWasSubmitted()

        // Then
        assertEqual(2, stores.receivedActions.count)
        XCTAssertTrue(stores.receivedActions.contains(where: {
            $0 is AppSettingsAction
        }))
        XCTAssertNotNil(updatedFeedbackStatus)
    }

    func test_feedback_status_when_IPPFeedbackBannerWasSubmitted_is_not_called_then_feedback_status_is_nil() {
        // Given
        let viewModel = OrderListViewModel(siteID: siteID, stores: stores, filters: nil)
        var feedbackStatus: FeedbackSettings.Status?

        // When
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .updateFeedbackStatus(.inPersonPayments, status, onCompletion):
                feedbackStatus = status
                onCompletion(.success(()))
            default:
                break
            }
        }
        viewModel.activate()

        // Then
        assertEqual(nil, feedbackStatus)
    }

    func test_feedback_type_when_IPPFeedbackBannerWasSubmitted_is_called_then_feedback_type_is_IPP() {
        // Given
        let viewModel = OrderListViewModel(siteID: siteID, stores: stores, filters: nil)
        var feedbackType: FeedbackType?

        // When
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .loadFeedbackVisibility(type, onCompletion):
                feedbackType = type
                onCompletion(.success(true))
            case let .updateFeedbackStatus(.inPersonPayments, _, onCompletion):
                feedbackType = .inPersonPayments
                onCompletion(.success(()))
            default:
                break
            }
        }
        viewModel.activate()
        viewModel.IPPFeedbackBannerWasSubmitted()

        // Then
        XCTAssertEqual(feedbackType, .inPersonPayments)
    }
}

// MARK: - Helpers

private extension OrderListViewModel {
    /// Returns the corresponding order IDs instances for all the given FetchResultSnapshot IDs.
    ///
    func orderIDs(from snapshot: FetchResultSnapshot) -> Set<Int64> {
        Set(snapshot.itemIdentifiers.compactMap { objectID in
            detailsViewModel(withID: objectID)?.order.orderID
        })
    }
}

private extension OrderListViewModelTests {
    // MARK: - Country helpers
    func setupCountry(country: Country) {
        let setting = SiteSetting.fake()
            .copy(
                siteID: siteID,
                settingID: "woocommerce_default_country",
                value: country.rawValue,
                settingGroupKey: SiteSettingGroup.general.rawValue
            )
        storageManager.insertSampleSiteSetting(readOnlySiteSetting: setting)
        ServiceLocator.selectedSiteSettings.refresh()
    }

    enum Country: String {
        case us = "US:CA"
        case es = "ES"
    }
}

private extension Array where Element == Yosemite.Order {
    /// Returns all the IDs
    ///
    var orderIDs: Set<Int64> {
        Set(map(\.orderID))
    }
}

// MARK: - Builders

private extension OrderListViewModelTests {

    /// Activate the viewModel to start fetching and then return the first
    /// valid `FetchResultSnapshot` triggered.
    func activateAndRetrieveSnapshot(of viewModel: OrderListViewModel) throws -> FetchResultSnapshot {
        return waitFor { promise in
            // The first snapshot is dropped because it's just the default empty one.
            viewModel.snapshot.dropFirst().sink { snapshot in
                promise(snapshot)
            }.store(in: &self.cancellables)

            viewModel.activate()
        }
    }

    func orderStatus(with status: OrderStatusEnum) -> Yosemite.OrderStatus {
        OrderStatus(name: nil, siteID: siteID, slug: status.rawValue, total: 0)
    }

    func insertOrder(id orderID: Int64,
                     status: OrderStatusEnum,
                     dateCreated: Date = Date()) -> Yosemite.Order {
        let readonlyOrder = MockOrders().empty().copy(siteID: siteID,
                                                      orderID: orderID,
                                                      status: status,
                                                      dateCreated: dateCreated)
        let storageOrder = storage.insertNewObject(ofType: StorageOrder.self)
        storageOrder.update(with: readonlyOrder)

        return readonlyOrder
    }
}
