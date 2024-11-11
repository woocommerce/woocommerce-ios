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
        let viewModel = WooShippingAddCustomPackageViewModel(dimensionsUnit: expectedDimensionUnit,
                                                             weightUnit: expectedWeightUnit)

        // Then
        XCTAssertNotNil(viewModel)
        viewModel.checkDefaultInitProperties()
        XCTAssertEqual(viewModel.dimensionsUnit, expectedDimensionUnit)
        XCTAssertEqual(viewModel.weightUnit, expectedWeightUnit)
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
        viewModel.fillWithDummyFieldValues()

        // Then
        XCTAssertEqual(viewModel.validateCustomPackageInputFields(), true)
    }

    func test_validate_custom_package_input_fields_when_fields_are_valid_and_save_template_shown() {
        // Given
        let viewModel = WooShippingAddCustomPackageViewModel()

        // When
        viewModel.fillWithDummyFieldValues()
        viewModel.showSaveTemplate = true

        // Then
        XCTAssertEqual(viewModel.validateCustomPackageInputFields(), false)

        // When
        viewModel.packageTemplateName = "a"

        // Then
        XCTAssertEqual(viewModel.validateCustomPackageInputFields(), true)
    }

    func test_add_package_action() async {
        // Given
        let dimensionUnit = "cm"
        let weightUnit = "kg"
        let viewModel = WooShippingAddCustomPackageViewModel(dimensionsUnit: dimensionUnit, weightUnit: weightUnit)
        let length = "1"
        let width = "2"
        let height = "3"
        let weight = "4"

        let expectedDimensions = "\(length) x \(width) x \(height) \(dimensionUnit)"
        let expectedWeight = "\(weight) \(weightUnit)"

        // When
        viewModel.fieldValues[.length] = length
        viewModel.fieldValues[.width] = width
        viewModel.fieldValues[.height] = height
        viewModel.fieldValues[.weight] = weight
        let packageDataResult = await viewModel.addPackageAction()

        // Then
        switch packageDataResult {
        case .success(let packageData):
            XCTAssertNotNil(packageData)
            XCTAssertEqual(packageData.dimensionsDescription, expectedDimensions)
            XCTAssertEqual(packageData.weightDescription, expectedWeight)
        case .failure(let failure):
            XCTFail(failure.localizedDescription)
        }
    }

    func test_save_package_as_template_action() async {
        // Given
        let viewModel = WooShippingAddCustomPackageViewModel()

        // When
        viewModel.fillWithDummyFieldValues()
        viewModel.showSaveTemplate = true
        viewModel.packageTemplateName = "a"
        let packageDataResult = await viewModel.savePackageAsTemplateAction()

        // Then
        switch packageDataResult {
        case .success(let packageData):
            XCTAssertNotNil(packageData)
            XCTAssertEqual(packageData.name, "a")
        case .failure(let failure):
            XCTFail(failure.localizedDescription)
        }
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
