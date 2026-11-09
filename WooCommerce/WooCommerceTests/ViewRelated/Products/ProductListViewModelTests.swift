import XCTest
import Yosemite
import Fakes
@testable import WooCommerce

@MainActor
final class ProductListViewModelTests: XCTestCase {
    private let sampleSiteID: Int64 = 123
    private var storesManager: MockStoresManager!
    private var upsertedSettings: [UpsertedSettings] = []

    override func setUp() {
        super.setUp()
        storesManager = MockStoresManager(sessionManager: .makeForTesting())
    }

    override func tearDown() {
        storesManager = nil
        upsertedSettings = []
        super.tearDown()
    }

    func test_selecting_and_deselecting_product_and_checking_its_state_works() {
        // Given
        let viewModel = ProductListViewModel(siteID: sampleSiteID, stores: storesManager)
        let sampleProduct1 = Product.fake().copy(productID: 1)
        XCTAssertFalse(viewModel.productIsSelected(sampleProduct1))

        // When
        viewModel.selectProduct(sampleProduct1)

        // Then
        XCTAssertEqual(viewModel.selectedProductsCount, 1)
        XCTAssertTrue(viewModel.productIsSelected(sampleProduct1))

        // When
        viewModel.deselectProduct(sampleProduct1)

        // Then
        XCTAssertEqual(viewModel.selectedProductsCount, 0)
        XCTAssertFalse(viewModel.productIsSelected(sampleProduct1))
    }

    func test_selecting_multiple_products_works() {
        // Given
        let viewModel = ProductListViewModel(siteID: sampleSiteID, stores: storesManager)
        let sampleProduct1 = Product.fake().copy(productID: 1)
        let sampleProduct2 = Product.fake().copy(productID: 2)
        let sampleProduct3 = Product.fake().copy(productID: 3)
        XCTAssertEqual(viewModel.selectedProductsCount, 0)

        // When
        viewModel.selectProduct(sampleProduct1)
        viewModel.selectProducts([sampleProduct2, sampleProduct3])

        // Then
        XCTAssertEqual(viewModel.selectedProductsCount, 3)
        XCTAssertTrue(viewModel.productIsSelected(sampleProduct1))
        XCTAssertTrue(viewModel.productIsSelected(sampleProduct2))
        XCTAssertTrue(viewModel.productIsSelected(sampleProduct3))
    }

    func test_deselecting_not_selected_product_does_nothing() {
        // Given
        let viewModel = ProductListViewModel(siteID: sampleSiteID, stores: storesManager)
        let sampleProduct1 = Product.fake().copy(productID: 1)
        let sampleProduct2 = Product.fake().copy(productID: 2)
        XCTAssertEqual(viewModel.selectedProductsCount, 0)

        // When
        viewModel.deselectProduct(sampleProduct1)
        viewModel.selectProduct(sampleProduct2)

        // Then
        XCTAssertEqual(viewModel.selectedProductsCount, 1)
        XCTAssertFalse(viewModel.productIsSelected(sampleProduct1))
        XCTAssertTrue(viewModel.productIsSelected(sampleProduct2))
    }

    func test_selecting_and_deselecting_product_twice_is_ignored() {
        // Given
        let viewModel = ProductListViewModel(siteID: sampleSiteID, stores: storesManager)
        let sampleProduct1 = Product.fake().copy(productID: 1)
        XCTAssertEqual(viewModel.selectedProductsCount, 0)

        // When
        viewModel.selectProduct(sampleProduct1)
        viewModel.selectProduct(sampleProduct1)

        // Then
        XCTAssertEqual(viewModel.selectedProductsCount, 1)
        XCTAssertTrue(viewModel.productIsSelected(sampleProduct1))

        // When
        viewModel.deselectProduct(sampleProduct1)
        viewModel.deselectProduct(sampleProduct1)

        // Then
        XCTAssertEqual(viewModel.selectedProductsCount, 0)
        XCTAssertFalse(viewModel.productIsSelected(sampleProduct1))
    }

