import XCTest
@testable import WooCommerce
@testable import Yosemite

final class CouponUsageDetailsViewModelTests: XCTestCase {

    func test_usage_details_are_correct() {
        // Given
        let coupon = Coupon.fake().copy(individualUse: true,
                                        usageLimit: 1000,
                                        usageLimitPerUser: 1,
                                        limitUsageToXItems: 10,
                                        excludeSaleItems: false,
                                        minimumAmount: "10.00",
                                        maximumAmount: "1000.00",
                                        emailRestrictions: ["*@a8c.com", "vip@mail.com"])
        let viewModel = CouponUsageDetailsViewModel(coupon: coupon, currencySettings: CurrencySettings())

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
}
