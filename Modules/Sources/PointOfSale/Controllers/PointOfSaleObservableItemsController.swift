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

    // Track which items have been loaded at least once
    private var hasLoadedProducts = false
    private var hasLoadedVariationsForCurrentParent = false

    // Track current parent for variation state mapping
    private var currentParentItem: POSItem?
    private var refreshError: Error?

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
            dataSource.loadProducts()
            hasLoadedProducts = true
        case .parent(let parent):
            guard case .variableParentProduct(let parentProduct) = parent else {
                assertionFailure("Unsupported parent type for loading items: \(parent)")
                return
            }

            // If switching to a different parent, reset the loaded flag
            if currentParentItem != parent {
                currentParentItem = parent
                hasLoadedVariationsForCurrentParent = false
            }

            dataSource.loadVariations(for: parentProduct)
            hasLoadedVariationsForCurrentParent = true
        }

        if refreshError != nil {
            await refreshItems(base: base)
        }
    }

    func refreshItems(base: ItemListBaseItem) async {
        refreshError = nil

        do {
            try await catalogSyncCoordinator.performIncrementalSync(for: siteID)
        } catch let error as POSCatalogSyncError {
            switch error {
            case .syncAlreadyInProgress:
                break
            default:
                refreshError = error
            }
        } catch {
            refreshError = error
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
        if !hasLoadedProducts && dataSource.isLoadingProducts {
            return .loading
        }
        return .content
    }

    var rootState: ItemListState {
        let items = dataSource.productItems

        // Initial state - not yet loaded
        if !hasLoadedProducts {
            return .initial
        }

        // Loading state - preserve existing items
        if dataSource.isLoadingProducts {
            return .loading(items)
        }

        // Error state for refresh
        if let error = refreshError {
            if items.isEmpty {
                return .error(.errorOnLoadingProducts(error: error))
            } else {
                return .inlineError(items, error: .errorOnLoadingProducts(error: error), context: .refresh)
            }
        }

        // Error state for data source observation
        if let error = dataSource.productError, items.isEmpty {
            return .error(.errorOnLoadingProducts(error: error))
        }

        // Empty state
        if items.isEmpty {
            return .empty
        }

        // Loaded state
        return .loaded(items, hasMoreItems: dataSource.hasMoreProducts)
    }

    var variationStates: [POSItem: ItemListState] {
        guard let parentItem = currentParentItem else {
            return [:]
        }

        let items = dataSource.variationItems

        // Initial state - not yet loaded
        if !hasLoadedVariationsForCurrentParent {
            return [parentItem: .initial]
        }

        // Loading state - preserve existing items
        if dataSource.isLoadingVariations {
            return [parentItem: .loading(items)]
        }

        // Error state for refresh
        if let error = refreshError {
            if items.isEmpty {
                return [parentItem: .error(.errorOnLoadingVariations(error: error))]
            } else {
                return [parentItem: .inlineError(items, error: .errorOnLoadingVariations(error: error), context: .refresh)]
            }
        }

        // Error state for data source observation
        if let error = dataSource.variationError, items.isEmpty {
            return [parentItem: .error(.errorOnLoadingVariations(error: error))]
        }

        // Empty state
        if items.isEmpty {
            return [parentItem: .empty]
        }

        // Loaded state
        return [parentItem: .loaded(items, hasMoreItems: dataSource.hasMoreVariations)]
    }
}
