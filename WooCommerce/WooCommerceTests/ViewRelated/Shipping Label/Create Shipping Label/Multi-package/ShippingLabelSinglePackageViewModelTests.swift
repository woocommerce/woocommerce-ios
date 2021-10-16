import XCTest
@testable import WooCommerce
import Yosemite

class ShippingLabelSinglePackageViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 1234

    func test_itemsRows_returns_zero_itemsRows_with_empty_items() {

        // Given
        let order = MockOrders().empty().copy(siteID: sampleSiteID)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())
        let viewModel = ShippingLabelSinglePackageViewModel(order: order,
                                                          orderItems: [],
                                                          packagesResponse: mockPackageResponse(),
                                                          selectedPackageID: "",
                                                          totalWeight: "",
                                                          onItemMoveRequest: {},
                                                          onPackageSwitch: { _ in },
                                                          onPackagesSync: { _ in },
                                                          formatter: currencyFormatter)

        // Then
        XCTAssertEqual(viewModel.itemsRows.count, 0)

    }

    func test_itemsRows_returns_expected_values() {

        // Given
        let orderItemAttribute = OrderItemAttribute(metaID: 170, name: "Packaging", value: "Box")
        let items: [ShippingLabelPackageItem] = [
            .fake(id: 1, name: "Easter Egg", weight: 123),
            .fake(id: 33, name: "Jacket", weight: 9),
            .fake(id: 23, name: "Italian Jacket", weight: 1),
            .fake(id: 49, name: "Jeans", weight: 0, attributes: [VariationAttributeViewModel(orderItemAttribute: orderItemAttribute)])
        ]

        let expectedFirstItemRow = ItemToFulfillRow(productOrVariationID: 1, title: "Easter Egg", subtitle: "123 kg")
        let expectedLastItemRow = ItemToFulfillRow(productOrVariationID: 49, title: "Jeans", subtitle: "Box・0 kg")
        let order = MockOrders().makeOrder().copy(siteID: sampleSiteID)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())

        // When
        let viewModel = ShippingLabelSinglePackageViewModel(order: order,
                                                          orderItems: items,
                                                          packagesResponse: mockPackageResponse(),
                                                          selectedPackageID: "",
                                                          totalWeight: "",
                                                          onItemMoveRequest: {},
                                                          onPackageSwitch: { _ in },
                                                          onPackagesSync: { _ in },
                                                          formatter: currencyFormatter,
                                                          weightUnit: "kg")

        // Then
        XCTAssertEqual(viewModel.itemsRows.count, 4)
        XCTAssertEqual(viewModel.itemsRows.first?.title, expectedFirstItemRow.title)
        XCTAssertEqual(viewModel.itemsRows.first?.subtitle, expectedFirstItemRow.subtitle)
        XCTAssertEqual(viewModel.itemsRows.last?.title, expectedLastItemRow.title)
        XCTAssertEqual(viewModel.itemsRows.last?.subtitle, expectedLastItemRow.subtitle)
    }

    func test_didSelectPackage_returns_the_expected_value() {
        // Given
        let customPackage = ShippingLabelCustomPackage(isUserDefined: true,
                                                       title: "Box",
                                                       isLetter: true,
                                                       dimensions: "3 x 10 x 4",
                                                       boxWeight: 10,
                                                       maxWeight: 11)
        let order = MockOrders().empty().copy(siteID: sampleSiteID)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())
        let viewModel = ShippingLabelSinglePackageViewModel(order: order,
                                                          orderItems: [],
                                                          packagesResponse: mockPackageResponse(),
                                                          selectedPackageID: "",
                                                          totalWeight: "",
                                                          onItemMoveRequest: {},
                                                          onPackageSwitch: { _ in },
                                                          onPackagesSync: { _ in },
                                                          formatter: currencyFormatter,
                                                          weightUnit: "kg")

        // When
        viewModel.packageListViewModel.didSelectPackage(customPackage.title)

        // Then
        XCTAssertEqual(viewModel.packageListViewModel.selectedCustomPackage, customPackage)
        XCTAssertNil(viewModel.packageListViewModel.selectedPredefinedPackage)
    }

    func test_confirmPackageSelection_returns_the_expected_value() {
        // Given
        let customPackage = ShippingLabelCustomPackage(isUserDefined: true,
                                                       title: "Box",
                                                       isLetter: true,
                                                       dimensions: "3 x 10 x 4",
                                                       boxWeight: 10,
                                                       maxWeight: 11)
        let order = MockOrders().empty().copy(siteID: sampleSiteID)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())

        var packageToTest: ShippingLabelPackageAttributes?
        let packageSwitchHandler: ShippingLabelSinglePackageViewModel.PackageSwitchHandler = { package in
            packageToTest = package
        }
        let viewModel = ShippingLabelSinglePackageViewModel(order: order,
                                                          orderItems: [],
                                                          packagesResponse: mockPackageResponse(),
                                                          selectedPackageID: "Test Box",
                                                          totalWeight: "",
                                                          onItemMoveRequest: {},
                                                          onPackageSwitch: packageSwitchHandler,
                                                          onPackagesSync: { _ in },
                                                          formatter: currencyFormatter,
                                                          weightUnit: "kg")

        // When
        viewModel.packageListViewModel.didSelectPackage(customPackage.title)
        viewModel.packageListViewModel.confirmPackageSelection()

        // Then
        XCTAssertEqual(packageToTest?.packageID, customPackage.title)
        XCTAssertEqual(packageToTest?.totalWeight, "")
        XCTAssertEqual(packageToTest?.items, [])
    }

    func test_showCustomPackagesHeader_returns_the_expected_value() {
        // Given
        let order = MockOrders().empty().copy(siteID: sampleSiteID)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())
        let viewModel = ShippingLabelSinglePackageViewModel(order: order,
                                                          orderItems: [],
                                                          packagesResponse: mockPackageResponse(),
                                                          selectedPackageID: "Test Box",
                                                          totalWeight: "10",
                                                          onItemMoveRequest: {},
                                                          onPackageSwitch: { _ in },
                                                          onPackagesSync: { _ in },
                                                          formatter: currencyFormatter,
                                                          weightUnit: "kg")


        // Then
        XCTAssertTrue(viewModel.packageListViewModel.showCustomPackagesHeader)
    }

    func test_totalWeight_returns_the_expected_value() {
        // Given
        let items: [ShippingLabelPackageItem] = [
            .fake(id: 1, name: "Easter Egg", weight: 120, quantity: 0.5),
            .fake(id: 23, name: "Italian Jacket", weight: 1.44, quantity: 2),
            .fake(id: 49, name: "Jeans", weight: 0)
        ]
        let order = MockOrders().makeOrder().copy(siteID: sampleSiteID)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())

        // When
        let viewModel = ShippingLabelSinglePackageViewModel(order: order,
                                                          orderItems: items,
                                                          packagesResponse: mockPackageResponse(),
                                                          selectedPackageID: "Box",
                                                          totalWeight: "",
                                                          onItemMoveRequest: {},
                                                          onPackageSwitch: { _ in },
                                                          onPackagesSync: { _ in },
                                                          formatter: currencyFormatter,
                                                          weightUnit: "kg")

        // Then
        XCTAssertEqual(viewModel.totalWeight, "72.88")
    }

    func test_totalWeight_returns_the_expected_value_when_already_set() {
        // Given
        let items: [ShippingLabelPackageItem] = [
            .fake(id: 1, name: "Easter Egg", weight: 120),
            .fake(id: 23, name: "Italian Jacket", weight: 1.44),
            .fake(id: 49, name: "Jeans", weight: 0)
        ]
        let order = MockOrders().makeOrder().copy(siteID: sampleSiteID)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())

        // When
        let viewModel = ShippingLabelSinglePackageViewModel(order: order,
                                                          orderItems: items,
                                                          packagesResponse: mockPackageResponse(),
                                                          selectedPackageID: "Box",
                                                          totalWeight: "30",
                                                          onItemMoveRequest: {},
                                                          onPackageSwitch: { _ in },
                                                          onPackagesSync: { _ in },
                                                          formatter: currencyFormatter,
                                                          weightUnit: "kg")

        // Then
        XCTAssertEqual(viewModel.totalWeight, "30")
    }

    func test_isValidTotalWeight_returns_true_initially() {
        // Given
        let order = MockOrders().makeOrder().copy(siteID: sampleSiteID)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())

        // When
        let viewModel = ShippingLabelSinglePackageViewModel(order: order,
                                                          orderItems: [],
                                                          packagesResponse: mockPackageResponse(),
                                                          selectedPackageID: "Test Box",
                                                          totalWeight: "10",
                                                          onItemMoveRequest: {},
                                                          onPackageSwitch: { _ in },
                                                          onPackagesSync: { _ in },
                                                          formatter: currencyFormatter,
                                                          weightUnit: "kg")

        // Then
        XCTAssertTrue(viewModel.isValidTotalWeight)
    }

    func test_isValidTotalWeight_returns_the_expected_value_when_the_totalWeight_is_not_valid() {
        // Given
        let order = MockOrders().makeOrder().copy(siteID: sampleSiteID)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())

        let viewModel = ShippingLabelSinglePackageViewModel(order: order,
                                                          orderItems: [],
                                                          packagesResponse: mockPackageResponse(),
                                                          selectedPackageID: "Test Box",
                                                          totalWeight: "10",
                                                          onItemMoveRequest: {},
                                                          onPackageSwitch: { _ in },
                                                          onPackagesSync: { _ in },
                                                          formatter: currencyFormatter,
                                                          weightUnit: "kg")

        // When
        viewModel.totalWeight = "0.0"

        // Then
        XCTAssertFalse(viewModel.isValidTotalWeight)

        // When
        viewModel.totalWeight = "1..1"

        // Then
        XCTAssertFalse(viewModel.isValidTotalWeight)

        // When
        viewModel.totalWeight = "test"

        // Then
        XCTAssertFalse(viewModel.isValidTotalWeight)
    }

    func test_validatedPackageAttributes_returns_correct_value_when_total_weight_is_valid() {
        // Given
        let items: [ShippingLabelPackageItem] = [.fake(weight: 120, quantity: 0.5)]
        let order = MockOrders().makeOrder().copy(siteID: sampleSiteID)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())

        // When
        let viewModel = ShippingLabelSinglePackageViewModel(order: order,
                                                          orderItems: items,
                                                          packagesResponse: mockPackageResponse(),
                                                          selectedPackageID: "Test Box",
                                                          totalWeight: "10",
                                                          onItemMoveRequest: {},
                                                          onPackageSwitch: { _ in },
                                                          onPackagesSync: { _ in },
                                                          formatter: currencyFormatter,
                                                          weightUnit: "kg")

        // Then
        XCTAssertEqual(viewModel.validatedPackageAttributes?.packageID, "Test Box")
        XCTAssertEqual(viewModel.validatedPackageAttributes?.totalWeight, "10")
        XCTAssertEqual(viewModel.validatedPackageAttributes?.items, items)

        // When
        viewModel.totalWeight = "12"

        // Then
        XCTAssertEqual(viewModel.validatedPackageAttributes?.packageID, "Test Box")
        XCTAssertEqual(viewModel.validatedPackageAttributes?.totalWeight, "12")
        XCTAssertEqual(viewModel.validatedPackageAttributes?.items, items)
    }

    func test_validatedPackageAttributes_returns_nil_when_the_totalWeight_is_not_valid() {
        // Given
        let items: [ShippingLabelPackageItem] = [.fake(weight: 120, quantity: 0.5)]
        let order = MockOrders().makeOrder().copy(siteID: sampleSiteID)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())

        let viewModel = ShippingLabelSinglePackageViewModel(order: order,
                                                          orderItems: items,
                                                          packagesResponse: mockPackageResponse(),
                                                          selectedPackageID: "Test Box",
                                                          totalWeight: "10",
                                                          onItemMoveRequest: {},
                                                          onPackageSwitch: { _ in },
                                                          onPackagesSync: { _ in },
                                                          formatter: currencyFormatter,
                                                          weightUnit: "kg")

        // When
        viewModel.totalWeight = "0.0"

        // Then
        XCTAssertNil(viewModel.validatedPackageAttributes)

        // When
        viewModel.totalWeight = "1..1"

        // Then
        XCTAssertNil(viewModel.validatedPackageAttributes)

        // When
        viewModel.totalWeight = "test"

        // Then
        XCTAssertNil(viewModel.validatedPackageAttributes)
    }

    func test_validatedPackageAttributes_returns_nil_when_original_package_dimensions_is_invalid() {
        // Given
        let items: [ShippingLabelPackageItem] = [.fake(weight: 120, quantity: 0.5)]
        let order = MockOrders().makeOrder().copy(siteID: sampleSiteID)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())

        // When
        let viewModel = ShippingLabelSinglePackageViewModel(order: order,
                                                            orderItems: items,
                                                            packagesResponse: mockPackageResponse(),
                                                            selectedPackageID: "invividual",
                                                            totalWeight: "10",
                                                            isOriginalPackaging: true,
                                                            onItemMoveRequest: {},
                                                            onPackageSwitch: { _ in },
                                                            onPackagesSync: { _ in },
                                                            formatter: currencyFormatter,
                                                            weightUnit: "kg")

        // Then
        XCTAssertEqual(viewModel.validatedPackageAttributes, nil)
    }

    func test_validatedPackageAttributes_returns_correctly_when_original_package_dimensions_is_valid() {
        // Given
        let dimensions = ProductDimensions(length: "2", width: "3", height: "5")
        let items: [ShippingLabelPackageItem] = [.fake(weight: 120, quantity: 0.5, dimensions: dimensions)]
        let order = MockOrders().makeOrder().copy(siteID: sampleSiteID)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())

        // When
        let viewModel = ShippingLabelSinglePackageViewModel(order: order,
                                                            orderItems: items,
                                                            packagesResponse: mockPackageResponse(),
                                                            selectedPackageID: "invividual",
                                                            totalWeight: "",
                                                            isOriginalPackaging: true,
                                                            onItemMoveRequest: {},
                                                            onPackageSwitch: { _ in },
                                                            onPackagesSync: { _ in },
                                                            formatter: currencyFormatter,
                                                            weightUnit: "kg")

        // Then
        XCTAssertEqual(viewModel.validatedPackageAttributes?.packageID, "invividual")
        XCTAssertEqual(viewModel.validatedPackageAttributes?.totalWeight, "60")
        XCTAssertEqual(viewModel.validatedPackageAttributes?.items, items)
    }

    func test_originalPackageDimensions_returns_correctly_when_package_has_no_dimensions() {
        // Given
        let item = ShippingLabelPackageItem.fake()
        let order = MockOrders().makeOrder().copy(siteID: sampleSiteID)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())

        // When
        let viewModel = ShippingLabelSinglePackageViewModel(order: order,
                                                            orderItems: [item],
                                                            packagesResponse: mockPackageResponse(),
                                                            selectedPackageID: "invividual",
                                                            totalWeight: "",
                                                            isOriginalPackaging: true,
                                                            onItemMoveRequest: {},
                                                            onPackageSwitch: { _ in },
                                                            onPackagesSync: { _ in },
                                                            formatter: currencyFormatter,
                                                            weightUnit: "kg")

        // Then
        XCTAssertEqual(viewModel.originalPackageDimensions, "0 x 0 x 0 in")
        XCTAssertFalse(viewModel.hasValidPackageDimensions)
    }

    func test_originalPackageDimensions_returns_correctly_when_package_has_dimensions() {
        // Given
        let dimensions = ProductDimensions(length: "2", width: "3", height: "5")
        let item = ShippingLabelPackageItem.fake(dimensions: dimensions)
        let order = MockOrders().makeOrder().copy(siteID: sampleSiteID)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())

        // When
        let viewModel = ShippingLabelSinglePackageViewModel(order: order,
                                                            orderItems: [item],
                                                            packagesResponse: mockPackageResponse(),
                                                            selectedPackageID: "invividual",
                                                            totalWeight: "",
                                                            isOriginalPackaging: true,
                                                            onItemMoveRequest: {},
                                                            onPackageSwitch: { _ in },
                                                            onPackagesSync: { _ in },
                                                            formatter: currencyFormatter,
                                                            weightUnit: "kg")

        // Then
        XCTAssertEqual(viewModel.originalPackageDimensions, "2 x 3 x 5 in")
        XCTAssertTrue(viewModel.hasValidPackageDimensions)
    }
}

