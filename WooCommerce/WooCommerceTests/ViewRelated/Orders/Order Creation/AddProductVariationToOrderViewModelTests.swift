import XCTest
import Yosemite
@testable import WooCommerce
@testable import Storage

class AddProductVariationToOrderViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 123
    private let sampleProductID: Int64 = 12
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

    func test_view_model_adds_product_rows_with_unchangeable_quantity() {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let productVariation = ProductVariation.fake().copy(siteID: sampleSiteID, productID: sampleProductID, purchasable: true)
        insert(productVariation)

        // When
        let viewModel = AddProductVariationToOrderViewModel(siteID: sampleSiteID, product: product, storageManager: storageManager)

        // Then
        XCTAssertEqual(viewModel.productRows.count, 1)

        let productRow = viewModel.productRows[0]
        XCTAssertFalse(productRow.canChangeQuantity, "Product row canChangeQuantity property should be false but is true instead")
    }

    func test_product_rows_only_include_purchasable_product_variations() {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let purchasableProductVariation = ProductVariation.fake().copy(siteID: sampleSiteID,
                                                                       productID: sampleProductID,
                                                                       productVariationID: 1,
                                                                       purchasable: true)
        let nonPurchasableProductVariation = ProductVariation.fake().copy(siteID: sampleSiteID, productVariationID: 2, purchasable: false)
        insert([purchasableProductVariation, nonPurchasableProductVariation])

        // When
        let viewModel = AddProductVariationToOrderViewModel(siteID: sampleSiteID, product: product, storageManager: storageManager)

        // Then
        XCTAssertTrue(viewModel.productRows.contains(where: { $0.productOrVariationID == 1 }), "Product rows do not include purchasable product variation")
        XCTAssertFalse(viewModel.productRows.contains(where: { $0.productOrVariationID == 2 }), "Product rows include non-purchasable product variation")
    }

    func test_scrolling_indicator_appears_only_during_sync() {
        // Given
        let product = Product.fake()
        let viewModel = AddProductVariationToOrderViewModel(siteID: sampleSiteID, product: product, storageManager: storageManager, stores: stores)
        XCTAssertFalse(viewModel.shouldShowScrollIndicator, "Scroll indicator is not disabled at start")
        stores.whenReceivingAction(ofType: ProductVariationAction.self) { action in
            switch action {
            case let .synchronizeProductVariations(_, _, _, _, onCompletion):
                XCTAssertTrue(viewModel.shouldShowScrollIndicator, "Scroll indicator is not enabled during sync")
                onCompletion(nil)
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        viewModel.sync(pageNumber: 1, pageSize: 25, onCompletion: { _ in })

        // Then
        XCTAssertFalse(viewModel.shouldShowScrollIndicator, "Scroll indicator is not disabled after sync ends")
    }

    func test_sync_status_updates_as_expected_for_empty_product_variation_list() {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let viewModel = AddProductVariationToOrderViewModel(siteID: sampleSiteID, product: product, storageManager: storageManager, stores: stores)
        stores.whenReceivingAction(ofType: ProductVariationAction.self) { action in
            switch action {
            case let .synchronizeProductVariations(_, _, _, _, onCompletion):
                XCTAssertEqual(viewModel.syncStatus, .firstPageSync)
                onCompletion(nil)
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        viewModel.sync(pageNumber: 1, pageSize: 25, onCompletion: { _ in })

        // Then
        XCTAssertEqual(viewModel.syncStatus, .empty)
    }

    func test_sync_status_updates_as_expected_when_product_variations_are_synced() {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let viewModel = AddProductVariationToOrderViewModel(siteID: sampleSiteID, product: product, storageManager: storageManager, stores: stores)
        stores.whenReceivingAction(ofType: ProductVariationAction.self) { action in
            switch action {
            case let .synchronizeProductVariations(_, _, _, _, onCompletion):
                XCTAssertEqual(viewModel.syncStatus, .firstPageSync)
                let productVariation = ProductVariation.fake().copy(siteID: self.sampleSiteID, productID: self.sampleProductID, purchasable: true)
                self.insert(productVariation)
                onCompletion(nil)
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        viewModel.sync(pageNumber: 1, pageSize: 25, onCompletion: { _ in })

        // Then
        XCTAssertEqual(viewModel.syncStatus, .results)
    }

    func test_sync_status_does_not_change_while_syncing_when_storage_contains_product_variations() {
        // Given
        let product = Product.fake().copy(productID: sampleProductID)
        let productVariation = ProductVariation.fake().copy(siteID: sampleSiteID, productID: sampleProductID, purchasable: true)
        insert(productVariation)

        let viewModel = AddProductVariationToOrderViewModel(siteID: sampleSiteID, product: product, storageManager: storageManager, stores: stores)
        stores.whenReceivingAction(ofType: ProductVariationAction.self) { action in
            switch action {
            case let .synchronizeProductVariations(_, _, _, _, onCompletion):
                XCTAssertEqual(viewModel.syncStatus, .results)
                onCompletion(nil)
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        viewModel.sync(pageNumber: 1, pageSize: 25, onCompletion: { _ in })

        // Then
        XCTAssertEqual(viewModel.syncStatus, .results)
    }
}

// MARK: - Utils
private extension AddProductVariationToOrderViewModelTests {
    /// Insert a `Product` into storage
    func insert(_ readOnlyProduct: Yosemite.Product) {
        let product = storage.insertNewObject(ofType: StorageProduct.self)
        product.update(with: readOnlyProduct)
    }

    /// Insert an array of `Product`s into storage
    func insert(_ readOnlyProducts: [Yosemite.Product]) {
        for readOnlyProduct in readOnlyProducts {
            let product = storage.insertNewObject(ofType: StorageProduct.self)
            product.update(with: readOnlyProduct)
        }
    }

    /// Insert a `ProductVariation` into storage
    func insert(_ readOnlyProduct: Yosemite.ProductVariation) {
        let product = storage.insertNewObject(ofType: StorageProductVariation.self)
        product.update(with: readOnlyProduct)
    }

    /// Insert an array of `ProductVariation`s into storage
    func insert(_ readOnlyProducts: [Yosemite.ProductVariation]) {
        for readOnlyProduct in readOnlyProducts {
            let product = storage.insertNewObject(ofType: StorageProductVariation.self)
            product.update(with: readOnlyProduct)
        }
    }
}
