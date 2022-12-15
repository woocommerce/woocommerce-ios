import XCTest
@testable import WooCommerce
import Yosemite

import protocol Storage.StorageManagerType
import protocol Storage.StorageType
import enum Storage.FeedbackType
import struct Storage.FeedbackSettings

final class CouponListViewModelTests: XCTestCase {
    private var mockStorageManager: MockStorageManager!
    private var mockStoresManager: MockStoresManager!
    private var mockSyncingCoordinator: MockSyncingCoordinator!
    private var sut: CouponListViewModel!

    private var mockStorage: StorageType {
        mockStorageManager.viewStorage
    }

    private let sampleSiteURL = "https://test.com"

    override func setUp() {
        super.setUp()
        createMocks()
        sut = CouponListViewModel(siteID: 123, siteURL: sampleSiteURL)
    }

    private func createMocks() {
        mockStorageManager = MockStorageManager()
        mockStoresManager = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        mockSyncingCoordinator = MockSyncingCoordinator()
    }

    private func setUpWithCouponFetched(injectedStores: StoresManager? = nil) {
        let coupon = Coupon.fake().copy(siteID: 123, code: "coupon")
        mockStorageManager.insertSampleCoupon(readOnlyCoupon: coupon)
        if let stores = injectedStores {
            sut = CouponListViewModel(siteID: 123,
                                      siteURL: sampleSiteURL,
                                      storesManager: stores,
                                      storageManager: mockStorageManager)
        } else {
            sut = CouponListViewModel(siteID: 123,
                                      siteURL: sampleSiteURL,
                                      storageManager: mockStorageManager)
        }
        sut.buildCouponViewModels()
    }

