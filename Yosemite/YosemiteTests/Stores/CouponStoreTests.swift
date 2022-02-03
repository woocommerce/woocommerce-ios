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

    /// Convenience: returns the number of stored search results
    ///
    private var storedSearchResultsCount: Int {
        return viewStorage.countObjects(ofType: StorageCouponSearchResult.self)
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
        XCTAssertEqual(storedCouponsCount, 4)
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
        XCTAssertEqual(storedCouponsCount, 4)
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
        XCTAssertEqual(storedCouponsCount, 5)
    }

    func test_deleteCoupon_calls_remote_using_correct_request_parameters() {
        setUpUsingSpyRemote()
        // Given
        let action = CouponAction.deleteCoupon(siteID: sampleSiteID, couponID: 10) { _ in }

        // When
        store.onAction(action)

        // Then
        XCTAssertTrue(remote.didCallDeleteCoupon)
        XCTAssertEqual(remote.spyDeleteCouponSiteID, sampleSiteID)
        XCTAssertEqual(remote.spyDeleteCouponWithID, 10)
    }

    func test_deleteCoupon_returns_network_error_on_failure() {
        // Given
        let sampleCouponID: Int64 = 720 // match with the one in the coupon.json file
        let sampleCoupon = Coupon.fake().copy(siteID: sampleSiteID, couponID: sampleCouponID)
        storeCoupon(sampleCoupon, for: sampleSiteID)
        XCTAssertEqual(storedCouponsCount, 1)

        let expectedError = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: "coupons/\(sampleCouponID)", error: expectedError)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = CouponAction.deleteCoupon(siteID: self.sampleSiteID, couponID: sampleCouponID) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertEqual(result.failure as? NetworkError, expectedError)
        XCTAssertEqual(storedCouponsCount, 1)
    }

    func test_deleteCoupon_deletes_coupon_upon_success() throws {
        // Given
        let sampleCouponID: Int64 = 720
        let sampleCoupon = Coupon.fake().copy(siteID: sampleSiteID, couponID: sampleCouponID)
        storeCoupon(sampleCoupon, for: sampleSiteID)
        XCTAssertEqual(storedCouponsCount, 1)

        network.simulateResponse(requestUrlSuffix: "coupons/\(sampleCouponID)", filename: "coupon")

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action: CouponAction
            action = .deleteCoupon(siteID: self.sampleSiteID, couponID: sampleCouponID) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(storedCouponsCount, 0)
    }

    func test_updateCoupon_calls_remote_using_correct_request_parameters() {
        setUpUsingSpyRemote()
        // Given
        let sampleCouponID: Int64 = 720
        let coupon = Coupon.fake().copy(siteID: sampleSiteID, couponID: sampleCouponID, amount: "10", discountType: .percent)
        let action = CouponAction.updateCoupon(coupon) { _ in }

        // When
        store.onAction(action)

        // Then
        XCTAssertTrue(remote.didCallUpdateCoupon)
        XCTAssertEqual(remote.spyUpdateCoupon, coupon)
    }

    func test_updateCoupon_returns_network_error_on_failure() {
        // Given
        let sampleCouponID: Int64 = 720
        let sampleCoupon = Coupon.fake().copy(siteID: sampleSiteID, couponID: sampleCouponID, amount: "10")
        storeCoupon(sampleCoupon, for: sampleSiteID)
        XCTAssertEqual(storedCouponsCount, 1)

        let expectedError = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: "coupons/\(sampleCouponID)", error: expectedError)

        // When
        let updatedCoupon = sampleCoupon.copy(amount: "9")
        let result: Result<Networking.Coupon, Error> = waitFor { promise in
            let action = CouponAction.updateCoupon(updatedCoupon) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertEqual(result.failure as? NetworkError, expectedError)
        XCTAssertEqual(storedCouponsCount, 1)
        XCTAssertEqual(viewStorage.loadCoupon(siteID: sampleSiteID, couponID: sampleCouponID)?.amount, "10")
    }

    func test_updateCoupon_updates_stored_coupon_upon_success() throws {
        // Given
        let sampleCouponID: Int64 = 720
        let sampleCoupon = Coupon.fake().copy(siteID: sampleSiteID, couponID: sampleCouponID, amount: "11", discountType: .percent)
        storeCoupon(sampleCoupon, for: sampleSiteID)
        XCTAssertEqual(storedCouponsCount, 1)

        network.simulateResponse(requestUrlSuffix: "coupons/\(sampleCouponID)", filename: "coupon")

        // When
        // this is not really important because we'll test the parsed coupon from the json file
        let updatedCoupon = sampleCoupon.copy(amount: "10.00", discountType: .fixedCart)
        let result: Result<Networking.Coupon, Error> = waitFor { promise in
            let action: CouponAction
            action = .updateCoupon(updatedCoupon) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let storedCoupon = viewStorage.loadCoupon(siteID: sampleSiteID, couponID: sampleCouponID)
        XCTAssertNotNil(storedCoupon)
        XCTAssertEqual(storedCoupon?.amount, "10.00")
        XCTAssertEqual(storedCoupon?.discountType, Coupon.DiscountType.fixedCart.rawValue)
    }

    func test_createCoupon_calls_remote_using_correct_request_parameters() {
        setUpUsingSpyRemote()
        // Given
        let sampleCouponID: Int64 = 720
        let coupon = Coupon.fake().copy(siteID: sampleSiteID, couponID: sampleCouponID, amount: "10", discountType: .percent)
        let action = CouponAction.createCoupon(coupon) { _ in }

        // When
        store.onAction(action)

        // Then
        XCTAssertTrue(remote.didCallCreateCoupon)
        XCTAssertEqual(remote.spyCreateCoupon, coupon)
    }

    func test_createCoupon_returns_network_error_on_failure() {
        // Given
        let sampleCouponID: Int64 = 720
        let sampleCoupon = Coupon.fake().copy(siteID: sampleSiteID, couponID: sampleCouponID, amount: "10.00")

        let expectedError = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: "coupons", error: expectedError)

        // When
        let result: Result<Networking.Coupon, Error> = waitFor { promise in
            let action = CouponAction.createCoupon(sampleCoupon) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertEqual(result.failure as? NetworkError, expectedError)
        XCTAssertEqual(storedCouponsCount, 0)
    }

    func test_createCoupon_insert_stored_coupon_upon_success() throws {
        // Given
        let sampleCouponID: Int64 = 720
        // this is not really important because we'll test the parsed coupon from the json file
        let sampleCoupon = Coupon.fake().copy(siteID: sampleSiteID, couponID: sampleCouponID, amount: "10.00", discountType: .percent)

        network.simulateResponse(requestUrlSuffix: "coupons", filename: "coupon")

        // When
        let result: Result<Networking.Coupon, Error> = waitFor { promise in
            let action: CouponAction
            action = .createCoupon(sampleCoupon) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let storedCoupon = viewStorage.loadCoupon(siteID: sampleSiteID, couponID: sampleCouponID)
        XCTAssertNotNil(storedCoupon)
        XCTAssertEqual(storedCoupon?.amount, "10.00")
        XCTAssertEqual(storedCoupon?.discountType, Coupon.DiscountType.fixedCart.rawValue)
    }

    func test_loadCouponReport_calls_remote_using_correct_request_parameters() {
        setUpUsingSpyRemote()
        // Given
        let sampleCouponID: Int64 = 571
        let action = CouponAction.loadCouponReport(siteID: sampleSiteID, couponID: sampleCouponID) { _ in }

        // When
        store.onAction(action)

        // Then
        XCTAssertTrue(remote.didCallLoadCouponReport)
        XCTAssertEqual(remote.spyLoadCouponReportSiteID, sampleSiteID)
        XCTAssertEqual(remote.spyLoadCouponReportCouponID, sampleCouponID)
    }

    func test_loadCouponReport_returns_network_error_on_failure() {
        // Given
        let sampleCouponID: Int64 = 571

        let expectedError = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: "coupons", error: expectedError)

        // When
        let result: Result<Networking.CouponReport, Error> = waitFor { promise in
            let action = CouponAction.loadCouponReport(siteID: self.sampleSiteID, couponID: sampleCouponID) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertEqual(result.failure as? NetworkError, expectedError)
    }

    func test_loadCouponReport_returns_expected_details_upon_success() throws {
        // Given
        let sampleCouponID: Int64 = 571
        let expectedReport = CouponReport(couponID: sampleCouponID, amount: 12, ordersCount: 1)
        network.simulateResponse(requestUrlSuffix: "reports/coupons", filename: "coupon-reports")

        // When
        let result: Result<Networking.CouponReport, Error> = waitFor { promise in
            let action = CouponAction.loadCouponReport(siteID: self.sampleSiteID, couponID: sampleCouponID) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(try result.get(), expectedReport)
    }

    func test_searchCoupons_calls_remote_using_correct_request_parameters() {
        setUpUsingSpyRemote()
        // Given
        let expectedKeyword = "Test keyword"
        let expectedPageNumber = 1
        let expectedPageSize = 20
        let action = CouponAction.searchCoupons(siteID: sampleSiteID,
                                                keyword: expectedKeyword,
                                                pageNumber: expectedPageNumber,
                                                pageSize: expectedPageSize) { _ in }

        // When
        store.onAction(action)

        // Then
        XCTAssertTrue(remote.didCallSearchCoupons)
        XCTAssertEqual(remote.spySearchCouponsSiteID, sampleSiteID)
        XCTAssertEqual(remote.spySearchCouponsKeyword, expectedKeyword)
        XCTAssertEqual(remote.spySearchCouponsPageNumber, expectedPageNumber)
        XCTAssertEqual(remote.spySearchCouponsPageSize, expectedPageSize)
    }

    func test_searchCoupons_returns_network_error_on_failure() {
        // Given
        let expectedError = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: "coupons", error: expectedError)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = CouponAction.searchCoupons(siteID: self.sampleSiteID, keyword: "test keyword", pageNumber: 1, pageSize: 20) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertEqual(result.failure as? NetworkError, expectedError)
    }

    func test_searchCoupons_upserts_coupons_and_search_results_upon_successful_search() throws {
        // Given
        let sampleCouponID: Int64 = 720
        let sampleCoupon = Coupon.fake().copy(siteID: sampleSiteID, couponID: sampleCouponID, amount: "12.00")
        storeCoupon(sampleCoupon, for: sampleSiteID)
        network.simulateResponse(requestUrlSuffix: "coupons", filename: "coupons-all")

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = CouponAction.searchCoupons(siteID: self.sampleSiteID, keyword: "test keyword", pageNumber: 1, pageSize: 20) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(storedCouponsCount, 4)
        XCTAssertEqual(storedSearchResultsCount, 1)
        let storedCoupon = viewStorage.loadCoupon(siteID: sampleSiteID, couponID: sampleCouponID)
        XCTAssertNotNil(storedCoupon)
        XCTAssertEqual(storedCoupon?.amount, "10.00") // Updated amount reflecting the response.
    }

    func test_retrieveCoupon_calls_remote_using_correct_request_parameters() {
        setUpUsingSpyRemote()
        // Given
        let sampleCouponID: Int64 = 134
        let action = CouponAction.retrieveCoupon(siteID: sampleSiteID, couponID: sampleCouponID) { _ in }

        // When
        store.onAction(action)

        // Then
        XCTAssertTrue(remote.didCallRetrieveCoupon)
        XCTAssertEqual(remote.spyRetrieveSiteID, sampleSiteID)
        XCTAssertEqual(remote.spyRetrieveCouponID, sampleCouponID)
    }

    func test_retrieveCoupon_returns_network_error_on_failure() {
        // Given
        let sampleCouponID: Int64 = 720
        let expectedError = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: "coupons/\(sampleCouponID)", error: expectedError)

        // When
        let result: Result<Networking.Coupon, Error> = waitFor { promise in
            let action = CouponAction.retrieveCoupon(siteID: self.sampleSiteID, couponID: sampleCouponID) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertEqual(result.failure as? NetworkError, expectedError)
    }

    func test_retrieveCoupon_upserts_the_returned_coupon() throws {
        // Given
        let sampleCouponID: Int64 = 720
        let sampleCoupon = Coupon.fake().copy(siteID: sampleSiteID, couponID: sampleCouponID, amount: "12.00")
        storeCoupon(sampleCoupon, for: sampleSiteID)
        network.simulateResponse(requestUrlSuffix: "coupons/\(sampleCouponID)", filename: "coupon")

        // When
        let result: Result<Networking.Coupon, Error> = waitFor { promise in
            let action = CouponAction.retrieveCoupon(siteID: self.sampleSiteID, couponID: sampleCouponID) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let storedCoupon = viewStorage.loadCoupon(siteID: sampleSiteID, couponID: sampleCouponID)
        XCTAssertNotNil(storedCoupon)
        XCTAssertEqual(storedCoupon?.amount, "10.00") // Updated amount reflecting the response.
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
