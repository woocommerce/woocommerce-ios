import XCTest
import Yosemite
@testable import WooCommerce
@testable import Storage

final class ProductSelectorViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 123
    private var storageManager: StorageManagerType!
    private var storage: StorageType {
        storageManager.viewStorage
    }
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!
    private let stores = MockStoresManager(sessionManager: .testingInstance)
    private let searchDebounceTime: UInt64 = 600_000_000 // 500 milliseconds with buffer

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
        stores.reset()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    override func tearDown() {
        storageManager = nil
        analytics = nil
        analyticsProvider = nil
        super.tearDown()
    }

    func test_ProductSelectorViewModel_supportsMultipleSelection_is_false_on_initialization() {
        // Given
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // Then
        XCTAssertFalse(viewModel.supportsMultipleSelection)
    }

    func test_ProductSelectorViewModel_toggleAllVariationsOnSelection_is_true_on_initialization() {
        // Given
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // Then
        XCTAssertTrue(viewModel.toggleAllVariationsOnSelection)
    }

    func test_view_model_is_initialized_with_default_values() {
        // Given
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID)

        // Then
        XCTAssertFalse(viewModel.supportsMultipleSelection)
        XCTAssertTrue(viewModel.isClearSelectionEnabled)
        XCTAssertTrue(viewModel.toggleAllVariationsOnSelection)
        XCTAssertEqual(viewModel.filterButtonTitle, "Filter")
        XCTAssertNil(viewModel.notice)
        XCTAssertEqual(viewModel.ghostRows.count, 6)
        XCTAssertEqual(viewModel.searchTerm, "")
        XCTAssertEqual(viewModel.totalSelectedItemsCount, 0)
    }

    func test_view_model_adds_product_rows_with_unchangeable_quantity() {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, purchasable: true)
        insert(product)

        // When
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // Then
        XCTAssertEqual(viewModel.productRows.count, 1)

        let productRow = viewModel.productRows[0]
        XCTAssertFalse(productRow.canChangeQuantity, "Product row canChangeQuantity property should be false but is true instead")
    }

    func test_scrolling_indicator_appears_only_during_sync() {
        // Given
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID, storageManager: storageManager, stores: stores)
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
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID, storageManager: storageManager, stores: stores)
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
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID, storageManager: storageManager, stores: stores)
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

        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID, storageManager: storageManager, stores: stores)
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
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID, storageManager: storageManager, stores: stores)
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
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID, storageManager: storageManager, stores: stores)
        let expectation = expectation(description: "Completed product search")
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .searchProducts(_, _, _, _, _, _, _, _, _, _, onCompletion):
                let product = Product.fake().copy(siteID: self.sampleSiteID, purchasable: true)
                self.insert(product, withSearchTerm: "shirt")
                onCompletion(.success(()))
                expectation.fulfill()
            case .searchProductsInCache:
                break
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        viewModel.searchTerm = "shirt"
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)

        // Then
        XCTAssertEqual(viewModel.productRows.count, 1)
    }

    func test_entering_search_term_when_there_are_no_filters_then_performs_local_product_search() {
        // Given
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID, storageManager: storageManager, stores: stores)
        let expectation = expectation(description: "Completed product search")
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case .searchProducts:
                break
            case let .searchProductsInCache(_, _, _, onCompletion):
                let product = Product.fake().copy(siteID: self.sampleSiteID, purchasable: true)
                self.insert(product, withSearchTerm: "shirt")
                onCompletion(true)
                expectation.fulfill()
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        viewModel.searchTerm = "shirt"
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)

        // Then
        XCTAssertEqual(viewModel.productRows.count, 1)
    }

    func test_entering_search_term_when_there_are_no_cached_items_then_it_does_not_reload_products() {
        // Given
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID, storageManager: storageManager, stores: stores)
        let expectation = expectation(description: "Completed product search")
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case .searchProducts:
                break
            case let .searchProductsInCache(_, _, _, onCompletion):
                let product = Product.fake().copy(siteID: self.sampleSiteID, purchasable: true)
                self.insert(product, withSearchTerm: "shirt")
                onCompletion(false)
                expectation.fulfill()
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        viewModel.searchTerm = "shirt"
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)

        // Then
        XCTAssertEqual(viewModel.productRows.count, 0)
    }

    func test_searching_products_filters_product_list_as_expected() {
        // Given
        let hoodie = Product.fake().copy(siteID: sampleSiteID, productID: 1, name: "Hoodie", purchasable: true)
        let shirt = Product.fake().copy(siteID: sampleSiteID, productID: 2, name: "T-shirt", purchasable: true)
        insert([hoodie, shirt])

        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID, storageManager: storageManager, stores: stores)
        let expectation = expectation(description: "Completed product search")
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .searchProducts(_, _, _, _, _, _, _, _, _, _, onCompletion):
                self.insert(shirt, withSearchTerm: "shirt")
                onCompletion(.success(()))
                expectation.fulfill()
            case .searchProductsInCache:
                break
            default:
                XCTFail("Unsupported Action")
            }
        }

        XCTAssertEqual(viewModel.productRows.count, 2, "Full product list is not loaded before search")

        // When
        viewModel.searchTerm = "shirt"
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)

        // Then
        XCTAssertEqual(viewModel.productRows.count, 1, "Product list is not filtered after search")
        XCTAssertEqual(viewModel.productRows[0].name, "T-shirt")
    }

    func test_clearSearchAndFilters_resets_searchTerm_and_filters() {
        // Given
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID)

        // When
        viewModel.searchTerm = "shirt"
        viewModel.filters = .init(stockStatus: .outOfStock,
                                  productStatus: .draft,
                                  productType: .simple,
                                  productCategory: nil,
                                  numberOfActiveFilters: 3)
        viewModel.clearSearchAndFilters()

        // Then
        XCTAssertEqual(viewModel.searchTerm, "")
        XCTAssertEqual(viewModel.filters, FilterProductListViewModel.Filters())
    }

    func test_clearing_search_returns_full_product_list() {
        // Given
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID, storageManager: storageManager, stores: stores)
        let expectation = expectation(description: "Cleared product search")
        let product = Product.fake().copy(siteID: sampleSiteID, purchasable: true)
        insert([product.copy(name: "T-shirt"), product.copy(name: "Hoodie")])
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .searchProducts(_, _, _, _, _, _, _, _, _, _, onCompletion):
                self.insert(product.copy(name: "T-shirt"), withSearchTerm: "shirt")
                onCompletion(.success(()))
            case let .synchronizeProducts(_, _, _, _, _, _, _, _, _, _, onCompletion):
                onCompletion(.success(true))
                expectation.fulfill()
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        viewModel.searchTerm = "shirt"
        viewModel.clearSearchAndFilters()
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)

        // Then
        XCTAssertEqual(viewModel.productRows.count, 2)
    }

    func test_searchTerm_and_filters_are_clear_on_init() {
        // Given
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID)

        // Then
        XCTAssertEqual(viewModel.searchTerm, "")
        XCTAssertNil(viewModel.filters.stockStatus)
        XCTAssertNil(viewModel.filters.productCategory)
        XCTAssertNil(viewModel.filters.productType)
        XCTAssertNil(viewModel.filters.productCategory)
        XCTAssertEqual(viewModel.filters.numberOfActiveFilters, 0)
    }

    func test_view_model_fires_error_notice_when_product_sync_fails() {
        // Given
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID, stores: stores)
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .synchronizeProducts(_, _, _, _, _, _, _, _, _, _, onCompletion):
                onCompletion(.failure(NSError(domain: "Error", code: 0)))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }

        // When
        viewModel.onLoadTrigger.send()

        // Then
        XCTAssertEqual(viewModel.notice, ProductSelectorViewModel.NoticeFactory.productSyncNotice(retryAction: {}))
    }

    func test_view_model_fires_error_notice_when_product_search_fails() {
        // Given
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID, stores: stores)

        // When
        let notice: Notice? = waitFor { promise in
            self.stores.whenReceivingAction(ofType: ProductAction.self) { action in
                switch action {
                case let .searchProducts(_, _, _, _, _, _, _, _, _, _, onCompletion):
                    onCompletion(.failure(NSError(domain: "Error", code: 0)))
                    promise(viewModel.notice)
                case .searchProductsInCache:
                    break
                default:
                    XCTFail("Received unsupported action: \(action)")
                }
            }
            viewModel.searchTerm = "shirt"
        }

        // Then
        XCTAssertEqual(notice, ProductSelectorViewModel.NoticeFactory.productSearchNotice(retryAction: {}))
    }

    func test_selectProduct_invokes_onProductSelected_closure_for_existing_product() {
        // Given
        var selectedProduct: Int64?
        let product = Product.fake().copy(siteID: sampleSiteID, productID: 1, purchasable: true)
        insert(product)
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                   storageManager: storageManager,
                                                   onProductSelected: { selectedProduct = $0.productID })

        // When
        viewModel.selectProduct(product.productID)

        // Then
        XCTAssertEqual(selectedProduct, product.productID)
    }

    func test_selectProduct_given_supportsMultipleSelection_is_enabled_invokes_onProductSelected_closure_for_existing_product() {
        // Given
        var selectedProduct: Int64?
        let product = Product.fake().copy(siteID: sampleSiteID, productID: 1, purchasable: true)
        insert(product)
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 storageManager: storageManager,
                                                 supportsMultipleSelection: true,
                                                 onProductSelected: { selectedProduct = $0.productID })

        // When
        viewModel.selectProduct(product.productID)

        // Then
        XCTAssertEqual(selectedProduct, product.productID)
    }

    func test_getVariationsViewModel_returns_expected_view_model_for_variable_product() throws {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: 1, name: "Test Product", purchasable: true, variations: [1, 2])
        insert(product)
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                   storageManager: storageManager)

        // When
        let variationsViewModel = viewModel.getVariationsViewModel(for: product.productID)

        // Then
        let actualViewModel = try XCTUnwrap(variationsViewModel)
        XCTAssertEqual(actualViewModel.productName, product.name)
    }

    func test_getVariationsViewModel_returns_nil_for_simple_product() {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: 1, name: "Test Product", purchasable: true)
        insert(product)
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                   storageManager: storageManager)

        // When
        let variationsViewModel = viewModel.getVariationsViewModel(for: product.productID)

        // Then
        XCTAssertNil(variationsViewModel)
    }

    func test_selecting_a_product_if_supportsMultipleSelection_is_true_and_selectProduct_is_invoked_sets_its_row_to_selected_state() {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: 1, purchasable: true)
        insert(product)
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 storageManager: storageManager,
                                                 supportsMultipleSelection: true,
                                                 onProductSelected: { _ in })

        // When
        viewModel.selectProduct(product.productID)

        // Then
        let productRow = viewModel.productRows.first(where: { $0.productOrVariationID == product.productID })
        XCTAssertNotNil(productRow)
        XCTAssertEqual(productRow?.selectedState, .selected)
    }

    func test_selecting_a_product_sets_its_row_to_notSelected_state_if_it_was_previously_selected() {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: 1, purchasable: true)
        insert(product)
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 storageManager: storageManager)

        // When
        viewModel.selectProduct(product.productID)
        viewModel.selectProduct(product.productID)

        // Then
        let productRow = viewModel.productRows.first(where: { $0.productOrVariationID == product.productID })
        XCTAssertNotNil(productRow)
        XCTAssertEqual(productRow?.selectedState, .notSelected)
    }

    func test_productRow_selectedState_if_supportsMultiselection_is_false_and_selectProduct_invoked_twice_then_selectedState_is_notSelected() {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: 1, purchasable: true)
        insert(product)
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 storageManager: storageManager,
                                                 supportsMultipleSelection: false,
                                                 onProductSelected: { _ in })

        // When
        viewModel.selectProduct(product.productID)
        viewModel.selectProduct(product.productID)

        // Then
        let productRow = viewModel.productRows.first(where: { $0.productOrVariationID == product.productID })
        XCTAssertNotNil(productRow)
        XCTAssertEqual(productRow?.selectedState, .notSelected)
    }

    func test_productRow_selectedState_if_supportsMultiselection_is_true_and_selectProduct_invoked_twice_then_selectedState_is_notSelected() {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: 1, purchasable: true)
        insert(product)
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 storageManager: storageManager,
                                                 supportsMultipleSelection: true)

        // When
        viewModel.selectProduct(product.productID)
        viewModel.selectProduct(product.productID)

        // Then
        let productRow = viewModel.productRows.first(where: { $0.productOrVariationID == product.productID })
        XCTAssertNotNil(productRow)
        XCTAssertEqual(productRow?.selectedState, .notSelected)
    }

    func test_selecting_a_product_variation_set_its_product_row_to_partiallySelected() {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: 1, purchasable: true, variations: [1, 2])
        insert(product)
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 storageManager: storageManager)

        // When
        viewModel.updateSelectedVariations(productID: product.productID, selectedVariationIDs: [2])

        // Then
        let productRow = viewModel.productRows.first(where: { $0.productOrVariationID == product.productID })
        XCTAssertNotNil(productRow)
        XCTAssertEqual(productRow?.selectedState, .partiallySelected)
    }

    func test_toggleSelectionForVariations_set_its_product_row_to_selected_if_no_variation_was_selected() {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: 1, purchasable: true, variations: [1, 2])
        insert(product)
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 storageManager: storageManager)

        // When
        viewModel.toggleSelectionForAllVariations(of: product.productID)

        // Then
        let productRow = viewModel.productRows.first(where: { $0.productOrVariationID == product.productID })
        XCTAssertNotNil(productRow)
        XCTAssertEqual(productRow?.selectedState, .selected)
    }

    func test_toggleSelectionForVariations_set_its_product_row_to_selected_if_some_variations_were_selected_earlier() {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: 1, purchasable: true, variations: [1, 2])
        insert(product)
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 storageManager: storageManager)

        // When
        viewModel.updateSelectedVariations(productID: product.productID, selectedVariationIDs: [2])
        viewModel.toggleSelectionForAllVariations(of: product.productID)

        // Then
        let productRow = viewModel.productRows.first(where: { $0.productOrVariationID == product.productID })
        XCTAssertNotNil(productRow)
        XCTAssertEqual(productRow?.selectedState, .selected)
    }

    func test_toggleSelectionForVariations_set_its_product_row_to_notSelected_if_all_variations_were_selected_earlier() {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: 1, purchasable: true, variations: [1, 2])
        insert(product)
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 storageManager: storageManager)

        // When
        viewModel.updateSelectedVariations(productID: product.productID, selectedVariationIDs: [1, 2])
        viewModel.toggleSelectionForAllVariations(of: product.productID)

        // Then
        let productRow = viewModel.productRows.first(where: { $0.productOrVariationID == product.productID })
        XCTAssertNotNil(productRow)
        XCTAssertEqual(productRow?.selectedState, .notSelected)
    }

    func test_initialSelectedItems_are_reflected_in_selected_rows() {
        // Given
        let simpleProduct = Product.fake().copy(siteID: sampleSiteID, productID: 1, purchasable: true)
        let variableProduct = Product.fake().copy(siteID: sampleSiteID, productID: 10, purchasable: true, variations: [12, 20])
        insert(simpleProduct)
        insert(variableProduct)

        // When
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 selectedItemIDs: [1, 12, 20],
                                                 storageManager: storageManager)

        // Then
        let simpleProductRow = viewModel.productRows.first(where: { $0.productOrVariationID == simpleProduct.productID })
        XCTAssertEqual(simpleProductRow?.selectedState, .selected)
        let variableProductRow = viewModel.productRows.first(where: { $0.productOrVariationID == variableProduct.productID })
        XCTAssertEqual(variableProductRow?.selectedState, .selected)
    }

    func test_completion_block_is_triggered_with_all_selected_items() {
        // Given
        let simpleProduct = Product.fake().copy(siteID: sampleSiteID, productID: 1, purchasable: true)
        let variableProduct = Product.fake().copy(siteID: sampleSiteID, productID: 10, purchasable: true, variations: [12, 20])
        insert(simpleProduct)
        insert(variableProduct)
        var selectedItems: [Int64] = []
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 selectedItemIDs: [],
                                                 storageManager: storageManager,
                                                 supportsMultipleSelection: true,
                                                 onMultipleSelectionCompleted: {
            selectedItems = $0
        })

        // When
        viewModel.selectProduct(simpleProduct.productID)
        viewModel.updateSelectedVariations(productID: variableProduct.productID, selectedVariationIDs: [12])
        viewModel.completeMultipleSelection()

        // Then
        XCTAssertEqual(selectedItems, [simpleProduct.productID, 12])
    }

    func test_analytics_when_completeMultipleSelection_closure_is_invoked_then_event_and_properties_are_logged_correctly() throws {
        // Given
        let simpleProduct = Product.fake().copy(siteID: sampleSiteID, productID: 1, purchasable: true)
        let variableProduct = Product.fake().copy(siteID: sampleSiteID, productID: 10, purchasable: true, variations: [12, 20])
        insert(simpleProduct)
        insert(variableProduct)
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 selectedItemIDs: [1, 10, 20],
                                                 storageManager: storageManager,
                                                 analytics: analytics,
                                                 supportsMultipleSelection: true)

        // When
        viewModel.completeMultipleSelection()

        // Then
        guard let eventIndex = analyticsProvider.receivedEvents.firstIndex(where: { $0 == "order_creation_product_selector_confirm_button_tapped"}) else {
            return XCTFail("No event received")
        }

        let eventProperties = analyticsProvider.receivedProperties[eventIndex]
        guard let property = eventProperties.first(where: { $0.key as? String == "product_count"}) else {
            return XCTFail("No property received")
        }
        XCTAssertEqual(property.value as? Int64, 3)
    }

    func test_filter_button_title_shows_correct_number_of_active_filters() async throws {
        // Given
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID)
        let defaultTitle = NSLocalizedString("Filter", comment: "")
        // confidence check
        XCTAssertEqual(viewModel.filterButtonTitle, defaultTitle)

        // When
        viewModel.searchTerm = ""
        viewModel.filters = FilterProductListViewModel.Filters(
            stockStatus: ProductStockStatus.outOfStock,
            productStatus: ProductStatus.draft,
            productType: ProductType.simple,
            productCategory: nil,
            numberOfActiveFilters: 3
        )
        try await Task.sleep(nanoseconds: searchDebounceTime)

        // Then
        XCTAssertEqual(viewModel.filterButtonTitle, String.localizedStringWithFormat(NSLocalizedString("Filter (%ld)", comment: ""), 3))
    }

    func test_productRows_are_updated_correctly_when_filters_are_applied() async throws {
        // Given
        let simpleProduct = Product.fake().copy(siteID: sampleSiteID, productID: 1, productTypeKey: ProductType.simple.rawValue, purchasable: true)
        let variableProduct = Product.fake().copy(siteID: sampleSiteID, productID: 10, productTypeKey: ProductType.variable.rawValue, purchasable: true)
        insert(variableProduct)
        insert(simpleProduct)
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // When
        viewModel.filters = FilterProductListViewModel.Filters(
            stockStatus: nil,
            productStatus: nil,
            productType: ProductType.simple,
            productCategory: nil,
            numberOfActiveFilters: 1
        )
        viewModel.searchTerm = ""
        try await Task.sleep(nanoseconds: searchDebounceTime)

        // Then
        XCTAssertEqual(viewModel.productRows.count, 1)
        XCTAssertEqual(viewModel.productRows.first?.productOrVariationID, simpleProduct.productID)
    }

    func test_clearSelection_unselects_previously_selected_items() {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: 1, purchasable: true)
        insert(product)
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 storageManager: storageManager,
                                                 supportsMultipleSelection: true)

        // When
        viewModel.selectProduct(product.productID)
        // Confidence check
        let productRow = viewModel.productRows.first(where: { $0.productOrVariationID == product.productID })
        XCTAssertEqual(productRow?.selectedState, .selected)
        viewModel.clearSelection()

        // Then
        let updatedRow = viewModel.productRows.first(where: { $0.productOrVariationID == product.productID })
        XCTAssertEqual(updatedRow?.selectedState, .notSelected)
    }

    func test_clearSelection_unselects_all_initially_selected_items() {
        // Given
        let simpleProduct = Product.fake().copy(siteID: sampleSiteID, productID: 1, purchasable: true)
        let variableProduct = Product.fake().copy(siteID: sampleSiteID, productID: 10, purchasable: true, variations: [12, 20])
        insert(simpleProduct)
        insert(variableProduct)

        // When
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 selectedItemIDs: [1, 12, 20],
                                                 storageManager: storageManager)
        viewModel.clearSelection()

        // Then
        let simpleProductRow = viewModel.productRows.first(where: { $0.productOrVariationID == simpleProduct.productID })
        XCTAssertEqual(simpleProductRow?.selectedState, .notSelected)
        let variableProductRow = viewModel.productRows.first(where: { $0.productOrVariationID == variableProduct.productID })
        XCTAssertEqual(variableProductRow?.selectedState, .notSelected)
    }

    func test_clearSelection_invokes_onAllSelectionsCleared_closure() {
        // Given
        var onAllSelectionsClearedCalled = false
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID, selectedItemIDs: [1, 12, 20], onAllSelectionsCleared: {
            onAllSelectionsClearedCalled = true
        })

        // When
        viewModel.clearSelection()

        // Then
        XCTAssertTrue(onAllSelectionsClearedCalled)
    }

    func test_synchronizeProducts_are_triggered_with_correct_filters() async throws {
        // Given
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID, stores: stores)
        var filteredStockStatus: ProductStockStatus?
        var filteredProductStatus: ProductStatus?
        var filteredProductType: ProductType?
        var filteredProductCategory: Yosemite.ProductCategory?
        let filters = FilterProductListViewModel.Filters(
            stockStatus: .outOfStock,
            productStatus: .draft,
            productType: ProductType.simple,
            productCategory: .init(categoryID: 123, siteID: sampleSiteID, parentID: 1, name: "Test", slug: "test"),
            numberOfActiveFilters: 1
        )
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .synchronizeProducts(_, _, _, stockStatus, productStatus, productType, category, _, _, _, onCompletion):
                filteredStockStatus = stockStatus
                filteredProductType = productType
                filteredProductStatus = productStatus
                filteredProductCategory = category
                onCompletion(.success(true))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }

        // When
        viewModel.filters = filters
        viewModel.searchTerm = ""
        try await Task.sleep(nanoseconds: searchDebounceTime)

        // Then
        assertEqual(filteredStockStatus, filters.stockStatus)
        assertEqual(filteredProductType, filters.productType)
        assertEqual(filteredProductStatus, filters.productStatus)
        assertEqual(filteredProductCategory, filters.productCategory)
    }

    func test_searchProducts_are_triggered_with_correct_filters() async throws {
        // Given
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID, stores: stores)
        var filteredStockStatus: ProductStockStatus?
        var filteredProductStatus: ProductStatus?
        var filteredProductType: ProductType?
        var filteredProductCategory: Yosemite.ProductCategory?
        let filters = FilterProductListViewModel.Filters(
            stockStatus: .outOfStock,
            productStatus: .draft,
            productType: ProductType.simple,
            productCategory: .init(categoryID: 123, siteID: sampleSiteID, parentID: 1, name: "Test", slug: "test"),
            numberOfActiveFilters: 1
        )
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .searchProducts(_, _, _, _, _, stockStatus, productStatus, productType, category, _, onCompletion):
                filteredStockStatus = stockStatus
                filteredProductType = productType
                filteredProductStatus = productStatus
                filteredProductCategory = category
                onCompletion(.success(Void()))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }

        // When
        viewModel.filters = filters
        viewModel.searchTerm = "hiii"
        try await Task.sleep(nanoseconds: searchDebounceTime)

        // Then
        assertEqual(filteredStockStatus, filters.stockStatus)
        assertEqual(filteredProductType, filters.productType)
        assertEqual(filteredProductStatus, filters.productStatus)
        assertEqual(filteredProductCategory, filters.productCategory)
    }

    func test_search_term_and_filters_are_combined_to_get_correct_results() {
        // Given
        let bolognese = Product.fake().copy(siteID: sampleSiteID, productID: 1, name: "Bolognese spaghetti", productTypeKey: ProductType.simple.rawValue)
        let carbonara = Product.fake().copy(siteID: sampleSiteID, productID: 23, name: "Carbonara spaghetti", productTypeKey: ProductType.simple.rawValue)
        let pizza = Product.fake().copy(siteID: sampleSiteID, productID: 11, name: "Pizza", productTypeKey: ProductType.variable.rawValue)
        insert(pizza)
        insert(bolognese, withSearchTerm: "spa")
        insert(carbonara, withSearchTerm: "spa")

        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID, storageManager: storageManager)
        XCTAssertEqual(viewModel.productRows.count, 3) // Confidence check

        // When
        viewModel.searchTerm = "spa"
        waitUntil {
            viewModel.productRows.count != 3
        }

        // Then
        XCTAssertEqual(viewModel.productRows.count, 2) // 2 spaghetti

        // When
        let updatedFilters = FilterProductListViewModel.Filters(
            stockStatus: nil,
            productStatus: nil,
            productType: ProductType.variable,
            productCategory: nil,
            numberOfActiveFilters: 1
        )
        viewModel.filters = updatedFilters

        // Then
        XCTAssertEqual(viewModel.productRows.count, 0) // no product matches the filter and search term

        // When
        viewModel.searchTerm = ""
        waitUntil {
            viewModel.productRows.isNotEmpty
        }

        // Then
        XCTAssertEqual(viewModel.productRows.count, 1) // only 1 variable product "Pizza"
    }

    func test_selectedProduct_does_not_change_if_selectedProduct_is_called_multiple_times_when_synchronizeProducts() {
        // Given
        var selectedProduct: Int64?
        let products = [
            Product.fake().copy(siteID: sampleSiteID, productID: 1, purchasable: true),
            Product.fake().copy(siteID: sampleSiteID, productID: 12345, purchasable: true)
        ]
        insert(products)

        let viewModel = ProductSelectorViewModel(
            siteID: sampleSiteID,
            storageManager: storageManager,
            onProductSelected: {
                selectedProduct = $0.productID
            })

        // When
        viewModel.selectProduct(products[0].productID)
        stores.whenReceivingAction(ofType: ProductAction.self, thenCall: { action in
            switch action {
            case let .synchronizeProducts(_, _, _, _, _, _, _, _, _, _, onCompletion):
                viewModel.selectProduct(products[1].productID)
                onCompletion(.success(true))
            default:
                XCTFail("Unsupported Action")
            }
        })

        // Then
        XCTAssertEqual(selectedProduct, products[0].productID)
    }
}

// MARK: - Utils
private extension ProductSelectorViewModelTests {
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
