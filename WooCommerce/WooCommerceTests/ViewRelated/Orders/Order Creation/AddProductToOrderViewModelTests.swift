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
        let product = Product.fake().copy(siteID: sampleSiteID, purchasable: true)
        insert(product)

        // When
        let viewModel = AddProductToOrderViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // Then
        XCTAssertEqual(viewModel.productRows.count, 1)

        let productRow = viewModel.productRows[0]
        XCTAssertFalse(productRow.canChangeQuantity, "Product row canChangeQuantity property should be false but is true instead")
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
                let product = Product.fake().copy(siteID: self.sampleSiteID, purchasable: true)
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
        let product = Product.fake().copy(siteID: self.sampleSiteID, purchasable: true)
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

    func test_onLoadTrigger_triggers_initial_product_sync() {
        // Given
        let viewModel = AddProductToOrderViewModel(siteID: sampleSiteID, storageManager: storageManager, stores: stores)
        var timesSynced = 0
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case .synchronizeProducts:
                timesSynced += 1
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        viewModel.onLoadTrigger.send()
        viewModel.onLoadTrigger.send()

        // Then
        XCTAssertEqual(timesSynced, 1)
    }

    func test_entering_search_term_performs_remote_product_search() {
        // Given
        let viewModel = AddProductToOrderViewModel(siteID: sampleSiteID, storageManager: storageManager, stores: stores)
        let searchTerm = "shirt"
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .searchProducts(_, _, _, _, _, onCompletion):
                let product = Product.fake().copy(siteID: self.sampleSiteID, purchasable: true)
                self.insert(product, withSearchTerm: searchTerm)
                onCompletion(.success(()))
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        viewModel.searchTerm = searchTerm

        // Then
        XCTAssertEqual(viewModel.productRows.count, 1)
    }

    func test_searching_products_returns_expected_results() {
        // Given
        let viewModel = AddProductToOrderViewModel(siteID: sampleSiteID, storageManager: storageManager, stores: stores)
        let product = Product.fake().copy(siteID: sampleSiteID, purchasable: true)
        insert(product.copy(name: "T-shirt"), withSearchTerm: "shirt")
        insert(product.copy(name: "Hoodie"), withSearchTerm: "hoodie")

        // When
        viewModel.searchTerm = "shirt"

        // Then
        XCTAssertEqual(viewModel.productRows.count, 1)
        XCTAssertEqual(viewModel.productRows[0].name, "T-shirt")
    }

    func test_clearing_search_returns_full_product_list() {
        // Given
        let viewModel = AddProductToOrderViewModel(siteID: sampleSiteID, storageManager: storageManager, stores: stores)
        let product = Product.fake().copy(siteID: sampleSiteID, purchasable: true)
        insert(product.copy(name: "T-shirt"), withSearchTerm: "shirt")
        insert(product.copy(name: "Hoodie"), withSearchTerm: "hoodie")

        // When
        viewModel.searchTerm = "shirt"
        XCTAssertNotEqual(viewModel.productRows.count, 2)

        // Then
        viewModel.searchTerm = ""
        XCTAssertEqual(viewModel.productRows.count, 2)
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

    func insert(_ readOnlyProduct: Yosemite.Product, withSearchTerm keyword: String) {
        insert(readOnlyProduct)

        let searchResult = storage.insertNewObject(ofType: ProductSearchResults.self)
        searchResult.keyword = keyword

        if let storedProduct = storage.loadProduct(siteID: readOnlyProduct.siteID, productID: readOnlyProduct.productID) {
            searchResult.addToProducts(storedProduct)
        }
    }
}
