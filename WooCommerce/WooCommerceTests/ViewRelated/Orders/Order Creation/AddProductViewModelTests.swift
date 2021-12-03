import XCTest
import Yosemite
@testable import WooCommerce
@testable import Storage

class AddProductViewModelTests: XCTestCase {

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

    func test_view_model_adds_product_rows_with_correct_values() {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, statusKey: "publish")
        insert(product)

        // When
        let viewModel = AddProductViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // Then
        XCTAssertEqual(viewModel.productRows.count, 1)

        let productRow = viewModel.productRows[0]
        XCTAssertEqual(productRow.product, product)
        XCTAssertFalse(productRow.canChangeQuantity, "Product row canChangeQuantity property should be false but is true instead")
    }

    func test_product_rows_include_all_product_types_except_variable() {
        // Given
        let simpleProduct = Product.fake().copy(siteID: sampleSiteID, productTypeKey: "simple", statusKey: "publish")
        let groupedProduct = Product.fake().copy(siteID: sampleSiteID, productTypeKey: "grouped", statusKey: "publish")
        let affiliateProduct = Product.fake().copy(siteID: sampleSiteID, productTypeKey: "external", statusKey: "publish")
        let variableProduct = Product.fake().copy(siteID: sampleSiteID, productTypeKey: "variable", statusKey: "publish")
        let subscriptionProduct = Product.fake().copy(siteID: sampleSiteID, productTypeKey: "subscription", statusKey: "publish")
        insert([simpleProduct, groupedProduct, affiliateProduct, variableProduct, subscriptionProduct])

        // When
        let viewModel = AddProductViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // Then
        XCTAssertTrue(viewModel.productRows.contains(where: { $0.product.productType == .simple }),
                      "Product rows do not include simple product")
        XCTAssertTrue(viewModel.productRows.contains(where: { $0.product.productType == .grouped }),
                      "Product rows do not include grouped product")
        XCTAssertTrue(viewModel.productRows.contains(where: { $0.product.productType == .affiliate }),
                      "Product rows do not include affiliate product")
        XCTAssertFalse(viewModel.productRows.contains(where: { $0.product.productType == .variable }),
                       "Product rows include variable product")
        XCTAssertTrue(viewModel.productRows.contains(where: { $0.product.productType == .subscription }),
                      "Product rows do not include subscription product")
    }

    func test_product_rows_only_contain_products_with_published_and_private_statuses() {
        // Given
        let publishedProduct = Product.fake().copy(siteID: sampleSiteID, statusKey: "publish")
        let draftProduct = Product.fake().copy(siteID: sampleSiteID, statusKey: "draft")
        let pendingProduct = Product.fake().copy(siteID: sampleSiteID, statusKey: "pending")
        let privateProduct = Product.fake().copy(siteID: sampleSiteID, statusKey: "private")
        insert([publishedProduct, draftProduct, pendingProduct, privateProduct])

        // When
        let viewModel = AddProductViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // Then
        XCTAssertTrue(viewModel.productRows.contains(where: { $0.product.productStatus == .publish }),
                      "Product rows do not include published product")
        XCTAssertFalse(viewModel.productRows.contains(where: { $0.product.productStatus == .draft }),
                       "Product rows include draft product")
        XCTAssertFalse(viewModel.productRows.contains(where: { $0.product.productStatus == .pending }),
                       "Product rows include pending product")
        XCTAssertTrue(viewModel.productRows.contains(where: { $0.product.productStatus == .privateStatus }),
                      "Product rows do not include private product")
    }
}

// MARK: - Utils
private extension AddProductViewModelTests {
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
