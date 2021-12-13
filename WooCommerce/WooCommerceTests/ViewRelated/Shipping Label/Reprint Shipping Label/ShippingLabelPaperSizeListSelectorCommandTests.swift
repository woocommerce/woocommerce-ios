import XCTest
@testable import WooCommerce
import Yosemite

final class ShippingLabelPaperSizeListSelectorCommandTests: XCTestCase {
    func test_data_are_set_to_paperSizeOptions_in_init() {
        // Given
        let paperSizeOptions: [ShippingLabelPaperSize] = [.legal, .label, .letter]
        let command = ShippingLabelPaperSizeListSelectorCommand(paperSizeOptions: paperSizeOptions, selected: nil)

        // When
        let data = command.data

        // Then
        XCTAssertEqual(data, paperSizeOptions)
    }

    func test_selected_is_initialized_to_selected_value_in_init() {
        // Given
        let command = ShippingLabelPaperSizeListSelectorCommand(paperSizeOptions: [.legal, .label, .letter], selected: nil)

        // When
        let selected = command.selected

        // Then
        XCTAssertNil(selected)
    }

    func test_handleSelectedChange_updates_selected_value() {
        // Given
        let command = ShippingLabelPaperSizeListSelectorCommand(paperSizeOptions: [.legal, .label, .letter], selected: nil)
        let listSelector = ListSelectorViewController(command: command, onDismiss: { _ in })

        // When
        command.handleSelectedChange(selected: .label, viewController: listSelector)

        // Then
        XCTAssertEqual(command.selected, .label)
    }

    func test_isSelected_with_non_selected_value_returns_false() {
        // Given
        let command = ShippingLabelPaperSizeListSelectorCommand(paperSizeOptions: [.legal, .label, .letter], selected: nil)

        // When
        let isSelected = command.isSelected(model: .legal)

        // Then
        XCTAssertFalse(isSelected)
    }

    func test_configureCell_sets_cell_text_to_paper_size_description() {
        // Given
        let command = ShippingLabelPaperSizeListSelectorCommand(paperSizeOptions: [.legal, .label, .letter], selected: nil)
        let cell: BasicTableViewCell = BasicTableViewCell.instantiateFromNib()

        // When
        command.configureCell(cell: cell, model: .letter)

        // Then
        XCTAssertEqual(cell.textLabel?.text, ShippingLabelPaperSize.letter.description)
    }
}
