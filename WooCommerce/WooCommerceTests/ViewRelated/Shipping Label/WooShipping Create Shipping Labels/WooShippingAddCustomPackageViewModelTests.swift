import XCTest
@testable import WooCommerce
import Yosemite

final class WooShippingAddCustomPackageViewModelTests: XCTestCase {
    @MainActor
    func test_it_inits_with_empty_field_values() {
        // Given/When
        let siteID: Int64 = 1234
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingAddCustomPackageViewModel(siteID: siteID,
                                                             stores: mockStores)

        // Then
        XCTAssertNotNil(viewModel)
        viewModel.checkDefaultInitProperties()
    }

    @MainActor
    func test_it_with_not_all_field_values_set() {
        // Given
        let siteID: Int64 = 1234
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingAddCustomPackageViewModel(siteID: siteID,
                                                             stores: mockStores)

        // When
        viewModel.fieldValues[.height] = "1"

        // Then
        XCTAssertEqual(viewModel.fieldValues.isEmpty, false)
        XCTAssertEqual(viewModel.areFieldValuesIncomplete, true)
    }

    @MainActor
    func test_it_with_all_field_values_set() {
        // Given
        let siteID: Int64 = 1234
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingAddCustomPackageViewModel(siteID: siteID,
                                                             stores: mockStores)

        // When
        viewModel.fillWithDummyFieldValues()

        // Then
        XCTAssertEqual(viewModel.fieldValues.isEmpty, false)
        XCTAssertEqual(viewModel.areFieldValuesIncomplete, false)
    }

    @MainActor
    func test_it_with_all_dimension_field_values_set_not_saving_template() {
        // Given
        let siteID: Int64 = 1234
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingAddCustomPackageViewModel(siteID: siteID,
                                                             stores: mockStores)

        // When
        viewModel.fillWithDummyDimensionFieldValues()
        viewModel.showSaveTemplate = false

        // Then
        XCTAssertEqual(viewModel.fieldValues.isEmpty, false)
        XCTAssertEqual(viewModel.areFieldValuesIncomplete, false)
    }

    @MainActor
    func test_it_with_all_dimension_field_values_set_saving_template() {
        // Given
        let siteID: Int64 = 1234
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingAddCustomPackageViewModel(siteID: siteID,
                                                             stores: mockStores)

        // When
        viewModel.fillWithDummyDimensionFieldValues()
        viewModel.showSaveTemplate = true

        // Then
        XCTAssertEqual(viewModel.fieldValues.isEmpty, false)
        XCTAssertEqual(viewModel.areFieldValuesIncomplete, true)
    }

    @MainActor
    func test_it_with_all_dimension_weight_field_values_set() {
        // Given
        let siteID: Int64 = 1234
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingAddCustomPackageViewModel(siteID: siteID,
                                                             stores: mockStores)

        // When
        viewModel.fillWithDummyDimensionFieldValues()
        viewModel.showSaveTemplate = true
        viewModel.fieldValues[.weight] = "1"
        // Then
        XCTAssertEqual(viewModel.fieldValues.isEmpty, false)
        XCTAssertEqual(viewModel.areFieldValuesIncomplete, false)
    }

    @MainActor
    func test_validate_custom_package_input_fields_when_init() {
        // Given/When
        let siteID: Int64 = 1234
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingAddCustomPackageViewModel(siteID: siteID,
                                                             stores: mockStores)

        // Then
        XCTAssertEqual(viewModel.validateCustomPackageInputFields(), false)
        XCTAssertNil(viewModel.packageData)
    }

    @MainActor
    func test_validate_custom_package_input_fields_when_fields_are_valid() {
        // Given
        let siteID: Int64 = 1234
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingAddCustomPackageViewModel(siteID: siteID,
                                                             stores: mockStores)

        // When
        viewModel.fillWithDummyFieldValues()

        // Then
        XCTAssertEqual(viewModel.validateCustomPackageInputFields(), true)
        XCTAssertNotNil(viewModel.packageData)
    }

