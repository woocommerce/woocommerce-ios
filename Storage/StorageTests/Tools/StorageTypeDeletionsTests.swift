import XCTest

@testable import Storage

final class StorageTypeDeletionsTests: XCTestCase {

    private let sampleSiteID: Int64 = 98765

    private var storageManager: StorageManagerType!

    private var storage: StorageType! {
        storageManager.viewStorage
    }

    override func setUp() {
        super.setUp()
        storageManager = CoreDataManager(name: "WooCommerce", crashLogger: MockCrashLogger())
    }

    override func tearDown() {
        storageManager.reset()
        storageManager = nil
        super.tearDown()
    }

    func test_deleteCoupon_by_siteID_deletes_all_coupons() throws {
        // Given
        let coupon1 = storage.insertNewObject(ofType: Coupon.self)
        coupon1.siteID = sampleSiteID
        coupon1.couponID = 1

        let coupon2 = storage.insertNewObject(ofType: Coupon.self)
        coupon2.siteID = sampleSiteID
        coupon2.couponID = 2

        // When
        storage.deleteCoupons(siteID: sampleSiteID)

        // Then
        let storedCoupons = try XCTUnwrap(storage.loadAllCoupons(siteID: sampleSiteID))
        XCTAssertEqual(storedCoupons, [])
    }

    func test_deleteCoupon_by_siteID_only_deletes_for_specified_site() throws {
        // Given
        let coupon = storage.insertNewObject(ofType: Coupon.self)
        coupon.siteID = sampleSiteID
        coupon.couponID = 1

        let otherSiteCoupon = storage.insertNewObject(ofType: Coupon.self)
        otherSiteCoupon.siteID = 12345
        otherSiteCoupon.couponID = 2

        // When
        storage.deleteCoupons(siteID: sampleSiteID)

        // Then
        let storedCoupons = try XCTUnwrap(storage.loadAllCoupons(siteID: 12345))
        XCTAssertEqual(storedCoupons, [otherSiteCoupon])
    }

}
