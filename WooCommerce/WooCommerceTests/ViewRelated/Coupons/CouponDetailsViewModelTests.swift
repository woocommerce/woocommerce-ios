import XCTest
@testable import Yosemite
@testable import WooCommerce

final class CouponDetailsViewModelTests: XCTestCase {

    func test_coupon_details_are_correct_for_fixedProduct_discount_type() {
        // Given
        let sampleCoupon = Coupon.fake().copy(
            code: "AGK32FD",
            amount: "10.00",
            discountType: .fixedProduct,
            description: "Coupon description",
            dateExpires: Date(timeIntervalSince1970: 1642755825), // GMT: January 21, 2022
            productIds: []
        )
        let viewModel = CouponDetailsViewModel(coupon: sampleCoupon, currencySettings: CurrencySettings())

        // Then
        XCTAssertEqual(viewModel.couponCode, "AGK32FD")
        XCTAssertEqual(viewModel.amount, "$10.00")
        XCTAssertEqual(viewModel.description, "Coupon description")
        XCTAssertEqual(viewModel.productsAppliedTo, "All Products")
        XCTAssertEqual(viewModel.expiryDate, "January 21, 2022")
    }

    func test_coupon_details_are_correct_for_percentage_discount_type() {
        // Given
        let sampleCoupon = Coupon.fake().copy(
            code: "AGK32FD",
            amount: "10.00",
            discountType: .percent,
            description: "Coupon description",
            dateExpires: Date(timeIntervalSince1970: 1642755825), // GMT: January 21, 2022
            productIds: []
        )
        let viewModel = CouponDetailsViewModel(coupon: sampleCoupon)

        // Then
        XCTAssertEqual(viewModel.couponCode, "AGK32FD")
        XCTAssertEqual(viewModel.amount, "10%")
        XCTAssertEqual(viewModel.description, "Coupon description")
        XCTAssertEqual(viewModel.productsAppliedTo, "All Products")
        XCTAssertEqual(viewModel.expiryDate, "January 21, 2022")
    }

}
