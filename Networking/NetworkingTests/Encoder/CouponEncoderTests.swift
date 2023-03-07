import XCTest
@testable import Networking

final class CouponEncoderTests: XCTestCase {

    func test_coupon_encoder_encodes_necessary_fields_correctly() throws {
        // Given
        let dateFormatter = DateFormatter.Defaults.dateTimeFormatter
        let coupon = Coupon(
            couponID: 720,
            code: "free shipping",
            amount: "10.00",
            dateCreated: dateFormatter.date(from: "2017-03-21T18:25:02")!,
            dateModified: dateFormatter.date(from: "2017-03-21T18:25:02")!,
            discountType: .fixedCart,
            description: "Coupon description",
            dateExpires: dateFormatter.date(from: "2017-03-31T15:25:02"),
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
            usedBy: ["someone.else@example.com", "person@a8c.com"]
        )

        // When
        let parameters = try coupon.toDictionary(keyEncodingStrategy: .convertToSnakeCase, dateFormatter: dateFormatter)

        // Then
        XCTAssertEqual(parameters["code"] as? String, "free shipping")
        XCTAssertEqual(parameters["amount"] as? String, "10.00")
        XCTAssertEqual(parameters["discount_type"] as? String, "fixed_cart")
        XCTAssertEqual(parameters["description"] as? String, "Coupon description")
        XCTAssertEqual(parameters["date_expires"] as? String, "2017-03-31T15:25:02")
        XCTAssertEqual(parameters["individual_use"] as? Bool, true)
        XCTAssertEqual(parameters["product_ids"] as? [Int], [12893712, 12389])
        XCTAssertEqual(parameters["excluded_product_ids"] as? [Int], [12213])
        XCTAssertEqual(parameters["usage_limit"] as? Int, 1200)
        XCTAssertEqual(parameters["usage_limit_per_user"] as? Int, 3)
        XCTAssertEqual(parameters["limit_usage_to_x_items"] as? Int, 10)
        XCTAssertEqual(parameters["free_shipping"] as? Bool, true)
        XCTAssertEqual(parameters["product_categories"] as? [Int], [123, 435, 232])
        XCTAssertEqual(parameters["excluded_product_categories"] as? [Int], [908])
        XCTAssertEqual(parameters["exclude_sale_items"] as? Bool, false)
        XCTAssertEqual(parameters["minimum_amount"] as? String, "5.00")
        XCTAssertEqual(parameters["maximum_amount"] as? String, "500.00")
        XCTAssertEqual(parameters["email_restrictions"] as? [String], ["*@a8c.com", "someone.else@example.com"])

        // These fields cannot be updated so they are not encoded
        XCTAssertNil(parameters["coupon_id"])
        XCTAssertNil(parameters["date_created"])
        XCTAssertNil(parameters["date_modified"])
        XCTAssertNil(parameters["usage_count"])
        XCTAssertNil(parameters["used_by"])
    }
}
