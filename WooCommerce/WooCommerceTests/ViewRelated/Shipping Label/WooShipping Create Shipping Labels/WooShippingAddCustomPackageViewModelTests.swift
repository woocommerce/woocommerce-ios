import XCTest
@testable import WooCommerce
import Yosemite

final class WooShippingAddCustomPackageViewModelTests: XCTestCase {
    func test_it_inits_with_empty_field_values() {
        // Given/When
        let viewModel = WooShippingAddCustomPackageViewModel()

        // Then
        XCTAssertNotNil(viewModel)
        viewModel.checkDefaultInitProperties()
    }

    func test_it_inits_with_dimension_weight_unit() {
        // Given/When
        let expectedDimensionUnit = "in"
        let expectedWeightUnit = "in"
        let viewModel = WooShippingAddCustomPackageViewModel(dimensionUnit: expectedDimensionUnit,
                                                             weightUnit: expectedWeightUnit)

        // Then
        XCTAssertNotNil(viewModel)
        viewModel.checkDefaultInitProperties()
        XCTAssertEqual(viewModel.dimensionUnit, expectedDimensionUnit)
        XCTAssertEqual(viewModel.weightUnit, expectedWeightUnit)
    }

    func test_clear_field_values() {
        // Given
        let viewModel = WooShippingAddCustomPackageViewModel()

        // When
        viewModel.fillWithDummyFieldValues()
        viewModel.clearFieldValues()

        // Then
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel.fieldValues.isEmpty, true)
        XCTAssertEqual(viewModel.areFieldValuesInvalid, true)
    }

    func test_reset_values() {
        // Given
        let viewModel = WooShippingAddCustomPackageViewModel()

        // When
        viewModel.fillWithDummyFieldValues()
        viewModel.showSaveTemplate = true
        viewModel.packageTemplateName = "a"
        viewModel.resetValues()

        // Then
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel.fieldValues.isEmpty, true)
        XCTAssertEqual(viewModel.areFieldValuesInvalid, true)
        XCTAssertEqual(viewModel.showSaveTemplate, false)
        XCTAssertEqual(viewModel.packageTemplateName, "")
    }

    func test_it_with_not_all_field_values_set() {
        // Given
        let viewModel = WooShippingAddCustomPackageViewModel()

        // When
        viewModel.fieldValues[.height] = "1"

        // Then
        XCTAssertEqual(viewModel.fieldValues.isEmpty, false)
        XCTAssertEqual(viewModel.areFieldValuesInvalid, true)
    }

    func test_it_with_all_field_values_set() {
        // Given
        let viewModel = WooShippingAddCustomPackageViewModel()

        // When
        viewModel.fillWithDummyFieldValues()

        // Then
        XCTAssertEqual(viewModel.fieldValues.isEmpty, false)
        XCTAssertEqual(viewModel.areFieldValuesInvalid, false)
    }

    func test_it_with_all_dimension_field_values_set_not_saving_template() {
        // Given
        let viewModel = WooShippingAddCustomPackageViewModel()

        // When
        viewModel.fillWithDummyDimensionFieldValues()
        viewModel.showSaveTemplate = false

        // Then
        XCTAssertEqual(viewModel.fieldValues.isEmpty, false)
        XCTAssertEqual(viewModel.areFieldValuesInvalid, false)
    }

    func test_it_with_all_dimension_field_values_set_saving_template() {
        // Given
        let viewModel = WooShippingAddCustomPackageViewModel()

        // When
        viewModel.fillWithDummyDimensionFieldValues()
        viewModel.showSaveTemplate = true

        // Then
        XCTAssertEqual(viewModel.fieldValues.isEmpty, false)
        XCTAssertEqual(viewModel.areFieldValuesInvalid, true)
    }

    func test_it_with_all_dimension_weight_field_values_set() {
        // Given
        let viewModel = WooShippingAddCustomPackageViewModel()

        // When
        viewModel.fillWithDummyDimensionFieldValues()
        viewModel.showSaveTemplate = true
        viewModel.fieldValues[.weight] = "1"
        // Then
        XCTAssertEqual(viewModel.fieldValues.isEmpty, false)
        XCTAssertEqual(viewModel.areFieldValuesInvalid, false)
    }

    func test_validate_custom_package_input_fields_when_init() {
        // Given/When
        let viewModel = WooShippingAddCustomPackageViewModel()

        // Then
        XCTAssertEqual(viewModel.validateCustomPackageInputFields(), false)
    }

    func test_validate_custom_package_input_fields_when_fields_are_valid() {
        // Given
        let viewModel = WooShippingAddCustomPackageViewModel()

        // When
        viewModel.clearFieldValues()
        viewModel.fillWithDummyFieldValues()

        // Then
        XCTAssertEqual(viewModel.validateCustomPackageInputFields(), true)
    }

    func test_validate_custom_package_input_fields_when_fields_are_valid_and_save_template_shown() {
        // Given
        let viewModel = WooShippingAddCustomPackageViewModel()

        // When
        viewModel.clearFieldValues()
        viewModel.fillWithDummyFieldValues()
        viewModel.showSaveTemplate = true

        // Then
        XCTAssertEqual(viewModel.validateCustomPackageInputFields(), false)

        // When
        viewModel.packageTemplateName = "a"

        // Then
        XCTAssertEqual(viewModel.validateCustomPackageInputFields(), true)
    }

    func test_add_package_action() {
        // Given
        let viewModel = WooShippingAddCustomPackageViewModel()

        // When
        viewModel.fillWithDummyFieldValues()
        viewModel.addPackageAction()

        // Then
        viewModel.checkDefaultInitProperties()
        XCTAssertEqual(viewModel.validateCustomPackageInputFields(), false)
    }

    func test_save_package_as_template_action() {
        // Given
        let viewModel = WooShippingAddCustomPackageViewModel()

        // When
        viewModel.fillWithDummyFieldValues()
        viewModel.showSaveTemplate = true
        viewModel.packageTemplateName = "a"
        viewModel.savePackageAsTemplateAction()

        // Then
        viewModel.checkDefaultInitProperties()
        XCTAssertEqual(viewModel.validateCustomPackageInputFields(), false)
    }
}

extension WooShippingAddCustomPackageViewModel {
    func fillWithDummyFieldValues() {
        for dimensionType in WooShippingPackageUnitType.allCases {
            fieldValues[dimensionType] = "1"
        }
    }

    func fillWithDummyDimensionFieldValues() {
        for dimensionType in WooShippingPackageUnitType.dimensionUnits {
            fieldValues[dimensionType] = "1"
        }
    }

    func checkDefaultInitProperties() {
        XCTAssertEqual(fieldValues.isEmpty, true)
        XCTAssertEqual(packageType, WooShippingPackageType.box)
        XCTAssertEqual(showSaveTemplate, false)
        XCTAssertEqual(packageTemplateName, "")
        XCTAssertEqual(areFieldValuesInvalid, true)
    }
}
