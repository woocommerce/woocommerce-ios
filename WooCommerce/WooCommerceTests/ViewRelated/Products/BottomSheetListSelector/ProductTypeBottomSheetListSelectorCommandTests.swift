import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductTypeBottomSheetListSelectorCommandTests: XCTestCase {
    // MARK: - `handleSelectedChange`

    func test_callback_is_called_on_selection() {
        // Arrange
        var selectedActions = [ProductType]()
        let command = ProductTypeBottomSheetListSelectorCommand(selected: .simple) { (selected) in
            selectedActions.append(selected)
        }

        // Action
        command.handleSelectedChange(selected: .grouped)
        command.handleSelectedChange(selected: .variable)
        command.handleSelectedChange(selected: .affiliate)

        // Assert
        let expectedActions: [ProductType] = [
            .grouped,
            .variable,
            .affiliate
        ]
        XCTAssertEqual(selectedActions, expectedActions)
    }
}
