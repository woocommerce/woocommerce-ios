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
        let viewModel = BundledProductsListViewModel(siteID: sampleSiteID, bundleItems: [bundleItem])
        let bundledProduct = try XCTUnwrap(viewModel.bundledProducts.first)

        // Then
        XCTAssertEqual(bundledProduct.id, bundleItem.bundledItemID)
        XCTAssertEqual(bundledProduct.title, bundleItem.title)
        XCTAssertEqual(bundledProduct.stockStatus, bundleItem.stockStatus.description)
    }

    func test_view_model_fetches_expected_product_properties_for_bundle_item() throws {
        // Given
        let bundleItem = ProductBundleItem.fake().copy(productID: 12)
        let imageURL = URL(string: "https://woocommerce.com/woo.jpg")
        let product = Product.fake().copy(siteID: sampleSiteID, productID: 12, sku: "product-sku", images: [.fake().copy(src: imageURL?.absoluteString)])
        insert(product)

        // When
        let viewModel = BundledProductsListViewModel(siteID: sampleSiteID, bundleItems: [bundleItem], storageManager: storageManager)
        let bundledProduct = try XCTUnwrap(viewModel.bundledProducts.first)

        // Then
        XCTAssertEqual(bundledProduct.imageURL, imageURL)
        XCTAssertEqual(bundledProduct.sku, product.sku)
    }

    func test_view_model_syncs_and_updates_bundled_products_with_missing_images() throws {
        // Given
        let productWithImage = Product.fake().copy(siteID: sampleSiteID, productID: 12, images: [.fake().copy(src: "https://woocommerce.com/woo.jpg")])
        let productWithoutImage = Product.fake().copy(siteID: sampleSiteID, productID: 13)
        insert([productWithImage, productWithoutImage])

        // When
        var viewModel: BundledProductsListViewModel?
        _ = waitFor { promise in
            self.stores.whenReceivingAction(ofType: ProductAction.self) { action in
                switch action {
                case let .retrieveProducts(_, _, _, _, onCompletion):
                    let products = [productWithImage, productWithImage.copy(productID: 13)]
                    onCompletion(.success((products: products, hasNextPage: false)))
                    promise(true)
                default:
                    XCTFail("Received unsupported action: \(action)")
                }
            }

            viewModel = BundledProductsListViewModel(siteID: self.sampleSiteID,
                                                     bundleItems: [ProductBundleItem.fake().copy(productID: 12),
                                                                       ProductBundleItem.fake().copy(productID: 13)],
                                                     storageManager: self.storageManager,
                                                     stores: self.stores)
        }

        // Then
        let bundledProductsWithoutImages = try XCTUnwrap(viewModel?.bundledProducts.filter({ $0.imageURL == nil }))
        XCTAssertTrue(bundledProductsWithoutImages.isEmpty)
    }

    func test_view_model_bundled_product_returns_expected_subtitle_with_stock_status_and_sku() {
        // Given
        let stockStatus = "In stock"
        let sku = "bundled-product"
        let bundledProduct = BundledProductsListViewModel.BundledProduct(id: 1, title: "", stockStatus: stockStatus, sku: sku, imageURL: nil)

        // Then
        let expectedSubtitle = "\(stockStatus)\n\(String.localizedStringWithFormat(Localization.skuFormat, sku))"
        XCTAssertEqual(bundledProduct.subtitle, expectedSubtitle)
    }

    func test_view_model_bundled_product_returns_expected_subtitle_when_sku_is_nil_or_empty() {
        // Given
        let stockStatus = "In stock"
        let bundledProductWithNilSKU = BundledProductsListViewModel.BundledProduct(id: 1, title: "", stockStatus: stockStatus, sku: nil, imageURL: nil)
        let bundledProductWithEmptySKU = BundledProductsListViewModel.BundledProduct(id: 2, title: "", stockStatus: stockStatus, sku: "", imageURL: nil)

        // Then
        XCTAssertEqual(bundledProductWithNilSKU.subtitle, stockStatus)
        XCTAssertEqual(bundledProductWithEmptySKU.subtitle, stockStatus)
    }
}

// MARK: - Utils
private extension BundledProductsListViewModelTests {
    /// Insert an array of `Product` into storage.
    func insert(_ readOnlyProducts: [Yosemite.Product]) {
        for readOnlyProduct in readOnlyProducts {
            insert(readOnlyProduct)
        }
    }

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

    enum Localization {
        static let skuFormat = NSLocalizedString("SKU: %1$@",
                                                 comment: "SKU label for a product in the bundled products screen. The variable shows the SKU of the product.")
    }
}
