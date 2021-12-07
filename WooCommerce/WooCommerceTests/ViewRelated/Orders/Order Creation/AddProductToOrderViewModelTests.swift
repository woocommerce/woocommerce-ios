import XCTest
import Yosemite
@testable import WooCommerce
@testable import Storage

class AddProductToOrderViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 123
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

    func test_view_model_adds_product_rows_with_unchangeable_quantity() {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, statusKey: "publish")
        insert(product)

        // When
        let viewModel = AddProductToOrderViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // Then
        XCTAssertEqual(viewModel.productRows.count, 1)

        let productRow = viewModel.productRows[0]
        XCTAssertFalse(productRow.canChangeQuantity, "Product row canChangeQuantity property should be false but is true instead")
    }

    func test_products_include_all_product_types_except_variable() {
        // Given
        let simpleProduct = Product.fake().copy(siteID: sampleSiteID, productID: 1, productTypeKey: "simple", statusKey: "publish")
        let groupedProduct = Product.fake().copy(siteID: sampleSiteID, productID: 2, productTypeKey: "grouped", statusKey: "publish")
        let affiliateProduct = Product.fake().copy(siteID: sampleSiteID, productID: 3, productTypeKey: "external", statusKey: "publish")
        let variableProduct = Product.fake().copy(siteID: sampleSiteID, productID: 4, productTypeKey: "variable", statusKey: "publish")
        let subscriptionProduct = Product.fake().copy(siteID: sampleSiteID, productID: 5, productTypeKey: "subscription", statusKey: "publish")
        insert([simpleProduct, groupedProduct, affiliateProduct, variableProduct, subscriptionProduct])

        // When
        let viewModel = AddProductToOrderViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // Then
        XCTAssertTrue(viewModel.productRows.contains(where: { $0.id == 1 }), "Products do not include simple product")
        XCTAssertTrue(viewModel.productRows.contains(where: { $0.id == 2 }), "Products do not include grouped product")
        XCTAssertTrue(viewModel.productRows.contains(where: { $0.id == 3 }), "Products do not include affiliate product")
        XCTAssertFalse(viewModel.productRows.contains(where: { $0.id == 4 }), "Products include variable product")
        XCTAssertTrue(viewModel.productRows.contains(where: { $0.id == 5 }), "Products do not include subscription product")
    }

    func test_product_rows_only_contain_products_with_published_and_private_statuses() {
        // Given
        let publishedProduct = Product.fake().copy(siteID: sampleSiteID, productID: 1, statusKey: "publish")
        let draftProduct = Product.fake().copy(siteID: sampleSiteID, productID: 2, statusKey: "draft")
        let pendingProduct = Product.fake().copy(siteID: sampleSiteID, productID: 3, statusKey: "pending")
        let privateProduct = Product.fake().copy(siteID: sampleSiteID, productID: 4, statusKey: "private")
        insert([publishedProduct, draftProduct, pendingProduct, privateProduct])

        // When
        let viewModel = AddProductToOrderViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // Then
        XCTAssertTrue(viewModel.productRows.contains(where: { $0.id == 1 }), "Product rows do not include published product")
        XCTAssertFalse(viewModel.productRows.contains(where: { $0.id == 2 }), "Product rows include draft product")
        XCTAssertFalse(viewModel.productRows.contains(where: { $0.id == 3 }), "Product rows include pending product")
        XCTAssertTrue(viewModel.productRows.contains(where: { $0.id == 4 }), "Product rows do not include private product")
    }
}

// MARK: - Utils
private extension AddProductToOrderViewModelTests {
    func insert(_ readOnlyProduct: Yosemite.Product) {
        let product = storage.insertNewObject(ofType: StorageProduct.self)
        product.update(with: readOnlyProduct)
    }

    func insert(_ readOnlyProducts: [Yosemite.Product]) {
        for readOnlyProduct in readOnlyProducts {
            let product = storage.insertNewObject(ofType: StorageProduct.self)
            product.update(with: readOnlyProduct)
        }
    }
}
