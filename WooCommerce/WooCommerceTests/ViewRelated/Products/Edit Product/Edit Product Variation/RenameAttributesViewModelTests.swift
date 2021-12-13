import XCTest

@testable import WooCommerce
@testable import Yosemite

class RenameAttributesViewModelTests: XCTestCase {

    func test_done_button_disabled_when_new_attribute_name_is_empty() {
        // Given
        let attribute = ProductVariationAttribute(id: 0, name: "Color", option: "Blue")
        let viewModel = RenameAttributesViewModel(attributeName: attribute.name)

        // When
        viewModel.handleAttributeNameChange("")

        // Then
        XCTAssertFalse(viewModel.shouldEnableDoneButton)
    }

    func test_viewModel_starts_with_no_unsaved_changes() {
        // Given
        let attribute = ProductVariationAttribute(id: 0, name: "Color", option: "Blue")

        // When
        let viewModel = RenameAttributesViewModel(attributeName: attribute.name)

        // Then
        XCTAssertFalse(viewModel.hasUnsavedChanges())
    }

    func test_viewModel_unsaved_changes_becomes_true_after_setting_new_attribute_name() {
        // Given
        let attribute = ProductVariationAttribute(id: 0, name: "Color", option: "Blue")
        let viewModel = RenameAttributesViewModel(attributeName: attribute.name)

        // When
        viewModel.handleAttributeNameChange("New Color")

        // Then
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func test_attribute_name_updates_from_original_to_new_attribute_name() {
        // Given
        let attribute = ProductVariationAttribute(id: 0, name: "Color", option: "Blue")
        let viewModel = RenameAttributesViewModel(attributeName: attribute.name)
        XCTAssertEqual(viewModel.attributeName, "Color")

        // When
        viewModel.handleAttributeNameChange("New Color")

        // Then
        XCTAssertEqual(viewModel.attributeName, "New Color")
    }

}
