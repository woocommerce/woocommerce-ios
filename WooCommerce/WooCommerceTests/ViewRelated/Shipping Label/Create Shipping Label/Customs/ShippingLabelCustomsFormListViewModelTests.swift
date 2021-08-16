import XCTest
@testable import WooCommerce
import Yosemite
@testable import Storage

class ShippingLabelCustomsFormListViewModelTests: XCTestCase {

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

    func test_customsForms_items_are_updated_correctly_after_fetching_products_and_variations() {
        // Given
        let orderItemAttributes = [OrderItemAttribute(metaID: 170, name: "Packaging", value: "Box")]
        let items = [MockOrderItem.sampleItem(name: "Easter Egg", productID: 1, quantity: 0.5, price: 15),
                     MockOrderItem.sampleItem(name: "Jeans",
                                              productID: 49,
                                              variationID: 49,
                                              quantity: 1,
                                              price: 49,
                                              attributes: orderItemAttributes)]
        let order = MockOrders().makeOrder().copy(siteID: sampleSiteID, items: items)
        let customsForm = ShippingLabelCustomsForm(packageID: "Custom package", packageName: "Custom package", productIDs: [1, 49])

        // When
        insert(Product.fake().copy(siteID: sampleSiteID, productID: 1, virtual: false, weight: "120.0"))
        insert(ProductVariation.fake().copy(siteID: sampleSiteID,
                                            productID: 49,
                                            productVariationID: 49,
                                            attributes: [ProductVariationAttribute(id: 1, name: "Color", option: "Blue")],
                                            weight: "10.0"))
        let viewModel = ShippingLabelCustomsFormListViewModel(order: order,
                                                              customsForms: [customsForm],
                                                              countries: [],
                                                              itnValidationRequired: false,
                                                              storageManager: storageManager)

        // Then
        let form = viewModel.customsForms.first
        XCTAssertEqual(form?.items.count, 2)
        XCTAssertEqual(form?.items.first?.description, items.first?.name)
        XCTAssertEqual(form?.items.first?.productID, items.first?.productID)
        XCTAssertEqual(form?.items.first?.quantity, items.first?.quantity)
        XCTAssertEqual(form?.items.first?.weight, Double(120))
        XCTAssertEqual(form?.items.first?.value, items.first?.price.doubleValue)

        XCTAssertEqual(form?.items.last?.description, items.last?.name)
        XCTAssertEqual(form?.items.last?.productID, items.last?.productID)
        XCTAssertEqual(form?.items.last?.quantity, items.last?.quantity)
        XCTAssertEqual(form?.items.last?.weight, Double(10))
        XCTAssertEqual(form?.items.last?.value, items.last?.price.doubleValue)
    }

    func test_virtual_products_are_excluded_in_customs_item_list() {
        // Given
        let items = [MockOrderItem.sampleItem(name: "Easter Egg", productID: 1, quantity: 0.5, price: 15),
                     MockOrderItem.sampleItem(name: "Ebook", productID: 49, quantity: 1, price: 15)]
        let order = MockOrders().makeOrder().copy(siteID: sampleSiteID, items: items)
        let customsForm = ShippingLabelCustomsForm(packageID: "Custom package", packageName: "Custom package", productIDs: [1, 49])

        // When
        insert(Product.fake().copy(siteID: sampleSiteID, productID: 1, virtual: false, weight: "120.0"))
        insert(Product.fake().copy(siteID: sampleSiteID, productID: 49, virtual: true, weight: "0"))
        let viewModel = ShippingLabelCustomsFormListViewModel(order: order, customsForms: [customsForm], countries: [], storageManager: storageManager)

        // Then
        let form = viewModel.customsForms.first
        XCTAssertEqual(form?.items.count, 1)
        XCTAssertEqual(form?.items.first?.description, items.first?.name)
        XCTAssertEqual(form?.items.first?.productID, items.first?.productID)
        XCTAssertEqual(form?.items.first?.quantity, items.first?.quantity)
        XCTAssertEqual(form?.items.first?.weight, Double(120))
        XCTAssertEqual(form?.items.first?.value, items.first?.price.doubleValue)
    }

    func test_nonexistent_products_are_excluded_in_customs_item_list() {
        // Given
        let items = [MockOrderItem.sampleItem(name: "Easter Egg", productID: 1, quantity: 0.5, price: 15),
                     MockOrderItem.sampleItem(name: "Ebook", productID: 49, quantity: 1, price: 15)]
        let order = MockOrders().makeOrder().copy(siteID: sampleSiteID, items: items)
        let customsForm = ShippingLabelCustomsForm(packageID: "Custom package", packageName: "Custom package", productIDs: [1, 49])

        // When
        insert(Product.fake().copy(siteID: sampleSiteID, productID: 1, virtual: false, weight: "120.0"))
        let viewModel = ShippingLabelCustomsFormListViewModel(order: order, customsForms: [customsForm], countries: [], storageManager: storageManager)

        // Then
        let form = viewModel.customsForms.first
        XCTAssertEqual(form?.items.count, 1)
        XCTAssertEqual(form?.items.first?.description, items.first?.name)
        XCTAssertEqual(form?.items.first?.productID, items.first?.productID)
        XCTAssertEqual(form?.items.first?.quantity, items.first?.quantity)
        XCTAssertEqual(form?.items.first?.weight, Double(120))
        XCTAssertEqual(form?.items.first?.value, items.first?.price.doubleValue)
    }
}

// MARK: - Utils
private extension ShippingLabelCustomsFormListViewModelTests {
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
