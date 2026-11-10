import Combine
import Foundation
import UIKit
import Yosemite

/// View model for `ProductsViewController`: sort, filters, saved settings, bulk editing and subscriptions.
///
final class ProductListViewModel: ObservableObject {

    enum BulkEditError: Error {
        case noProductsSelected
    }

    let siteID: Int64
    private let stores: StoresManager
    private let pluginsService: PluginsServiceProtocol

    private(set) var selectedProducts: Set<Product> = .init()

    private var wooSubscriptionProductsEligibilityChecker: WooSubscriptionProductsEligibilityCheckerProtocol

    private let barcodeScannerItemFinder: BarcodeScannerItemFinder

    private let favoriteProductsUseCase: FavoriteProductsUseCase
    private(set) var favoriteProductIDs: [Int64] = []

    /// Latest presentable products, recomputed on every storage, sort or filter change.
    @MainActor
    @Published private(set) var products: [ProductListItem] = []

    /// Sent after `products` is recomputed for a storage change, unlike sort, filter or page-order reloads.
    let storageDidChange = PassthroughSubject<Void, Never>()

    // TODO: temporary until pagination moves into the view model.
    @MainActor
    var syncingPageNumber: Int?
    @MainActor
    var onNeedsResync: (() -> Void)?

    // The store's name sort can differ from the local sort, so keep products from later pages below earlier pages.
    @MainActor
    private var productPageOrder = ProductListPageOrder()

    private let providedResultsController: ResultsController<StorageProduct>?

    /// ResultsController: Surrounds us. Binds the galaxy together. And also, keeps the UITableView <> (Stored) Products in sync.
    ///
    @MainActor
    private lazy var resultsController: ResultsController<StorageProduct> = {
        let resultsController = providedResultsController ?? createResultsController()
        configureResultsController(resultsController)
        return resultsController
    }()

    @MainActor
    var sortOrder: ProductsSortOrder = .default {
        didSet {
            if sortOrder != oldValue {
                updateLocalProductSettings(sort: sortOrder,
                                           filters: filters)
                resultsController.updateSortOrder(sortOrder)

                /// Reload data because `updateSortOrder` generates a new `predicate` which calls `performFetch`
                resyncWithNewSortOrFilters()
            }
        }
    }

    @MainActor
    @Published var filters = FilterProductListViewModel.Filters() {
        didSet {
            Task { @MainActor in
                if filters != oldValue ||
                    categoryHasChangedRemotely {
                    updateLocalProductSettings(sort: sortOrder,
                                               filters: filters)
                    await updatePredicate(filters: filters)

                    /// Reload because `updatePredicate` calls `performFetch` when creating a new predicate
                    resyncWithNewSortOrFilters()
                }
            }
        }
    }

