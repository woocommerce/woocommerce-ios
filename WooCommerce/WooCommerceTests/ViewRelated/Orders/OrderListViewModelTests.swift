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
            viewModel.topBanner == .inPersonPaymentsFeedback(.none)
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
                viewModel.topBanner == .inPersonPaymentsFeedback(.none)
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

// MARK: - In-Person Payments feedback banner tracks

    func test_trackInPersonPaymentsFeedbackBannerShown_tracks_event_and_properties_correctly() {
        // Given
        let expectedEvent = WooAnalyticsStat.inPersonPaymentsBannerShown
        let expectedCampaign = FeatureAnnouncementCampaign.inPersonPaymentsCashOnDelivery
        let expectedSource = WooAnalyticsEvent.InPersonPaymentsFeedbackBanner.Source.orderList.rawValue

        // When
        let viewModel = OrderListViewModel(siteID: siteID, analytics: analytics, filters: nil)
        viewModel.trackInPersonPaymentsFeedbackBannerShown(for: .inPersonPaymentsCashOnDelivery)

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

// MARK: - In-Person Payments feedback banner survey

    func test_feedbackBannerSurveySource_Cash_on_Delivery_store_in_an_IPP_country_with_non_WCPay_IPP_orders_is_shown_inPersonPaymentsCashOnDelivery_survey() {
        // Given
        insertCODPaymentGateway()

        // This is not a WCPay order, so receipt_url does not denote an IPP order in this case
        let _ = insertOrder(
            id: 123,
            status: .completed,
            dateCreated: Date(),
            datePaid: Date(),
            customFields: [OrderMetaData.init(metadataID: 1, key: "receipt_url", value: "https://example.com/receipts/1902384")]
        )

        let viewModel = OrderListViewModel(siteID: siteID,
                                           cardPresentPaymentsConfiguration: .init(country: "US"),
                                           stores: stores,
                                           storageManager: storageManager,
                                           filters: nil)

        // Confidence check
        XCTAssertEqual(storage.countObjects(ofType: StorageOrder.self), 1)

        // When
        let survey = viewModel.feedbackBannerSurveySource()

        // Then
        assertEqual(.inPersonPaymentsCashOnDelivery, survey)
    }

    func test_feedbackBannerSurveySource_non_Cash_on_Delivery_store_in_an_IPP_country_without_WCPay_IPP_orders_is_not_shown_a_survey() {
        // Given
        // This is not a WCPay order, so receipt_url does not denote an IPP order in this case
        let _ = insertOrder(
            id: 123,
            status: .completed,
            dateCreated: Date(),
            datePaid: Date(),
            customFields: [OrderMetaData.init(metadataID: 1, key: "receipt_url", value: "https://example.com/receipts/1902384")]
        )

        let viewModel = OrderListViewModel(siteID: siteID,
                                           cardPresentPaymentsConfiguration: .init(country: "US"),
                                           stores: stores,
                                           storageManager: storageManager,
                                           filters: nil)

        // Confidence check
        XCTAssertEqual(storage.countObjects(ofType: StorageOrder.self), 1)

        // When
        let survey = viewModel.feedbackBannerSurveySource()

        // Then
        assertEqual(.none, survey)
    }

    func test_feedbackBannerSurveySource_Cash_on_Delivery_store_in_a_non_IPP_country_is_not_shown_a_survey() {
        // Given
        insertCODPaymentGateway()

        // This is not a WCPay order, so receipt_url does not denote an IPP order in this case
        let _ = insertOrder(
            id: 123,
            status: .completed,
            dateCreated: Date(),
            datePaid: Date(),
            customFields: [OrderMetaData.init(metadataID: 1, key: "receipt_url", value: "https://example.com/receipts/1902384")]
        )

        let viewModel = OrderListViewModel(siteID: siteID,
                                           cardPresentPaymentsConfiguration: .init(country: "AQ"), // Antarctica ;)
                                           stores: stores,
                                           storageManager: storageManager,
                                           filters: nil)

        // Confidence check
        XCTAssertEqual(storage.countObjects(ofType: StorageOrder.self), 1)

        // When
        let survey = viewModel.feedbackBannerSurveySource()

        // Then
        assertEqual(.none, survey)
    }

    func test_feedbackBannerSurveySource_Cash_on_Delivery_store_in_an_IPP_country_with_only_WCPay_web_orders_is_shown_inPersonPaymentsCashOnDelivery_survey() {
        // Given
        insertCODPaymentGateway()

        // This is not an IPP order, as it has no receipt_url
        let _ = insertOrder(
            id: 123,
            status: .completed,
            dateCreated: Date(),
            datePaid: Date(),
            customFields: [],
            paymentMethodID: "woocommerce_payments"
        )

        let viewModel = OrderListViewModel(siteID: siteID,
                                           cardPresentPaymentsConfiguration: .init(country: "US"),
                                           stores: stores,
                                           storageManager: storageManager,
                                           filters: nil)

        // Confidence check
        XCTAssertEqual(storage.countObjects(ofType: StorageOrder.self), 1)

        // When
        let survey = viewModel.feedbackBannerSurveySource()

        // Then
        assertEqual(.inPersonPaymentsCashOnDelivery, survey)
    }

    func test_feedbackBannerSurveySource_when_there_are_less_than_ten_wcpay_orders_then_assigns_inPersonPaymentsFirstTransaction_survey() {
        // Given
        let viewModel = OrderListViewModel(siteID: siteID,
                                           cardPresentPaymentsConfiguration: .init(country: "CA"),
                                           stores: stores,
                                           storageManager: storageManager,
                                           filters: nil)

        let _ = (0..<9).map { orderID in
            let metaDataID = Int64(orderID + 100)
            return insertOrder(
                id: Int64(orderID),
                status: .completed,
                dateCreated: Date(),
                datePaid: Date(),
                customFields: [OrderMetaData.init(metadataID: metaDataID, key: "receipt_url", value: "https://example.com/receipts/\(orderID)")],
                paymentMethodID: "woocommerce_payments"
            )
        }

        // Confidence check
        XCTAssertEqual(storage.countObjects(ofType: StorageOrder.self), 9)

        // When
        let survey = viewModel.feedbackBannerSurveySource()

        // Then
        assertEqual(.inPersonPaymentsFirstTransaction, survey)
    }

    func test_feedbackBannerSurveySource_when_there_are_less_than_ten_wcpay_orders_all_order_than_30_days_then_no_survey() {
        // Given
        let viewModel = OrderListViewModel(siteID: siteID,
                                           cardPresentPaymentsConfiguration: .init(country: "CA"),
                                           stores: stores,
                                           storageManager: storageManager,
                                           filters: nil)

        let thirtyOneDaysAgo = Date().adding(days: -31) ?? Date()
        let _ = (0..<9).map { orderID in
            let metaDataID = Int64(orderID + 100)
            return insertOrder(
                id: Int64(orderID),
                status: .completed,
                dateCreated: thirtyOneDaysAgo,
                datePaid: thirtyOneDaysAgo,
                customFields: [OrderMetaData.init(metadataID: metaDataID, key: "receipt_url", value: "https://example.com/receipts/\(orderID)")],
                paymentMethodID: "woocommerce_payments"
            )
        }

        // Confidence check
        XCTAssertEqual(storage.countObjects(ofType: StorageOrder.self), 9)

        // When
        let survey = viewModel.feedbackBannerSurveySource()

        // Then
        assertEqual(.none, survey)
    }

    func test_feedbackBannerSurveySource_when_there_are_more_than_ten_wcpay_orders_then_assigns_inPersonPaymentsPowerUsers_survey() {
        // Given
        let viewModel = OrderListViewModel(siteID: siteID,
                                           cardPresentPaymentsConfiguration: .init(country: "CA"),
                                           stores: stores,
                                           storageManager: storageManager,
                                           filters: nil)

        let _ = (0..<15).map { orderID in
            let metaDataID = Int64(orderID + 100)
            return insertOrder(
                id: Int64(orderID),
                status: .completed,
                dateCreated: Date(),
                datePaid: Date(),
                customFields: [OrderMetaData.init(metadataID: metaDataID, key: "receipt_url", value: "https://example.com/receipts/\(orderID)")],
                paymentMethodID: "woocommerce_payments"
            )
        }

        // Confidence check
        XCTAssertEqual(storage.countObjects(ofType: StorageOrder.self), 15)

        // When
        let survey = viewModel.feedbackBannerSurveySource()

        // Then
        assertEqual(.inPersonPaymentsPowerUsers, survey)
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

    func test_IPPFeedbackBannerWasSubmitted_then_it_calls_updateFeedbackStatus_with_right_parameters() {
        // Given
        let viewModel = OrderListViewModel(siteID: siteID, stores: stores, filters: nil)
        var updatedFeedbackStatus: FeedbackSettings.Status?
        var receivedFeedbackType: FeedbackType?

        // When
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .updateFeedbackStatus(type, status, onCompletion):
                receivedFeedbackType = type
                updatedFeedbackStatus = status
                onCompletion(.success(()))
            default:
                break
            }
        }

        viewModel.activate()
        viewModel.IPPFeedbackBannerWasSubmitted()

        // Then
        XCTAssertTrue(viewModel.hideIPPFeedbackBanner)

        XCTAssertEqual(receivedFeedbackType, .inPersonPayments)

        switch updatedFeedbackStatus {
        case .given:
            break
        default:
            XCTFail()
        }
    }

    func test_IPPFeedbackBannerWasSubmitted_then_it_calls_setFeatureAnnouncementDismissed_with_right_parameters() {
        // Given
        let viewModel = OrderListViewModel(siteID: siteID, stores: stores, filters: nil)
        var receivedCampaign: FeatureAnnouncementCampaign?
        var receivedRemindAfterDays: Int?

        // When
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .setFeatureAnnouncementDismissed(campaign, remindAfterDays, _):
                receivedRemindAfterDays = remindAfterDays
                receivedCampaign = campaign
            default:
                break
            }
        }

        viewModel.activate()
        viewModel.IPPFeedbackBannerWasSubmitted()

        // Then
        XCTAssertEqual(receivedCampaign, .inPersonPaymentsPowerUsers)
        XCTAssertNil(receivedRemindAfterDays)
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
                     dateCreated: Date = Date(),
                     datePaid: Date? = nil,
                     customFields: [Yosemite.OrderMetaData] = [],
                     paymentMethodID: String? = nil) -> Yosemite.Order {
        let readonlyOrder = MockOrders().empty().copy(siteID: siteID,
                                                      orderID: orderID,
                                                      status: status,
                                                      dateCreated: dateCreated,
                                                      datePaid: datePaid,
                                                      paymentMethodID: paymentMethodID,
                                                      customFields: customFields)
        let storageOrder = storage.insertNewObject(ofType: StorageOrder.self)
        storageOrder.update(with: readonlyOrder)

        for field in customFields {
            let storageMetaData = storage.insertNewObject(ofType: Storage.OrderMetaData.self)
            storageMetaData.update(with: field)
            storageOrder.addToCustomFields(storageMetaData)
        }

        return readonlyOrder
    }

    func insertCODPaymentGateway() {
        //let codGateway = PaymentGateway.fake().copy(siteID: siteID, gatewayID: "cod", enabled: true)
        let codGateway = PaymentGateway(siteID: siteID,
                                        gatewayID: "cod",
                                        title: "Pay in Person",
                                        description: "Pay by cash or card when you pick up in store",
                                        enabled: true,
                                        features: [],
                                        instructions: nil)
        let storageGateway = storage.insertNewObject(ofType: StoragePaymentGateway.self)
        storageGateway.update(with: codGateway)
    }
}
