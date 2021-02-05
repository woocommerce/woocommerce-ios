import XCTest

@testable import WooCommerce
@testable import Yosemite


/// Tests for `AttributeOptionPickerViewModel`.
///
final class AttributeOptionPickerViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 123456

    func test_viewmodel_saves_option_change_for_attribute() throws {
        // Given
        let attribute = ProductAttribute(siteID: sampleSiteID,
                                         attributeID: 1,
                                         name: "Color",
                                         position: 1,
                                         visible: true,
                                         variation: true,
                                         options: ["Blue", "Red"])
        let selectedAttribute = ProductVariationAttribute(id: 1, name: "Color", option: "Blue")
        let viewModel = AttributeOptionPickerViewModel(attribute: attribute, selectedOption: selectedAttribute)

        // When
        viewModel.selectRow(at: IndexPath(row: 2, section: 0))

        // Then
        XCTAssertTrue(viewModel.isChanged)
        XCTAssertEqual(viewModel.selectedRow, .option("Red"))
        XCTAssertEqual(viewModel.resultAttribute?.option, "Red")
    }

    func test_viewmodel_saves_option_switch_to_any() throws {
        // Given
        let attribute = ProductAttribute(siteID: sampleSiteID,
                                         attributeID: 1,
                                         name: "Color",
                                         position: 1,
                                         visible: true,
                                         variation: true,
                                         options: ["Blue", "Red"])
        let selectedAttribute = ProductVariationAttribute(id: 1, name: "Color", option: "Blue")
        let viewModel = AttributeOptionPickerViewModel(attribute: attribute, selectedOption: selectedAttribute)

        // When
        viewModel.selectRow(at: IndexPath(row: 0, section: 0))

        // Then
        XCTAssertTrue(viewModel.isChanged)
        XCTAssertEqual(viewModel.selectedRow, .anyAttribute)
        XCTAssertNil(viewModel.resultAttribute)
    }

    func test_viewmodel_saves_option_switch_from_any() throws {
        // Given
        let attribute = ProductAttribute(siteID: sampleSiteID,
                                         attributeID: 1,
                                         name: "Color",
                                         position: 1,
                                         visible: true,
                                         variation: true,
                                         options: ["Blue", "Red"])
        let viewModel = AttributeOptionPickerViewModel(attribute: attribute, selectedOption: nil)

        // When
        viewModel.selectRow(at: IndexPath(row: 1, section: 0))

        // Then
        XCTAssertTrue(viewModel.isChanged)
        XCTAssertEqual(viewModel.selectedRow, .option("Blue"))
        XCTAssertNotNil(viewModel.resultAttribute)
    }

    func test_viewmodel_changed_state_works_correctly() throws {
        // Given
        let attribute = ProductAttribute(siteID: sampleSiteID,
                                         attributeID: 1,
                                         name: "Color",
                                         position: 1,
                                         visible: true,
                                         variation: true,
                                         options: ["Blue", "Red"])
        let selectedAttribute = ProductVariationAttribute(id: 1, name: "Color", option: "Blue")
        let viewModel = AttributeOptionPickerViewModel(attribute: attribute, selectedOption: selectedAttribute)

        // When
        viewModel.selectRow(at: IndexPath(row: 0, section: 0))

        // Then
        XCTAssertTrue(viewModel.isChanged)

        // When
        viewModel.selectRow(at: IndexPath(row: 1, section: 0))

        // Then
        XCTAssertFalse(viewModel.isChanged)
    }

    func test_viewmodel_changed_state_does_not_crash_on_unexpected_data() throws {
        // Given
        let attribute = ProductAttribute(siteID: sampleSiteID,
                                         attributeID: 1,
                                         name: "Color",
                                         position: 1,
                                         visible: true,
                                         variation: true,
                                         options: ["Blue", "Red"])
        let viewModel = AttributeOptionPickerViewModel(attribute: attribute, selectedOption: nil)

        // When
        viewModel.selectRow(at: IndexPath(row: 50, section: 0))

        // Then
        XCTAssertFalse(viewModel.isChanged)
    }
}
