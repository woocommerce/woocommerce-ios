import XCTest
@testable import WooCommerce
import Yosemite

final class WooShippingAddCustomPackageViewModelTests: XCTestCase {
    @MainActor
    func test_it_inits_with_empty_field_values() {
        // Given/When
        let packagesRepository = MockWooShippingPackagesRepository()
        let siteID: Int64 = 1234
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingAddCustomPackageViewModel(siteID: siteID,
                                                             storeOptions: ShippingLabelStoreOptions(currencySymbol: "$",
                                                                                                     dimensionUnit: "in",
                                                                                                     weightUnit: "oz",
                                                                                                     originCountry: "US"),
                                                             stores: mockStores,
                                                             packagesRepository: packagesRepository)

        // Then
        XCTAssertNotNil(viewModel)
        viewModel.checkDefaultInitProperties()
    }

    @MainActor
    func test_it_inits_with_store_options() {
        // Given/When
        let expectedCurrencySymbol = "$"
        let expectedDimensionUnit = "in"
        let expectedWeightUnit = "kg"
        let expectedOriginCountry = "US"
        let packagesRepository = MockWooShippingPackagesRepository()
        let siteID: Int64 = 1234
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingAddCustomPackageViewModel(siteID: siteID,
                                                             storeOptions: ShippingLabelStoreOptions(currencySymbol: expectedCurrencySymbol,
                                                                                                     dimensionUnit: expectedDimensionUnit,
                                                                                                     weightUnit: expectedWeightUnit,
                                                                                                     originCountry: expectedOriginCountry),
                                                             stores: mockStores,
                                                             packagesRepository: packagesRepository)

        // Then
        XCTAssertNotNil(viewModel)
        viewModel.checkDefaultInitProperties()
        XCTAssertEqual(viewModel.storeOptions.currencySymbol, expectedCurrencySymbol)
        XCTAssertEqual(viewModel.storeOptions.dimensionUnit, expectedDimensionUnit)
        XCTAssertEqual(viewModel.storeOptions.weightUnit, expectedWeightUnit)
        XCTAssertEqual(viewModel.storeOptions.originCountry, expectedOriginCountry)
    }

    @MainActor
    func test_it_with_not_all_field_values_set() {
        // Given
        let packagesRepository = MockWooShippingPackagesRepository()
        let siteID: Int64 = 1234
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingAddCustomPackageViewModel(siteID: siteID,
                                                             storeOptions: ShippingLabelStoreOptions(currencySymbol: "$",
                                                                                                     dimensionUnit: "in",
                                                                                                     weightUnit: "oz",
                                                                                                     originCountry: "US"),
                                                             stores: mockStores,
                                                             packagesRepository: packagesRepository)

        // When
        viewModel.fieldValues[.height] = "1"

        // Then
        XCTAssertEqual(viewModel.fieldValues.isEmpty, false)
        XCTAssertEqual(viewModel.areFieldValuesInvalid, true)
    }

    @MainActor
    func test_it_with_all_field_values_set() {
        // Given
        let packagesRepository = MockWooShippingPackagesRepository()
        let siteID: Int64 = 1234
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingAddCustomPackageViewModel(siteID: siteID,
                                                             storeOptions: ShippingLabelStoreOptions(currencySymbol: "$",
                                                                                                     dimensionUnit: "in",
                                                                                                     weightUnit: "oz",
                                                                                                     originCountry: "US"),
                                                             stores: mockStores,
                                                             packagesRepository: packagesRepository)

        // When
        viewModel.fillWithDummyFieldValues()

        // Then
        XCTAssertEqual(viewModel.fieldValues.isEmpty, false)
        XCTAssertEqual(viewModel.areFieldValuesInvalid, false)
    }

    @MainActor
    func test_it_with_all_dimension_field_values_set_not_saving_template() {
        // Given
        let packagesRepository = MockWooShippingPackagesRepository()
        let siteID: Int64 = 1234
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingAddCustomPackageViewModel(siteID: siteID,
                                                             storeOptions: ShippingLabelStoreOptions(currencySymbol: "$",
                                                                                                     dimensionUnit: "in",
                                                                                                     weightUnit: "oz",
                                                                                                     originCountry: "US"),
                                                             stores: mockStores,
                                                             packagesRepository: packagesRepository)

        // When
        viewModel.fillWithDummyDimensionFieldValues()
        viewModel.showSaveTemplate = false

        // Then
        XCTAssertEqual(viewModel.fieldValues.isEmpty, false)
        XCTAssertEqual(viewModel.areFieldValuesInvalid, false)
    }

