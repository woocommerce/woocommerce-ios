import XCTest
@testable import WooCommerce
@testable import Yosemite

final class DiscountTypeBottomSheetListSelectorCommandTests: XCTestCase {
    func test_callback_is_called_on_selection() {
        // Arrange
        var selectedActions = [Coupon.DiscountType]()
        let command = DiscountTypeBottomSheetListSelectorCommand(selected: .percent) { (selected) in
            selectedActions.append(selected)
        }

        // Action
        command.handleSelectedChange(selected: .fixedProduct)
        command.handleSelectedChange(selected: .fixedCart)
        command.handleSelectedChange(selected: .percent)

        // Assert
        let expectedActions: [Coupon.DiscountType] = [
            .fixedProduct,
            .fixedCart,
            .percent
        ]
        XCTAssertEqual(selectedActions, expectedActions)
    }
}
