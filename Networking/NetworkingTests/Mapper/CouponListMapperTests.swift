import XCTest
@testable import Networking

class CouponListMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 12983476

    /// Verifies that the whole list is parsed.
    ///
    func test_CouponsList_map_parses_all_coupons_in_response() throws {
        let coupons = try mapLoadAllCouponsResponse()
        XCTAssertEqual(coupons.count, 2)
    }

    /// Verifies that the `siteID` is added in the mapper, to all results, because it's not provided by the API endpoint
    ///
    func test_CouponsList_map_includes_siteID_in_parsed_results() throws {
        let coupons = try mapLoadAllCouponsResponse()
        guard coupons.count > 0 else {
            XCTFail("No coupons parsed")
            return
        }

        for coupon in coupons {
            XCTAssertEqual(coupon.siteId, dummySiteID)
        }
    }

    /// Verifies that the fields are all parsed correctly
    ///
    func test_CouponsList_map_parses_all_fields_in_result() throws {
        let coupons = try mapLoadAllCouponsResponse()
        let coupon = coupons[0]

        let dateFormatter = DateFormatter.Defaults.dateTimeFormatter

        XCTAssertEqual(coupon.couponId, 720)
        XCTAssertEqual(coupon.code, "free shipping")
        XCTAssertEqual(coupon.amount, "10.00")
        XCTAssertEqual(coupon.dateCreated, dateFormatter.date(from: "2017-03-21T18:25:02"))
        XCTAssertEqual(coupon.dateModified, dateFormatter.date(from: "2017-03-21T18:25:02"))
        XCTAssertEqual(coupon.discountType, .fixedCart)
        XCTAssertEqual(coupon.description, "Coupon description")
        XCTAssertEqual(coupon.dateExpires, dateFormatter.date(from: "2017-03-31T18:25:02"))
        XCTAssertEqual(coupon.usageCount, 10)
        XCTAssertEqual(coupon.individualUse, true)
        XCTAssertEqual(coupon.productIds, [12893712, 12389])
        XCTAssertEqual(coupon.excludedProductIds, [12213])
        XCTAssertEqual(coupon.usageLimit, 1200)
        XCTAssertEqual(coupon.usageLimitPerUser, 3)
        XCTAssertEqual(coupon.limitUsageToXItems, 10)
        XCTAssertEqual(coupon.freeShipping, true)
        XCTAssertEqual(coupon.productCategories, [123, 435, 232])
        XCTAssertEqual(coupon.excludedProductCategories, [908])
        XCTAssertEqual(coupon.excludeSaleItems, false)
        XCTAssertEqual(coupon.minimumAmount, "5.00")
        XCTAssertEqual(coupon.maximumAmount, "500.00")
        XCTAssertEqual(coupon.emailRestrictions, ["*@a8c.com", "someone.else@example.com"])
        XCTAssertEqual(coupon.usedBy, ["someone.else@example.com", "person@a8c.com"])
    }

}


// MARK: - Test Helpers
///
private extension CouponListMapperTests {

    /// Returns the CouponListMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapCoupons(from filename: String) throws -> [Coupon] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try CouponListMapper(siteID: dummySiteID).map(response: response)
    }

    /// Returns the CouponsMapper output from `coupons-all.json`
    ///
    func mapLoadAllCouponsResponse() throws -> [Coupon] {
        return try mapCoupons(from: "coupons-all")
    }
}
