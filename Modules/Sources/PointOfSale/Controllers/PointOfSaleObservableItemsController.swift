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
    }

    // periphery:ignore - used by tests
    init(siteID: Int64,
         dataSource: POSObservableDataSourceProtocol,
         catalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol) {
        self.siteID = siteID
        self.dataSource = dataSource
        self.catalogSyncCoordinator = catalogSyncCoordinator
    }

    func loadItems(base: ItemListBaseItem) async {
        switch base {
        case .root:
            if shouldRefresh(for: base) {
                await refreshItems(base: base)
            }
            dataSource.loadProducts()
            loadingState.productsLoaded = true

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

    func refreshItems(base: ItemListBaseItem) async {
        if itemsEmpty(for: base) {
            refreshState = .loading
        }

        do {
            try await catalogSyncCoordinator.performIncrementalSync(for: siteID)
            refreshState = .idle
        } catch let error as POSCatalogSyncError {
            switch error {
            case .syncAlreadyInProgress:
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
        // Use .loading during initial load, .content otherwise
        if !loadingState.productsLoaded && dataSource.isLoadingProducts {
            return .loading
        }
        return .content
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
