import XCTest
@testable import WooCommerce
import Yosemite

import protocol Storage.StorageManagerType
import protocol Storage.StorageType

final class CouponManagementListViewModelTests: XCTestCase {

    private var mockStorageManager: MockStorageManager!
    private var mockStoresManager: MockStoresManager!
    private var mockSyncingCoordinator: MockSyncingCoordinator!

    private var mockStorage: StorageType {
        mockStorageManager.viewStorage
    }

    override func setUp() {
        super.setUp()
        mockStorageManager = MockStorageManager()
        mockStoresManager = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        mockSyncingCoordinator = MockSyncingCoordinator()
    }

    override func tearDown() {
        mockStorageManager = nil
        mockSyncingCoordinator = nil
        super.tearDown()
    }

    func test_viewDidLoad_calls_synchronizeFirstPage_on_syncCoordinator() {
        // Given
        let sut = CouponManagementListViewModel(siteID: 123,
                                                syncingCoordinator: mockSyncingCoordinator) { _ in }

        // When
        sut.viewDidLoad()

        // Then
        XCTAssertTrue(mockSyncingCoordinator.spyDidCallSynchronizeFirstPage)
    }

    func test_init_starts_loading_state() {
        // Given
        var latestState: CouponListState?
        let sut = CouponManagementListViewModel(siteID: 123) { state in
            latestState = state
        }

        // When
        sut.viewDidLoad()

        // Then
        XCTAssertEqual(latestState, .loading)
    }

    func test_sync_sends_correct_synchronize_coupons_action_to_store() throws {
        // Given
        let sut = CouponManagementListViewModel(siteID: 123,
                                                storesManager: mockStoresManager) { _ in }

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
            XCTFail("Expected action to be .synchronizeCoupons")
        }
    }

    func test_couponStore_calls_completion_handler_with_failure_sets_failed_state() throws {
        // Given
        var latestState: CouponListState?
        let sut = CouponManagementListViewModel(siteID: 123,
                                                storesManager: mockStoresManager) { state in
            latestState = state
        }

        // When
        sut.sync(pageNumber: 4, pageSize: 8, reason: nil, onCompletion: nil)
        let action = try XCTUnwrap(mockStoresManager.receivedActions.last as? CouponAction)
        switch action {
        case let .synchronizeCoupons(_, _, _, completionHandler):
            completionHandler(.failure(NSError(domain: "Sync Error", code: 1, userInfo: nil)))
        default:
            XCTFail("Expected action to be .synchronizeCoupons")
        }
        // Then
            XCTAssertEqual(latestState, .failed)
    }

    func test_updateViewModelState_builds_cell_view_models_when_coupons_present() {
        // Given
        let coupon = Coupon.fake().copy(siteID: 123, code: "coupon")
        mockStorageManager.insertSampleCoupon(readOnlyCoupon: coupon)
        var latestState: CouponListState?
        let sut = CouponManagementListViewModel(siteID: 123,
                                                storageManager: mockStorageManager) { state in
            latestState = state
        }

        // When
        sut.updateViewModelState()

        // Then
        XCTAssertEqual(sut.couponViewModels.count, 1)
        XCTAssertEqual(latestState, .coupons)
    }

    func test_updateViewModelState_shows_empty_when_no_coupons_present() {
        // Given
        var latestState: CouponListState?
        let sut = CouponManagementListViewModel(siteID: 123,
                                                storageManager: mockStorageManager) { state in
            latestState = state
        }

        // When
        sut.updateViewModelState()

        // Then
        XCTAssertEqual(latestState, .empty)
    }

}
