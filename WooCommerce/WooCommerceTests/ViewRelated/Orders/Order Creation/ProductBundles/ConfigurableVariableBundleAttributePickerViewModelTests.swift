import XCTest
import Yosemite
@testable import WooCommerce

final class ConfigurableVariableBundleAttributePickerViewModelTests: XCTestCase {
    func test_init_sets_name_and_options_from_attribute() throws {
        // Given
        let attribute = ProductAttribute.fake().copy(name: "Flavor",
                                                     options: ["Strawberry", "Grape"])

        // When
        let viewModel = ConfigurableVariableBundleAttributePickerViewModel(attribute: attribute,
                                                                           selectedOption: nil)

        // Then
        XCTAssertEqual(viewModel.name, "Flavor")
        XCTAssertEqual(viewModel.options, ["Strawberry", "Grape"])
    }

    func test_init_with_nil_selectedOption_sets_selectedOption_to_empty_string() throws {
        // Given
        let attribute = ProductAttribute.fake().copy(name: "Flavor",
                                                     options: ["Strawberry", "Grape"])

        // When
        let viewModel = ConfigurableVariableBundleAttributePickerViewModel(attribute: attribute,
                                                                           selectedOption: nil)

        // Then
        XCTAssertEqual(viewModel.selectedOption, "")
    }

    func test_init_with_selectedOption_sets_selectedOption_string() throws {
        // Given
        let attribute = ProductAttribute.fake().copy(name: "Flavor",
                                                     options: ["Strawberry", "Grape"])

        // When
        let viewModel = ConfigurableVariableBundleAttributePickerViewModel(attribute: attribute,
                                                                           selectedOption: "Strawberry")

        // Then
        XCTAssertEqual(viewModel.selectedOption, "Strawberry")
    }

    func test_when_selectedOption_is_invalid_then_selectedAttribute_is_nil() throws {
        // Given
        let attribute = ProductAttribute.fake().copy(name: "Flavor",
                                                     options: ["Strawberry", "Grape"])

        // When
        let viewModel = ConfigurableVariableBundleAttributePickerViewModel(attribute: attribute,
                                                                           selectedOption: nil)
        // Invalid option, not one the options
        viewModel.selectedOption = "Woo"

        // Then
        XCTAssertNil(viewModel.selectedAttribute)
    }

    func test_when_selectedOption_is_valid_then_selectedAttribute_is_not_nil() throws {
        // Given
        let attribute = ProductAttribute.fake().copy(attributeID: 8,
                                                     name: "Flavor",
                                                     options: ["Strawberry", "Grape"])

        // When
        let viewModel = ConfigurableVariableBundleAttributePickerViewModel(attribute: attribute,
                                                                           selectedOption: nil)
        // Invalid option, not one the options
        viewModel.selectedOption = "Grape"

        // Then
        XCTAssertEqual(viewModel.selectedAttribute, .init(id: 8, name: "Flavor", option: "Grape"))
    }
}