    func test_bulk_edit_bool_is_set_correctly() {
        // Given
        let viewModel = ProductListViewModel(siteID: sampleSiteID, stores: storesManager)
        let sampleProduct1 = Product.fake().copy(productID: 1)
        XCTAssertFalse(viewModel.bulkEditActionIsEnabled)

        // When
        viewModel.selectProduct(sampleProduct1)

        // Then
        XCTAssertTrue(viewModel.bulkEditActionIsEnabled)

        // When
        viewModel.deselectProduct(sampleProduct1)

        // Then
        XCTAssertFalse(viewModel.bulkEditActionIsEnabled)
    }

    func test_deselect_all_works_correctly() {
        // Given
        let viewModel = ProductListViewModel(siteID: sampleSiteID, stores: storesManager)
        let sampleProduct1 = Product.fake().copy(productID: 1)
        let sampleProduct2 = Product.fake().copy(productID: 2)

        viewModel.selectProduct(sampleProduct1)
        viewModel.selectProduct(sampleProduct2)
        XCTAssertEqual(viewModel.selectedProductsCount, 2)

        // When
        viewModel.deselectAll()

        // Then
        XCTAssertEqual(viewModel.selectedProductsCount, 0)

        // When - Duplicated call
        viewModel.deselectAll()

        // Then
        XCTAssertEqual(viewModel.selectedProductsCount, 0)
    }

    func test_variation_helpers_work_correctly() {
        // Given
        let viewModel = ProductListViewModel(siteID: sampleSiteID, stores: storesManager)
        let sampleProduct1 = Product.fake().copy(productID: 1, productTypeKey: "simple")
        let sampleProduct2 = Product.fake().copy(productID: 2, productTypeKey: "variable")

        // When
        viewModel.selectProduct(sampleProduct1)
        viewModel.selectProduct(sampleProduct2)

        // Then
        XCTAssertEqual(viewModel.selectedProductsCount, 2)
        XCTAssertEqual(viewModel.selectedVariableProductsCount, 1)
        XCTAssertFalse(viewModel.onlyPriceIncompatibleProductsSelected)

        // When
        viewModel.deselectProduct(sampleProduct1)

        // Then
        XCTAssertEqual(viewModel.selectedProductsCount, 1)
        XCTAssertEqual(viewModel.selectedVariableProductsCount, 1)
        XCTAssertTrue(viewModel.onlyPriceIncompatibleProductsSelected)
    }

    func test_product_type_helpers_work_correctly() {
        // Given
        let viewModel = ProductListViewModel(siteID: sampleSiteID, stores: storesManager)

        // products compatible with bulk price update
        let sampleProduct1 = Product.fake().copy(productID: 1, productTypeKey: "simple")
        let sampleProduct2 = Product.fake().copy(productID: 2, productTypeKey: "affiliate")
        let sampleProduct3 = Product.fake().copy(productID: 3, productTypeKey: "custom-unknown")

        // products incompatible with bulk price update
        let sampleProduct4 = Product.fake().copy(productID: 4, productTypeKey: "variable")
        let sampleProduct5 = Product.fake().copy(productID: 5, productTypeKey: "grouped")
        let sampleProduct6 = Product.fake().copy(productID: 6, productTypeKey: "booking")

        // When
        viewModel.selectProduct(sampleProduct1)
        viewModel.selectProduct(sampleProduct2)
        viewModel.selectProduct(sampleProduct3)
        viewModel.selectProduct(sampleProduct4)
        viewModel.selectProduct(sampleProduct5)
        viewModel.selectProduct(sampleProduct6)

        // Then
        XCTAssertEqual(viewModel.selectedProductsCount, 6)
        XCTAssertEqual(viewModel.selectedPriceIncompatibleProductsCount, 3)
        XCTAssertFalse(viewModel.onlyPriceIncompatibleProductsSelected)

        // When
        viewModel.deselectProduct(sampleProduct1)
        viewModel.deselectProduct(sampleProduct2)
        viewModel.deselectProduct(sampleProduct3)

        // Then
        XCTAssertEqual(viewModel.selectedProductsCount, 3)
        XCTAssertEqual(viewModel.selectedPriceIncompatibleProductsCount, 3)
        XCTAssertTrue(viewModel.onlyPriceIncompatibleProductsSelected)
    }