    override func tearDown() {
        mockStorageManager = nil
        mockSyncingCoordinator = nil
        mockStoresManager = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Tests
    //
    func test_viewDidLoad_calls_synchronizeFirstPage_on_syncCoordinator() {
        // Given
        sut = CouponListViewModel(siteID: 123,
                                  siteURL: sampleSiteURL,
                                  syncingCoordinator: mockSyncingCoordinator)

        // When
        sut.viewDidLoad()

        // Then
        XCTAssertTrue(mockSyncingCoordinator.spyDidCallSynchronizeFirstPage)
    }

    func test_viewDidLoad_starts_loading_state() {
        // When
        sut.viewDidLoad()

        // Then
        XCTAssertEqual(sut.state, .loading)
    }

    func test_sync_sends_correct_synchronize_coupons_action_to_store() throws {
        // Given
        sut = CouponListViewModel(siteID: 123,
                                  siteURL: sampleSiteURL,
                                  storesManager: mockStoresManager)
        // When
        sut.sync(pageNumber: 4, pageSize: 8, reason: nil, onCompletion: nil)

        // Then
        let action = try XCTUnwrap(mockStoresManager.receivedActions.last as? CouponAction)
        switch action {
        case let .synchronizeCoupons(siteID, _, pageNumber, pageSize, _):
            XCTAssertEqual(siteID, 123)
            XCTAssertEqual(pageNumber, 4)
            XCTAssertEqual(pageSize, 8)
        default:
            break
        }
    }

    func test_sync_sets_state_to_loading_when_first_page_loaded_without_data_present() {
        // When
        sut.sync(pageNumber: 1, pageSize: 10, reason: nil, onCompletion: nil)

        // Then
        XCTAssertEqual(sut.state, .loading)
    }

    func test_handleCouponSyncResult_sets_state_to_coupons_when_coupons_present() throws {
        // Given
        setUpWithCouponFetched()

        // When
        sut.handleCouponSyncResult(result: .success(false), pageNumber: 1)

        // Then
        XCTAssertEqual(sut.state, .coupons)
        XCTAssertEqual(sut.couponViewModels.count, 1)
    }

    func test_handleCouponSyncResult_shows_empty_when_no_coupons_present() {
        // When
        sut.handleCouponSyncResult(result: .success(false), pageNumber: 1)

        // Then
        XCTAssertEqual(sut.state, .empty)
    }

    func test_refreshCoupon_updates_state_to_refreshing() {
        // Given
        setUpWithCouponFetched() // we need to have existing data to enter refreshing state

        // When
        sut.refreshCoupons()

        // Then
        XCTAssertEqual(sut.state, .refreshing)
    }

    func test_refreshCoupons_calls_resynchronize_on_syncCoordinator() {
        // Given
        sut = CouponListViewModel(siteID: 123, siteURL: sampleSiteURL, syncingCoordinator: mockSyncingCoordinator)

        // When
        sut.refreshCoupons()

        // Then
        XCTAssert(mockSyncingCoordinator.spyDidCallResynchronize)
    }

    func test_handleCouponSyncResult_removes_refreshing_when_refresh_completes() {
        // Given
        setUpWithCouponFetched()
        sut.refreshCoupons()

        // When
        sut.handleCouponSyncResult(result: .success(false), pageNumber: 1)

        // Then
        XCTAssertEqual(sut.state, .coupons)
    }

    func test_tableWillDisplayCellAtIndexPath_calls_ensureNextPageIsSynchronized_on_syncCoordinator() {
        // Given
        sut = CouponListViewModel(siteID: 123, siteURL: sampleSiteURL, syncingCoordinator: mockSyncingCoordinator)

        // When
        sut.tableWillDisplayCell(at: IndexPath(row: 3, section: 0))

        // Then
        XCTAssertTrue(mockSyncingCoordinator.spyDidCallEnsureNextPageIsSynchronized)
        XCTAssertEqual(mockSyncingCoordinator.spyEnsureNextPageIsSynchronizedLastVisibleIndex, 3)
    }

    func test_sync_updates_state_correctly_when_syncing_next_page() {
        // When
        sut.sync(pageNumber: 2, pageSize: 10, reason: nil, onCompletion: nil)

        // Then
        XCTAssertEqual(sut.state, .loadingNextPage)
    }

    func test_shouldDisplayFeedbackBanner_returns_false_if_state_is_initialized() {
        // Given
        sut = CouponListViewModel(siteID: 123, siteURL: sampleSiteURL, syncingCoordinator: mockSyncingCoordinator)
        XCTAssertEqual(sut.state, .empty) // confidence check

        // Then
        XCTAssertFalse(sut.shouldDisplayFeedbackBanner)
    }

    func test_shouldDisplayFeedbackBanner_returns_false_if_state_is_loading() {
        // When
        sut.viewDidLoad()
        XCTAssertEqual(sut.state, .loading) // confidence check

        // Then
        XCTAssertFalse(sut.shouldDisplayFeedbackBanner)
    }

    func test_shouldDisplayFeedbackBanner_returns_false_if_state_is_empty() {
        // When
        sut.handleCouponSyncResult(result: .success(false), pageNumber: 1)
        XCTAssertEqual(sut.state, .empty) // confidence check

        // Then
        XCTAssertFalse(sut.shouldDisplayFeedbackBanner)
    }

    func test_shouldDisplayFeedbackBanner_returns_true_if_state_is_coupons_and_couponManagement_feedback_visibility_is_enabled_in_app_settings() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        var feedbackType: FeedbackType?
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .loadFeedbackVisibility(type, onCompletion):
                feedbackType = type
                onCompletion(.success(true))
            default:
                break
            }
        }
        setUpWithCouponFetched(injectedStores: stores)

        // When
        sut.handleCouponSyncResult(result: .success(false), pageNumber: 1)
        XCTAssertEqual(sut.state, .coupons) // confidence check

        // Then
        XCTAssertEqual(feedbackType, .couponManagement)
        XCTAssertTrue(sut.shouldDisplayFeedbackBanner)
    }

    func test_shouldDisplayFeedbackBanner_returns_false_if_state_is_coupons_and_couponManagement_feedback_visibility_is_disabled_in_app_settings() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        var feedbackType: FeedbackType?
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .loadFeedbackVisibility(type, onCompletion):
                feedbackType = type
                onCompletion(.success(false))
            default:
                break
            }
        }
        setUpWithCouponFetched(injectedStores: stores)

        // When
        sut.handleCouponSyncResult(result: .success(false), pageNumber: 1)
        XCTAssertEqual(sut.state, .coupons) // confidence check

        // Then
        XCTAssertEqual(feedbackType, .couponManagement)
        XCTAssertFalse(sut.shouldDisplayFeedbackBanner)
    }

    func test_shouldDisplayFeedbackBanner_returns_true_if_state_is_refreshing_and_couponManagement_feedback_visibility_is_enabled_in_app_settings() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        var feedbackType: FeedbackType?
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .loadFeedbackVisibility(type, onCompletion):
                feedbackType = type
                onCompletion(.success(true))
            default:
                break
            }
        }
        setUpWithCouponFetched(injectedStores: stores) // we need to have existing data to enter refreshing state

        // When
        sut.refreshCoupons()
        XCTAssertEqual(sut.state, .refreshing) // confidence check

        // Then
        XCTAssertEqual(feedbackType, .couponManagement)
        XCTAssertTrue(sut.shouldDisplayFeedbackBanner)
    }

    func test_shouldDisplayFeedbackBanner_returns_false_if_state_is_refreshing_and_couponManagement_feedback_visibility_is_disabled_in_app_settings() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        var feedbackType: FeedbackType?
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .loadFeedbackVisibility(type, onCompletion):
                feedbackType = type
                onCompletion(.success(false))
            default:
                break
            }
        }
        setUpWithCouponFetched(injectedStores: stores) // we need to have existing data to enter refreshing state

        // When
        sut.refreshCoupons()
        XCTAssertEqual(sut.state, .refreshing) // confidence check

        // Then
        XCTAssertEqual(feedbackType, .couponManagement)
        XCTAssertFalse(sut.shouldDisplayFeedbackBanner)
    }

    func test_shouldDisplayFeedbackBanner_returns_true_if_state_is_loadingNextPage_and_couponManagement_feedback_visibility_is_enabled_in_app_settings() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        var feedbackType: FeedbackType?
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .loadFeedbackVisibility(type, onCompletion):
                feedbackType = type
                onCompletion(.success(true))
            default:
                break
            }
        }
        setUpWithCouponFetched(injectedStores: stores)

        // When
        sut.sync(pageNumber: 2, pageSize: 10, reason: nil, onCompletion: nil)
        XCTAssertEqual(sut.state, .loadingNextPage) // confidence check

        // Then
        XCTAssertEqual(feedbackType, .couponManagement)
        XCTAssertTrue(sut.shouldDisplayFeedbackBanner)
    }

    func test_shouldDisplayFeedbackBanner_returns_false_if_state_is_loadingNextPage_and_couponManagement_feedback_visibility_is_disabled_in_app_settings() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        var feedbackType: FeedbackType?
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .loadFeedbackVisibility(type, onCompletion):
                feedbackType = type
                onCompletion(.success(false))
            default:
                break
            }
        }
        setUpWithCouponFetched(injectedStores: stores)

        // When
        sut.sync(pageNumber: 2, pageSize: 10, reason: nil, onCompletion: nil)
        XCTAssertEqual(sut.state, .loadingNextPage) // confidence check

        // Then
        XCTAssertEqual(feedbackType, .couponManagement)
        XCTAssertFalse(sut.shouldDisplayFeedbackBanner)
    }

    func test_shouldDisplayFeedbackBanner_returns_false_after_dismissing_feedback_banner() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        var status: FeedbackSettings.Status?
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .loadFeedbackVisibility(_, onCompletion):
                onCompletion(.success(true))
            case let .updateFeedbackStatus(_, newStatus, onCompletion):
                status = newStatus
                onCompletion(.success(()))
            default:
                break
            }
        }
        setUpWithCouponFetched(injectedStores: stores)

        // When
        sut.handleCouponSyncResult(result: .success(false), pageNumber: 1)
        XCTAssertTrue(sut.shouldDisplayFeedbackBanner) // confidence check
        sut.dismissFeedbackBanner()

        // Then
        XCTAssertEqual(status, .dismissed)
        XCTAssertFalse(sut.shouldDisplayFeedbackBanner)
    }

    func test_state_is_couponsDisabled_if_coupon_setting_returns_false() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case let .retrieveCouponSetting(_, onCompletion):
                onCompletion(.success(false))
            default:
                break
            }
        }
        sut = CouponListViewModel(siteID: 123,
                                  siteURL: sampleSiteURL,
                                  storesManager: stores)

        // When
        let error = NSError(domain: "Test", code: 503, userInfo: nil)
        sut.handleCouponSyncResult(result: .failure(error), pageNumber: 1)

        // Then
        assertEqual(.couponsDisabled, sut.state)
    }

    func test_state_is_coupons_if_enableCoupons_and_synchronizeFirstPage_succeed() {
        // Given
        let sampleSiteID: Int64 = 123
        mockStorageManager.insertSampleCoupon(readOnlyCoupon: Coupon.fake().copy(siteID: sampleSiteID))
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case let .retrieveCouponSetting(_, onCompletion):
                onCompletion(.success(true))
            case let .enableCouponSetting(_, onCompletion):
                onCompletion(.success(()))
            default:
                break
            }
        }
        stores.whenReceivingAction(ofType: CouponAction.self) { action in
            switch action {
            case let .synchronizeCoupons(_, _, _, _, onCompletion):
                onCompletion(.success(true))
            default:
                break
            }
        }
        sut = CouponListViewModel(siteID: sampleSiteID,
                                  siteURL: sampleSiteURL,
                                  storesManager: stores,
                                  storageManager: mockStorageManager)

        // When
        sut.buildCouponViewModels()
        sut.enableCoupons()

        // Then
        assertEqual(.coupons, sut.state)
    }

    func test_state_is_couponDisabled_if_enableCoupons_fails() {
        // Given
        let sampleSiteID: Int64 = 123
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case let .enableCouponSetting(_, onCompletion):
                let error = NSError(domain: "Test", code: 503, userInfo: nil)
                onCompletion(.failure(error))
            default:
                break
            }
        }
        sut = CouponListViewModel(siteID: sampleSiteID,
                                  siteURL: sampleSiteURL,
                                  storesManager: stores,
                                  storageManager: mockStorageManager)

        // When
        sut.enableCoupons()

        // Then
        assertEqual(.couponsDisabled, sut.state)
    }

    func test_state_is_empty_when_all_coupons_gets_deleted() {
        // Given
        mockStorageManager.insertSampleCoupon(readOnlyCoupon: Coupon.fake().copy(siteID: 123))
        sut = CouponListViewModel(siteID: 123, siteURL: sampleSiteURL, storageManager: mockStorageManager)
        assertEqual(.coupons, sut.state)

        // When
        mockStorageManager.reset()
        sut.buildCouponViewModels()

        // Then
        assertEqual(.empty, sut.state)
    }
}
