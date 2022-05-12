import XCTest
@testable import Networking
@testable import WooCommerce

final class CouponWooTests: XCTestCase {
    func test_expiry_status_is_active_if_dateExpires_is_undefined() {
        // Given
        let coupon = Coupon.fake().copy(dateExpires: nil)

        // Then
        XCTAssertEqual(coupon.expiryStatus(), .active)
    }

    func test_expiry_status_is_active_if_dateExpires_is_later_than_current_date() {
        // Given
        // GMT: Monday, February 21, 2022 5:00:00 PM
        let expiryDate = Date(timeIntervalSince1970: 1645462800)
        // GMT: Monday, February 21, 2022 11:01:36 AM
        let now = Date(timeIntervalSince1970: 1645441296)
        let coupon = Coupon.fake().copy(dateExpires: expiryDate)

        // Then
        XCTAssertEqual(coupon.expiryStatus(now: now), .active)
    }

    func test_expiry_status_is_expired_if_dateExpires_is_earlier_than_current_date() {
        // Given
        // GMT: Thursday, August 15, 2019 6:14:35 PM
        let expiryDate = Date(timeIntervalSince1970: 1565892875)
        // GMT: Friday, January 21, 2022 9:03:45 AM
        let now = Date(timeIntervalSince1970: 1642755825)
        let coupon = Coupon.fake().copy(dateExpires: expiryDate)

        // Then
        XCTAssertEqual(coupon.expiryStatus(now: now), .expired)
    }

    func test_summary_returns_correct_amount_fixedProduct_discount_type() {
        // Given
        let sampleCoupon = Coupon.fake().copy(
            amount: "10.00",
            discountType: .fixedProduct
        )
        let currencySettings = CurrencySettings()

        // Then
        XCTAssertTrue(sampleCoupon.summary(currencySettings: currencySettings).contains("$10.00"))
    }

    func test_summary_returns_correct_amount_percentage_discount_type() {
        // Given
        let sampleCoupon = Coupon.fake().copy(
            amount: "10.00",
            discountType: .percent
        )

        // Then
        XCTAssertTrue(sampleCoupon.summary().contains("10%"))
    }

    func test_summary_returns_correct_amount_percentage_discount_type_with_comma_as_decimal_separator_in_currency_settings() {
        // Given
        let sampleCoupon = Coupon.fake().copy(
            amount: "10.29",
            discountType: .percent
        )
        let currencySettings = CurrencySettings(currencyCode: .USD,
                                                currencyPosition: .left,
                                                thousandSeparator: ".",
                                                decimalSeparator: ",",
                                                numberOfDecimals: 2)

        // Then
        XCTAssertTrue(sampleCoupon.summary(currencySettings: currencySettings).contains("10,29%"))
    }

    func test_coupon_apply_rule_with_no_limit() {
        // Given
        let sampleCoupon = Coupon.fake().copy(productIds: [], excludedProductIds: [], productCategories: [], excludedProductCategories: [])

        // Then
        XCTAssertTrue(sampleCoupon.summary().contains(NSLocalizedString("All Products", comment: "")))
    }

    func test_coupon_apply_rule_with_one_productId() {
        // Given
        let sampleCoupon = Coupon.fake().copy(productIds: [12], excludedProductIds: [], productCategories: [], excludedProductCategories: [])

        // Then
        let appliedTo = String(format: NSLocalizedString("%d Product", comment: ""), 1)
        XCTAssertTrue(sampleCoupon.summary().contains(appliedTo))
    }

    func test_coupon_apply_rule_with_multiple_productIds() {
        // Given
        let sampleCoupon = Coupon.fake().copy(productIds: [12, 23, 45], excludedProductIds: [], productCategories: [], excludedProductCategories: [])

        // Then
        let appliedTo = String(format: NSLocalizedString("%d Products", comment: ""), 3)
        XCTAssertTrue(sampleCoupon.summary().contains(appliedTo))
    }

    func test_coupon_apply_rule_with_multiple_productIds_and_categories() {
        // Given
        let sampleCoupon = Coupon.fake().copy(productIds: [12, 23, 45], excludedProductIds: [], productCategories: [22, 33], excludedProductCategories: [])

        // Then
        let appliedTo = String(format: NSLocalizedString("%d Products, %d Categories", comment: ""), 3, 2)
        XCTAssertTrue(sampleCoupon.summary().contains(appliedTo))
    }

    func test_coupon_apply_rule_with_productIds_and_excluded_categories() {
        // Given
        let sampleCoupon = Coupon.fake().copy(productIds: [12, 23, 45], excludedProductIds: [], productCategories: [], excludedProductCategories: [11])

        // Then
        let appliedTo = String(format: NSLocalizedString("%d Products excl. %d Category", comment: ""), 3, 1)
        XCTAssertTrue(sampleCoupon.summary().contains(appliedTo))
    }

    func test_coupon_apply_rule_with_categories_and_excluded_products() {
        // Given
        let sampleCoupon = Coupon.fake().copy(productIds: [], excludedProductIds: [11, 22], productCategories: [1, 2, 3], excludedProductCategories: [])

        // Then
        let appliedTo = String(format: NSLocalizedString("%d Categories excl. %d Products", comment: ""), 3, 2)
        XCTAssertTrue(sampleCoupon.summary().contains(appliedTo))
    }

    func test_coupon_apply_rule_with_excluded_products() {
        // Given
        let sampleCoupon = Coupon.fake().copy(productIds: [], excludedProductIds: [11, 22], productCategories: [], excludedProductCategories: [])

        // Then
        let appliedTo = String(format: NSLocalizedString("All Products excl. %d Products", comment: ""), 2)
        XCTAssertTrue(sampleCoupon.summary().contains(appliedTo))
    }

    func test_coupon_apply_rule_with_excluded_categories() {
        // Given
        let sampleCoupon = Coupon.fake().copy(productIds: [], excludedProductIds: [], productCategories: [], excludedProductCategories: [11, 22])

        // Then
        let appliedTo = String(format: NSLocalizedString("All Products excl. %d Categories", comment: ""), 2)
        XCTAssertTrue(sampleCoupon.summary().contains(appliedTo))
    }
}
