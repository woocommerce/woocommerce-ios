import XCTest
@testable import Networking

final class CouponMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    fileprivate let dummySiteID: Int64 = 12983476

    /// Verifies that the coupon is parsed.
    ///
    func test_Coupon_map_parses_all_coupons_in_response() throws {
        let coupon = try mapRetrieveCouponResponse()
        XCTAssertNotNil(coupon)
    }

    /// Verifies that the `siteID` is added in the mapper, because it's not provided by the API endpoint
    ///
    func test_CouponsList_map_includes_siteID_in_parsed_results() throws {
        let coupon = try mapRetrieveCouponResponse()

        XCTAssertEqual(coupon.siteId, dummySiteID)
    }

    /// Verifies that the fields are all parsed correctly
    ///
    func test_CouponsList_map_parses_all_fields_in_result() throws {
        let coupon = try mapRetrieveCouponResponse()

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

    /// Verifies that nulls in optional fields are parsed correctly
    ///
    func test_CouponsList_map_accepts_nulls_in_expected_optional_fields() throws {
        let coupon = try mapRetrieveMinimalCouponResponse()

        let dateFormatter = DateFormatter.Defaults.dateTimeFormatter

        XCTAssertEqual(coupon.couponId, 10714)
        XCTAssertEqual(coupon.code, "test")
        XCTAssertEqual(coupon.amount, "0.00")
        XCTAssertEqual(coupon.dateCreated, dateFormatter.date(from: "2021-04-13T08:26:25"))
        XCTAssertEqual(coupon.dateModified, dateFormatter.date(from: "2021-04-13T08:26:25"))
        XCTAssertEqual(coupon.discountType, .fixedCart)
        XCTAssertEqual(coupon.description, "")
        XCTAssertEqual(coupon.dateExpires, nil)
        XCTAssertEqual(coupon.usageCount, 0)
        XCTAssertEqual(coupon.individualUse, false)
        XCTAssertEqual(coupon.productIds, [])
        XCTAssertEqual(coupon.excludedProductIds, [])
        XCTAssertEqual(coupon.usageLimit, nil)
        XCTAssertEqual(coupon.usageLimitPerUser, nil)
        XCTAssertEqual(coupon.limitUsageToXItems, nil)
        XCTAssertEqual(coupon.freeShipping, false)
        XCTAssertEqual(coupon.productCategories, [])
        XCTAssertEqual(coupon.excludedProductCategories, [])
        XCTAssertEqual(coupon.excludeSaleItems, false)
        XCTAssertEqual(coupon.minimumAmount, "0.00")
        XCTAssertEqual(coupon.maximumAmount, "0.00")
        XCTAssertEqual(coupon.emailRestrictions, [])
        XCTAssertEqual(coupon.usedBy, [])
    }
}


// MARK: - Test Helpers
///
private extension CouponMapperTests {

    /// Returns the CouponMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapCoupon(from filename: String) throws -> Coupon {
        guard let response = Loader.contentsOf(filename) else {
            throw FileNotFoundError()
        }

        return try CouponMapper(siteID: dummySiteID).map(response: response)
    }

    /// Returns the CouponMapper output from `coupon.json`
    ///
    func mapRetrieveCouponResponse() throws -> Coupon {
        return try mapCoupon(from: "coupon")
    }

    /// Returns the CouponMapper output from `coupon-minimal.json`
    ///
    func mapRetrieveMinimalCouponResponse() throws -> Coupon {
        return try mapCoupon(from: "coupon-minimal")
    }

    struct FileNotFoundError: Error {}
}
