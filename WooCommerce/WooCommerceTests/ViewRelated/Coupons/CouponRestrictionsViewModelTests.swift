import XCTest
@testable import WooCommerce
@testable import Yosemite

final class CouponRestrictionsViewModelTests: XCTestCase {

    func test_restriction_details_are_correct() {
        // Given
        let coupon = Coupon.fake().copy(individualUse: true,
                                        usageLimit: 1000,
                                        usageLimitPerUser: 1,
                                        limitUsageToXItems: 10,
                                        excludeSaleItems: false,
                                        minimumAmount: "10.00",
                                        maximumAmount: "1000.00",
                                        emailRestrictions: ["*@a8c.com", "vip@mail.com"])
        let viewModel = CouponRestrictionsViewModel(coupon: coupon, currencySettings: CurrencySettings())

        // Then
        XCTAssertEqual(viewModel.minimumSpend, "10.00")
        XCTAssertEqual(viewModel.maximumSpend, "1000.00")
        XCTAssertEqual(viewModel.usageLimitPerCoupon, "1000")
        XCTAssertEqual(viewModel.usageLimitPerUser, "1")
        XCTAssertEqual(viewModel.limitUsageToXItems, "10")
        XCTAssertEqual(viewModel.allowedEmails, "*@a8c.com, vip@mail.com")
        XCTAssertEqual(viewModel.individualUseOnly, true)
        XCTAssertEqual(viewModel.excludeSaleItems, false)
    }

    func test_exclude_products_button_icon_and_title_when_no_product_is_selected() {
        // Given
        let coupon = Coupon.fake()
        let viewModel = CouponRestrictionsViewModel(coupon: coupon)

        // Then
        XCTAssertEqual(viewModel.excludeProductsButtonIcon.pngData(), UIImage.plusImage.pngData())
        XCTAssertEqual(viewModel.excludeProductsTitle, NSLocalizedString("Exclude Products", comment: ""))
    }

    func test_exclude_products_button_icon_and_title_when_some_products_are_selected() {
        // Given
        let coupon = Coupon.fake().copy(excludedProductIds: [123, 2, 56])
        let viewModel = CouponRestrictionsViewModel(coupon: coupon)

        // Then
        XCTAssertEqual(viewModel.excludeProductsButtonIcon.pngData(), UIImage.pencilImage.pngData())
        let expectedTitle = String.localizedStringWithFormat(NSLocalizedString("Exclude Products (%1$d)", comment: ""), 3)
        XCTAssertEqual(viewModel.excludeProductsTitle, expectedTitle)
    }

    func test_exclude_product_categories_button_icon_and_title_when_no_product_is_selected() {
        // Given
        let coupon = Coupon.fake()
        let viewModel = CouponRestrictionsViewModel(coupon: coupon)

        // Then
        XCTAssertEqual(viewModel.excludeCategoriesButtonIcon.pngData(), UIImage.plusImage.pngData())
        XCTAssertEqual(viewModel.excludeCategoriesButtonTitle, NSLocalizedString("Exclude Product Categories", comment: ""))
    }

    func test_exclude_product_categories_button_icon_and_title_when_some_products_are_selected() {
        // Given
        let coupon = Coupon.fake().copy(excludedProductCategories: [44, 6])
        let viewModel = CouponRestrictionsViewModel(coupon: coupon)

        // Then
        XCTAssertEqual(viewModel.excludeCategoriesButtonIcon.pngData(), UIImage.pencilImage.pngData())
        let expectedTitle = String.localizedStringWithFormat(NSLocalizedString("Exclude Product Categories (%1$d)", comment: ""), 2)
        XCTAssertEqual(viewModel.excludeCategoriesButtonTitle, expectedTitle)
    }

    func test_shouldDisplayLimitUsageToXItemsRow_is_false_when_fixed_cart_discount_type_is_set() {
        // Given
        let sampleCoupon = Coupon.fake().copy(discountType: .fixedCart)
        let viewModel = CouponRestrictionsViewModel(coupon: sampleCoupon)

        // Then
        XCTAssertFalse(viewModel.shouldDisplayLimitUsageToXItemsRow)
    }

    func test_shouldDisplayLimitUsageToXItemsRow_is_true_when_fixed_cart_discount_type_is_NOT_set() {
        // Given
        let sampleCoupon = Coupon.fake().copy(discountType: .percent)
        let viewModel = CouponRestrictionsViewModel(coupon: sampleCoupon)

        // Then
        XCTAssertTrue(viewModel.shouldDisplayLimitUsageToXItemsRow)
    }

    func test_shouldDisplayLimitUsageToXItemsRow_is_false_when_discount_type_is_changed_to_fixed_cart() {
        // Given
        let sampleCoupon = Coupon.fake().copy(discountType: .percent)
        let viewModel = CouponRestrictionsViewModel(coupon: sampleCoupon)

        // Then
        XCTAssertTrue(viewModel.shouldDisplayLimitUsageToXItemsRow)

        // When
        viewModel.onDiscountTypeChanged(discountType: .fixedCart)

        // Then
        XCTAssertFalse(viewModel.shouldDisplayLimitUsageToXItemsRow)
    }

    func test_shouldDisplayLimitUsageToXItemsRow_is_true_when_discount_type_is_changed_from_fixed_cart() {
        // Given
        let sampleCoupon = Coupon.fake().copy(discountType: .fixedCart)
        let viewModel = CouponRestrictionsViewModel(coupon: sampleCoupon)

        // Then
        XCTAssertFalse(viewModel.shouldDisplayLimitUsageToXItemsRow)

        // When
        viewModel.onDiscountTypeChanged(discountType: .percent)

        XCTAssertTrue(viewModel.shouldDisplayLimitUsageToXItemsRow)
    }
}
