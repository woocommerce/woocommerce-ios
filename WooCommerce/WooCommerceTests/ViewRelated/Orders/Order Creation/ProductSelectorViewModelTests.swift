import TestKit
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

    func test_view_model_is_initialized_with_default_values() {
        // Given
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID, source: .orderForm(flow: .creation))

        // Then
        XCTAssertTrue(viewModel.toggleAllVariationsOnSelection)
        XCTAssertEqual(viewModel.filterButtonTitle, "Filter")
        XCTAssertNil(viewModel.notice)
        XCTAssertEqual(viewModel.ghostRows.count, 6)
        XCTAssertEqual(viewModel.searchTerm, "")
        XCTAssertEqual(viewModel.totalSelectedItemsCount, 0)
    }

    func test_selectProductsTitle_when_changeSelectionStateForProduct_then_updates_text_reflecting_number_of_products_selected() {
        // Given
        let product1 = Product.fake().copy(siteID: sampleSiteID, productID: 1, purchasable: true)
        let product2 = Product.fake().copy(siteID: sampleSiteID, productID: 2, purchasable: true)
        insert(product1)
        insert(product2)
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation),
                                                 storageManager: storageManager)
        // When, Then
        assertEqual("Select products", viewModel.selectProductsTitle)

        viewModel.changeSelectionStateForProduct(with: product1.productID, selected: true)
        assertEqual("1 product selected", viewModel.selectProductsTitle)

        viewModel.changeSelectionStateForProduct(with: product2.productID, selected: true)
        assertEqual("2 products selected", viewModel.selectProductsTitle)
    }

    func test_view_model_adds_product_rows() {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, purchasable: true)
        insert(product)

        // When
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation),
                                                 storageManager: storageManager)

        // Then
        XCTAssertEqual(viewModel.productRows.count, 1)
    }

    func test_scrolling_indicator_appears_only_during_sync() {
        // Given
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation),
                                                 storageManager: storageManager,
                                                 stores: stores)
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
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation),
                                                 storageManager: storageManager,
                                                 stores: stores)
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .synchronizeProducts(_, _, _, _, _, _, _, _, _, _, onCompletion):
                XCTAssertEqual(viewModel.syncStatus, .loading)
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

    @MainActor
    func test_sync_status_updates_as_expected_when_products_are_synced() {
        // Given
        let mockStorageManager = MockStorageManager()
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = ProductSelectorViewModel(
            siteID: sampleSiteID,
            source: .orderForm(flow: .creation),
            storageManager: mockStorageManager,
            stores: mockStores
        )
        var syncStatusSpy: [ProductSelectorViewModel.SyncStatus] = []

        mockStores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .synchronizeProducts(_, _, _, _, _, _, _, _, _, _, onCompletion):
                if let syncStatus = viewModel.syncStatus {
                    syncStatusSpy.append(syncStatus)
                }
                let readOnlyProduct = Product.fake().copy(siteID: self.sampleSiteID, purchasable: true)
                let product = mockStorageManager.viewStorage.insertNewObject(ofType: StorageProduct.self)
                product.update(with: readOnlyProduct)
                onCompletion(.success(true))
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        waitFor { promise in
            viewModel.sync(pageNumber: 1, pageSize: 25, onCompletion: { _ in
                if let syncStatus = viewModel.syncStatus {
                    syncStatusSpy.append(syncStatus)
                }
                promise(())
            })
        }

        // Then
        XCTAssertEqual(syncStatusSpy, [.loading, .results])
        XCTAssertEqual(viewModel.syncStatus, .results)
    }

    func test_sync_status_does_not_change_while_syncing_when_storage_contains_products() {
        // Given
        let product = Product.fake().copy(siteID: self.sampleSiteID, purchasable: true)
        insert(product)

        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation),
                                                 storageManager: storageManager,
                                                 stores: stores)
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
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation),
                                                 storageManager: storageManager,
                                                 stores: stores)
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
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation),
                                                 storageManager: storageManager,
                                                 stores: stores)
        let expectation = expectation(description: "Completed product search")
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .searchProducts(_, _, _, _, _, _, _, _, _, _, onCompletion):
                let product = Product.fake().copy(siteID: self.sampleSiteID, purchasable: true)
                self.insert(product, withSearchTerm: "shirt")
                onCompletion(.success(false))
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

    func test_entering_search_term_when_search_filter_is_sku_then_requests_and_shows_right_products() {
        // Given
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation),
                                                 storageManager: storageManager,
                                                 stores: stores)
        let expectation = expectation(description: "Completed product search")
        let allFilterProduct = Product.fake().copy(siteID: self.sampleSiteID, productID: 1, name: "shirt", purchasable: true)
        let skuFilterProduct = Product.fake().copy(siteID: self.sampleSiteID, productID: 2, name: "t-shirt", purchasable: true)
        var remoteRequestSearchFilter: ProductSearchFilter?

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .searchProducts(_, _, filter, _, _, _, _, _, _, _, onCompletion):
                remoteRequestSearchFilter = filter
                self.insert(skuFilterProduct, withSearchTerm: "shirt", filterKey: "sku")
                self.insert(allFilterProduct, withSearchTerm: "shirt", filterKey: "all")
                onCompletion(.success(false))
                expectation.fulfill()
            case .searchProductsInCache:
                break
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        viewModel.productSearchFilter = .sku
        viewModel.searchTerm = "shirt"
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)

        // Then
        XCTAssertEqual(remoteRequestSearchFilter, .sku)
        XCTAssertEqual(viewModel.productRows.count, 1)
        XCTAssertEqual(viewModel.productRows[0].name, skuFilterProduct.name)
    }

    func test_entering_search_term_when_search_filter_is_sku_and_returns_variations_as_products_then_shows_the_variations() {
        // Given
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation),
                                                 storageManager: storageManager,
                                                 stores: stores)
        let expectation = expectation(description: "Completed product search")
        let skuFilterVariation = Product.fake().copy(siteID: self.sampleSiteID, productID: 2, name: "t-shirt", productTypeKey: "variation", purchasable: true)

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .searchProducts(_, _, _, _, _, _, _, _, _, _, onCompletion):
                self.insert(skuFilterVariation, withSearchTerm: "shirt", filterKey: "sku")
                onCompletion(.success(false))
                expectation.fulfill()
            case .searchProductsInCache:
                break
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        viewModel.productSearchFilter = .sku
        viewModel.searchTerm = "shirt"
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)

        // Then
        XCTAssertEqual(viewModel.productRows.count, 1)
        XCTAssertEqual(viewModel.productRows[0].name, skuFilterVariation.name)
    }

    func test_entering_search_term_when_there_are_no_filters_then_performs_local_product_search() {
        // Given
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation),
                                                 storageManager: storageManager,
                                                 stores: stores)
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
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation),
                                                 storageManager: storageManager,
                                                 stores: stores)
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

        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation),
                                                 storageManager: storageManager,
                                                 stores: stores)
        let expectation = expectation(description: "Completed product search")
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .searchProducts(_, _, _, _, _, _, _, _, _, _, onCompletion):
                self.insert(shirt, withSearchTerm: "shirt")
                onCompletion(.success(false))
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
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation))

        // When
        let filters = FilterProductListViewModel.Filters(
            stockStatus: .outOfStock,
            productStatus: .draft,
            promotableProductType: PromotableProductType(productType: .simple, isAvailable: true, promoteUrl: nil),
            productCategory: nil,
            numberOfActiveFilters: 3)

        viewModel.searchTerm = "shirt"
        viewModel.updateFilters(filters)
        viewModel.clearSearchAndFilters()

        // Then
        XCTAssertEqual(viewModel.searchTerm, "")
        XCTAssertEqual(viewModel.productSearchFilter, .all)
        XCTAssertEqual(viewModel.filterListViewModel.criteria, FilterProductListViewModel.Filters())
    }

    func test_clearing_search_returns_full_product_list() {
        // Given
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation),
                                                 storageManager: storageManager,
                                                 stores: stores)
        let expectation = expectation(description: "Cleared product search")
        let product = Product.fake().copy(siteID: sampleSiteID, purchasable: true)
        insert([product.copy(name: "T-shirt"), product.copy(name: "Hoodie")])
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .searchProducts(_, _, _, _, _, _, _, _, _, _, onCompletion):
                self.insert(product.copy(name: "T-shirt"), withSearchTerm: "shirt")
                onCompletion(.success(false))
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
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation))

        // Then
        let currentFilters = viewModel.filterListViewModel.criteria
        XCTAssertEqual(viewModel.searchTerm, "")
        XCTAssertNil(currentFilters.stockStatus)
        XCTAssertNil(currentFilters.productCategory)
        XCTAssertNil(currentFilters.promotableProductType)
        XCTAssertNil(currentFilters.productCategory)
        XCTAssertEqual(currentFilters.numberOfActiveFilters, 0)
    }

    func test_view_model_fires_error_notice_when_product_sync_fails() {
        // Given
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation),
                                                 stores: stores)
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
        let mockStorageManager = MockStorageManager()
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = ProductSelectorViewModel(
            siteID: sampleSiteID,
            source: .orderForm(flow: .creation),
            storageManager: mockStorageManager,
            stores: mockStores
        )

        // When
        let notice: Notice? = waitFor { promise in
            mockStores.whenReceivingAction(ofType: ProductAction.self) { action in
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
                                                 source: .orderForm(flow: .creation),
                                                 storageManager: storageManager,
                                                 onProductSelectionStateChanged: { updatedProduct, _ in
            selectedProduct = updatedProduct.productID
        })

        // When
        viewModel.changeSelectionStateForProduct(with: product.productID, selected: true)

        // Then
        XCTAssertEqual(selectedProduct, product.productID)
    }

    func test_selectProduct_given_supportsMultipleSelection_is_enabled_invokes_onProductSelected_closure_for_existing_product() {
        // Given
        var selectedProduct: Int64?
        let product = Product.fake().copy(siteID: sampleSiteID, productID: 1, purchasable: true)
        insert(product)
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation),
                                                 storageManager: storageManager,
                                                 onProductSelectionStateChanged: { updatedProduct, _ in
            selectedProduct = updatedProduct.productID
        })

        // When
        viewModel.changeSelectionStateForProduct(with: product.productID, selected: true)

        // Then
        XCTAssertEqual(selectedProduct, product.productID)
    }

    func test_variationRowTapped_sets_expected_view_model_for_variable_product() throws {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: 1, name: "Test Product", purchasable: true, variations: [1, 2])
        insert(product)
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation),
                                                 storageManager: storageManager)

        // When
        viewModel.variationRowTapped(for: product.productID)

        // Then
        let variationsViewModel = viewModel.productVariationListViewModel
        let actualViewModel = try XCTUnwrap(variationsViewModel)
        XCTAssertEqual(actualViewModel.productName, product.name)
        XCTAssertTrue(viewModel.isShowingProductVariationList)
    }

    func test_variationRowTapped_sets_nil_for_simple_product() {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: 1, name: "Test Product", purchasable: true)
        insert(product)
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation),
                                                 storageManager: storageManager)

        // When
        viewModel.variationRowTapped(for: product.productID)

        // Then
        let variationsViewModel = viewModel.productVariationListViewModel
        XCTAssertNil(variationsViewModel)
        XCTAssertFalse(viewModel.isShowingProductVariationList)
    }

    func test_variationCheckboxTapped_sets_expected_view_model_for_variable_product() throws {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: 1, name: "Test Product", purchasable: true, variations: [1, 2])
        insert(product)
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation),
                                                 storageManager: storageManager,
                                                 toggleAllVariationsOnSelection: false)

        // When
        viewModel.variationCheckboxTapped(for: product.productID)

        // Then
        let variationsViewModel = viewModel.productVariationListViewModel
        XCTAssertEqual(variationsViewModel?.productName, product.name)
        XCTAssertTrue(viewModel.isShowingProductVariationList)
    }

    func test_variationCheckboxTapped_sets_nil_for_simple_product() {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: 1, name: "Test Product", purchasable: true)
        insert(product)
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation),
                                                 storageManager: storageManager,
                                                 toggleAllVariationsOnSelection: false)

        // When
        viewModel.variationCheckboxTapped(for: product.productID)

        // Then
        let variationsViewModel = viewModel.productVariationListViewModel
        XCTAssertNil(variationsViewModel)
        XCTAssertFalse(viewModel.isShowingProductVariationList)
    }

    func test_selecting_a_product_if_supportsMultipleSelection_is_true_and_selectProduct_is_invoked_sets_its_row_to_selected_state() {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: 1, purchasable: true)
        insert(product)
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation),
                                                 storageManager: storageManager,
                                                 onProductSelectionStateChanged: { _, _ in })

        // When
        viewModel.changeSelectionStateForProduct(with: product.productID, selected: true)

        // Then
        let productRow = viewModel.productRows.first(where: { $0.productOrVariationID == product.productID })
        XCTAssertNotNil(productRow)
        XCTAssertEqual(productRow?.selectedState, .selected)
    }

    func test_deselecting_a_product_sets_its_row_to_notSelected_state_if_it_was_previously_selected() {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: 1, purchasable: true)
        insert(product)
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation),
                                                 storageManager: storageManager)

        // When
        viewModel.changeSelectionStateForProduct(with: product.productID, selected: true)
        viewModel.changeSelectionStateForProduct(with: product.productID, selected: false)

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
                                                 source: .orderForm(flow: .creation),
                                                 storageManager: storageManager,
                                                 onProductSelectionStateChanged: { _, _ in })

        // When
        viewModel.changeSelectionStateForProduct(with: product.productID, selected: true)
        viewModel.changeSelectionStateForProduct(with: product.productID, selected: false)

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
                                                 source: .orderForm(flow: .creation),
                                                 storageManager: storageManager)

        // When
        viewModel.changeSelectionStateForProduct(with: product.productID, selected: true)
        viewModel.changeSelectionStateForProduct(with: product.productID, selected: false)

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
                                                 source: .orderForm(flow: .creation),
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
                                                 source: .orderForm(flow: .creation),
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
                                                 source: .orderForm(flow: .creation),
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
                                                 source: .orderForm(flow: .creation),
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
                                                 source: .orderForm(flow: .creation),
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
                                                 source: .orderForm(flow: .creation),
                                                 selectedItemIDs: [],
                                                 storageManager: storageManager,
                                                 onMultipleSelectionCompleted: {
            selectedItems = $0
        })

        // When
        viewModel.changeSelectionStateForProduct(with: simpleProduct.productID, selected: true)
        viewModel.updateSelectedVariations(productID: variableProduct.productID, selectedVariationIDs: [12])
        viewModel.completeMultipleSelection()

        // Then
        XCTAssertEqual(selectedItems, [simpleProduct.productID, 12])
    }

    func test_analytics_when_completeMultipleSelection_closure_is_invoked_then_event_and_products_are_logged_correctly() throws {
        // Given
        let simpleProduct = Product.fake().copy(siteID: sampleSiteID, productID: 1, purchasable: true)
        let variableProduct = Product.fake().copy(siteID: sampleSiteID, productID: 10, purchasable: true, variations: [12, 20])
        insert(simpleProduct)
        insert(variableProduct)
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation),
                                                 selectedItemIDs: [1, 10, 20],
                                                 storageManager: storageManager,
                                                 analytics: analytics)

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

    func test_analytics_when_completeMultipleSelection_closure_is_invoked_and_filters_are_enabled_then_event_and_properties_are_logged_correctly() throws {
        // Given
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation),
                                                 selectedItemIDs: [1, 10, 20],
                                                 storageManager: storageManager,
                                                 analytics: analytics)

        // When
        let filters = FilterProductListViewModel.Filters(
            stockStatus: ProductStockStatus.outOfStock,
            productStatus: ProductStatus.draft,
            promotableProductType: PromotableProductType(productType: .simple, isAvailable: true, promoteUrl: nil),
            productCategory: nil,
            numberOfActiveFilters: 3
        )
        viewModel.searchTerm = ""
        viewModel.updateFilters(filters)

        viewModel.completeMultipleSelection()

        // Then
        guard let eventIndex = analyticsProvider.receivedEvents.firstIndex(where: { $0 == "order_creation_product_selector_confirm_button_tapped"}) else {
            return XCTFail("No event received")
        }

        let eventProperties = analyticsProvider.receivedProperties[eventIndex]
        guard let property = eventProperties.first(where: { $0.key as? String == "is_filter_active"}) else {
            return XCTFail("No property received")
        }
        XCTAssertTrue((property.value as? Bool) ?? false)
    }

    func test_analytics_when_completeMultipleSelection_closure_is_invoked_with_different_sources_then_event_and_source_are_logged_correctly() throws {
        // Given
        let mostPopularProductId: Int64 = 1
        let lastSoldProductId: Int64 = 10
        let otherProductId: Int64 = 50
        let selectedVariationId: Int64 = 12

        let simplePopularProduct = Product.fake().copy(siteID: sampleSiteID, productID: mostPopularProductId, purchasable: true)
        let variableLastSoldProduct = Product.fake().copy(siteID: sampleSiteID,
                                                          productID: lastSoldProductId,
                                                          purchasable: true,
                                                          variations: [selectedVariationId, 20])
        let otherSimpleProduct = Product.fake().copy(siteID: sampleSiteID, productID: otherProductId, purchasable: true)
        insert(simplePopularProduct)
        insert(variableLastSoldProduct)
        insert(otherSimpleProduct)

        let topProductsProvider = MockProductSelectorTopProductsProvider(provideTopProductsFromCachedOrders:
                                                                            ProductSelectorTopProducts(popularProductsIds: [mostPopularProductId],
                                                                                                        lastSoldProductsIds: [lastSoldProductId]))

        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation),
                                                 storageManager: storageManager,
                                                 analytics: analytics,
                                                 topProductsProvider: topProductsProvider)

        // When
        viewModel.changeSelectionStateForProduct(with: mostPopularProductId, selected: true)
        viewModel.updateSelectedVariations(productID: lastSoldProductId, selectedVariationIDs: [selectedVariationId])
        viewModel.changeSelectionStateForProduct(with: otherProductId, selected: true)
        viewModel.completeMultipleSelection()

        // Then
        guard let eventIndex = analyticsProvider.receivedEvents.firstIndex(where: { $0 == "order_creation_product_selector_confirm_button_tapped"}) else {
            return XCTFail("No event received")
        }

        let eventProperties = analyticsProvider.receivedProperties[eventIndex]
        guard let property = eventProperties.first(where: { $0.key as? String == "source"}),
        let propertyValue = property.value as? String else {
            return XCTFail("No property received")
        }

        XCTAssertTrue(propertyValue.contains("popular"))
        XCTAssertTrue(propertyValue.contains("recent"))
        XCTAssertTrue(propertyValue.contains("alphabetical"))
    }

    func test_analytics_when_completeMultipleSelection_closure_is_invoked_with_search_then_event_and_source_are_logged_correctly() throws {
        // Given
        let searchProductId: Int64 = 50

        let searchSimpleProduct = Product.fake().copy(siteID: sampleSiteID, productID: searchProductId, purchasable: true)
        insert(searchSimpleProduct)

        let topProductsProvider = MockProductSelectorTopProductsProvider(provideTopProductsFromCachedOrders:
                                                                            ProductSelectorTopProducts(popularProductsIds: [1],
                                                                                                        lastSoldProductsIds: [2]))

        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation),
                                                 storageManager: storageManager,
                                                 analytics: analytics,
                                                 topProductsProvider: topProductsProvider)

        // When
        viewModel.searchTerm = "test"
        viewModel.changeSelectionStateForProduct(with: searchProductId, selected: true)
        viewModel.completeMultipleSelection()

        // Then
        guard let eventIndex = analyticsProvider.receivedEvents.firstIndex(where: { $0 == "order_creation_product_selector_confirm_button_tapped"}) else {
            return XCTFail("No event received")
        }

        let eventProperties = analyticsProvider.receivedProperties[eventIndex]
        guard let property = eventProperties.first(where: { $0.key as? String == "source"}),
        let propertyValue = property.value as? String else {
            return XCTFail("No property received")
        }

        XCTAssertEqual(propertyValue, "search")
    }

    func test_analytics_when_completeMultipleSelection_closure_is_invoked_then_event_and_source_are_logged_correctly() throws {
        // Given
        let mostPopularProductId: Int64 = 1
        let lastSoldProductId: Int64 = 10
        let otherProductId: Int64 = 50
        let selectedVariationId: Int64 = 12

        let simplePopularProduct = Product.fake().copy(siteID: sampleSiteID, productID: mostPopularProductId, purchasable: true)
        let variableLastSoldProduct = Product.fake().copy(siteID: sampleSiteID,
                                                          productID: lastSoldProductId,
                                                          purchasable: true,
                                                          variations: [selectedVariationId, 20])
        let otherSimpleProduct = Product.fake().copy(siteID: sampleSiteID, productID: otherProductId, purchasable: true)
        insert(simplePopularProduct)
        insert(variableLastSoldProduct)
        insert(otherSimpleProduct)

        let topProductsProvider = MockProductSelectorTopProductsProvider(provideTopProductsFromCachedOrders:
                                                                            ProductSelectorTopProducts(popularProductsIds: [mostPopularProductId],
                                                                                                        lastSoldProductsIds: [lastSoldProductId]))

        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation),
                                                 storageManager: storageManager,
                                                 analytics: analytics,
                                                 topProductsProvider: topProductsProvider)

        // When
        viewModel.changeSelectionStateForProduct(with: mostPopularProductId, selected: true)
        viewModel.updateSelectedVariations(productID: lastSoldProductId, selectedVariationIDs: [selectedVariationId])
        viewModel.changeSelectionStateForProduct(with: otherProductId, selected: true)
        viewModel.completeMultipleSelection()

        // Then
        guard let eventIndex = analyticsProvider.receivedEvents.firstIndex(where: { $0 == "order_creation_product_selector_confirm_button_tapped"}) else {
            return XCTFail("No event received")
        }

        let eventProperties = analyticsProvider.receivedProperties[eventIndex]
        guard let property = eventProperties.first(where: { $0.key as? String == "source"}),
        let propertyValue = property.value as? String else {
            return XCTFail("No property received")
        }

        XCTAssertTrue(propertyValue.contains("popular"))
        XCTAssertTrue(propertyValue.contains("recent"))
        XCTAssertTrue(propertyValue.contains("alphabetical"))
    }

    func test_filter_button_title_shows_correct_number_of_active_filters() async throws {
        // Given
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation))
        let defaultTitle = NSLocalizedString("Filter", comment: "")
        // confidence check
        XCTAssertEqual(viewModel.filterButtonTitle, defaultTitle)

        // When
        let filters = FilterProductListViewModel.Filters(
            stockStatus: ProductStockStatus.outOfStock,
            productStatus: ProductStatus.draft,
            promotableProductType: PromotableProductType(productType: .simple, isAvailable: true, promoteUrl: nil),
            productCategory: nil,
            numberOfActiveFilters: 3
        )
        viewModel.searchTerm = ""
        viewModel.updateFilters(filters)
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
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation),
                                                 storageManager: storageManager)

        // When
        let filters = FilterProductListViewModel.Filters(
            stockStatus: nil,
            productStatus: nil,
            promotableProductType: PromotableProductType(productType: .simple, isAvailable: true, promoteUrl: nil),
            productCategory: nil,
            numberOfActiveFilters: 1
        )
        viewModel.updateFilters(filters)
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
                                                 source: .orderForm(flow: .creation),
                                                 storageManager: storageManager)

        // When
        viewModel.changeSelectionStateForProduct(with: product.productID, selected: true)
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
                                                 source: .orderForm(flow: .creation),
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
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation),
                                                 selectedItemIDs: [1, 12, 20],
                                                 onAllSelectionsCleared: {
            onAllSelectionsClearedCalled = true
        })

        // When
        viewModel.clearSelection()

        // Then
        XCTAssertTrue(onAllSelectionsClearedCalled)
    }

    func test_addSelection_allows_multiple_same_ids() {
        // Given
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation),
                                                 selectedItemIDs: [1, 12, 20])

        // When
        viewModel.addSelection(id: 1)
        viewModel.addSelection(id: 1)

        // Then
        XCTAssertEqual(viewModel.totalSelectedItemsCount, 5)
    }

    @MainActor
    func test_synchronizeProducts_are_triggered_with_correct_filters() async throws {
        // Given
        let mockStorageManager = MockStorageManager()
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = ProductSelectorViewModel(
            siteID: sampleSiteID,
            source: .orderForm(flow: .creation),
            storageManager: mockStorageManager,
            stores: mockStores
        )

        var filteredStockStatus: ProductStockStatus?
        var filteredProductStatus: ProductStatus?
        var filteredProductType: ProductType?
        var filteredProductCategory: Yosemite.ProductCategory?
        let filters = FilterProductListViewModel.Filters(
            stockStatus: .outOfStock,
            productStatus: .draft,
            promotableProductType: PromotableProductType(productType: .simple, isAvailable: true, promoteUrl: nil),
            productCategory: .init(categoryID: 123, siteID: sampleSiteID, parentID: 1, name: "Test", slug: "test"),
            numberOfActiveFilters: 1
        )

        mockStores.whenReceivingAction(ofType: ProductAction.self) { action in
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
        viewModel.updateFilters(filters)
        viewModel.searchTerm = ""
        try await Task.sleep(nanoseconds: searchDebounceTime)

        // Then
        assertEqual(filteredStockStatus, filters.stockStatus)
        assertEqual(filteredProductType, filters.promotableProductType?.productType)
        assertEqual(filteredProductStatus, filters.productStatus)
        assertEqual(filteredProductCategory, filters.productCategory)
    }

    func test_searchProducts_are_triggered_with_correct_filters() async throws {
        // Given
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation),
                                                 stores: stores)
        var filteredStockStatus: ProductStockStatus?
        var filteredProductStatus: ProductStatus?
        var filteredProductType: ProductType?
        var filteredProductCategory: Yosemite.ProductCategory?
        let filters = FilterProductListViewModel.Filters(
            stockStatus: .outOfStock,
            productStatus: .draft,
            promotableProductType: PromotableProductType(productType: .simple, isAvailable: true, promoteUrl: nil),
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
                onCompletion(.success(false))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }

        // When
        viewModel.updateFilters(filters)
        viewModel.searchTerm = "hiii"
        try await Task.sleep(nanoseconds: searchDebounceTime)

        // Then
        assertEqual(filteredStockStatus, filters.stockStatus)
        assertEqual(filteredProductType, filters.promotableProductType?.productType)
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

        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation),
                                                 storageManager: storageManager)
        XCTAssertEqual(viewModel.productRows.count, 3) // Confidence check

        // When
        viewModel.searchTerm = "spa"
        waitUntil {
            viewModel.productRows.count != 3
        }

        // Then
        XCTAssertEqual(viewModel.productRows.count, 2) // 2 spaghetti

        // When
        let filters = FilterProductListViewModel.Filters(
            stockStatus: nil,
            productStatus: nil,
            promotableProductType: PromotableProductType(productType: .variable, isAvailable: true, promoteUrl: nil),
            productCategory: nil,
            numberOfActiveFilters: 1
        )
        viewModel.updateFilters(filters)

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
            source: .orderForm(flow: .creation),
            storageManager: storageManager,
            onProductSelectionStateChanged: { updatedProduct, _ in
                selectedProduct = updatedProduct.productID
            })

        // When
        viewModel.changeSelectionStateForProduct(with: products[0].productID, selected: true)
        stores.whenReceivingAction(ofType: ProductAction.self, thenCall: { action in
            switch action {
            case let .synchronizeProducts(_, _, _, _, _, _, _, _, _, _, onCompletion):
                viewModel.changeSelectionStateForProduct(with: products[1].productID, selected: true)
                onCompletion(.success(true))
            default:
                XCTFail("Unsupported Action")
            }
        })

        // Then
        XCTAssertEqual(selectedProduct, products[0].productID)
    }

    func test_productsSectionViewModels_when_we_have_popular_and_most_recently_sold_products_then_it_includes_them_with_a_limit_and_with_the_given_order() {
        let maxTopProductGroupCount = 5
        let mostPopularProductIds: [Int64] = Array(1...6)
        let lastSoldProductIds: [Int64] = Array(7...10)

        let topProducts = (mostPopularProductIds.reversed() + lastSoldProductIds).map {
            Product.fake().copy(siteID: sampleSiteID, productID: $0, purchasable: true)
        }

        let extraProducts = [
            Product.fake().copy(siteID: sampleSiteID, productID: 123, purchasable: true),
            Product.fake().copy(siteID: sampleSiteID, productID: 12345, purchasable: true)
        ]

        let totalProducts = topProducts + extraProducts
        insert(totalProducts)

        let topProductsProvider = MockProductSelectorTopProductsProvider(provideTopProductsFromCachedOrders:
                                                                            ProductSelectorTopProducts(popularProductsIds: mostPopularProductIds,
                                                                                                        lastSoldProductsIds: lastSoldProductIds))
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation),
                                                 storageManager: storageManager,
                                                 stores: stores,
                                                 topProductsProvider: topProductsProvider)

        waitUntil {
            viewModel.productsSectionViewModels.isNotEmpty
        }

        let displayingPopularIds = viewModel.productsSectionViewModels.first?.productRows.map { $0.productOrVariationID }
        let displayingLastSoldIds = viewModel.productsSectionViewModels[safe: 1]?.productRows.map { $0.productOrVariationID }

        XCTAssertEqual(viewModel.productsSectionViewModels.count, 3)
        XCTAssertEqual(displayingPopularIds, Array(mostPopularProductIds.prefix(maxTopProductGroupCount)))
        XCTAssertEqual(displayingLastSoldIds, Array(lastSoldProductIds.prefix(maxTopProductGroupCount)))
        XCTAssertEqual(viewModel.productsSectionViewModels.last?.productRows.count, totalProducts.count)
    }

    func test_productsSectionViewModels_when_we_have_popular_and_most_recently_sold_products_with_duplicates_then_it_removes_limit() {
        let mostPopularProductIds: [Int64] = Array(1...6)
        let lastSoldProductIds: [Int64] = Array(5...8)

        let topProducts = (mostPopularProductIds + lastSoldProductIds).map {
            Product.fake().copy(siteID: sampleSiteID, productID: $0, purchasable: true)
        }

        let extraProducts = [
            Product.fake().copy(siteID: sampleSiteID, productID: 123, purchasable: true),
            Product.fake().copy(siteID: sampleSiteID, productID: 12345, purchasable: true)
        ]

        let totalProducts = topProducts + extraProducts
        insert(totalProducts)

        let topProductsProvider = MockProductSelectorTopProductsProvider(provideTopProductsFromCachedOrders:
                                                                            ProductSelectorTopProducts(popularProductsIds: mostPopularProductIds,
                                                                                                        lastSoldProductsIds: lastSoldProductIds))
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation),
                                                 storageManager: storageManager,
                                                 stores: stores,
                                                 topProductsProvider: topProductsProvider)

        waitUntil {
            viewModel.productsSectionViewModels.isNotEmpty
        }

        let displayingPopularIds = viewModel.productsSectionViewModels.first?.productRows.map { $0.productOrVariationID }
        let displayingLastSoldIds = viewModel.productsSectionViewModels[safe: 1]?.productRows.map { $0.productOrVariationID }

        guard let displayingPopularIds = displayingPopularIds,
              displayingPopularIds.isNotEmpty,
              let displayingLastSoldIds = displayingLastSoldIds,
              displayingLastSoldIds.isNotEmpty else {
            XCTFail()

            return
        }

        XCTAssertTrue(Set(displayingPopularIds).intersection(Set(displayingLastSoldIds)).isEmpty)
    }

    func test_productsSectionViewModels_when_we_have_popular_and_most_recently_sold_products_with_a_search_term_it_ignores_them() {
        // Given
        let mostPopularProductIds: [Int64] = Array(1...6)
        let lastSoldProductIds: [Int64] = Array(7...10)

        let topProductsProvider = MockProductSelectorTopProductsProvider(provideTopProductsFromCachedOrders:
                                                                            ProductSelectorTopProducts(popularProductsIds: mostPopularProductIds,
                                                                                                        lastSoldProductsIds: lastSoldProductIds))
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation),
                                                 storageManager: storageManager,
                                                 stores: stores,
                                                 topProductsProvider: topProductsProvider)


        let expectation = expectation(description: "Completed product search")
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .searchProducts(_, _, _, _, _, _, _, _, _, _, onCompletion):
                let product = Product.fake().copy(siteID: self.sampleSiteID, purchasable: true)
                self.insert(product, withSearchTerm: "shirt")
                onCompletion(.success(false))
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
        XCTAssertEqual(viewModel.productsSectionViewModels.count, 1)

    }

    func test_productsSectionViewModels_when_we_have_top_products_and_filters_it_shows_one_section() async throws {
        // Given
        let popularProductId: Int64 = 1
        let lastSoldProductId: Int64 = 10

        let topProductsProvider = MockProductSelectorTopProductsProvider(provideTopProductsFromCachedOrders:
                                                                            ProductSelectorTopProducts(popularProductsIds: [popularProductId],
                                                                                                        lastSoldProductsIds: [lastSoldProductId]))


        let simpleProduct = Product.fake().copy(siteID: sampleSiteID,
                                                productID: popularProductId,
                                                productTypeKey: ProductType.simple.rawValue,
                                                purchasable: true)
        let variableProduct = Product.fake().copy(siteID: sampleSiteID,
                                                  productID: lastSoldProductId,
                                                  productTypeKey: ProductType.variable.rawValue,
                                                  purchasable: true)
        insert(variableProduct)
        insert(simpleProduct)

        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation),
                                                 storageManager: storageManager,
                                                 stores: stores,
                                                 topProductsProvider: topProductsProvider)

        // When
        let filters = FilterProductListViewModel.Filters(
            stockStatus: nil,
            productStatus: nil,
            promotableProductType: PromotableProductType(productType: .simple, isAvailable: true, promoteUrl: nil),
            productCategory: nil,
            numberOfActiveFilters: 1
        )
        viewModel.updateFilters(filters)
        viewModel.searchTerm = ""
        try await Task.sleep(nanoseconds: searchDebounceTime)

        // Then
        XCTAssertEqual(viewModel.productsSectionViewModels.count, 1)
        XCTAssertEqual(viewModel.productRows.count, 1)
        XCTAssertEqual(viewModel.productRows.first?.productOrVariationID, simpleProduct.productID)
    }

    func test_bundle_product_row_is_not_configurable_when_onConfigureProductRow_is_nil() async throws {
        // Given
        _ = createAndInsertBundleProduct(bundleItems: [.fake()])
        let featureFlagService = MockFeatureFlagService(productBundlesInOrderForm: true)

        // When
        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation),
                                                 storageManager: storageManager,
                                                 stores: stores,
                                                 featureFlagService: featureFlagService,
                                                 onConfigureProductRow: nil)

        // Then
        XCTAssertEqual(viewModel.productRows.count, 1)
        let productRow = try XCTUnwrap(viewModel.productRows.first)
        XCTAssertFalse(productRow.isConfigurable)
    }

    func test_bundle_product_row_is_configurable_and_invokes_onConfigureProductRow_on_row_configure() async throws {
        // Given
        let bundleProduct = createAndInsertBundleProduct(bundleItems: [.fake()])
        let featureFlagService = MockFeatureFlagService(productBundlesInOrderForm: true)

        // When
        let productToConfigure: Yosemite.Product = try waitFor { promise in
            let viewModel = ProductSelectorViewModel(siteID: self.sampleSiteID,
                                                     source: .orderForm(flow: .creation),
                                                     storageManager: self.storageManager,
                                                     stores: self.stores,
                                                     featureFlagService: featureFlagService,
                                                     onConfigureProductRow: { product in
                promise(product)
            })

            // Then bundle product row is configurable
            XCTAssertEqual(viewModel.productRows.count, 1)
            let productRow = try XCTUnwrap(viewModel.productRows.first)
            XCTAssertTrue(productRow.isConfigurable)
            productRow.configure?()
        }

        // Then
        assertEqual(bundleProduct, productToConfigure)
    }

    // MARK: - Pagination

    func test_it_syncs_the_second_page_after_searching_and_selecting_a_product_not_in_the_first_page() {
        // Given
        var searchProductsPages = [Int]()
        var synchronizeProductsPages = [Int]()
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
                case let .searchProducts(_, _, _, pageNumber, _, _, _, _, _, _, onCompletion):
                    searchProductsPages.append(pageNumber)
                    let product = Product.fake().copy(siteID: self.sampleSiteID, productID: 3, purchasable: true)
                    self.insert(product, withSearchTerm: "shirt")
                    // No next page from the search.
                    onCompletion(.success(false))
                case let .synchronizeProducts(_, pageNumber, _, _, _, _, _, _, _, _, onCompletion):
                    synchronizeProductsPages.append(pageNumber)
                    let hasNextPage = pageNumber < 2
                    onCompletion(.success(hasNextPage))
                case .searchProductsInCache:
                    break
                default:
                    XCTFail("Unsupported Action")
            }
        }

        let viewModel = ProductSelectorViewModel(siteID: sampleSiteID,
                                                 source: .orderForm(flow: .creation),
                                                 storageManager: storageManager,
                                                 stores: stores)
        viewModel.onLoadTrigger.send(())

        XCTAssertEqual(synchronizeProductsPages, [1])
        XCTAssertEqual(searchProductsPages, [])

        // When
        viewModel.searchTerm = "shirt"

        waitUntil {
            searchProductsPages.isNotEmpty
        }

        viewModel.changeSelectionStateForProduct(with: 3, selected: true)

        XCTAssertEqual(synchronizeProductsPages, [1])
        XCTAssertEqual(searchProductsPages, [1])

        viewModel.searchTerm = ""

        waitUntil {
            synchronizeProductsPages == [1, 1]
        }

        XCTAssertEqual(searchProductsPages, [1])

        viewModel.syncNextPage()

        // Then
        XCTAssertEqual(synchronizeProductsPages, [1, 1, 2])
        XCTAssertEqual(searchProductsPages, [1])
    }
}

