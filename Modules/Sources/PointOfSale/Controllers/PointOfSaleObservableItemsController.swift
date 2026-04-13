import CocoaLumberjackSwift
import Foundation
import Observation
import class WooFoundation.CurrencySettings
import enum Yosemite.POSItem
import protocol Yosemite.POSObservableDataSourceProtocol
import struct Yosemite.POSVariableParentProduct
import class Yosemite.GRDBObservableDataSource
import protocol Storage.GRDBManagerProtocol
import protocol Yosemite.POSCatalogSyncCoordinatorProtocol
import enum Yosemite.POSCatalogSyncError

/// Controller that wraps an observable data source for POS items
/// Uses computed state based on data source observations for automatic UI updates
@Observable
@MainActor
final class PointOfSaleObservableItemsController: PointOfSaleItemsControllerProtocol {
    private let dataSource: POSObservableDataSourceProtocol
    private let catalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol
    private let siteID: Int64

    // Track loading and refresh for products and variations
    private var loadingState: LoadingState = LoadingState()
    private var refreshState: RefreshState = .idle

    // Track current parent for variation state mapping
    private var currentParentItem: POSItem?

    var itemsViewState: ItemsViewState {
        ItemsViewState(
            containerState: containerState,
            itemsStack: ItemsStackState(
                root: rootState,
                itemStates: variationStates
            )
        )
    }

    init(siteID: Int64,
         grdbManager: GRDBManagerProtocol,
         currencySettings: CurrencySettings,
         catalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol) {
        self.siteID = siteID
        self.dataSource = GRDBObservableDataSource(
            siteID: siteID,
            grdbManager: grdbManager,
            currencySettings: currencySettings
        )
        self.catalogSyncCoordinator = catalogSyncCoordinator

        preloadloadLastFullSyncState()
    }

    // periphery:ignore - used by tests
    init(siteID: Int64,
         dataSource: POSObservableDataSourceProtocol,
         catalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol) {
        self.siteID = siteID
        self.dataSource = dataSource
        self.catalogSyncCoordinator = catalogSyncCoordinator

        preloadloadLastFullSyncState()
    }

    func loadItems(base: ItemListBaseItem) async {
        switch base {
        case .root:
            if await shouldReload(for: base) {
                await reloadItems(base: base)
            } else if shouldRefresh(for: base) {
                await refreshItems(base: base)
            }
            dataSource.loadProducts()
            loadingState.productsLoaded = true

            // Start FTS rebuild in background after observation is registered,
            // so the writer is free for observation setup first.
            Task {
                await catalogSyncCoordinator.startBackgroundFTSRebuildIfNeeded(for: siteID)
            }

        case .parent(let parent):
            guard case .variableParentProduct(let parentProduct) = parent else {
                assertionFailure("Unsupported parent type for loading items: \(parent)")
                return
            }

            if currentParentItem != parent {
                currentParentItem = parent
                loadingState.variationsLoaded = false
            }

            if shouldRefresh(for: base) {
                await refreshItems(base: base)
            }
            dataSource.loadVariations(for: parentProduct)
            loadingState.variationsLoaded = true
        }
    }

    func reloadItems(base: ItemListBaseItem) async {
        guard case .root = base else {
            return
        }
        loadingState = .init()

        try? await catalogSyncCoordinator.performSmartSync(for: siteID, isBackgroundSync: false)
    }

    func refreshItems(base: ItemListBaseItem) async {
        if itemsEmpty(for: base) {
            refreshState = .loading
        }

        do {
            try await catalogSyncCoordinator.performIncrementalSync(for: siteID)
            refreshState = .idle
        } catch let error as POSCatalogSyncError {
            switch error {
            case .syncAlreadyInProgress, .requestCancelled:
                refreshState = .idle
            default:
                refreshState = .error(error)
            }
        } catch {
            refreshState = .error(error)
        }
    }

    func loadNextItems(base: ItemListBaseItem) async {
        switch base {
        case .root:
            dataSource.loadMoreProducts()
        case .parent:
            dataSource.loadMoreVariations()
        }
    }
}

// MARK: - State Computation
private extension PointOfSaleObservableItemsController {
    var containerState: ItemsContainerState {
        if isInitialCatalogSync {
            return .loading(isCatalogSyncing: true)
        }

        if case .failure(let error) = initialSyncResult {
            return .error(.errorOnInitalCatalogSync(error: error))
        }

        if !loadingState.productsLoaded && dataSource.isLoadingProducts {
            return .loading()
        }

        return .content
    }

