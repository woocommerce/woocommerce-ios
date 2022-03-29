import XCTest
@testable import Yosemite
@testable import WooCommerce

final class AddEditCouponViewModelTests: XCTestCase {

    func test_titleView_property_return_expected_values_on_creation_depending_on_discountType() {
        let viewModel1 = AddEditCouponViewModel(siteID: 123, discountType: .percent)
        XCTAssertEqual(viewModel1.title, "Create percentage discount")

        let viewModel2 = AddEditCouponViewModel(siteID: 123, discountType: .fixedCart)
        XCTAssertEqual(viewModel2.title, "Create fixed card discount")

        let viewModel3 = AddEditCouponViewModel(siteID: 123, discountType: .fixedProduct)
        XCTAssertEqual(viewModel3.title, "Create fixed product discount")

        let viewModel4 = AddEditCouponViewModel(siteID: 123, discountType: .other)
        XCTAssertEqual(viewModel4.title, "Create discount")
    }

    func test_titleView_property_return_expected_values_on_editing_depending_on_discountType() {
        let viewModel1 = AddEditCouponViewModel(existingCoupon: Coupon.sampleCoupon.copy(discountType: .percent))
        XCTAssertEqual(viewModel1.title, "Edit percentage discount")

        let viewModel2 = AddEditCouponViewModel(existingCoupon: Coupon.sampleCoupon.copy(discountType: .fixedCart))
        XCTAssertEqual(viewModel2.title, "Edit fixed card discount")

        let viewModel3 = AddEditCouponViewModel(existingCoupon: Coupon.sampleCoupon.copy(discountType: .fixedProduct))
        XCTAssertEqual(viewModel3.title, "Edit fixed product discount")

        let viewModel4 = AddEditCouponViewModel(existingCoupon: Coupon.sampleCoupon.copy(discountType: .other))
        XCTAssertEqual(viewModel4.title, "Edit discount")
    }
}