    /// Set to `true` when a category is applied to the product filters and the value has changed after a remote sync.
    @MainActor
    private var categoryHasChangedRemotely: Bool = false

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         favoriteProductsUseCase: FavoriteProductsUseCase? = nil,
         barcodeScannerItemFinder: BarcodeScannerItemFinder = BarcodeScannerItemFinder(),
         pluginsService: PluginsServiceProtocol = PluginsService(storageManager: ServiceLocator.storageManager),
         resultsController: ResultsController<StorageProduct>? = nil) {
        self.siteID = siteID
        self.providedResultsController = resultsController
        self.stores = stores
        self.wooSubscriptionProductsEligibilityChecker = WooSubscriptionProductsEligibilityChecker(siteID: siteID)
        self.barcodeScannerItemFinder = barcodeScannerItemFinder
        self.favoriteProductsUseCase = favoriteProductsUseCase ?? DefaultFavoriteProductsUseCase(siteID: siteID)
        self.pluginsService = pluginsService

        Task { @MainActor [weak self] in
            await self?.loadFavoriteProductIDs()
        }
    }

    var selectedProductsCount: Int {
        selectedProducts.count
    }

    var selectedVariableProductsCount: Int {
        selectedProducts.filter({ $0.productType == .variable }).count
    }

    /// Product types that are incompatible with bulk update of regular price
    ///
    private let priceIncompatibleProductsTypes: Set<ProductType> = [
        .variable,
        .grouped,
        .custom("booking")
    ]

    /// Number of selected products that are incompatible with bulk update of regular price
    ///
    var selectedPriceIncompatibleProductsCount: Int {
        selectedProducts.filter({ priceIncompatibleProductsTypes.contains($0.productType) }).count
    }

    /// Boolean indicating if all of selected products are incompatible with bulk update of regular price
    ///
    var onlyPriceIncompatibleProductsSelected: Bool {
        !selectedProducts.isEmpty && onlyPriceCompatibleSelectedProducts.isEmpty
    }

    /// Subset of selected products filtered for types that support bulk update of regular price
    ///
    private var onlyPriceCompatibleSelectedProducts: Set<Product> {
        selectedProducts.filter({ !priceIncompatibleProductsTypes.contains($0.productType) })
    }

    var bulkEditActionIsEnabled: Bool {
        !selectedProducts.isEmpty
    }

    func productIsSelected(_ productToCheck: Product) -> Bool {
        return selectedProducts.contains(productToCheck)
    }

    func selectProduct(_ product: Product) {
        selectedProducts.insert(product)
    }

    func selectProducts(_ products: [Product]) {
        selectedProducts.formUnion(products)
    }

    func deselectProduct(_ product: Product) {
        selectedProducts.remove(product)
    }

    func deselectAll() {
        selectedProducts.removeAll()
    }

    /// Represents if a property in a collection of `Product`  has the same value or different values or is missing.
    ///
    enum BulkValue: Equatable {
        /// All variations have the same value
        case value(String)
        /// When variations have mixed values.
        case mixed
        /// None of the variation has a value
        case none
    }

    /// Check if selected products share the same common ProductStatus. Returns `nil` otherwise.
    ///
    var commonStatusForSelectedProducts: ProductStatus? {
        let status = selectedProducts.first?.productStatus
        if selectedProducts.allSatisfy({ $0.productStatus == status }) {
            return status
        } else {
            return nil
        }
    }

    /// Check if selected products share the same common ProductStatus. Returns `nil` otherwise.
    ///
    var commonPriceForSelectedProducts: BulkValue {
        if selectedProducts.allSatisfy({ $0.regularPrice?.isEmpty != false }) {
            return .none
        } else if let price = selectedProducts.first?.regularPrice, selectedProducts.allSatisfy({ $0.regularPrice == price }) {
            return .value(price)
        } else {
            return .mixed
        }
    }

    /// Update selected products with new ProductStatus and trigger Network action to save the change remotely.
    ///
    func updateSelectedProducts(with newStatus: ProductStatus, completion: @escaping (Result<Void, Error>) -> Void ) {
        guard selectedProductsCount > 0 else {
            completion(.failure(BulkEditError.noProductsSelected))
            return
        }

        let updatedProducts = selectedProducts.map({ $0.copy(statusKey: newStatus.rawValue) })
        let batchAction = ProductAction.updateProducts(siteID: siteID, products: updatedProducts) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        stores.dispatch(batchAction)
    }

    /// Update selected products with new price and trigger Network action to save the change remotely.
    ///
    func updateSelectedProducts(with newPrice: String, completion: @escaping (Result<Void, Error>) -> Void ) {
        guard !onlyPriceIncompatibleProductsSelected else {
            completion(.failure(BulkEditError.noProductsSelected))
            return
        }

        let updatedProducts = onlyPriceCompatibleSelectedProducts.map({ $0.copy(regularPrice: newPrice) })
        let batchAction = ProductAction.updateProducts(siteID: siteID, products: updatedProducts) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        stores.dispatch(batchAction)
    }

    /// Whether site has Woo Subscriptions extension enabled
    ///
    var isEligibleForSubscriptions: Bool {
        wooSubscriptionProductsEligibilityChecker.isSiteEligible()
    }

    @MainActor
    func handleScannedBarcode(_ scannedBarcode: ScannedBarcode) async throws -> ItemIdentifierSearchResult {
        do {
            return try await barcodeScannerItemFinder.searchByIdentifier(from: scannedBarcode,
                                                                     siteID: siteID,
                                                                     source: .scanToUpdateInventory)
        } catch {
            DDLogInfo("SKU search failed with error: \(error)")
            throw error
            // TODO: Show error notice
        }
    }

    // The feature breaks if the Square plugin is active, since modifies inventory management logic
    // If the plugin is active, we'll hide the inventory scanner button
    // More details: https://wp.me/pdfdoF-2Nq
    @MainActor
    func scanToUpdateInventoryButtonShouldBeVisible(isCameraAvailable: Bool? = nil,
                                                    completion: @escaping (Bool) -> (Void)) {
        let isCameraAvailable = isCameraAvailable ?? UIImagePickerController.isSourceTypeAvailable(.camera)
        let isPluginActive = isPluginActive(.wooSquare)
        switch isPluginActive {
        case true:
            completion(false)
        case false:
            guard isCameraAvailable else {
                return completion(false)
            }
            // If all conditions are met, scan to update inventory should be visible:
            // 1. No Square plugin
            // 2. Camera is available
            completion(true)
        }
    }

    /// Loads favorite product IDs
    ///
    @MainActor
    func loadFavoriteProductIDs() async {
        favoriteProductIDs = await favoriteProductsUseCase.favoriteProductIDs()
    }

    @MainActor
    private func isPluginActive(_ plugin: Plugin) -> Bool {
        pluginsService.isPluginActiveInStorage(siteID: siteID, plugin: plugin)
    }
}