    func test_common_status_works_correctly() {
        // Given
        let viewModel = ProductListViewModel(siteID: sampleSiteID, stores: storesManager)
        let sampleProduct1 = Product.fake().copy(productID: 1, statusKey: "draft")
        let sampleProduct2 = Product.fake().copy(productID: 2, statusKey: "draft")
        let sampleProduct3 = Product.fake().copy(productID: 3, statusKey: "publish")
        XCTAssertNil(viewModel.commonStatusForSelectedProducts)

        // When
        viewModel.selectProduct(sampleProduct1)
        viewModel.selectProduct(sampleProduct2)

        // Then
        XCTAssertEqual(viewModel.commonStatusForSelectedProducts, .draft)

        // When
        viewModel.selectProduct(sampleProduct3)

        // Then
        XCTAssertNil(viewModel.commonStatusForSelectedProducts)
    }

    func test_common_price_works_correctly() {
        // Given
        let viewModel = ProductListViewModel(siteID: sampleSiteID, stores: storesManager)
        let sampleProduct1 = Product.fake().copy(productID: 1, regularPrice: "100")
        let sampleProduct2 = Product.fake().copy(productID: 2, regularPrice: "100")
        let sampleProduct3 = Product.fake().copy(productID: 3, regularPrice: "200")
        XCTAssertEqual(viewModel.commonPriceForSelectedProducts, .none)

        // When
        viewModel.selectProduct(sampleProduct1)
        viewModel.selectProduct(sampleProduct2)

        // Then
        XCTAssertEqual(viewModel.commonPriceForSelectedProducts, .value("100"))

        // When
        viewModel.selectProduct(sampleProduct3)

        // Then
        XCTAssertEqual(viewModel.commonPriceForSelectedProducts, .mixed)
    }

