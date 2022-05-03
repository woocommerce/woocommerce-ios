import XCTest
@testable import Yosemite
@testable import WooCommerce

final class AddEditCouponViewModelTests: XCTestCase {

    func test_titleView_property_return_expected_values_on_creation_depending_on_discountType() {
        let viewModel1 = AddEditCouponViewModel(siteID: 123, discountType: .percent)
        XCTAssertEqual(viewModel1.title, Localization.titleCreatePercentageDiscount)

        let viewModel2 = AddEditCouponViewModel(siteID: 123, discountType: .fixedCart)
        XCTAssertEqual(viewModel2.title, Localization.titleCreateFixedCartDiscount)

        let viewModel3 = AddEditCouponViewModel(siteID: 123, discountType: .fixedProduct)
        XCTAssertEqual(viewModel3.title, Localization.titleCreateFixedProductDiscount)

        let viewModel4 = AddEditCouponViewModel(siteID: 123, discountType: .other)
        XCTAssertEqual(viewModel4.title, Localization.titleCreateGenericDiscount)
    }

    func test_titleView_property_return_expected_values_on_editing_depending_on_discountType() {
        let viewModel1 = AddEditCouponViewModel(existingCoupon: Coupon.sampleCoupon.copy(discountType: .percent))
        XCTAssertEqual(viewModel1.title, Localization.titleEditPercentageDiscount)

        let viewModel2 = AddEditCouponViewModel(existingCoupon: Coupon.sampleCoupon.copy(discountType: .fixedCart))
        XCTAssertEqual(viewModel2.title, Localization.titleEditFixedCartDiscount)

        let viewModel3 = AddEditCouponViewModel(existingCoupon: Coupon.sampleCoupon.copy(discountType: .fixedProduct))
        XCTAssertEqual(viewModel3.title, Localization.titleEditFixedProductDiscount)

        let viewModel4 = AddEditCouponViewModel(existingCoupon: Coupon.sampleCoupon.copy(discountType: .other))
        XCTAssertEqual(viewModel4.title, Localization.titleEditGenericDiscount)
    }

    func test_generateRandomCouponCode_populate_correctly_the_codeField() {
        // Given
        let viewModel = AddEditCouponViewModel(existingCoupon: Coupon.sampleCoupon.copy(code: ""))
        XCTAssertEqual(viewModel.codeField, "")

        // When
        viewModel.generateRandomCouponCode()

        // Then
        let dictionary = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"
        XCTAssertEqual(viewModel.codeField.count, 8)
        XCTAssertTrue(viewModel.codeField.allSatisfy(dictionary.contains))

    }

    func test_populatedCoupon_return_expected_coupon_during_editing() {
        // Given
        let viewModel = AddEditCouponViewModel(existingCoupon: Coupon.sampleCoupon.copy(discountType: .percent))
        XCTAssertEqual(viewModel.populatedCoupon, Coupon.sampleCoupon.copy(discountType: .percent))

        // When
        viewModel.amountField = "24.23"
        viewModel.codeField = "TEST"
        viewModel.descriptionField = "This is a test description"
        viewModel.expiryDateField = Date().endOfDay(timezone: TimeZone.current)
        viewModel.freeShipping = true
        viewModel.couponRestrictionsViewModel.minimumSpend = "10"
        viewModel.couponRestrictionsViewModel.maximumSpend = "50"
        viewModel.couponRestrictionsViewModel.usageLimitPerCoupon = "40"
        viewModel.couponRestrictionsViewModel.usageLimitPerUser = "1"
        viewModel.couponRestrictionsViewModel.limitUsageToXItems = "10"
        viewModel.couponRestrictionsViewModel.allowedEmails = "*@gmail.com, *@wordpress.com"
        viewModel.couponRestrictionsViewModel.individualUseOnly = true
        viewModel.couponRestrictionsViewModel.excludeSaleItems = true


        // Then
        XCTAssertEqual(viewModel.populatedCoupon, Coupon.sampleCoupon.copy(code: "TEST",
                                                                           amount: "24.23",
                                                                           discountType: .percent,
                                                                           description: "This is a test description",
                                                                           dateExpires: Date().startOfDay(timezone: TimeZone.current),
                                                                           individualUse: true,
                                                                           usageLimit: 40,
                                                                           usageLimitPerUser: 1,
                                                                           limitUsageToXItems: 10,
                                                                           freeShipping: true,
                                                                           excludeSaleItems: true,
                                                                           minimumAmount: "10",
                                                                           maximumAmount: "50",
                                                                           emailRestrictions: ["*@gmail.com", "*@wordpress.com"]))
    }

    func test_populatedCoupon_return_expected_coupon_during_creation() {
        //TODO: implement this test method in the implementation of coupon creation (M3)
    }

    func test_validateCouponLocally_return_expected_error_if_coupon_code_is_empty() {
        // Given
        let coupon = Coupon.sampleCoupon.copy(code: "")
        let viewModel = AddEditCouponViewModel(existingCoupon: coupon)

        // When
        let result = viewModel.validateCouponLocally(coupon)

        // Then
        XCTAssertEqual(result, AddEditCouponViewModel.CouponError.couponCodeEmpty)
    }

    func test_validateCouponLocally_return_nil_if_coupon_code_is_not_empty() {
        // Given
        let coupon = Coupon.sampleCoupon.copy(code: "ABCDEF")
        let viewModel = AddEditCouponViewModel(existingCoupon: coupon)

        // When
        let result = viewModel.validateCouponLocally(coupon)

        // Then
        XCTAssertNil(result)
    }

    private enum Localization {
        static let titleCreatePercentageDiscount = NSLocalizedString(
            "Create percentage discount",
            comment: "Title of the view for creating a coupon with percentage discount.")
        static let titleCreateFixedCartDiscount = NSLocalizedString(
            "Create fixed cart discount",
            comment: "Title of the view for creating a coupon with fixed cart discount.")
        static let titleCreateFixedProductDiscount = NSLocalizedString(
            "Create fixed product discount",
            comment: "Title of the view for creating a coupon with fixed product discount.")
        static let titleCreateGenericDiscount = NSLocalizedString(
            "Create discount",
            comment: "Title of the view for creating a coupon with generic discount.")
        static let titleEditPercentageDiscount = NSLocalizedString(
            "Edit percentage discount",
            comment: "Title of the view for editing a coupon with percentage discount.")
        static let titleEditFixedCartDiscount = NSLocalizedString(
            "Edit fixed cart discount",
            comment: "Title of the view for editing a coupon with fixed cart discount.")
        static let titleEditFixedProductDiscount = NSLocalizedString(
            "Edit fixed product discount",
            comment: "Title of the view for editing a coupon with fixed product discount.")
        static let titleEditGenericDiscount = NSLocalizedString(
            "Edit discount",
            comment: "Title of the view for editing a coupon with generic discount.")
    }
}