// MARK: - Utils
private extension ProductSelectorViewModelTests {
    @discardableResult
    func insert(_ readOnlyProduct: Yosemite.Product) -> StorageProduct {
        let product = storage.insertNewObject(ofType: StorageProduct.self)
        product.update(with: readOnlyProduct)
        return product
    }

    func insert(_ readOnlyProducts: [Yosemite.Product]) {
        for readOnlyProduct in readOnlyProducts {
            let product = storage.insertNewObject(ofType: StorageProduct.self)
            product.update(with: readOnlyProduct)
        }
    }

    func insert(_ readOnlyProduct: Yosemite.Product, withSearchTerm keyword: String, filterKey: String = "all") {
        insert(readOnlyProduct)

        let searchResult = storage.insertNewObject(ofType: ProductSearchResults.self)
        searchResult.keyword = keyword
        searchResult.filterKey = filterKey

        if let storedProduct = storage.loadProduct(siteID: readOnlyProduct.siteID, productID: readOnlyProduct.productID) {
            searchResult.addToProducts(storedProduct)
        }
    }

    func insert(_ readOnlyProductBundleItem: Yosemite.ProductBundleItem, for product: StorageProduct) {
        let bundleItem = storage.insertNewObject(ofType: StorageProductBundleItem.self)
        bundleItem.update(with: readOnlyProductBundleItem)
        bundleItem.product = product
    }

    func createAndInsertBundleProduct(bundleItems: [Yosemite.ProductBundleItem]) -> Yosemite.Product {
        let bundleProduct = Product.fake().copy(siteID: sampleSiteID,
                                                productID: 1,
                                                productTypeKey: ProductType.bundle.rawValue,
                                                purchasable: true,
                                                bundledItems: bundleItems)
        let storageProduct = insert(bundleProduct)

        bundleItems.forEach { bundleItem in
            insert(bundleItem, for: storageProduct)
        }

        return bundleProduct
    }
}

private extension ProductSelectorViewModel {
    var productRows: [ProductRowViewModel] {
        productsSectionViewModels.flatMap { $0.productRows }
    }
}
