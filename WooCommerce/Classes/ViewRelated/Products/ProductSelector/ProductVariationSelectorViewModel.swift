import Yosemite
import protocol Storage.StorageManagerType
import Combine
import WooFoundation

/// View model for `ProductVariationSelectorView`.
///
final class ProductVariationSelectorViewModel: ObservableObject {
    private let siteID: Int64

    /// Storage to fetch product variation list
    ///
    private let storageManager: StorageManagerType

    /// Stores to sync product variation list
    ///
    private let stores: StoresManager

    /// Store for publishers subscriptions
    ///
    private var subscriptions = Set<AnyCancellable>()

    /// Trigger to perform any one time setups.
    ///
    let onLoadTrigger: PassthroughSubject<Void, Never> = PassthroughSubject()

    /// Defines the current notice that should be shown.
    /// Defaults to `nil`.
    ///
    @Published var notice: Notice?

    /// The ID of the parent variable product
    ///
    let productID: Int64

    /// The name of the parent variable product
    ///
    let productName: String

    /// All attributes for variations of the parent variable product
    ///
    private let productAttributes: [ProductAttribute]

    /// All purchasable product variations for the product.
    ///
    @Published private var productVariations: [ProductVariation] = []

    /// View models for each product variation row
    ///
    @Published var productVariationRows: [ProductRowViewModel] = []

    /// Closure to be invoked when a product variation is selected
    ///
    let onVariationSelectionStateChanged: ((ProductVariation, Product, Bool) -> Void)?

    /// Closure to be invoked when "Clear Selection" is called.
    ///
    private let onSelectionsCleared: (() -> Void)?

    /// A list of variation IDs that are allowed in the selector.
    ///
    private let allowedProductVariationIDs: [Int64]

    /// All selected product variations if the selector supports multiple selections.
    ///
    @Published private(set) var selectedProductVariationIDs: [Int64]

    // MARK: Sync & Storage properties

    /// Current sync status; used to determine what list view to display.
    ///
    @Published private(set) var syncStatus: SyncStatus?

    /// SyncCoordinator: Keeps tracks of which pages have been refreshed, and encapsulates the "What should we sync now" logic.
    ///
    private let syncingCoordinator = SyncingCoordinator()

    /// Tracks if the infinite scroll indicator should be displayed
    ///
    @Published private(set) var shouldShowScrollIndicator = false

    /// View models of the ghost rows used during the loading process.
    ///
    var ghostRows: [ProductRowViewModel] {
        return Array(0..<6).map { index in
            ghostProductRow(id: index)
        }
    }

    /// Product Result Controller.
    /// Used the retrieve the parent product upon selecting a variation.
    ///
    private lazy var productResultsController: ResultsController<StorageProduct> = {
        let predicate = NSPredicate(format: "siteID == %lld AND productID == %lld", siteID, productID)
        let resultsController = ResultsController<StorageProduct>(storageManager: storageManager, matching: predicate, sortedBy: [])
        return resultsController
    }()