// MARK: - Products data
//
@MainActor
extension ProductListViewModel {
    var isEmpty: Bool {
        resultsController.isEmpty
    }

    var fetchedProducts: [Product] {
        resultsController.fetchedObjects
    }

    func product(withID productID: Int64) -> Product? {
        guard let indexPath = resultsController.indexPath(forObjectMatching: { $0.productID == productID }) else {
            return nil
        }
        return resultsController.safeObject(at: indexPath)
    }

    /// Recorded pages belong to the previous sort or filters.
    func resyncWithNewSortOrFilters() {
        productPageOrder.reset()
        products = presentableProducts(resultsController.listItems)
        onNeedsResync?()
    }

    /// A successful first page replaces the stored products (`shouldDeleteStoredProductsOnFirstPage`).
    func firstPageDidSync() {
        productPageOrder.reset()
        recordProductPages()
        let syncedProducts = presentableProducts(resultsController.listItems)
        if syncedProducts.map(\.productID) != products.map(\.productID) {
            products = syncedProducts
        }
    }

    func reloadFavoriteProductsIfNeeded() async {
        // Reload only if favorite products filter is turned on
        guard filters.favoriteProduct != nil else {
            return
        }

        let previousFavoriteProductIDs = favoriteProductIDs
        await loadFavoriteProductIDs()

        // Reload only if favorite product IDs changed
        guard favoriteProductIDs != previousFavoriteProductIDs else {
            return
        }

        await updatePredicate(filters: filters)

        /// Reload because `updatePredicate` calls `performFetch` when creating a new predicate
        resyncWithNewSortOrFilters()
    }

    func updatePredicate(filters: FilterProductListViewModel.Filters) async {
        let productIDs: [Int64]? = await {
            guard filters.favoriteProduct != nil else {
                return nil
            }

            await loadFavoriteProductIDs()
            return favoriteProductIDs
        }()

        resultsController.updatePredicate(siteID: siteID,
                                          stockStatus: filters.stockStatus,
                                          productStatus: filters.productStatus,
                                          productType: filters.promotableProductType?.productType,
                                          productIDs: productIDs)
    }
}

@MainActor
private extension ProductListViewModel {
    func createResultsController() -> ResultsController<StorageProduct> {
        let predicate = NSPredicate.createProductPredicate(siteID: siteID,
                                                           stockStatus: filters.stockStatus,
                                                           productStatus: filters.productStatus,
                                                           productType: filters.promotableProductType?.productType)

        return ResultsController<StorageProduct>(storageManager: ServiceLocator.storageManager,
                                                 matching: predicate,
                                                 sortOrder: sortOrder)
    }

    /// Configure resultController.
    /// Assign closures and start performBatch
    ///
    func configureResultsController(_ resultsController: ResultsController<StorageProduct>) {
        resultsController.onDidChangeContent = { [weak self] in
            self?.didChangeStoredProducts()
        }

        resultsController.onDidResetContent = { [weak self] in
            self?.didChangeStoredProducts()
        }

        do {
            try resultsController.performFetch()
        } catch {
            ServiceLocator.crashLogging.logError(error)
        }

        products = presentableProducts(resultsController.listItems)
    }

    /// Records pages on every storage change, even while a refresh defers presentation.
    func didChangeStoredProducts() {
        recordProductPages()
        products = presentableProducts(resultsController.listItems)
        storageDidChange.send(())
    }

