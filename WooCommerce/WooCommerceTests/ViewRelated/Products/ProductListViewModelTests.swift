import XCTest
import Yosemite
import Fakes
import YosemiteTestHelpers
@testable import WooCommerce

@MainActor
final class ProductListViewModelTests: XCTestCase {
    private let sampleSiteID: Int64 = 123
    private var storesManager: MockStoresManager!
    private var upsertedSettings: [UpsertedSettings] = []
    private var resyncs: [Resync] = []

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
        recordResyncs(of: viewModel)
        let category = ProductCategory.fake().copy(categoryID: 7)
        viewModel.filters = FilterProductListViewModel.Filters(stockStatus: .outOfStock,
                                                               productStatus: nil,
                                                               promotableProductType: nil,
                                                               productCategory: category,
                                                               favoriteProduct: nil,
                                                               numberOfActiveFilters: 2)
        waitUntil { self.resyncs.isNotEmpty }
        upsertedSettings = []
        resyncs = []

        // When
        viewModel.sortOrder = .dateDescending

        // Then
        XCTAssertEqual(resyncs.map(\.sortOrder), [.dateDescending])
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
        recordResyncs(of: viewModel)

        // When
        viewModel.sortOrder = .default

        // Then
        XCTAssertTrue(resyncs.isEmpty, "Re-picking the current sort must not reset the list pages")
        XCTAssertTrue(upsertedSettings.isEmpty)
    }

    func test_filters_when_changed_then_persists_and_notifies_after_main_actor_hop() throws {
        // Given
        let viewModel = makeViewModel()
        recordProductsSettings()
        recordResyncs(of: viewModel)
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
        XCTAssertTrue(resyncs.isEmpty, "Restoring settings relies on `onDataReloaded` being sent before the filters side effects run")
        XCTAssertTrue(upsertedSettings.isEmpty)
        waitUntil { self.resyncs.isNotEmpty }
        XCTAssertEqual(resyncs.map(\.filters), [filters])
        let upserted = try XCTUnwrap(upsertedSettings.last)
        XCTAssertEqual(upserted.stockStatus, .outOfStock)
        XCTAssertEqual(upserted.productStatus, .draft)
        XCTAssertEqual(upserted.category, category)
        XCTAssertTrue(upserted.favoriteProduct)
    }

    func test_filters_when_set_to_equal_value_then_does_not_persist_or_notify() async {
        // Given
        let viewModel = makeViewModel()
        recordProductsSettings()
        recordResyncs(of: viewModel)

        // When
        viewModel.filters = FilterProductListViewModel.Filters()
        // Queued behind the didSet task on the main actor, so it runs once that task has finished.
        await Task { @MainActor in }.value

        // Then
        XCTAssertTrue(resyncs.isEmpty, "Re-applying the current filters must not reset the list pages")
        XCTAssertTrue(upsertedSettings.isEmpty)
    }

    func test_syncLocalProductsSettings_when_settings_stored_then_restores_sort_and_filters_before_completion() {
        // Given
        let viewModel = makeViewModel()
        recordProductsSettings(loading: .success(storedSettings(sort: ProductsSortOrder.dateAscending.rawValue, stockStatus: .inStock)))
        recordResyncs(of: viewModel)

        // When
        let (result, sortOrder, filters, resyncedSortOrders) = waitFor { promise in
            viewModel.syncLocalProductsSettings { result in
                promise((result, viewModel.sortOrder, viewModel.filters, self.resyncs.map(\.sortOrder)))
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(sortOrder, .dateAscending)
        XCTAssertEqual(resyncedSortOrders, [.dateAscending], "The list must be re-sorted before it reports the settings as loaded")
        XCTAssertEqual(filters.stockStatus, .inStock)
        XCTAssertEqual(filters.numberOfActiveFilters, 1)
    }

    func test_syncLocalProductsSettings_when_stored_category_was_deleted_remotely_then_clears_category_and_notifies() {
        // Given
        let viewModel = makeViewModel()
        let category = ProductCategory.fake().copy(categoryID: 7)
        recordProductsSettings(loading: .success(storedSettings(category: category)))
        stubCategorySync(result: .failure(ProductCategoryActionError.categoryDoesNotExistRemotely))
        recordResyncs(of: viewModel)

        // When
        viewModel.syncLocalProductsSettings { _ in }

        // Then
        waitUntil { self.resyncs.isNotEmpty }
        XCTAssertNil(viewModel.filters.productCategory)
        XCTAssertEqual(resyncs.map(\.filters), [FilterProductListViewModel.Filters()], "Restored filters equal the defaults, so only the remote change reloads")
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
        recordResyncs(of: viewModel)

        // When
        viewModel.syncLocalProductsSettings { _ in }

        // Then
        waitUntil { self.resyncs.isNotEmpty }
        XCTAssertEqual(viewModel.filters.productCategory, renamedCategory, "The filter must show the category's current name")
        XCTAssertEqual(resyncs.last?.filters.productCategory, renamedCategory)
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
        recordResyncs(of: viewModel)

        // When
        let result = waitFor { promise in
            viewModel.syncLocalProductsSettings { promise($0) }
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(viewModel.sortOrder, .default)
        XCTAssertEqual(viewModel.filters, FilterProductListViewModel.Filters())
        XCTAssertTrue(resyncs.isEmpty)
        XCTAssertTrue(upsertedSettings.isEmpty)
    }

    // MARK: - Products data

    func test_products_when_storage_changes_after_load_then_lists_stored_products_in_local_order() {
        // Given
        let storage = MockStorageManager()
        insert(makeProducts(["B", "A"]), into: storage)
        let viewModel = makeViewModel(storage: storage)

        // When
        XCTAssertFalse(viewModel.isEmpty)
        insert([Product.fake().copy(siteID: sampleSiteID, productID: 3, name: "C")], into: storage)

        // Then
        XCTAssertEqual(viewModel.products.map(\.name), ["A", "B", "C"], "The list must show what search or other flows store")
    }

    func test_sortOrder_when_changed_then_reorders_products() {
        // Given
        let storage = MockStorageManager()
        insert([
            Product.fake().copy(siteID: sampleSiteID, productID: 1, name: "A", date: Date(timeIntervalSince1970: 1)),
            Product.fake().copy(siteID: sampleSiteID, productID: 2, name: "B", date: Date(timeIntervalSince1970: 2))
        ], into: storage)
        let viewModel = makeViewModel(storage: storage)

        // When
        viewModel.sortOrder = .dateDescending

        // Then
        XCTAssertEqual(viewModel.products.map(\.productID), [2, 1])
    }

    func test_filters_when_favorite_filter_is_applied_then_lists_only_favorite_products() {
        // Given
        let storage = MockStorageManager()
        let favoriteProductsUseCase = MockFavoriteProductsUseCase()
        favoriteProductsUseCase.favoriteProductIDsValue = [2]
        let viewModel = makeViewModel(storage: storage, favoriteProductsUseCase: favoriteProductsUseCase)
        insert(makeProducts(["A", "B"]), into: storage)

        // When
        viewModel.filters = FilterProductListViewModel.Filters(stockStatus: nil,
                                                               productStatus: nil,
                                                               promotableProductType: nil,
                                                               productCategory: nil,
                                                               favoriteProduct: FavoriteProductsFilter(),
                                                               numberOfActiveFilters: 1)

        // Then
        waitUntil { viewModel.products.map(\.productID) == [2] }
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

    struct Resync {
        let sortOrder: ProductsSortOrder
        let filters: FilterProductListViewModel.Filters
    }

    func makeViewModel(storage: MockStorageManager = MockStorageManager(),
                       favoriteProductsUseCase: MockFavoriteProductsUseCase = MockFavoriteProductsUseCase()) -> ProductListViewModel {
        let resultsController = ResultsController<StorageProduct>(storageManager: storage,
                                                                  matching: NSPredicate(format: "siteID == %lld", sampleSiteID),
                                                                  sortOrder: .nameAscending)
        return ProductListViewModel(siteID: sampleSiteID,
                                    stores: storesManager,
                                    favoriteProductsUseCase: favoriteProductsUseCase,
                                    resultsController: resultsController)
    }

    func makeProducts(_ names: [String]) -> [Product] {
        names.enumerated().map { index, name in
            Product.fake().copy(siteID: sampleSiteID, productID: Int64(index + 1), name: name)
        }
    }

    /// `MockStorageManager` saves synchronously on the main queue.
    func insert(_ products: [Product], into storageManager: MockStorageManager) {
        storageManager.performAndSave({ storage in
            for product in products {
                storage.insertNewObject(ofType: StorageProduct.self).update(with: product)
            }
        }, completion: nil, on: .main)
    }

    /// Records the query the list resyncs with.
    func recordResyncs(of viewModel: ProductListViewModel) {
        viewModel.onNeedsResync = { [weak self, weak viewModel] in
            guard let viewModel else { return }
            self?.resyncs.append(.init(sortOrder: viewModel.sortOrder, filters: viewModel.filters))
        }
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
