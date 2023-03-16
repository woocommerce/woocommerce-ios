import XCTest
@testable import WooCommerce
@testable import Yosemite
@testable import Storage

final class BundledProductsListViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 12345
    private var storageManager: StorageManagerType!
    private var storage: StorageType {
        storageManager.viewStorage
    }
    private let stores = MockStoresManager(sessionManager: .testingInstance)

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
        stores.reset()
    }

    override func tearDown() {
        storageManager = nil
        super.tearDown()
    }

    func test_view_model_prefills_bundle_item_data_correctly() throws {
        // Given
        let bundleItem = ProductBundleItem.fake().copy(bundledItemID: 1, title: "Hoodie", stockStatus: .outOfStock)

        // When
        let viewModel = BundledProductsListViewModel(siteID: sampleSiteID, bundledProducts: [bundleItem])
        let bundledProduct = try XCTUnwrap(viewModel.bundledProducts.first)

        // Then
        XCTAssertEqual(bundledProduct.id, bundleItem.bundledItemID)
        XCTAssertEqual(bundledProduct.title, bundleItem.title)
        XCTAssertEqual(bundledProduct.stockStatus, bundleItem.stockStatus.description)
    }

    func test_view_model_fetches_expected_image_URL_for_bundle_item() throws {
        // Given
        let bundleItem = ProductBundleItem.fake().copy(productID: 12)
        let imageURL = URL(string: "https://woocommerce.com/woo.jpg")
        let product = Product.fake().copy(siteID: sampleSiteID, productID: 12, images: [.fake().copy(src: imageURL?.absoluteString)])
        insert(product)

        // When
        let viewModel = BundledProductsListViewModel(siteID: sampleSiteID, bundledProducts: [bundleItem], storageManager: storageManager)
        let bundledProduct = try XCTUnwrap(viewModel.bundledProducts.first)

        // Then
        XCTAssertEqual(bundledProduct.imageURL, imageURL)
    }
}

// MARK: - Utils
private extension BundledProductsListViewModelTests {
    /// Insert a `Product` into storage.
    func insert(_ readOnlyProduct: Yosemite.Product) {
        let product = storage.insertNewObject(ofType: StorageProduct.self)
        product.update(with: readOnlyProduct)

        for readOnlyImage in readOnlyProduct.images {
            let productImage = storage.insertNewObject(ofType: StorageProductImage.self)
            productImage.update(with: readOnlyImage)
            productImage.product = product
        }
    }
}