    func recordProductPages() {
        productPageOrder.record(resultsController.productNames, syncingPageNumber: syncingPageNumber)
    }

    /// Only the name sort can differ between the store and the device.
    func presentableProducts(_ products: [ProductListItem]) -> [ProductListItem] {
        switch sortOrder {
        case .nameAscending, .nameDescending:
            return productPageOrder.ordered(products)
        case .dateAscending, .dateDescending:
            return products
        }
    }
}

// MARK: - Products settings
//
@MainActor
extension ProductListViewModel {
    /// Update local Products Settings (eg. sort order or filters stored in Products settings)
    ///
    private func updateLocalProductSettings(sort: ProductsSortOrder? = nil,
                                            filters: FilterProductListViewModel.Filters) {
        let action = AppSettingsAction.upsertProductsSettings(siteID: siteID,
                                                              sort: sort?.rawValue,
                                                              stockStatusFilter: filters.stockStatus,
                                                              productStatusFilter: filters.productStatus,
                                                              productTypeFilter: filters.promotableProductType?.productType,
                                                              productCategoryFilter: filters.productCategory,
                                                              favoriteProduct: filters.favoriteProduct != nil) { _ in
        }
        stores.dispatch(action)
    }

    /// Fetch local Products Settings (eg. sort order or filters stored in Products settings)
    ///
    func syncLocalProductsSettings(onCompletion: @escaping (Result<StoredProductSettings.Setting, Error>) -> Void) {
        let action = AppSettingsAction.loadProductsSettings(siteID: siteID) { [weak self] result in
            switch result {
            case .success(let settings):
                self?.syncProductCategoryFilterRemotely(from: settings) { [weak self] settings in
                    guard let self else { return }
                    if let sort = settings.sort {
                        sortOrder = ProductsSortOrder(rawValue: sort) ?? .default
                    }

                    let promotableProductType = settings.productTypeFilter.map { PromotableProductType(productType: $0, isAvailable: true, promoteUrl: nil) }
                    filters = FilterProductListViewModel.Filters(stockStatus: settings.stockStatusFilter,
                                                                 productStatus: settings.productStatusFilter,
                                                                 promotableProductType: promotableProductType,
                                                                 productCategory: settings.productCategoryFilter,
                                                                 favoriteProduct: settings.favoriteProduct ? FavoriteProductsFilter() : nil,
                                                                 numberOfActiveFilters: settings.numberOfActiveFilters())
                    onCompletion(result)
                }
            case let .failure(error):
                DDLogError("⛔️ Error loading product settings: \(error)")
                onCompletion(result)
            }
        }
        stores.dispatch(action)
    }

    /// Syncs the Product Category filter of settings remotely. This is necessary in case the category information was updated
    /// or the category itself removed.
    ///
    private func syncProductCategoryFilterRemotely(from settings: StoredProductSettings.Setting,
                                                   onCompletion: @escaping (StoredProductSettings.Setting) -> Void) {
        categoryHasChangedRemotely = false
        guard let productCategory = settings.productCategoryFilter else {
            onCompletion(settings)
            return
        }

        let action = ProductCategoryAction.synchronizeProductCategory(siteID: siteID, categoryID: productCategory.categoryID) { [weak self] result in
            guard let self else { return }
            var updatingProductCategory: ProductCategory? = productCategory

            switch result {
            case .success(let productCategory):
                updatingProductCategory = productCategory
            case .failure(let error):
                if let error = error as? ProductCategoryActionError,
                   case .categoryDoesNotExistRemotely = error {
                    // The product category was removed
                    updatingProductCategory = nil
                }
            }

            var completionSettings = settings
            if updatingProductCategory != productCategory {
                categoryHasChangedRemotely = true
                completionSettings = StoredProductSettings.Setting(siteID: settings.siteID,
                                                                sort: settings.sort,
                                                                stockStatusFilter: settings.stockStatusFilter,
                                                                productStatusFilter: settings.productStatusFilter,
                                                                productTypeFilter: settings.productTypeFilter,
                                                                productCategoryFilter: updatingProductCategory,
                                                                favoriteProduct: settings.favoriteProduct)
            }

            onCompletion(completionSettings)
        }

        stores.dispatch(action)
    }
}
