import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductTypeBottomSheetListSelectorCommandTests: XCTestCase {
    // MARK: - `handleSelectedChange`

    func test_callback_is_called_on_selection() {
        // Arrange
        var selectedActions = [BottomSheetProductType]()
        let command = ProductTypeBottomSheetListSelectorCommand(selected: .simple(isVirtual: false)) { (selected) in
            selectedActions.append(selected)
        }

        // Action
        command.handleSelectedChange(selected: .simple(isVirtual: true))
        command.handleSelectedChange(selected: .grouped)
        command.handleSelectedChange(selected: .variable)
        command.handleSelectedChange(selected: .affiliate)
        command.handleSelectedChange(selected: .subscription)
        command.handleSelectedChange(selected: .variableSubscription)

        // Assert
        let expectedActions: [BottomSheetProductType] = [
            .simple(isVirtual: true),
            .grouped,
            .variable,
            .affiliate,
            .subscription,
            .variableSubscription
        ]
        XCTAssertEqual(selectedActions, expectedActions)
    }
}
