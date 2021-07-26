import XCTest
@testable import WooCommerce
import Yosemite
@testable import Storage


final class ShippingLabelPackageDetailsViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 1234

    private var storageManager: StorageManagerType!

    private var storage: StorageType {
        storageManager.viewStorage
    }

    private var stores: MockStoresManager!

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
        stores = MockStoresManager(sessionManager: SessionManager.makeForTesting(authenticated: true))
    }

    override func tearDown() {
        storageManager = nil
        stores = nil
        super.tearDown()
    }

    func test_itemsRows_returns_zero_itemsRows_with_empty_items() {

        // Given
        let order = MockOrders().empty().copy(siteID: sampleSiteID)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())
        let viewModel = ShippingLabelPackageDetailsViewModel(order: order,
                                                             packagesResponse: mockPackageResponse(),
                                                             selectedPackageID: nil,
                                                             totalWeight: nil,
                                                             formatter: currencyFormatter,
                                                             storageManager: storageManager)

        // Then
        XCTAssertEqual(viewModel.itemsRows.count, 0)

    }

    func test_itemsRows_returns_expected_values() {

        // Given
        let expect = expectation(description: "itemsRows returns expected values")

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
        let viewModel = ShippingLabelPackageDetailsViewModel(order: order,
                                                             packagesResponse: mockPackageResponse(),
                                                             selectedPackageID: nil,
                                                             totalWeight: nil,
                                                             formatter: currencyFormatter,
                                                             storageManager: storageManager,
                                                             weightUnit: "kg")
        XCTAssertEqual(viewModel.itemsRows.count, 0)

        // When
        insert(Product.fake().copy(siteID: sampleSiteID, productID: 1, virtual: false, weight: "123"))
        insert(Product.fake().copy(siteID: sampleSiteID, productID: 33, virtual: true, weight: "9"))
        insert(Product.fake().copy(siteID: sampleSiteID, productID: 23, virtual: false, weight: "1"))
        insert(ProductVariation.fake().copy(siteID: sampleSiteID,
                                            productID: 49,
                                            productVariationID: 49,
                                            attributes: [ProductVariationAttribute(id: 1, name: "Color", option: "Blue")]))

        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertEqual(viewModel.itemsRows.count, 4)
            XCTAssertEqual(viewModel.itemsRows.first?.title, expectedFirstItemRow.title)
            XCTAssertEqual(viewModel.itemsRows.first?.subtitle, expectedFirstItemRow.subtitle)
            XCTAssertEqual(viewModel.itemsRows.last?.title, expectedLastItemRow.title)
            XCTAssertEqual(viewModel.itemsRows.last?.subtitle, expectedLastItemRow.subtitle)
            expect.fulfill()
        }

        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
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
        let viewModel = ShippingLabelPackageDetailsViewModel(order: order,
                                                             packagesResponse: mockPackageResponse(),
                                                             selectedPackageID: nil,
                                                             totalWeight: nil,
                                                             formatter: currencyFormatter,
                                                             stores: stores,
                                                             storageManager: storageManager,
                                                             weightUnit: "kg")


        XCTAssertNil(viewModel.selectedCustomPackage)
        XCTAssertNil(viewModel.selectedPredefinedPackage)

        // When
        viewModel.didSelectPackage(customPackage.title)

        // Then
        XCTAssertEqual(viewModel.selectedCustomPackage, customPackage)
        XCTAssertNil(viewModel.selectedPredefinedPackage)
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
        let viewModel = ShippingLabelPackageDetailsViewModel(order: order,
                                                             packagesResponse: mockPackageResponse(),
                                                             selectedPackageID: nil,
                                                             totalWeight: nil,
                                                             formatter: currencyFormatter,
                                                             stores: stores,
                                                             storageManager: storageManager,
                                                             weightUnit: "kg")

        XCTAssertNil(viewModel.selectedCustomPackage)
        XCTAssertNil(viewModel.selectedPredefinedPackage)

        // When
        viewModel.didSelectPackage(customPackage.title)
        viewModel.confirmPackageSelection()

        // Then
        XCTAssertEqual(viewModel.selectedPackageID, customPackage.title)
    }

    func test_showCustomPackagesHeader_returns_the_expected_value() {
        // Given
        let order = MockOrders().empty().copy(siteID: sampleSiteID)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())
        let viewModel = ShippingLabelPackageDetailsViewModel(order: order,
                                                             packagesResponse: mockPackageResponse(),
                                                             selectedPackageID: nil,
                                                             totalWeight: nil,
                                                             formatter: currencyFormatter,
                                                             stores: stores,
                                                             storageManager: storageManager,
                                                             weightUnit: "kg")


        // Then
        XCTAssertTrue(viewModel.showCustomPackagesHeader)
    }

    func test_selected_package_defaults_to_last_selected_package() {
        // Given
        insert(MockShippingLabelAccountSettings.sampleAccountSettings(siteID: sampleSiteID, lastSelectedPackageID: "package-1"))
        let order = MockOrders().empty().copy(siteID: sampleSiteID)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())
        let viewModel = ShippingLabelPackageDetailsViewModel(order: order,
                                                             packagesResponse: mockPackageResponse(),
                                                             selectedPackageID: nil,
                                                             totalWeight: nil,
                                                             formatter: currencyFormatter,
                                                             stores: stores,
                                                             storageManager: storageManager,
                                                             weightUnit: "kg")

        // Then
        XCTAssertEqual(viewModel.selectedPackageID, "package-1")
        XCTAssertEqual(viewModel.selectedPackageName, "Small")
    }

    func test_isPackageDetailsDoneButtonEnabled_returns_the_expected_value() {
        // Given
        let order = MockOrders().empty().copy(siteID: sampleSiteID)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())
        let viewModel = ShippingLabelPackageDetailsViewModel(order: order,
                                                             packagesResponse: mockPackageResponse(),
                                                             selectedPackageID: nil,
                                                             totalWeight: nil,
                                                             formatter: currencyFormatter,
                                                             stores: stores,
                                                             storageManager: storageManager,
                                                             weightUnit: "kg")

        XCTAssertFalse(viewModel.isPackageDetailsDoneButtonEnabled())

        // When
        viewModel.totalWeight = "10"
        viewModel.selectedPackageID = "sample-package"

        // Then
        XCTAssertTrue(viewModel.isPackageDetailsDoneButtonEnabled())
    }

    func test_isPackageDetailsDoneButtonEnabled_returns_the_expected_value_when_the_totalWeight_is_not_valid() {
        // Given
        let order = MockOrders().empty().copy(siteID: sampleSiteID)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())
        let viewModel = ShippingLabelPackageDetailsViewModel(order: order,
                                                             packagesResponse: mockPackageResponse(),
                                                             selectedPackageID: nil,
                                                             totalWeight: nil,
                                                             formatter: currencyFormatter,
                                                             stores: stores,
                                                             storageManager: storageManager,
                                                             weightUnit: "kg")

        XCTAssertFalse(viewModel.isPackageDetailsDoneButtonEnabled())

        // When
        viewModel.totalWeight = "0"
        viewModel.selectedPackageID = "sample-package"

        // Then
        XCTAssertFalse(viewModel.isPackageDetailsDoneButtonEnabled())

        // When
        viewModel.totalWeight = "0.0"

        // Then
        XCTAssertFalse(viewModel.isPackageDetailsDoneButtonEnabled())

        // When
        viewModel.totalWeight = "1..1"

        // Then
        XCTAssertFalse(viewModel.isPackageDetailsDoneButtonEnabled())

        // When
        viewModel.totalWeight = "test"

        // Then
        XCTAssertFalse(viewModel.isPackageDetailsDoneButtonEnabled())
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
        insert(Product.fake().copy(siteID: sampleSiteID, productID: 1, virtual: false, weight: "120"))
        insert(Product.fake().copy(siteID: sampleSiteID, productID: 33, virtual: true, weight: "9"))
        insert(Product.fake().copy(siteID: sampleSiteID, productID: 23, virtual: false, weight: "1.44"))
        insert(ProductVariation.fake().copy(siteID: sampleSiteID,
                                            productID: 49,
                                            productVariationID: 49,
                                            attributes: [ProductVariationAttribute(id: 1, name: "Color", option: "Blue")]))


        let viewModel = ShippingLabelPackageDetailsViewModel(order: order,
                                                             packagesResponse: mockPackageResponse(),
                                                             selectedPackageID: "Box",
                                                             totalWeight: nil,
                                                             formatter: currencyFormatter,
                                                             storageManager: storageManager,
                                                             weightUnit: "kg")


        // Then
        XCTAssertEqual(viewModel.totalWeight, "72.88")
    }

    func test_totalWeight_returns_the_expected_value_when_already_set() {
        // Given
        let expect = expectation(description: "totalWeight returns expected value when already set")

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
        insert(Product.fake().copy(siteID: sampleSiteID, productID: 1, virtual: false, weight: "123"))
        insert(Product.fake().copy(siteID: sampleSiteID, productID: 33, virtual: true, weight: "9"))
        insert(Product.fake().copy(siteID: sampleSiteID, productID: 23, virtual: false, weight: "1"))
        insert(ProductVariation.fake().copy(siteID: sampleSiteID,
                                            productID: 49,
                                            productVariationID: 49,
                                            attributes: [ProductVariationAttribute(id: 1, name: "Color", option: "Blue")]))


        let viewModel = ShippingLabelPackageDetailsViewModel(order: order,
                                                             packagesResponse: mockPackageResponse(),
                                                             selectedPackageID: nil,
                                                             totalWeight: "30",
                                                             formatter: currencyFormatter,
                                                             storageManager: storageManager,
                                                             weightUnit: "kg")
        XCTAssertEqual(viewModel.totalWeight, "30")

        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertEqual(viewModel.totalWeight, "30")
            expect.fulfill()
        }

        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    func test_totalWeight_updates_when_selected_package_changes() {
        // Given
        let items = [MockOrderItem.sampleItem(name: "Easter Egg", productID: 1, quantity: 1)]
        let order = MockOrders().makeOrder().copy(siteID: sampleSiteID, items: items)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())

        // When
        insert(Product.fake().copy(siteID: sampleSiteID, productID: 1, virtual: false, weight: "120"))

        let viewModel = ShippingLabelPackageDetailsViewModel(order: order,
                                                             packagesResponse: mockPackageResponse(),
                                                             selectedPackageID: nil,
                                                             totalWeight: nil,
                                                             formatter: currencyFormatter,
                                                             storageManager: storageManager,
                                                             weightUnit: "kg")

        // Then
        XCTAssertEqual(viewModel.totalWeight, "120.0")

        // When
        viewModel.didSelectPackage("Box")
        viewModel.confirmPackageSelection()

        // Then
        XCTAssertEqual(viewModel.totalWeight, "130.0")
    }

    func test_totalWeight_does_not_update_when_initial_weight_is_arbitrary_value() {
        // Given
        let items = [MockOrderItem.sampleItem(name: "Easter Egg", productID: 1, quantity: 1)]
        let order = MockOrders().makeOrder().copy(siteID: sampleSiteID, items: items)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())

        // When
        insert(Product.fake().copy(siteID: sampleSiteID, productID: 1, virtual: false, weight: "120"))

        let viewModel = ShippingLabelPackageDetailsViewModel(order: order,
                                                             packagesResponse: mockPackageResponse(),
                                                             selectedPackageID: nil,
                                                             totalWeight: "500",
                                                             formatter: currencyFormatter,
                                                             storageManager: storageManager,
                                                             weightUnit: "kg")

        // Then
        XCTAssertEqual(viewModel.totalWeight, "500")

        // When new package with additional weight is selected
        viewModel.didSelectPackage("Box")
        viewModel.confirmPackageSelection()

        // Then
        XCTAssertEqual(viewModel.totalWeight, "500")
    }

    func test_totalWeight_does_not_update_after_new_weight_is_input_manually() {
        // Given
        let items = [MockOrderItem.sampleItem(name: "Easter Egg", productID: 1, quantity: 1)]
        let order = MockOrders().makeOrder().copy(siteID: sampleSiteID, items: items)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())

        // When
        insert(Product.fake().copy(siteID: sampleSiteID, productID: 1, virtual: false, weight: "120"))

        let viewModel = ShippingLabelPackageDetailsViewModel(order: order,
                                                             packagesResponse: mockPackageResponse(),
                                                             selectedPackageID: nil,
                                                             totalWeight: nil,
                                                             formatter: currencyFormatter,
                                                             storageManager: storageManager,
                                                             weightUnit: "kg")

        // Then
        XCTAssertEqual(viewModel.totalWeight, "120.0")

        // When new weight is input manually
        viewModel.totalWeight = "500"
        viewModel.isPackageWeightEdited = true

        // Then
        XCTAssertEqual(viewModel.totalWeight, "500")

        // When new package with additional weight is selected
        viewModel.didSelectPackage("Box")
        viewModel.confirmPackageSelection()

        // Then
        XCTAssertEqual(viewModel.totalWeight, "500")
    }
}

