import XCTest
@testable import Yosemite
@testable import WooCommerce

final class CouponDetailsViewModelTests: XCTestCase {

    func test_coupon_details_are_correct() {
        // Given
        let sampleCoupon = Coupon.sampleCoupon
        let viewModel = CouponDetailsViewModel(coupon: sampleCoupon)

        // Then
        XCTAssertEqual(viewModel.couponCode, "AGK32FD")
        XCTAssertEqual(viewModel.amount, "$10.00")
        XCTAssertEqual(viewModel.description, "Coupon description")
        XCTAssertEqual(viewModel.applyTo, "All Products")
        XCTAssertEqual(viewModel.expiryDate, "January 28, 2022")
    }

}