    /// Product Variations Results Controller.
    ///
    private lazy var productVariationsResultsController: ResultsController<StorageProductVariation> = {
        let siteAndProductIDPredicate = NSPredicate(format: "siteID == %lld AND productID == %lld", siteID, productID)
        let predicate: NSPredicate
        if allowedProductVariationIDs.isNotEmpty {
            let variationIDsPredicate = NSPredicate(format: "productVariationID IN %@", allowedProductVariationIDs)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [siteAndProductIDPredicate, variationIDsPredicate])
        } else {
            predicate = siteAndProductIDPredicate
        }
        let menuOrderDescriptor = NSSortDescriptor(keyPath: \StorageProductVariation.menuOrder, ascending: true)
        let variationIdDescriptor = NSSortDescriptor(keyPath: \StorageProductVariation.productVariationID, ascending: false)
        let resultsController = ResultsController<StorageProductVariation>(storageManager: storageManager,
                                                                           matching: predicate,
                                                                           sortedBy: [menuOrderDescriptor, variationIdDescriptor])
        return resultsController
    }()

    /// Whether the variation list should contains only purchasable items.
    ///
    private let purchasableItemsOnly: Bool

    private var orderSyncState: Published<OrderSyncState>.Publisher?

    init(siteID: Int64,
         productID: Int64,
         productName: String,
         productAttributes: [ProductAttribute],
         allowedProductVariationIDs: [Int64] = [],
         selectedProductVariationIDs: [Int64] = [],
         purchasableItemsOnly: Bool = false,
         orderSyncState: Published<OrderSyncState>.Publisher? = nil,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         stores: StoresManager = ServiceLocator.stores,
         onVariationSelectionStateChanged: ((ProductVariation, Product, Bool) -> Void)? = nil,
         onSelectionsCleared: (() -> Void)? = nil) {
        self.siteID = siteID
        self.productID = productID
        self.productName = productName
        self.productAttributes = productAttributes
        self.orderSyncState = orderSyncState
        self.storageManager = storageManager
        self.stores = stores
        self.onVariationSelectionStateChanged = onVariationSelectionStateChanged
        self.allowedProductVariationIDs = allowedProductVariationIDs
        self.selectedProductVariationIDs = selectedProductVariationIDs
        self.purchasableItemsOnly = purchasableItemsOnly
        self.onSelectionsCleared = onSelectionsCleared

        configureSyncingCoordinator()
        configureProductVariationsResultsController()
        configureFirstPageLoad()
        bindSelectionDisabledState()
    }

    convenience init(siteID: Int64,
                     product: Product,
                     allowedProductVariationIDs: [Int64] = [],
                     selectedProductVariationIDs: [Int64] = [],
                     purchasableItemsOnly: Bool = false,
                     orderSyncState: Published<OrderSyncState>.Publisher? = nil,
                     storageManager: StorageManagerType = ServiceLocator.storageManager,
                     stores: StoresManager = ServiceLocator.stores,
                     onVariationSelectionStateChanged: ((ProductVariation, Product, Bool) -> Void)? = nil,
                     onSelectionsCleared: (() -> Void)? = nil) {
        self.init(siteID: siteID,
                  productID: product.productID,
                  productName: product.name,
                  productAttributes: product.attributesForVariations,
                  allowedProductVariationIDs: allowedProductVariationIDs,
                  selectedProductVariationIDs: selectedProductVariationIDs,
                  purchasableItemsOnly: purchasableItemsOnly,
                  orderSyncState: orderSyncState,
                  storageManager: storageManager,
                  stores: stores,
                  onVariationSelectionStateChanged: onVariationSelectionStateChanged,
                  onSelectionsCleared: onSelectionsCleared)
    }

    @Published var selectionDisabled: Bool = false

    private func bindSelectionDisabledState() {
        orderSyncState?.map({ state in
            switch state {
            case .syncing(blocking: true):
                return true
            default:
                return false
            }
        })
        .assign(to: &$selectionDisabled)
    }

    /// Select a product variation to add to the order
    ///
    func changeSelectionStateForVariation(with variationID: Int64, selected: Bool) {
        // Fetch parent product
        // Needed because the parent product contains the product name & attributes.
        try? productResultsController.performFetch()

        guard let parentProduct = productResultsController.fetchedObjects.first,
              let selectedVariation = productVariations.first(where: { $0.productVariationID == variationID }) else {
            return
        }

        switch selected {
        case true:
            addSelection(variationID)
        case false:
            removeSelection(variationID)
        }

        onVariationSelectionStateChanged?(selectedVariation, parentProduct, selected)
    }

    /// Unselect all items.
    ///
    func clearSelection() {
        selectedProductVariationIDs = []
        onSelectionsCleared?()
    }

    func removeSelection(_ productVariationID: Int64) {
        selectedProductVariationIDs = selectedProductVariationIDs.filter { $0 != productVariationID}
    }
}

// MARK: - SyncingCoordinatorDelegate & Sync Methods
extension ProductVariationSelectorViewModel: SyncingCoordinatorDelegate {
    /// Sync product variations from remote.
    ///
    func sync(pageNumber: Int, pageSize: Int, reason: String? = nil, onCompletion: ((Bool) -> Void)?) {
        transitionToSyncingState()
        let action = ProductVariationAction.synchronizeProductVariationsSubset(siteID: siteID,
                                                                               productID: productID,
                                                                               variationIDs: allowedProductVariationIDs,
                                                                               pageNumber: pageNumber,
                                                                               pageSize: pageSize) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                self.updateProductVariationsResultsController()
            case .failure(let error):
                self.notice = NoticeFactory.productVariationSyncNotice() { [weak self] in
                    self?.sync(pageNumber: pageNumber, pageSize: pageSize, onCompletion: nil)
                }
                DDLogError("⛔️ Error synchronizing product variations during order creation: \(error)")
            }

