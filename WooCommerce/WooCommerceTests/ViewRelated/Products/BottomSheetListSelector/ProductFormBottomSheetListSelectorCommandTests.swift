import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductFormBottomSheetListSelectorCommandTests: XCTestCase {
    // MARK: - `handleSelectedChange`

    func testCallbackIsCalledOnSelection() {
        // Arrange
        let actions: [ProductFormBottomSheetAction] = [.editInventorySettings, .editShippingSettings, .editCategories, .editBriefDescription]
        var selectedActions = [ProductFormBottomSheetAction]()
        let command = ProductFormBottomSheetListSelectorCommand(actions: actions) { selected in
                                                                    selectedActions.append(selected)
        }

        // Action
        command.handleSelectedChange(selected: .editInventorySettings)
        command.handleSelectedChange(selected: .editBriefDescription)
        command.handleSelectedChange(selected: .editShippingSettings)
        command.handleSelectedChange(selected: .editCategories)

        // Assert
        let expectedActions: [ProductFormBottomSheetAction] = [
            .editInventorySettings,
            .editBriefDescription,
            .editShippingSettings,
            .editCategories
        ]
        XCTAssertEqual(selectedActions, expectedActions)
    }
}
