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

    override func setUp() {
        super.setUp()
        createMocks()
        sut = CouponListViewModel(siteID: 123)
    }

    private func createMocks() {
        mockStorageManager = MockStorageManager()
        mockStoresManager = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        mockSyncingCoordinator = MockSyncingCoordinator()
    }

    private func setUpWithCouponFetched(injectedStores: StoresManager? = nil) {
        let coupon = Coupon.fake().copy(siteID: 123, couponID: 1234, code: "coupon")
        mockStorageManager.insertSampleCoupon(readOnlyCoupon: coupon)
        if let stores = injectedStores {
            sut = CouponListViewModel(siteID: 123,
                                      storesManager: stores,
                                      storageManager: mockStorageManager)
        } else {
            sut = CouponListViewModel(siteID: 123,
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
                                  storesManager: mockStoresManager)
        // When
        sut.sync(pageNumber: 4, pageSize: 8, reason: nil, onCompletion: nil)

        // Then
        let action = try XCTUnwrap(mockStoresManager.receivedActions.last as? CouponAction)
        switch action {
        case let .synchronizeCoupons(siteID, pageNumber, pageSize, _):
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
        sut = CouponListViewModel(siteID: 123, syncingCoordinator: mockSyncingCoordinator)

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
        sut = CouponListViewModel(siteID: 123, syncingCoordinator: mockSyncingCoordinator)

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
        mockStorageManager.insertSampleCoupon(readOnlyCoupon: Coupon.fake().copy(siteID: sampleSiteID, couponID: 1, code: "senth"))
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
            case let .synchronizeCoupons(_, _, _, onCompletion):
                onCompletion(.success(true))
            default:
                break
            }
        }
        sut = CouponListViewModel(siteID: sampleSiteID,
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
                                  storesManager: stores,
                                  storageManager: mockStorageManager)

        // When
        sut.enableCoupons()

        // Then
        assertEqual(.couponsDisabled, sut.state)
    }

    func test_state_is_empty_when_all_coupons_gets_deleted() {
        // Given
        mockStorageManager.insertSampleCoupon(readOnlyCoupon: Coupon.fake().copy(siteID: 123, couponID: 1, code: "riset"))
        sut = CouponListViewModel(siteID: 123, storageManager: mockStorageManager)
        assertEqual(.coupons, sut.state)

        // When
        mockStorageManager.reset()
        sut.buildCouponViewModels()

        // Then
        assertEqual(.empty, sut.state)
    }

    func test_buildCouponViewModels_ignores_coupons_with_zero_id_or_empty_code() {
        // Given
        let validCoupon = Coupon.fake().copy(siteID: 123, couponID: 1, code: "VALID")
        let zeroIdCoupon = Coupon.fake().copy(siteID: 123, couponID: 0, code: "ZERO_ID")
        let emptyCodeCoupon = Coupon.fake().copy(siteID: 123, couponID: 2, code: "")

        mockStorageManager.insertSampleCoupon(readOnlyCoupon: validCoupon)
        mockStorageManager.insertSampleCoupon(readOnlyCoupon: zeroIdCoupon)
        mockStorageManager.insertSampleCoupon(readOnlyCoupon: emptyCodeCoupon)

        sut = CouponListViewModel(siteID: 123, storageManager: mockStorageManager)

        // When
        sut.buildCouponViewModels()

        // Then
        XCTAssertEqual(sut.couponViewModels.count, 1)
        XCTAssertEqual(sut.couponViewModels.first?.id, "\(validCoupon.couponID)")
        XCTAssertEqual(sut.state, .coupons)
    }

    func test_buildCouponViewModels_deduplicates_coupons_with_same_id() {
        // Given
        let firstCoupon = Coupon.fake().copy(siteID: 123, couponID: 10, code: "FIRST")
        let duplicateIdCoupon = Coupon.fake().copy(siteID: 123, couponID: 10, code: "SECOND")

        mockStorageManager.insertSampleCoupon(readOnlyCoupon: firstCoupon)
        mockStorageManager.insertSampleCoupon(readOnlyCoupon: duplicateIdCoupon)

        sut = CouponListViewModel(siteID: 123, storageManager: mockStorageManager)

        // When
        sut.buildCouponViewModels()

        // Then
        XCTAssertEqual(sut.couponViewModels.count, 1)
        XCTAssertEqual(sut.couponViewModels.first?.id, "\(firstCoupon.couponID)")
        XCTAssertEqual(sut.state, .coupons)
    }

    func test_buildCouponViewModels_sets_empty_state_when_all_coupons_filtered_out() {
        // Given
        let invalidCoupon = Coupon.fake().copy(siteID: 123, couponID: 0, code: "")
        mockStorageManager.insertSampleCoupon(readOnlyCoupon: invalidCoupon)

        sut = CouponListViewModel(siteID: 123, storageManager: mockStorageManager)

        // When
        sut.buildCouponViewModels()

        // Then
        XCTAssertTrue(sut.couponViewModels.isEmpty)
        XCTAssertEqual(sut.state, .empty)
    }
}
