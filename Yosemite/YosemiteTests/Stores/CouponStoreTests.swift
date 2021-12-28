import XCTest
@testable import Networking
@testable import Storage
@testable import Yosemite
import Fakes

final class CouponStoreTests: XCTestCase {
    /// Mock network to inject responses
    ///
    private var network: MockNetwork!

    /// Spy remote to check request parameter use
    ///
    private var remote: MockCouponsRemote!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Storage
    ///
    private var storage: StorageType! {
        storageManager.viewStorage
    }

    /// Convenience: returns the StorageType associated with the main thread
    ///
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }

    /// Convenience: returns the number of stored coupons
    ///
    private var storedCouponsCount: Int {
        return viewStorage.countObjects(ofType: StorageCoupon.self)
    }

    /// Store
    ///
    private var store: CouponStore!

    /// SiteID
    ///
    private let sampleSiteID: Int64 = 120934

    /// Default page number
    ///
    private let defaultPageNumber = 1

    /// Default page size
    ///
    private let defaultPageSize = 12

    // MARK: - Set up and Tear down

    override func setUp() {
        super.setUp()
        network = MockNetwork(useResponseQueue: true)
        storageManager = MockStorageManager()
        store = CouponStore(dispatcher: Dispatcher(),
                            storageManager: storageManager,
                            network: network)
    }

    func setUpUsingSpyRemote() {
        network = MockNetwork(useResponseQueue: true)
        remote = MockCouponsRemote()
        storageManager = MockStorageManager()
        store = CouponStore(dispatcher: Dispatcher(),
                            storageManager: storageManager,
                            network: network,
                            remote: remote)
    }

    // MARK: - Tests

    func test_synchronizeCoupons_calls_remote_using_correct_request_parameters() {
        setUpUsingSpyRemote()
        // Given
        let action = CouponAction.synchronizeCoupons(siteID: 1092,
                                                     pageNumber: 12,
                                                     pageSize: 3) { _ in }

        // When
        store.onAction(action)

        // Then
        XCTAssertTrue(remote.didCallLoadAllCoupons)
        XCTAssertEqual(remote.spyLoadAllCouponsSiteID, 1092)
        XCTAssertEqual(remote.spyLoadAllCouponsPageNumber, 12)
        XCTAssertEqual(remote.spyLoadAllCouponsPageSize, 3)
    }

    func test_synchronizeCoupons_returns_network_error_on_failure() {
        setUpUsingSpyRemote()
        // Given
        let expectedError = NetworkError.unacceptableStatusCode(statusCode: 418)
        remote.resultForLoadAllCoupons = .failure(expectedError)

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            let action = CouponAction.synchronizeCoupons(siteID: 1092,
                                                         pageNumber: 12,
                                                         pageSize: 3) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertEqual(result.failure as? NetworkError, expectedError)
    }

    func test_synchronizeCoupons_returns_has_next_page_true_when_number_of_retrieved_results_matches_pagesize() throws {
        setUpUsingSpyRemote()
        // Given
        let coupons = [Networking.Coupon.fake(), Networking.Coupon.fake()]
        remote.resultForLoadAllCoupons = .success(coupons)

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            let action: CouponAction
            action = .synchronizeCoupons(siteID: self.sampleSiteID,
                                         pageNumber: self.defaultPageNumber,
                                         pageSize: 2) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        //Then
        let hasNextPage = try! result.get()
        XCTAssertTrue(hasNextPage)
    }

    func test_synchronizeCoupons_returns_has_next_page_false_when_number_of_retrieved_results_differs_from_pagesize() throws {
        setUpUsingSpyRemote()
        // Given
        let coupons = [Networking.Coupon.fake(), Networking.Coupon.fake()]
        remote.resultForLoadAllCoupons = .success(coupons)

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            let action: CouponAction
            action = .synchronizeCoupons(siteID: self.sampleSiteID,
                                         pageNumber: self.defaultPageNumber,
                                         pageSize: 10) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        //Then
        let hasNextPage = try! result.get()
        XCTAssertFalse(hasNextPage)
    }

    func test_synchronizeCoupons_stores_coupons_upon_success() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "coupons",
                                 filename: "coupons-all")
        XCTAssertEqual(storedCouponsCount, 0)

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            let action: CouponAction
            action = .synchronizeCoupons(siteID: self.sampleSiteID,
                                         pageNumber: self.defaultPageNumber,
                                         pageSize: self.defaultPageSize) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(storedCouponsCount, 3)
    }

    func test_synchronizeCoupons_deletes_coupons_when_first_page_recieved_from_API() {
        // Given
        storeCoupon(Coupon.fake(), for: sampleSiteID)
        network.simulateResponse(requestUrlSuffix: "coupons",
                                 filename: "coupons-all")
        XCTAssertEqual(storedCouponsCount, 1)

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            let action: CouponAction
            action = .synchronizeCoupons(siteID: self.sampleSiteID,
                                         pageNumber: 1,
                                         pageSize: self.defaultPageSize) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(storedCouponsCount, 3)
    }

    func test_synchronizeCoupons_does_not_delete_coupons_when_subsequent_pages_recieved_from_API() {
        // Given
        storeCoupon(Coupon.fake(), for: sampleSiteID)
        network.simulateResponse(requestUrlSuffix: "coupons",
                                 filename: "coupons-all")
        XCTAssertEqual(storedCouponsCount, 1)

        // When
        let result: Result<Bool, Error> = waitFor { promise in
            let action: CouponAction
            action = .synchronizeCoupons(siteID: self.sampleSiteID,
                                         pageNumber: 2,
                                         pageSize: self.defaultPageSize) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(storedCouponsCount, 4)
    }
}

private extension CouponStoreTests {
    @discardableResult
    func storeCoupon(_ coupon: Networking.Coupon, for siteID: Int64) -> Storage.Coupon {
        let storedCoupon = storage.insertNewObject(ofType: Coupon.self)
        storedCoupon.update(with: coupon)
        storedCoupon.siteID = siteID
        return storedCoupon
    }
}