    @MainActor
    func test_validate_custom_package_input_fields_when_fields_are_valid_and_save_template_shown() {
        // Given
        let siteID: Int64 = 1234
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingAddCustomPackageViewModel(siteID: siteID,
                                                             stores: mockStores)

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

    func test_packageData_is_correct() throws {
        // Given
        let dimensionUnit = "cm"
        let weightUnit = "kg"
        let siteID: Int64 = 1234
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingAddCustomPackageViewModel(siteID: siteID,
                                                             stores: mockStores)
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

        // Then
        let packageData = try XCTUnwrap(viewModel.packageData)
        XCTAssertEqual(packageData.dimensionsDescription(unit: dimensionUnit), expectedDimensions)
        XCTAssertEqual(packageData.weightDescription(unit: weightUnit), expectedWeight)
        XCTAssertEqual(packageData.id, "custom_box")

        // When: selecting a template
        viewModel.showSaveTemplate = true
        viewModel.packageTemplateName = "a"

        // Then
        let updatedPackageData = try XCTUnwrap(viewModel.packageData)
        XCTAssertEqual(updatedPackageData.id, "a")
    }

    func test_packageData_does_not_show_height_if_height_is_unavailable() throws {
        // Given
        let dimensionUnit = "cm"
        let weightUnit = "kg"
        let siteID: Int64 = 1234
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingAddCustomPackageViewModel(siteID: siteID,
                                                             stores: mockStores)
        let length = "1"
        let width = "2"
        let height = "0"
        let weight = "4"

        let expectedDimensions = "\(length) x \(width) \(dimensionUnit)"
        let expectedWeight = "\(weight) \(weightUnit)"

        // When
        viewModel.fieldValues[.length] = length
        viewModel.fieldValues[.width] = width
        viewModel.fieldValues[.height] = height
        viewModel.fieldValues[.weight] = weight

        // Then
        let packageData = try XCTUnwrap(viewModel.packageData)
        XCTAssertEqual(packageData.dimensionsDescription(unit: dimensionUnit), expectedDimensions)
        XCTAssertEqual(packageData.weightDescription(unit: weightUnit), expectedWeight)
        XCTAssertEqual(packageData.id, "custom_box")

        // When: selecting a template
        viewModel.showSaveTemplate = true
        viewModel.packageTemplateName = "a"

        // Then
        let updatedPackageData = try XCTUnwrap(viewModel.packageData)
        XCTAssertEqual(updatedPackageData.id, "a")
    }

    @MainActor
    func test_save_package_as_template_action() async {
        // Given
        let siteID: Int64 = 1234
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingAddCustomPackageViewModel(siteID: siteID,
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
        let packageDataResult = await viewModel.savePackageAsTemplateAction()

        // Then
        switch packageDataResult {
        case .success(let packageData):
            XCTAssertNotNil(packageData)
            XCTAssertEqual(packageData.name, packageName)
            XCTAssertEqual(packageData.id, "1")
        case .failure(let failure):
            XCTFail(failure.localizedDescription)
        }
    }

    func test_it_handles_selected_package_data() {
        // Given
        let selectedPackage = WooShippingPackageData(name: "",
                                                     length: "31.75",
                                                     width: "24.13",
                                                     height: "1.27",
                                                     weight: "",
                                                     source: .custom,
                                                     packageType: "envelope")

        // When
        let viewModel = WooShippingAddCustomPackageViewModel(selectedPackage: selectedPackage)

        // Then
        XCTAssertEqual(viewModel.fieldValues[.length], "31.75")
        XCTAssertEqual(viewModel.fieldValues[.width], "24.13")
        XCTAssertEqual(viewModel.fieldValues[.height], "1.27")
        XCTAssertEqual(viewModel.packageType, .envelope)
    }

    // MARK: - allDimensionsValid tests

    func test_allDimensionsValid_returns_false_when_dimension_is_zero() {
        // Given
        let siteID: Int64 = 1234
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingAddCustomPackageViewModel(siteID: siteID, stores: mockStores)

        // When
        viewModel.fieldValues[.length] = "10"
        viewModel.fieldValues[.width] = "0"
        viewModel.fieldValues[.height] = "5"

        // Then
        XCTAssertFalse(viewModel.allDimensionsValid)
    }

    func test_allDimensionsValid_returns_false_when_dimension_is_empty_string() {
        // Given
        let siteID: Int64 = 1234
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingAddCustomPackageViewModel(siteID: siteID, stores: mockStores)

        // When
        viewModel.fieldValues[.length] = "10"
        viewModel.fieldValues[.width] = ""
        viewModel.fieldValues[.height] = "5"

        // Then
        XCTAssertFalse(viewModel.allDimensionsValid)
    }

    func test_allDimensionsValid_returns_false_when_dimension_is_invalid_string() {
        // Given
        let siteID: Int64 = 1234
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingAddCustomPackageViewModel(siteID: siteID, stores: mockStores)

        // When
        viewModel.fieldValues[.length] = "10"
        viewModel.fieldValues[.width] = "abc"
        viewModel.fieldValues[.height] = "5"

        // Then
        XCTAssertFalse(viewModel.allDimensionsValid)
    }

    func test_allDimensionsValid_returns_false_when_dimension_is_negative() {
        // Given
        let siteID: Int64 = 1234
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingAddCustomPackageViewModel(siteID: siteID, stores: mockStores)

        // When
        viewModel.fieldValues[.length] = "10"
        viewModel.fieldValues[.width] = "-5"
        viewModel.fieldValues[.height] = "5"

        // Then
        XCTAssertFalse(viewModel.allDimensionsValid)
    }

    func test_allDimensionsValid_returns_true_when_all_dimensions_are_valid_positive_numbers() {
        // Given
        let siteID: Int64 = 1234
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingAddCustomPackageViewModel(siteID: siteID, stores: mockStores)

        // When
        viewModel.fieldValues[.length] = "10"
        viewModel.fieldValues[.width] = "5"
        viewModel.fieldValues[.height] = "3"

        // Then
        XCTAssertTrue(viewModel.allDimensionsValid)
    }

    func test_allDimensionsValid_returns_true_when_all_dimensions_are_valid_decimals() {
        // Given
        let siteID: Int64 = 1234
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingAddCustomPackageViewModel(siteID: siteID, stores: mockStores)

        // When
        viewModel.fieldValues[.length] = "10.5"
        viewModel.fieldValues[.width] = "5.25"
        viewModel.fieldValues[.height] = "3.75"

        // Then
        XCTAssertTrue(viewModel.allDimensionsValid)
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
        XCTAssertEqual(areFieldValuesIncomplete, true)
    }
}
