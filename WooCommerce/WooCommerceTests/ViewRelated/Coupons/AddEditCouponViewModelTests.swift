import XCTest
@testable import Yosemite
@testable import WooCommerce

final class AddEditCouponViewModelTests: XCTestCase {

    func test_titleView_property_return_expected_values_on_creation_depending_on_discountType() {
        let viewModel1 = AddEditCouponViewModel(siteID: 123, discountType: .percent)
        XCTAssertEqual(viewModel1.title, Localization.titleCreatePercentageDiscount)

        let viewModel2 = AddEditCouponViewModel(siteID: 123, discountType: .fixedCart)
        XCTAssertEqual(viewModel2.title, Localization.titleCreateFixedCardDiscount)

        let viewModel3 = AddEditCouponViewModel(siteID: 123, discountType: .fixedProduct)
        XCTAssertEqual(viewModel3.title, Localization.titleCreateFixedProductDiscount)

        let viewModel4 = AddEditCouponViewModel(siteID: 123, discountType: .other)
        XCTAssertEqual(viewModel4.title, Localization.titleCreateGenericDiscount)
    }

    func test_titleView_property_return_expected_values_on_editing_depending_on_discountType() {
        let viewModel1 = AddEditCouponViewModel(existingCoupon: Coupon.sampleCoupon.copy(discountType: .percent))
        XCTAssertEqual(viewModel1.title, Localization.titleEditPercentageDiscount)

        let viewModel2 = AddEditCouponViewModel(existingCoupon: Coupon.sampleCoupon.copy(discountType: .fixedCart))
        XCTAssertEqual(viewModel2.title, Localization.titleEditFixedCardDiscount)

        let viewModel3 = AddEditCouponViewModel(existingCoupon: Coupon.sampleCoupon.copy(discountType: .fixedProduct))
        XCTAssertEqual(viewModel3.title, Localization.titleEditFixedProductDiscount)

        let viewModel4 = AddEditCouponViewModel(existingCoupon: Coupon.sampleCoupon.copy(discountType: .other))
        XCTAssertEqual(viewModel4.title, Localization.titleEditGenericDiscount)
    }

    private enum Localization {
        static let titleCreatePercentageDiscount = NSLocalizedString(
            "Create percentage discount",
            comment: "Title of the view for creating a coupon with percentage discount.")
        static let titleCreateFixedCardDiscount = NSLocalizedString(
            "Create fixed card discount",
            comment: "Title of the view for creating a coupon with fixed card discount.")
        static let titleCreateFixedProductDiscount = NSLocalizedString(
            "Create fixed product discount",
            comment: "Title of the view for creating a coupon with fixed product discount.")
        static let titleCreateGenericDiscount = NSLocalizedString(
            "Create discount",
            comment: "Title of the view for creating a coupon with generic discount.")
        static let titleEditPercentageDiscount = NSLocalizedString(
            "Edit percentage discount",
            comment: "Title of the view for editing a coupon with percentage discount.")
        static let titleEditFixedCardDiscount = NSLocalizedString(
            "Edit fixed card discount",
            comment: "Title of the view for editing a coupon with fixed card discount.")
        static let titleEditFixedProductDiscount = NSLocalizedString(
            "Edit fixed product discount",
            comment: "Title of the view for editing a coupon with fixed product discount.")
        static let titleEditGenericDiscount = NSLocalizedString(
            "Edit discount",
            comment: "Title of the view for editing a coupon with generic discount.")
    }
}
