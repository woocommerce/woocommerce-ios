import XCTest
@testable import Networking

class CouponListMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 12983476

    /// Verifies that the whole list is parsed, minus the items with non-default discount type.
    ///
    func test_CouponsList_map_parses_all_coupons_in_response() throws {
        let coupons = try mapLoadAllCouponsResponse()
        XCTAssertEqual(coupons.count, 4)
    }

    /// Verifies that the `siteID` is added in the mapper, to all results, because it's not provided by the API endpoint
    ///
    func test_CouponsList_map_includes_siteID_in_parsed_results() throws {
        let coupons = try mapLoadAllCouponsResponse()
        XCTAssertTrue(coupons.count > 0)

        for coupon in coupons {
            XCTAssertEqual(coupon.siteID, dummySiteID)
        }
    }

    /// Verifies that the fields are all parsed correctly
    ///
    func test_CouponsList_map_parses_all_fields_in_result() throws {
        let coupons = try mapLoadAllCouponsResponse()
        let coupon = coupons[0]

        let dateFormatter = DateFormatter.Defaults.dateTimeFormatter
        let expectedCoupon = Coupon(
            couponID: 720,
            code: "free shipping",
            amount: "10.00",
            dateCreated: dateFormatter.date(from: "2017-03-21T18:25:02")!,
            dateModified: dateFormatter.date(from: "2017-03-21T18:25:02")!,
            discountType: .fixedCart,
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

    /// Verifies that nulls in optional fields are parsed correctly
    ///
    func test_CouponsList_map_accepts_nulls_in_expected_optional_fields() throws {
        let coupons = try mapLoadAllCouponsResponse()
        let coupon = coupons[2]

        let dateFormatter = DateFormatter.Defaults.dateTimeFormatter
        let expectedCoupon = Coupon(
            couponID: 10714,
            code: "test",
            amount: "0.00",
            dateCreated: dateFormatter.date(from: "2021-04-13T08:26:25")!,
            dateModified: dateFormatter.date(from: "2021-04-13T08:26:25")!,
            discountType: .percent,
            description: "",
            dateExpires: nil,
            usageCount: 0,
            individualUse: false,
            productIds: [],
            excludedProductIds: [],
            usageLimit: nil,
            usageLimitPerUser: nil,
            limitUsageToXItems: nil,
            freeShipping: false,
            productCategories: [],
            excludedProductCategories: [],
            excludeSaleItems: false,
            minimumAmount: "0.00",
            maximumAmount: "0.00",
            emailRestrictions: [],
            usedBy: []).copy(siteID: self.dummySiteID)

        XCTAssertEqual(coupon, expectedCoupon)
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
