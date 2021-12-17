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
        XCTAssertTrue(viewModel.productRows.contains(where: { $0.productID == 1 }), "Products do not include simple product")
        XCTAssertTrue(viewModel.productRows.contains(where: { $0.productID == 2 }), "Products do not include grouped product")
        XCTAssertTrue(viewModel.productRows.contains(where: { $0.productID == 3 }), "Products do not include affiliate product")
        XCTAssertFalse(viewModel.productRows.contains(where: { $0.productID == 4 }), "Products include variable product")
        XCTAssertTrue(viewModel.productRows.contains(where: { $0.productID == 5 }), "Products do not include subscription product")
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
        XCTAssertTrue(viewModel.productRows.contains(where: { $0.productID == 1 }), "Product rows do not include published product")
        XCTAssertFalse(viewModel.productRows.contains(where: { $0.productID == 2 }), "Product rows include draft product")
        XCTAssertFalse(viewModel.productRows.contains(where: { $0.productID == 3 }), "Product rows include pending product")
        XCTAssertTrue(viewModel.productRows.contains(where: { $0.productID == 4 }), "Product rows do not include private product")
    }

    func test_scrolling_indicator_appears_only_during_sync() {
        // Given
        let viewModel = AddProductToOrderViewModel(siteID: sampleSiteID, storageManager: storageManager, stores: stores)
        XCTAssertFalse(viewModel.shouldShowScrollIndicator, "Scroll indicator is not disabled at start")
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .synchronizeProducts(_, _, _, _, _, _, _, _, _, _, onCompletion):
                XCTAssertTrue(viewModel.shouldShowScrollIndicator, "Scroll indicator is not enabled during sync")
                onCompletion(.success(true))
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        viewModel.sync(pageNumber: 1, pageSize: 25, onCompletion: { _ in })

        // Then
        XCTAssertFalse(viewModel.shouldShowScrollIndicator, "Scroll indicator is not disabled after sync ends")
    }

    func test_sync_status_updates_as_expected_for_empty_product_list() {
        // Given
        let viewModel = AddProductToOrderViewModel(siteID: sampleSiteID, storageManager: storageManager, stores: stores)
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .synchronizeProducts(_, _, _, _, _, _, _, _, _, _, onCompletion):
                XCTAssertEqual(viewModel.syncStatus, .firstPageSync)
                onCompletion(.success(true))
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        viewModel.sync(pageNumber: 1, pageSize: 25, onCompletion: { _ in })

        // Then
        XCTAssertEqual(viewModel.syncStatus, .empty)
    }

    func test_sync_status_updates_as_expected_when_products_are_synced() {
        // Given
        let viewModel = AddProductToOrderViewModel(siteID: sampleSiteID, storageManager: storageManager, stores: stores)
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .synchronizeProducts(_, _, _, _, _, _, _, _, _, _, onCompletion):
                XCTAssertEqual(viewModel.syncStatus, .firstPageSync)
                let product = Product.fake().copy(siteID: self.sampleSiteID, statusKey: "publish")
                self.insert(product)
                onCompletion(.success(true))
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        viewModel.sync(pageNumber: 1, pageSize: 25, onCompletion: { _ in })

        // Then
        XCTAssertEqual(viewModel.syncStatus, .results)
    }

    func test_sync_status_does_not_change_while_syncing_when_storage_contains_products() {
        // Given
        let product = Product.fake().copy(siteID: self.sampleSiteID, statusKey: "publish")
        insert(product)

        let viewModel = AddProductToOrderViewModel(siteID: sampleSiteID, storageManager: storageManager, stores: stores)
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .synchronizeProducts(_, _, _, _, _, _, _, _, _, _, onCompletion):
                XCTAssertEqual(viewModel.syncStatus, .results)
                onCompletion(.success(true))
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
