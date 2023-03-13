import XCTest

import WooFoundation
@testable import WooCommerce
@testable import struct Yosemite.OrderCouponLine

final class CouponLineDetailsViewModelTests: XCTestCase {

    func test_view_model_disables_done_button_for_empty_state_and_enables_with_input() {
        // Given
        let viewModel = CouponLineDetailsViewModel(isExistingCouponLine: false,
                                                   code: "",
                                                   didSelectSave: { _ in })
        XCTAssertTrue(viewModel.shouldDisableDoneButton)

        // When
        viewModel.code = "COUPON"

        // Then
        XCTAssertFalse(viewModel.shouldDisableDoneButton)

        // When
        viewModel.code = ""

        // Then
        XCTAssertTrue(viewModel.shouldDisableDoneButton)
    }

    func test_view_model_disables_done_button_for_prefilled_data_and_enables_with_changes() {
        // Given
        let viewModel = CouponLineDetailsViewModel(isExistingCouponLine: false,
                                                   code: "COUPON",
                                                   didSelectSave: { _ in })
        XCTAssertTrue(viewModel.shouldDisableDoneButton)

        // When
        viewModel.code = "COUPON1"

        // Then
        XCTAssertFalse(viewModel.shouldDisableDoneButton)

        // When
        viewModel.code = "COUPON"

        // Then
        XCTAssertTrue(viewModel.shouldDisableDoneButton)
    }


    func test_view_model_creates_coupon_line_with_data_from_fields() {
        // Given
        var savedCouponLine: OrderCouponLine?
        let viewModel = CouponLineDetailsViewModel(isExistingCouponLine: false,
                                                   code: "COUPON",
                                                   didSelectSave: { newCouponLine in
            savedCouponLine = newCouponLine
        })

        // When
        viewModel.code = "COUPON"
        viewModel.saveData()

        // Then
        XCTAssertEqual(savedCouponLine?.code, "COUPON")
    }

    func test_view_model_initializes_correctly_with_no_existing_coupon_line() {
        // Given
        let viewModel = CouponLineDetailsViewModel(isExistingCouponLine: false,
                                                   code: "",
                                                   didSelectSave: { _ in })

        // Then
        XCTAssertFalse(viewModel.isExistingCouponLine)
    }
}