// MARK: - Utils
private extension ShippingLabelPackageDetailsViewModelTests {
    func insert(_ readOnlyOrderProduct: Yosemite.Product) {
        let product = storage.insertNewObject(ofType: StorageProduct.self)
        product.update(with: readOnlyOrderProduct)
    }

    func insert(_ readOnlyOrderProductVariation: Yosemite.ProductVariation) {
        let productVariation = storage.insertNewObject(ofType: StorageProductVariation.self)
        productVariation.update(with: readOnlyOrderProductVariation)
    }

    func insert(_ readOnlyAccountSettings: Yosemite.ShippingLabelAccountSettings) {
        let accountSettings = storage.insertNewObject(ofType: StorageShippingLabelAccountSettings.self)
        accountSettings.update(with: readOnlyAccountSettings)
    }
}

// MARK: - Mocks
private extension ShippingLabelPackageDetailsViewModelTests {
    func mockPackageResponse() -> ShippingLabelPackagesResponse {
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

        let predefinedOptions = [ShippingLabelPredefinedOption(title: "USPS", predefinedPackages: [ShippingLabelPredefinedPackage(id: "package-1",
                                                                                                                                  title: "Small",
                                                                                                                                  isLetter: true,
                                                                                                                                  dimensions: "3 x 4 x 5"),
                                                                                                   ShippingLabelPredefinedPackage(id: "package-2",
                                                                                                                                  title: "Big",
                                                                                                                                  isLetter: true,
                                                                                                                                  dimensions: "5 x 7 x 9")])]

        let packagesResponse = ShippingLabelPackagesResponse(storeOptions: storeOptions, customPackages: customPackages, predefinedOptions: predefinedOptions)

        return packagesResponse
    }
}