    func test_updating_products_with_status_sets_correct_status() throws {
        // Given
        let viewModel = ProductListViewModel(siteID: sampleSiteID, stores: storesManager)
        let sampleProduct1 = Product.fake().copy(productID: 1, statusKey: "draft")
        let sampleProduct2 = Product.fake().copy(productID: 2, statusKey: "draft")
        let sampleProduct3 = Product.fake().copy(productID: 3, statusKey: "publish")

        storesManager.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .updateProducts(_, products, completion):
                XCTAssertTrue(products.allSatisfy { $0.statusKey == "publish" })
                completion(.success(products))
            default:
                break
            }
        }

        // When
        viewModel.selectProduct(sampleProduct1)
        viewModel.selectProduct(sampleProduct2)
        viewModel.selectProduct(sampleProduct3)
        let result = waitFor { promise in
            viewModel.updateSelectedProducts(with: .published) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
    }

    func test_updating_products_with_price_sets_correct_price_and_filters_simple_products() throws {
        // Given
        let viewModel = ProductListViewModel(siteID: sampleSiteID, stores: storesManager)
        let sampleProduct1 = Product.fake().copy(productID: 1, productTypeKey: "simple", regularPrice: "100")
        let sampleProduct2 = Product.fake().copy(productID: 2, productTypeKey: "affiliate", regularPrice: "200")
        let sampleProduct3 = Product.fake().copy(productID: 3, productTypeKey: "variable", regularPrice: "200")

        storesManager.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .updateProducts(_, products, completion):
                XCTAssertEqual(products.count, 2)
                XCTAssertTrue(products.allSatisfy { $0.regularPrice == "150" })
                completion(.success(products))
            default:
                break
            }
        }

        // When
        viewModel.selectProduct(sampleProduct1)
        viewModel.selectProduct(sampleProduct2)
        viewModel.selectProduct(sampleProduct3)
        let result = waitFor { promise in
            viewModel.updateSelectedProducts(with: "150") { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
    }

    func test_scanToUpdateInventoryButton_when_square_plugin_is_active_then_should_not_be_visible() {
        // Given
        let pluginsService = MockPluginsService()
        pluginsService.setMockPlugin(.wooSquare, systemPlugin: .fake().copy(
            siteID: sampleSiteID,
            plugin: "woocommerce-square/woocommerce-square.php",
            active: true
        ))

        let viewModel = ProductListViewModel(
            siteID: sampleSiteID,
            stores: storesManager,
            pluginsService: pluginsService
        )

        // When
        let result = waitFor { promise in
            viewModel.scanToUpdateInventoryButtonShouldBeVisible(isCameraAvailable: true) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertFalse(result)
    }

    func test_scanToUpdateInventoryButton_when_square_plugin_is_inactive_then_should_be_visible() {
        // Given
        let pluginsService = MockPluginsService()
        pluginsService.setMockPlugin(.wooSquare, systemPlugin: .fake().copy(
            siteID: sampleSiteID,
            plugin: "woocommerce-square/woocommerce-square.php",
            active: false
        ))

        let viewModel = ProductListViewModel(
            siteID: sampleSiteID,
            stores: storesManager,
            pluginsService: pluginsService
        )

        // When
        let result = waitFor { promise in
            viewModel.scanToUpdateInventoryButtonShouldBeVisible(isCameraAvailable: true) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result)
    }

    func test_scanToUpdateInventoryButton_when_square_plugin_is_not_installed_then_should_be_visible() {
        // Given
        let pluginsService = MockPluginsService()
        pluginsService.pluginsToReturnForLoadPluginInStorageByPlugin = [:]

        let viewModel = ProductListViewModel(
            siteID: sampleSiteID,
            stores: storesManager,
            pluginsService: pluginsService
        )

        // When
        let result = waitFor { promise in
            viewModel.scanToUpdateInventoryButtonShouldBeVisible(isCameraAvailable: true) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result)
    }

    // MARK: Favorite products
    //
    func test_it_loads_favorite_products_on_init() {
        // Given
        let favoriteProductsUseCase = MockFavoriteProductsUseCase()
        let viewModel = ProductListViewModel(siteID: sampleSiteID,
                                             stores: storesManager,
                                             favoriteProductsUseCase: favoriteProductsUseCase)

        // Then
        waitUntil {
            favoriteProductsUseCase.favoriteProductIDsCalled == true
        }
    }

    func test_it_loads_and_sets_favorite_product_IDs_correctly() async {
        // Given
        let favoriteProductsUseCase = MockFavoriteProductsUseCase()
        let viewModel = ProductListViewModel(siteID: sampleSiteID,
                                             stores: storesManager,
                                             favoriteProductsUseCase: favoriteProductsUseCase)

        XCTAssertTrue(viewModel.favoriteProductIDs.isEmpty)

        // When
        let sampleProductIDs: [Int64] = [1, 2, 3]
        favoriteProductsUseCase.favoriteProductIDsValue = sampleProductIDs
        await viewModel.loadFavoriteProductIDs()

        // Then
        XCTAssertEqual(viewModel.favoriteProductIDs, sampleProductIDs)
    }

    // MARK: - Products settings

    func test_sortOrder_when_changed_then_persists_sort_with_current_filters_and_notifies() throws {
        // Given
        let viewModel = makeViewModel()
        recordProductsSettings()
        var filtersApplied = false
        viewModel.onFiltersChanged = { _ in filtersApplied = true }
        let category = ProductCategory.fake().copy(categoryID: 7)
        viewModel.filters = FilterProductListViewModel.Filters(stockStatus: .outOfStock,
                                                               productStatus: nil,
                                                               promotableProductType: nil,
                                                               productCategory: category,
                                                               favoriteProduct: nil,
                                                               numberOfActiveFilters: 2)
        waitUntil { filtersApplied }
        upsertedSettings = []
        var notifiedSortOrder: ProductsSortOrder?
        viewModel.onSortOrderChanged = { notifiedSortOrder = $0 }

        // When
        viewModel.sortOrder = .dateDescending

        // Then
        XCTAssertEqual(notifiedSortOrder, .dateDescending)
        let upserted = try XCTUnwrap(upsertedSettings.last)
        XCTAssertEqual(upsertedSettings.count, 1)
        XCTAssertEqual(upserted.sort, ProductsSortOrder.dateDescending.rawValue)
        XCTAssertEqual(upserted.stockStatus, .outOfStock, "Saving a new sort must not drop the saved filters")
        XCTAssertEqual(upserted.category, category)
    }

    func test_sortOrder_when_set_to_same_value_then_does_not_persist_or_notify() {
        // Given
        let viewModel = makeViewModel()
        recordProductsSettings()
        var notified = false
        viewModel.onSortOrderChanged = { _ in notified = true }

        // When
        viewModel.sortOrder = .default

        // Then
        XCTAssertFalse(notified, "Re-picking the current sort must not reset the list pages")
        XCTAssertTrue(upsertedSettings.isEmpty)
    }

    func test_filters_when_changed_then_persists_and_notifies_after_main_actor_hop() throws {
        // Given
        let viewModel = makeViewModel()
        recordProductsSettings()
        var notifiedFilters: FilterProductListViewModel.Filters?
        viewModel.onFiltersChanged = { notifiedFilters = $0 }
        let category = ProductCategory.fake().copy(categoryID: 7)
        let filters = FilterProductListViewModel.Filters(stockStatus: .outOfStock,
                                                         productStatus: .draft,
                                                         promotableProductType: nil,
                                                         productCategory: category,
                                                         favoriteProduct: FavoriteProductsFilter(),
                                                         numberOfActiveFilters: 4)

        // When
        viewModel.filters = filters

        // Then
        XCTAssertNil(notifiedFilters, "Restoring settings relies on `onDataReloaded` being sent before the filters side effects run")
        XCTAssertTrue(upsertedSettings.isEmpty)
        waitUntil { notifiedFilters != nil }
        XCTAssertEqual(notifiedFilters, filters)
        let upserted = try XCTUnwrap(upsertedSettings.last)
        XCTAssertEqual(upserted.stockStatus, .outOfStock)
        XCTAssertEqual(upserted.productStatus, .draft)
        XCTAssertEqual(upserted.category, category)
        XCTAssertTrue(upserted.favoriteProduct)
    }

    func test_filters_when_set_to_equal_value_then_does_not_persist_or_notify() {
        // Given
        let viewModel = makeViewModel()
        recordProductsSettings()
        var notified = false
        viewModel.onFiltersChanged = { _ in notified = true }

        // When
        viewModel.filters = FilterProductListViewModel.Filters()
        // Queued behind the didSet task on the main actor, so it runs once that task has finished.
        var didSetTaskFinished = false
        Task { @MainActor in didSetTaskFinished = true }
        waitUntil { didSetTaskFinished }

        // Then
        XCTAssertFalse(notified, "Re-applying the current filters must not reset the list pages")
        XCTAssertTrue(upsertedSettings.isEmpty)
    }

    func test_syncLocalProductsSettings_when_settings_stored_then_restores_sort_and_filters_before_completion() {
        // Given
        let viewModel = makeViewModel()
        recordProductsSettings(loading: .success(storedSettings(sort: ProductsSortOrder.dateAscending.rawValue, stockStatus: .inStock)))
        var notifiedSortOrder: ProductsSortOrder?
        viewModel.onSortOrderChanged = { notifiedSortOrder = $0 }

        // When
        let (result, sortOrder, filters) = waitFor { promise in
            viewModel.syncLocalProductsSettings { result in
                promise((result, viewModel.sortOrder, viewModel.filters))
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(sortOrder, .dateAscending)
        XCTAssertEqual(notifiedSortOrder, .dateAscending, "The list must be re-sorted before it reports the settings as loaded")
        XCTAssertEqual(filters.stockStatus, .inStock)
        XCTAssertEqual(filters.numberOfActiveFilters, 1)
    }

    func test_syncLocalProductsSettings_when_stored_category_was_deleted_remotely_then_clears_category_and_notifies() {
        // Given
        let viewModel = makeViewModel()
        let category = ProductCategory.fake().copy(categoryID: 7)
        recordProductsSettings(loading: .success(storedSettings(category: category)))
        stubCategorySync(result: .failure(ProductCategoryActionError.categoryDoesNotExistRemotely))
        var notifiedFilters: FilterProductListViewModel.Filters?
        viewModel.onFiltersChanged = { notifiedFilters = $0 }

        // When
        viewModel.syncLocalProductsSettings { _ in }

        // Then
        waitUntil { notifiedFilters != nil }
        XCTAssertNil(viewModel.filters.productCategory)
        XCTAssertEqual(notifiedFilters, FilterProductListViewModel.Filters(), "Restored filters equal the defaults, so only the remote change reloads")
        XCTAssertEqual(upsertedSettings.count, 1)
        XCTAssertNil(upsertedSettings.first?.category, "A deleted category must not stay saved and pin the list to no results")
    }

    func test_syncLocalProductsSettings_when_stored_category_was_renamed_remotely_then_saves_and_applies_the_updated_category() {
        // Given
        let viewModel = makeViewModel()
        let category = ProductCategory.fake().copy(categoryID: 7, name: "Shoes")
        let renamedCategory = category.copy(name: "Sneakers")
        recordProductsSettings(loading: .success(storedSettings(category: category)))
        stubCategorySync(result: .success(renamedCategory))
        var notifiedFilters: FilterProductListViewModel.Filters?
        viewModel.onFiltersChanged = { notifiedFilters = $0 }

        // When
        viewModel.syncLocalProductsSettings { _ in }

        // Then
        waitUntil { notifiedFilters != nil }
        XCTAssertEqual(viewModel.filters.productCategory, renamedCategory, "The filter must show the category's current name")
        XCTAssertEqual(notifiedFilters?.productCategory, renamedCategory)
        XCTAssertEqual(upsertedSettings.last?.category, renamedCategory, "The saved filter must not keep the old name")
    }

    func test_syncLocalProductsSettings_when_category_sync_fails_for_other_reasons_then_keeps_stored_category() {
        // Given
        let viewModel = makeViewModel()
        let category = ProductCategory.fake().copy(categoryID: 7)
        recordProductsSettings(loading: .success(storedSettings(category: category)))
        stubCategorySync(result: .failure(NSError(domain: "network", code: 0)))

        // When
        let filters = waitFor { promise in
            viewModel.syncLocalProductsSettings { _ in
                promise(viewModel.filters)
            }
        }

        // Then
        XCTAssertEqual(filters.productCategory, category, "Being offline must not drop the user's category filter")
    }

    func test_syncLocalProductsSettings_when_loading_fails_then_completes_with_failure_and_keeps_defaults() {
        // Given
        let viewModel = makeViewModel()
        recordProductsSettings(loading: .failure(NSError(domain: "storage", code: 0)))
        var notified = false
        viewModel.onSortOrderChanged = { _ in notified = true }

        // When
        let result = waitFor { promise in
            viewModel.syncLocalProductsSettings { promise($0) }
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(viewModel.sortOrder, .default)
        XCTAssertEqual(viewModel.filters, FilterProductListViewModel.Filters())
        XCTAssertFalse(notified)
        XCTAssertTrue(upsertedSettings.isEmpty)
    }
}

private extension ProductListViewModelTests {
    struct UpsertedSettings {
        let sort: String?
        let stockStatus: ProductStockStatus?
        let productStatus: ProductStatus?
        let category: ProductCategory?
        let favoriteProduct: Bool
    }

    func makeViewModel() -> ProductListViewModel {
        ProductListViewModel(siteID: sampleSiteID, stores: storesManager, favoriteProductsUseCase: MockFavoriteProductsUseCase())
    }

    func recordProductsSettings(loading loadResult: Result<StoredProductSettings.Setting, Error>? = nil) {
        storesManager.whenReceivingAction(ofType: AppSettingsAction.self) { [weak self] action in
            switch action {
            case let .upsertProductsSettings(_, sort, stockStatus, productStatus, _, category, favoriteProduct, onCompletion):
                self?.upsertedSettings.append(.init(sort: sort,
                                                    stockStatus: stockStatus,
                                                    productStatus: productStatus,
                                                    category: category,
                                                    favoriteProduct: favoriteProduct))
                onCompletion(nil)
            case let .loadProductsSettings(_, onCompletion):
                if let loadResult {
                    onCompletion(loadResult)
                }
            default:
                break
            }
        }
    }

    func stubCategorySync(result: Result<ProductCategory, Error>) {
        storesManager.whenReceivingAction(ofType: ProductCategoryAction.self) { action in
            if case let .synchronizeProductCategory(_, _, onCompletion) = action {
                onCompletion(result)
            }
        }
    }

    func storedSettings(sort: String? = nil,
                        stockStatus: ProductStockStatus? = nil,
                        category: ProductCategory? = nil) -> StoredProductSettings.Setting {
        StoredProductSettings.Setting(siteID: sampleSiteID,
                                      sort: sort,
                                      stockStatusFilter: stockStatus,
                                      productStatusFilter: nil,
                                      productTypeFilter: nil,
                                      productCategoryFilter: category,
                                      favoriteProduct: false)
    }
}
