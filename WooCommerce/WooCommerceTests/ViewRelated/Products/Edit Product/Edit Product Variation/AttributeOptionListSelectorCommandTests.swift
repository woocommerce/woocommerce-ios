import XCTest
import Yosemite

@testable import WooCommerce

/// Test cases for `AttributeOptionListSelectorCommand`
///
final class AttributeOptionListSelectorCommandTests: XCTestCase {

    private let sampleSiteID: Int64 = 123456

    func test_command_produces_correct_data() {
        // Given
        let attribute = ProductAttribute(siteID: sampleSiteID,
                                         attributeID: 1,
                                         name: "Color",
                                         position: 1,
                                         visible: true,
                                         variation: true,
                                         options: ["Blue", "Red"])
        let selectedAttribute = ProductVariationAttribute(id: 1, name: "Color", option: "Blue")

        // When
        let command = AttributeOptionListSelectorCommand(attribute: attribute, selectedOption: selectedAttribute)

        // Then
        XCTAssertEqual(command.data, [.anyOption("Color"), .option("Blue"), .option("Red")])
    }

    func test_command_selects_initial_option_correctly() {
        // Given
        let attribute = ProductAttribute(siteID: sampleSiteID,
                                         attributeID: 1,
                                         name: "Color",
                                         position: 1,
                                         visible: true,
                                         variation: true,
                                         options: ["Blue", "Red"])
        let selectedAttribute = ProductVariationAttribute(id: 1, name: "Color", option: "Blue")

        // When
        let command = AttributeOptionListSelectorCommand(attribute: attribute, selectedOption: selectedAttribute)

        // Then
        XCTAssertEqual(command.selected, .option("Blue"))
    }

    func test_command_selects_initial_any_correctly() {
        // Given
        let attribute = ProductAttribute(siteID: sampleSiteID,
                                         attributeID: 1,
                                         name: "Color",
                                         position: 1,
                                         visible: true,
                                         variation: true,
                                         options: ["Blue", "Red"])

        // When
        let command = AttributeOptionListSelectorCommand(attribute: attribute, selectedOption: nil)

        // Then
        XCTAssertEqual(command.selected, .anyOption("Color"))
    }


    func test_handleSelectedChange_updates_selected_value() {
        // Given
        let attribute = ProductAttribute(siteID: sampleSiteID,
                                         attributeID: 1,
                                         name: "Color",
                                         position: 1,
                                         visible: true,
                                         variation: true,
                                         options: ["Blue", "Red"])
        let command = AttributeOptionListSelectorCommand(attribute: attribute, selectedOption: nil)
        let listSelector = ListSelectorViewController(command: command, onDismiss: { _ in })

        // When
        let redOption = AttributeOptionListSelectorCommand.Row.option("Red")
        command.handleSelectedChange(selected: redOption, viewController: listSelector)

        // Then
        XCTAssertEqual(command.selected, redOption)
    }

    func test_configureCell_sets_cell_text_to_option_name() {
        // Given
        let attribute = ProductAttribute(siteID: sampleSiteID,
                                         attributeID: 1,
                                         name: "Color",
                                         position: 1,
                                         visible: true,
                                         variation: true,
                                         options: ["Blue", "Red"])
        let command = AttributeOptionListSelectorCommand(attribute: attribute, selectedOption: nil)
        let cell: BasicTableViewCell = BasicTableViewCell.instantiateFromNib()

        // When
        command.configureCell(cell: cell, model: .option("Red"))

        // Then
        XCTAssertEqual(cell.textLabel?.text, "Red")
    }
}