// MARK: - Mocks
private extension ShippingLabelSinglePackageViewModelTests {
    func mockPackageResponse(withCustom: Bool = true, withPredefined: Bool = true) -> ShippingLabelPackagesResponse {
        let storeOptions = ShippingLabelStoreOptions(currencySymbol: "$",
                                                     dimensionUnit: "in",
                                                     weightUnit: "oz",
                                                     originCountry: "US")

        let customPackages = [
            ShippingLabelCustomPackage(isUserDefined: true,
                                       title: "Box",
                                       isLetter: true,
                                       dimensions: "3 x 10 x 4",
                                       boxWeight: 10,
                                       maxWeight: 11),
            ShippingLabelCustomPackage(isUserDefined: true,
                                       title: "Box n°2",
                                       isLetter: true,
                                       dimensions: "30 x 1 x 20",
                                       boxWeight: 2,
                                       maxWeight: 4),
            ShippingLabelCustomPackage(isUserDefined: true,
                                       title: "Box n°3",
                                       isLetter: true,
                                       dimensions: "10 x 40 x 3",
                                       boxWeight: 7,
                                       maxWeight: 10)]

        let predefinedOptions = [ShippingLabelPredefinedOption(title: "USPS",
                                                               providerID: "USPS",
                                                               predefinedPackages: [ShippingLabelPredefinedPackage(id: "package-1",
                                                                                                                   title: "Small",
                                                                                                                   isLetter: true,
                                                                                                                   dimensions: "3 x 4 x 5"),
                                                                                    ShippingLabelPredefinedPackage(id: "package-2",
                                                                                                                   title: "Big",
                                                                                                                   isLetter: true,
                                                                                                                   dimensions: "5 x 7 x 9")])]

        let packagesResponse = ShippingLabelPackagesResponse(storeOptions: storeOptions,
                                                             customPackages: withCustom ? customPackages : [],
                                                             predefinedOptions: withPredefined ? predefinedOptions : [],
                                                             unactivatedPredefinedOptions: [])

        return packagesResponse
    }
}