    var isInitialCatalogSync: Bool {
        guard let syncState = catalogSyncCoordinator.fullSyncStateModel.state[siteID] else {
            return false
        }

        switch syncState {
        case .initialSyncStarted, .syncNeverDone:
            return true
        default:
            return false
        }
    }

    var initialSyncResult: Result<Void, Error>? {
        switch catalogSyncCoordinator.fullSyncStateModel.state[siteID] {
        case .initialSyncFailed(_, let error):
            return .failure(error)
        case .syncFailed(_, let error):
            // If there's no catalog data, treat subsequent sync failures as critical
            return dataSource.productItems.isEmpty ? .failure(error) : .success(())
        case .syncCompleted:
            return .success(())
        default:
            return nil
        }
    }

    var rootState: ItemListState {
        computeItemListState(
            items: dataSource.productItems,
            hasLoaded: loadingState.productsLoaded,
            isLoading: dataSource.isLoadingProducts,
            error: dataSource.productError,
            hasMoreItems: dataSource.hasMoreProducts,
            errorType: PointOfSaleErrorState.errorOnLoadingProducts
        )
    }

    var variationStates: [POSItem: ItemListState] {
        guard let parentItem = currentParentItem else {
            return [:]
        }

        let state = computeItemListState(
            items: dataSource.variationItems,
            hasLoaded: loadingState.variationsLoaded,
            isLoading: dataSource.isLoadingVariations,
            error: dataSource.variationError,
            hasMoreItems: dataSource.hasMoreVariations,
            errorType: PointOfSaleErrorState.errorOnLoadingVariations
        )
        return [parentItem: state]
    }
}

private extension PointOfSaleObservableItemsController {
    func shouldReload(for type: ItemListBaseItem) async -> Bool {
        guard case .root = type else {
            return false
        }

        // Reload if there's a failure
        if case .failure = initialSyncResult {
            return true
        }

        return false
    }

    /// Determines if a refresh should be triggered
    func shouldRefresh(for type: ItemListBaseItem) -> Bool {
        if case .error = refreshState {
            return true
        }
        return itemsEmpty(for: type)
    }

    /// Checks if items are loaded but empty
    func itemsEmpty(for type: ItemListBaseItem) -> Bool {
        switch type {
        case .root:
            return loadingState.productsLoaded && dataSource.productItems.isEmpty
        case .parent:
            return loadingState.variationsLoaded && dataSource.variationItems.isEmpty
        }
    }

    /// Computes the item list state based on current conditions
    func computeItemListState(
        items: [POSItem],
        hasLoaded: Bool,
        isLoading: Bool,
        error: Error?,
        hasMoreItems: Bool,
        errorType: (Error) -> PointOfSaleErrorState
    ) -> ItemListState {
        // Initial state - not yet loaded
        if !hasLoaded {
            return .initial
        }

        // Loading state - preserve existing items
        if isLoading {
            return .loading(items)
        }

        // Refresh loading with empty items
        if refreshState == .loading && items.isEmpty {
            return .loading([])
        }

        // Error state for refresh
        if case .error(let refreshError) = refreshState {
            return items.isEmpty
                ? .error(errorType(refreshError))
                : .inlineError(items, error: errorType(refreshError), context: .refresh)
        }

        // Error state for data source observation
        if let error = error, items.isEmpty {
            return .error(errorType(error))
        }

        // Empty state
        if items.isEmpty {
            return .empty
        }

        // Loaded state
        return .loaded(items, hasMoreItems: hasMoreItems)
    }

    /// Represents the state of a refresh operation
    enum RefreshState: Equatable {
        case idle
        case loading
        case error(Error)

        static func == (lhs: RefreshState, rhs: RefreshState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle):
                return true
            case (.loading, .loading):
                return true
            case (.error(let lhsError as POSCatalogSyncError), .error(let rhsError as POSCatalogSyncError)):
                return lhsError == rhsError
            case (.error(let lhsError), .error(let rhsError)):
                return lhsError.localizedDescription == rhsError.localizedDescription
            default:
                return false
            }
        }
    }

    /// Encapsulates loading state for products and variations
    struct LoadingState {
        var productsLoaded = false
        var variationsLoaded = false
    }
}

private extension PointOfSaleObservableItemsController {
    func preloadloadLastFullSyncState() {
        Task { @MainActor in
            /// Ensure last full sync state is loaded with initial value
            _ = await catalogSyncCoordinator.loadLastFullSyncState(for: siteID)
        }
    }
}
