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
        XCTAssertEqual(coupon.siteID, dummySiteID)
    }

    /// Verifies that the fields are all parsed correctly
    ///
    func test_CouponsList_map_parses_all_fields_in_result() throws {
        let coupon = try mapRetrieveCouponResponse()

        let dateFormatter = DateFormatter.Defaults.dateTimeFormatter

        let expectedCoupon = Coupon(
            couponID: 720,
            code: "free shipping",
            amount: "10.00",
            dateCreated: dateFormatter.date(from: "2017-03-21T18:25:02")!,
            dateModified: dateFormatter.date(from: "2017-03-21T18:25:02")!,
            mappedDiscountType: .fixedCart,
            description: "Coupon description",
            dateExpires: dateFormatter.date(from: "2017-03-31T18:25:02"),
            usageCount: 10,
            individualUse: true,
            productIds: [12893712, 12389],
            excludedProductIds: [12213],
            usageLimit: 1200,
            usageLimitPerUser: 3,
            limitUsageToXItems: 10,
            freeShipping: true,
            productCategories: [123, 435, 232],
            excludedProductCategories: [908],
            excludeSaleItems: false,
            minimumAmount: "5.00",
            maximumAmount: "500.00",
            emailRestrictions: ["*@a8c.com", "someone.else@example.com"],
            usedBy: ["someone.else@example.com", "person@a8c.com"]).copy(siteID: self.dummySiteID)

        XCTAssertEqual(coupon, expectedCoupon)
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

    struct FileNotFoundError: Error {}
}