            self.transitionToResultsUpdatedState()
            onCompletion?(result.isSuccess)
        }
        stores.dispatch(action)
    }

    /// Sync first page of product variations from remote if needed.
    ///
    func syncFirstPage() {
        syncingCoordinator.synchronizeFirstPage()
    }

    /// Sync next page of product variations from remote.
    ///
    func syncNextPage() {
        let lastIndex = productVariationsResultsController.numberOfObjects - 1
        syncingCoordinator.ensureNextPageIsSynchronized(lastVisibleIndex: lastIndex)
    }
}

// MARK: - Finite State Machine Management
private extension ProductVariationSelectorViewModel {
    /// Update state for sync from remote.
    ///
    func transitionToSyncingState() {
        shouldShowScrollIndicator = true
        if productVariations.isEmpty {
            syncStatus = .firstPageSync
        }
    }

    /// Update state after sync is complete.
    ///
    func transitionToResultsUpdatedState() {
        shouldShowScrollIndicator = false
        syncStatus = productVariations.isNotEmpty ? .results: .empty
    }
}

// MARK: - Configuration
private extension ProductVariationSelectorViewModel {
    /// Performs initial fetch from storage and updates sync status accordingly.
    ///
    func configureProductVariationsResultsController() {
        updateProductVariationsResultsController()
        transitionToResultsUpdatedState()
    }

    /// Fetches product variations from storage.
    ///
    func updateProductVariationsResultsController() {
        do {
            try productVariationsResultsController.performFetch()
            if purchasableItemsOnly {
                productVariations = productVariationsResultsController.fetchedObjects.filter { $0.purchasable }
            } else {
                productVariations = productVariationsResultsController.fetchedObjects
            }
            observeSelections()
        } catch {
            DDLogError("⛔️ Error fetching product variations for new order: \(error)")
        }
    }

    /// Setup: Syncing Coordinator
    ///
    func configureSyncingCoordinator() {
        syncingCoordinator.delegate = self
    }

    /// Performs initial sync on first page load
    ///
    func configureFirstPageLoad() {
        // Listen only to the first emitted event.
        onLoadTrigger.first()
            .sink { [weak self] in
                guard let self = self else { return }
                self.syncFirstPage()
            }
            .store(in: &subscriptions)
    }
}

// MARK: - Multiple selection support
private extension ProductVariationSelectorViewModel {
    func addSelection(_ productVariationID: Int64) {
        selectedProductVariationIDs.append(productVariationID)
    }

    /// Observe changes in selections to update product rows
    ///
    func observeSelections() {
        $productVariations.combineLatest($selectedProductVariationIDs) { [weak self] variations, selectedIDs -> [ProductRowViewModel] in
            guard let self = self else { return [] }
            return variations.map { variation in
                let selectedState: ProductRow.SelectedState = selectedIDs.contains(variation.productVariationID) ? .selected : .notSelected
                return ProductRowViewModel(productVariation: variation,
                                           name: ProductVariationFormatter().generateName(for: variation, from: self.productAttributes),
                                           displayMode: .stock,
                                           selectedState: selectedState)
            }
        }.assign(to: &$productVariationRows)
    }
}

// MARK: - Utils
extension ProductVariationSelectorViewModel {
    /// Represents possible statuses for syncing product variations
    ///
    enum SyncStatus {
        case firstPageSync
        case results
        case empty
    }

    /// Used for ghost list view while syncing
    ///
    private func ghostProductRow(id: Int64) -> ProductRowViewModel {
        ProductRowViewModel(productOrVariationID: id,
                            name: "Ghost Variation",
                            sku: nil,
                            price: "20",
                            stockStatusKey: ProductStockStatus.inStock.rawValue,
                            stockQuantity: 1,
                            manageStock: false,
                            imageURL: nil,
                            isConfigurable: false)
    }

    /// Add Product Variation to Order notices
    ///
    enum NoticeFactory {
        /// Returns a product variation sync error notice with a retry button.
        ///
        static func productVariationSyncNotice(retryAction: @escaping () -> Void) -> Notice {
            Notice(title: Localization.errorMessage, feedbackType: .error, actionTitle: Localization.errorActionTitle) {
                retryAction()
            }
        }
    }
}

private extension ProductVariationSelectorViewModel {
    enum Localization {
        static let errorMessage = NSLocalizedString("There was an error syncing product variations",
                                                    comment: "Notice displayed when syncing the list of product variations fails")
        static let errorActionTitle = NSLocalizedString("Retry", comment: "Retry action for an error notice")
    }
}
