import XCTest
@testable import WooCommerce
import Yosemite

class ShippingLabelPackageItemViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 1234

    func test_itemsRows_returns_zero_itemsRows_with_empty_items() {

        // Given
        let order = MockOrders().empty().copy(siteID: sampleSiteID)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())
        let viewModel = ShippingLabelPackageItemViewModel(order: order,
                                                          orderItems: order.items,
                                                          packagesResponse: mockPackageResponse(),
                                                          selectedPackageID: "",
                                                          totalWeight: "",
                                                          products: [],
                                                          productVariations: [],
                                                          onPackageSwitch: { _ in },
                                                          onPackagesSync: { _ in },
                                                          formatter: currencyFormatter)

        // Then
        XCTAssertEqual(viewModel.itemsRows.count, 0)

    }

    func test_itemsRows_returns_expected_values() {

        // Given
        let orderItemAttributes = [OrderItemAttribute(metaID: 170, name: "Packaging", value: "Box")]
        let items = [MockOrderItem.sampleItem(name: "Easter Egg", productID: 1, quantity: 1),
                     MockOrderItem.sampleItem(name: "Jacket", productID: 33, quantity: 1),
                     MockOrderItem.sampleItem(name: "Italian Jacket", productID: 23, quantity: 2),
                     MockOrderItem.sampleItem(name: "Jeans",
                                              productID: 49,
                                              variationID: 49,
                                              quantity: 1,
                                              attributes: orderItemAttributes)]
        let expectedFirstItemRow = ItemToFulfillRow(title: "Easter Egg", subtitle: "123 kg")
        let expectedLastItemRow = ItemToFulfillRow(title: "Jeans", subtitle: "Box・0 kg")
        let order = MockOrders().makeOrder().copy(siteID: sampleSiteID, items: items)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())

        let product1 = Product.fake().copy(siteID: sampleSiteID, productID: 1, virtual: false, weight: "123")
        let product2 = Product.fake().copy(siteID: sampleSiteID, productID: 33, virtual: true, weight: "9")
        let product3 = Product.fake().copy(siteID: sampleSiteID, productID: 23, virtual: false, weight: "1")
        let variation = ProductVariation.fake().copy(siteID: sampleSiteID,
                                                     productID: 49,
                                                     productVariationID: 49,
                                                     attributes: [ProductVariationAttribute(id: 1, name: "Color", option: "Blue")])

        // When
        let viewModel = ShippingLabelPackageItemViewModel(order: order,
                                                          orderItems: items,
                                                          packagesResponse: mockPackageResponse(),
                                                          selectedPackageID: "",
                                                          totalWeight: "",
                                                          products: [product1, product2, product3],
                                                          productVariations: [variation],
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
        let viewModel = ShippingLabelPackageItemViewModel(order: order,
                                                          orderItems: order.items,
                                                          packagesResponse: mockPackageResponse(),
                                                          selectedPackageID: "",
                                                          totalWeight: "",
                                                          products: [],
                                                          productVariations: [],
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
        let packageSwitchHandler: ShippingLabelPackageItemViewModel.PackageSwitchHandler = { package in
            packageToTest = package
        }
        let viewModel = ShippingLabelPackageItemViewModel(order: order,
                                                          orderItems: order.items,
                                                          packagesResponse: mockPackageResponse(),
                                                          selectedPackageID: "Test Box",
                                                          totalWeight: "",
                                                          products: [],
                                                          productVariations: [],
                                                          onPackageSwitch: packageSwitchHandler,
                                                          onPackagesSync: { _ in },
                                                          formatter: currencyFormatter,
                                                          weightUnit: "kg")

        // When
        viewModel.packageListViewModel.didSelectPackage(customPackage.title)
        viewModel.packageListViewModel.confirmPackageSelection()

        // Then
        XCTAssertEqual(packageToTest, ShippingLabelPackageAttributes(packageID: customPackage.title,
                                                                     totalWeight: "",
                                                                     productIDs: order.items.map { $0.productOrVariationID }))
    }

    func test_showCustomPackagesHeader_returns_the_expected_value() {
        // Given
        let order = MockOrders().empty().copy(siteID: sampleSiteID)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())
        let viewModel = ShippingLabelPackageItemViewModel(order: order,
                                                          orderItems: order.items,
                                                          packagesResponse: mockPackageResponse(),
                                                          selectedPackageID: "Test Box",
                                                          totalWeight: "10",
                                                          products: [],
                                                          productVariations: [],
                                                          onPackageSwitch: { _ in },
                                                          onPackagesSync: { _ in },
                                                          formatter: currencyFormatter,
                                                          weightUnit: "kg")


        // Then
        XCTAssertTrue(viewModel.packageListViewModel.showCustomPackagesHeader)
    }

    func test_totalWeight_returns_the_expected_value() {
        // Given
        let orderItemAttributes = [OrderItemAttribute(metaID: 170, name: "Packaging", value: "Box")]
        let items = [MockOrderItem.sampleItem(name: "Easter Egg", productID: 1, quantity: 0.5),
                     MockOrderItem.sampleItem(name: "Jacket", productID: 33, quantity: 1),
                     MockOrderItem.sampleItem(name: "Italian Jacket", productID: 23, quantity: 2),
                     MockOrderItem.sampleItem(name: "Jeans",
                                              productID: 49,
                                              variationID: 49,
                                              quantity: 1,
                                              attributes: orderItemAttributes)]
        let order = MockOrders().makeOrder().copy(siteID: sampleSiteID, items: items)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())

        // When
        let product1 = Product.fake().copy(siteID: sampleSiteID, productID: 1, virtual: false, weight: "120")
        let product2 = Product.fake().copy(siteID: sampleSiteID, productID: 33, virtual: true, weight: "9")
        let product3 = Product.fake().copy(siteID: sampleSiteID, productID: 23, virtual: false, weight: "1.44")
        let variation = ProductVariation.fake().copy(siteID: sampleSiteID,
                                                     productID: 49,
                                                     productVariationID: 49,
                                                     attributes: [ProductVariationAttribute(id: 1, name: "Color", option: "Blue")])

        let viewModel = ShippingLabelPackageItemViewModel(order: order,
                                                          orderItems: order.items,
                                                          packagesResponse: mockPackageResponse(),
                                                          selectedPackageID: "Box",
                                                          totalWeight: "",
                                                          products: [product1, product2, product3],
                                                          productVariations: [variation],
                                                          onPackageSwitch: { _ in },
                                                          onPackagesSync: { _ in },
                                                          formatter: currencyFormatter,
                                                          weightUnit: "kg")

        // Then
        XCTAssertEqual(viewModel.totalWeight, "72.88")
    }

    func test_totalWeight_returns_the_expected_value_when_already_set() {
        // Given
        let orderItemAttributes = [OrderItemAttribute(metaID: 170, name: "Packaging", value: "Box")]
        let items = [MockOrderItem.sampleItem(name: "Easter Egg", productID: 1, quantity: 1),
                     MockOrderItem.sampleItem(name: "Jacket", productID: 33, quantity: 1),
                     MockOrderItem.sampleItem(name: "Italian Jacket", productID: 23, quantity: 2),
                     MockOrderItem.sampleItem(name: "Jeans",
                                              productID: 49,
                                              variationID: 49,
                                              quantity: 1,
                                              attributes: orderItemAttributes)]
        let order = MockOrders().makeOrder().copy(siteID: sampleSiteID, items: items)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())

        // When
        let product1 = Product.fake().copy(siteID: sampleSiteID, productID: 1, virtual: false, weight: "123")
        let product2 = Product.fake().copy(siteID: sampleSiteID, productID: 33, virtual: true, weight: "9")
        let product3 = Product.fake().copy(siteID: sampleSiteID, productID: 23, virtual: false, weight: "1")
        let variation = ProductVariation.fake().copy(siteID: sampleSiteID,
                                                     productID: 49,
                                                     productVariationID: 49,
                                                     attributes: [ProductVariationAttribute(id: 1, name: "Color", option: "Blue")])

        let viewModel = ShippingLabelPackageItemViewModel(order: order,
                                                          orderItems: order.items,
                                                          packagesResponse: mockPackageResponse(),
                                                          selectedPackageID: "Box",
                                                          totalWeight: "30",
                                                          products: [product1, product2, product3],
                                                          productVariations: [variation],
                                                          onPackageSwitch: { _ in },
                                                          onPackagesSync: { _ in },
                                                          formatter: currencyFormatter,
                                                          weightUnit: "kg")

        // Then
        XCTAssertEqual(viewModel.totalWeight, "30")
    }

    func test_isValidTotalWeight_returns_true_initially() {
        // Given
        let items = [MockOrderItem.sampleItem(name: "Easter Egg", productID: 1, quantity: 0.5)]
        let order = MockOrders().makeOrder().copy(siteID: sampleSiteID, items: items)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())

        // When
        let product = Product.fake().copy(siteID: sampleSiteID, productID: 1, virtual: false, weight: "120")
        let viewModel = ShippingLabelPackageItemViewModel(order: order,
                                                          orderItems: order.items,
                                                          packagesResponse: mockPackageResponse(),
                                                          selectedPackageID: "Test Box",
                                                          totalWeight: "10",
                                                          products: [product],
                                                          productVariations: [],
                                                          onPackageSwitch: { _ in },
                                                          formatter: currencyFormatter,
                                                          weightUnit: "kg")

        // Then
        XCTAssertTrue(viewModel.isValidTotalWeight)
    }

    func test_isValidTotalWeight_returns_the_expected_value_when_the_totalWeight_is_not_valid() {
        // Given
        // Given
        let order = MockOrders().makeOrder().copy(siteID: sampleSiteID, items: [])
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())

        let viewModel = ShippingLabelPackageItemViewModel(order: order,
                                                          orderItems: order.items,
                                                          packagesResponse: mockPackageResponse(),
                                                          selectedPackageID: "Test Box",
                                                          totalWeight: "10",
                                                          products: [],
                                                          productVariations: [],
                                                          onPackageSwitch: { _ in },
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
        let items = [MockOrderItem.sampleItem(name: "Easter Egg", productID: 1, quantity: 0.5)]
        let order = MockOrders().makeOrder().copy(siteID: sampleSiteID, items: items)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())

        // When
        let product = Product.fake().copy(siteID: sampleSiteID, productID: 1, virtual: false, weight: "120")
        let viewModel = ShippingLabelPackageItemViewModel(order: order,
                                                          orderItems: order.items,
                                                          packagesResponse: mockPackageResponse(),
                                                          selectedPackageID: "Test Box",
                                                          totalWeight: "10",
                                                          products: [product],
                                                          productVariations: [],
                                                          onPackageSwitch: { _ in },
                                                          formatter: currencyFormatter,
                                                          weightUnit: "kg")

        // Then
        let expectedPackage1 = ShippingLabelPackageAttributes(packageID: "Test Box", totalWeight: "10", productIDs: [1])
        XCTAssertEqual(viewModel.validatedPackageAttributes, expectedPackage1)

        // When
        viewModel.totalWeight = "12"

        // Then
        let expectedPackage2 = ShippingLabelPackageAttributes(packageID: "Test Box", totalWeight: "12", productIDs: [1])
        XCTAssertEqual(viewModel.validatedPackageAttributes, expectedPackage2)
    }

    func test_validatedPackageAttributes_returns_nil_when_the_totalWeight_is_not_valid() {
        // Given
        // Given
        let items = [MockOrderItem.sampleItem(name: "Easter Egg", productID: 1, quantity: 0.5)]
        let order = MockOrders().makeOrder().copy(siteID: sampleSiteID, items: items)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())

        let product = Product.fake().copy(siteID: sampleSiteID, productID: 1, virtual: false, weight: "120")
        let viewModel = ShippingLabelPackageItemViewModel(order: order,
                                                          orderItems: order.items,
                                                          packagesResponse: mockPackageResponse(),
                                                          selectedPackageID: "Test Box",
                                                          totalWeight: "10",
                                                          products: [product],
                                                          productVariations: [],
                                                          onPackageSwitch: { _ in },
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
}

// MARK: - Mocks
private extension ShippingLabelPackageItemViewModelTests {
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