    @MainActor
    func test_it_with_all_dimension_field_values_set_saving_template() {
        // Given
        let packagesRepository = MockWooShippingPackagesRepository()
        let siteID: Int64 = 1234
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingAddCustomPackageViewModel(siteID: siteID,
                                                             storeOptions: ShippingLabelStoreOptions(currencySymbol: "$",
                                                                                                     dimensionUnit: "in",
                                                                                                     weightUnit: "oz",
                                                                                                     originCountry: "US"),
                                                             stores: mockStores,
                                                             packagesRepository: packagesRepository)

        // When
        viewModel.fillWithDummyDimensionFieldValues()
        viewModel.showSaveTemplate = true

        // Then
        XCTAssertEqual(viewModel.fieldValues.isEmpty, false)
        XCTAssertEqual(viewModel.areFieldValuesInvalid, true)
    }

    @MainActor
    func test_it_with_all_dimension_weight_field_values_set() {
        // Given
        let packagesRepository = MockWooShippingPackagesRepository()
        let siteID: Int64 = 1234
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingAddCustomPackageViewModel(siteID: siteID,
                                                             storeOptions: ShippingLabelStoreOptions(currencySymbol: "$",
                                                                                                     dimensionUnit: "in",
                                                                                                     weightUnit: "oz",
                                                                                                     originCountry: "US"),
                                                             stores: mockStores,
                                                             packagesRepository: packagesRepository)

        // When
        viewModel.fillWithDummyDimensionFieldValues()
        viewModel.showSaveTemplate = true
        viewModel.fieldValues[.weight] = "1"
        // Then
        XCTAssertEqual(viewModel.fieldValues.isEmpty, false)
        XCTAssertEqual(viewModel.areFieldValuesInvalid, false)
    }

    @MainActor
    func test_validate_custom_package_input_fields_when_init() {
        // Given/When
        let packagesRepository = MockWooShippingPackagesRepository()
        let siteID: Int64 = 1234
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingAddCustomPackageViewModel(siteID: siteID,
                                                             storeOptions: ShippingLabelStoreOptions(currencySymbol: "$",
                                                                                                     dimensionUnit: "in",
                                                                                                     weightUnit: "oz",
                                                                                                     originCountry: "US"),
                                                             stores: mockStores,
                                                             packagesRepository: packagesRepository)

        // Then
        XCTAssertEqual(viewModel.validateCustomPackageInputFields(), false)
    }

    @MainActor
    func test_validate_custom_package_input_fields_when_fields_are_valid() {
        // Given
        let packagesRepository = MockWooShippingPackagesRepository()
        let siteID: Int64 = 1234
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingAddCustomPackageViewModel(siteID: siteID,
                                                             storeOptions: ShippingLabelStoreOptions(currencySymbol: "$",
                                                                                                     dimensionUnit: "in",
                                                                                                     weightUnit: "oz",
                                                                                                     originCountry: "US"),
                                                             stores: mockStores,
                                                             packagesRepository: packagesRepository)

        // When
        viewModel.fillWithDummyFieldValues()

        // Then
        XCTAssertEqual(viewModel.validateCustomPackageInputFields(), true)
    }

    @MainActor
    func test_validate_custom_package_input_fields_when_fields_are_valid_and_save_template_shown() {
        // Given
        let packagesRepository = MockWooShippingPackagesRepository()
        let siteID: Int64 = 1234
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingAddCustomPackageViewModel(siteID: siteID,
                                                             storeOptions: ShippingLabelStoreOptions(currencySymbol: "$",
                                                                                                     dimensionUnit: "in",
                                                                                                     weightUnit: "oz",
                                                                                                     originCountry: "US"),
                                                             stores: mockStores,
                                                             packagesRepository: packagesRepository)

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

    @MainActor
    func test_add_package_action() async {
        // Given
        let dimensionUnit = "cm"
        let weightUnit = "kg"
        let packagesRepository = MockWooShippingPackagesRepository()
        let siteID: Int64 = 1234
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingAddCustomPackageViewModel(siteID: siteID,
                                                             storeOptions: ShippingLabelStoreOptions(currencySymbol: "$",
                                                                                                     dimensionUnit: dimensionUnit,
                                                                                                     weightUnit: weightUnit,
                                                                                                     originCountry: "US"),
                                                             stores: mockStores,
                                                             packagesRepository: packagesRepository)
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

    @MainActor
    func test_save_package_as_template_action() async {
        // Given
        let packagesRepository = WooShippingPackagesRepository()
        let siteID: Int64 = 1234
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingAddCustomPackageViewModel(siteID: siteID,
                                                             storeOptions: ShippingLabelStoreOptions(currencySymbol: "$",
                                                                                                     dimensionUnit: "in",
                                                                                                     weightUnit: "lb",
                                                                                                     originCountry: "US"),
                                                             stores: stores,
                                                             packagesRepository: packagesRepository)
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
