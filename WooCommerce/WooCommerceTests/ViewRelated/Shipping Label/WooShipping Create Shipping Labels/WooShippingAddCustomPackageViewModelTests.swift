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
        let expectedWeightUnit = "kg"
        let viewModel = WooShippingAddCustomPackageViewModel(storeOptions: ShippingLabelStoreOptions(currencySymbol: "$",
                                                                                                     dimensionUnit: expectedDimensionUnit,
                                                                                                     weightUnit: expectedWeightUnit,
                                                                                                     originCountry: "US"))

        // Then
        XCTAssertNotNil(viewModel)
        viewModel.checkDefaultInitProperties()
        XCTAssertEqual(viewModel.storeOptions?.dimensionUnit, expectedDimensionUnit)
        XCTAssertEqual(viewModel.storeOptions?.weightUnit, expectedWeightUnit)
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
        let dimensionUnit = "cm"
        let weightUnit = "kg"
        let viewModel = WooShippingAddCustomPackageViewModel(storeOptions: ShippingLabelStoreOptions(currencySymbol: "$",
                                                                                                     dimensionUnit: dimensionUnit,
                                                                                                     weightUnit: weightUnit,
                                                                                                     originCountry: "US"))
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
        let packageData = viewModel.addPackageAction()

        // Then
        viewModel.checkDefaultInitProperties()
        XCTAssertEqual(viewModel.validateCustomPackageInputFields(), false)
        XCTAssertNotNil(packageData)
        XCTAssertEqual(packageData?.dimensionsDescription, expectedDimensions)
        XCTAssertEqual(packageData?.weightDescription, expectedWeight)
        XCTAssertNil(viewModel.addPackageAction())
    }

    @MainActor
    func test_save_package_as_template_action() async {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingAddCustomPackageViewModel(storeOptions: ShippingLabelStoreOptions(currencySymbol: "$",
                                                                                                     dimensionUnit: "in",
                                                                                                     weightUnit: "lb",
                                                                                                     originCountry: "US"),
                                                             stores: stores)
        let packageName = "a"
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case let .createPackage(_, _, _, completion):
                completion(.success(WooShippingCreatePackageResponse(customPackages: [WooShippingCustomPackage.fake().copy(id: "1", name: packageName)],
                                                                     predefinedOptions: [])))
            default:
                XCTFail("Received unexpected action: \(action)")
            }
        }

        // When
        viewModel.fillWithDummyFieldValues()
        viewModel.showSaveTemplate = true
        viewModel.packageTemplateName = packageName
        let packageData = await viewModel.savePackageAsTemplateAction()

        // Then
        viewModel.checkDefaultInitProperties()
        XCTAssertEqual(viewModel.validateCustomPackageInputFields(), false)
        XCTAssertNotNil(packageData)
        XCTAssertEqual(packageData?.name, packageName)
        XCTAssertEqual(packageData?.id, "1")
        let updatedPackageData = await viewModel.savePackageAsTemplateAction()
        XCTAssertNil(updatedPackageData)
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
