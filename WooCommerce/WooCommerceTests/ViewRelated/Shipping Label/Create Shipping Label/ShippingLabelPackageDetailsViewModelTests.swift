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

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
    }

    override func tearDown() {
        storageManager = nil
        super.tearDown()
    }

    func test_itemsRows_returns_zero_itemsRows_with_empty_items() {

        // Given
        let order = MockOrders().empty().copy(siteID: sampleSiteID)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())
        let viewModel = ShippingLabelPackageDetailsViewModel(order: order,
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
}

private extension ShippingLabelPackageDetailsViewModelTests {
    func insert(_ readOnlyOrderProduct: Yosemite.Product) {
        let product = storage.insertNewObject(ofType: StorageProduct.self)
        product.update(with: readOnlyOrderProduct)
    }

    func insert(_ readOnlyOrderProductVariation: Yosemite.ProductVariation) {
        let productVariation = storage.insertNewObject(ofType: StorageProductVariation.self)
        productVariation.update(with: readOnlyOrderProductVariation)
    }
}
