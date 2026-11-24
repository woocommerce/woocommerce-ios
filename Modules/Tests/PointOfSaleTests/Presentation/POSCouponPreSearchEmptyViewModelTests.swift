import Testing
@testable import PointOfSale

struct POSCouponPreSearchEmptyViewModelTests {
    @Test func test_viewModel_when_created_then_has_coupon_specific_text_and_no_action() {
        // When
        let viewModel = POSCouponPreSearchEmptyViewModel()

        // Then
        #expect(viewModel.title == "Find a coupon")
        #expect(viewModel.subtitle == "Type a coupon code to search.")
        #expect(viewModel.hint == nil)
        #expect(viewModel.buttonTitle == nil)
    }
}
