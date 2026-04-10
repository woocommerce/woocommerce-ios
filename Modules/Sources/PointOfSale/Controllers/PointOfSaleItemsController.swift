import Foundation
import Observation
import enum Yosemite.POSItem
import struct Yosemite.POSSimpleProduct
import class Yosemite.PointOfSaleItemService
import protocol Yosemite.PointOfSaleItemServiceProtocol
import protocol Yosemite.PointOfSaleItemFetchStrategyFactoryProtocol
import protocol Yosemite.PointOfSalePurchasableItemFetchStrategy
import enum Yosemite.PointOfSaleItemServiceError
import struct Yosemite.POSVariableParentProduct
import class Yosemite.Store
import enum Yosemite.POSItemType
import class Yosemite.AsyncPaginationTracker
import enum Yosemite.SearchDebounceStrategy

protocol PointOfSaleItemsControllerProtocol {
    ///
    var itemsViewState: ItemsViewState { get }
    /// Loads the first page of items for a given base item.
    func loadItems(base: ItemListBaseItem) async
    /// Refreshes the items for a given base item – will result in showing only the first page.
    func refreshItems(base: ItemListBaseItem) async
    /// Loads the next page of items for a given base item.
    func loadNextItems(base: ItemListBaseItem) async
}

protocol PointOfSaleSearchingItemsControllerProtocol: PointOfSaleItemsControllerProtocol {
    /// Searches for items
    func searchItems(searchTerm: String, baseItem: ItemListBaseItem) async
    func clearSearchItems(baseItem: ItemListBaseItem)
    /// The debouncing strategy from the current fetch strategy
    var currentDebounceStrategy: SearchDebounceStrategy { get }
    /// The debouncing strategy that will be used when performing a search
    var searchDebounceStrategy: SearchDebounceStrategy { get }
}


@Observable final class PointOfSaleItemsController: PointOfSaleSearchingItemsControllerProtocol {
    var itemsViewState: ItemsViewState
    private let paginationTracker: AsyncPaginationTracker
    private var childPaginationTrackers: [POSItem: AsyncPaginationTracker] = [:]
    private var itemProvider: PointOfSaleItemServiceProtocol
    private let itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactoryProtocol
    private var fetchStrategy: PointOfSalePurchasableItemFetchStrategy
    private let analyticsProvider: POSAnalyticsProviding

    init(itemProvider: PointOfSaleItemServiceProtocol,
         itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactoryProtocol,
         initialState: ItemsViewState = ItemsViewState(containerState: .loading(),
                                                       itemsStack: ItemsStackState(root: .initial,
                                                                                   itemStates: [:])),
         analyticsProvider: POSAnalyticsProviding) {
        self.itemProvider = itemProvider
        self.itemFetchStrategyFactory = itemFetchStrategyFactory
        self.itemsViewState = initialState
        self.paginationTracker = .init()
        self.analyticsProvider = analyticsProvider
        self.fetchStrategy = itemFetchStrategyFactory.defaultStrategy(analytics: POSItemFetchAnalytics(itemType: .product,
                                                                                                       analytics: analyticsProvider))
    }

    @MainActor
    func loadItems(base: ItemListBaseItem) async {
        setLoadingState(base: base)
        await loadFirstPage(base: base)
    }

    @MainActor
    func refreshItems(base: ItemListBaseItem) async {
        await loadFirstPage(base: base)
    }

    @MainActor
    func searchItems(searchTerm: String, baseItem: ItemListBaseItem) async {
        fetchStrategy = itemFetchStrategyFactory.searchStrategy(searchTerm: searchTerm,
                                                                analytics: POSItemFetchAnalytics(itemType: .product,
                                                                                                 analytics: analyticsProvider))
        await loadFirstPage(base: baseItem)
    }

    func clearSearchItems(baseItem: ItemListBaseItem) {
        setSearchingState(base: baseItem)
    }

    var currentDebounceStrategy: SearchDebounceStrategy {
        fetchStrategy.debounceStrategy
    }

    var searchDebounceStrategy: SearchDebounceStrategy {
        // Return the debounce strategy that would be used for a search
        // We create a temporary search strategy to get its debounce settings
        let searchStrategy = itemFetchStrategyFactory.searchStrategy(searchTerm: "",
                                                                     analytics: POSItemFetchAnalytics(itemType: .product,
                                                                                                      analytics: analyticsProvider))
        return searchStrategy.debounceStrategy
    }

    @MainActor
    private func loadFirstPage(base: ItemListBaseItem) async {
        switch base {
        case .root:
            await loadRootItems()
        case .parent(let parent):
            await loadChildItems(for: parent)
        }
    }

    @MainActor
    private func loadRootItems() async {
        do {
            try await paginationTracker.resync { [weak self] pageNumber in
                guard let self else { return true }
                return try await fetchItems(pageNumber: pageNumber, appendToExistingItems: false)
            }
        } catch {
            let items = itemsViewState.itemsStack.root.items
            let stackState: ItemsStackState
            if items.isEmpty {
                stackState = ItemsStackState(root: .error(.errorOnLoadingProducts(error: error)), itemStates: [:])
            } else {
                stackState = ItemsStackState(root: .inlineError(items, error: .errorOnLoadingProducts(error: error), context: .refresh), itemStates: [:])
            }
            itemsViewState = ItemsViewState(containerState: .content, itemsStack: stackState)
        }
    }

    @MainActor
    func loadNextItems(base: ItemListBaseItem) async {
        switch base {
        case .root:
            await loadNextRootItems()
        case .parent(let parent):
            await loadNextChildItems(for: parent)
        }
    }

    @MainActor
    private func loadNextRootItems() async {
        guard paginationTracker.hasNextPage else {
            return
        }
        let currentItems = itemsViewState.itemsStack.root.items
        let currentItemStates = itemsViewState.itemsStack.itemStates
        itemsViewState.containerState = .content
        itemsViewState.itemsStack = ItemsStackState(root: .loading(currentItems),
                                                   itemStates: currentItemStates)
        do {
            _ = try await paginationTracker.ensureNextPageIsSynced { [weak self] pageNumber in
                guard let self else { return true }
                return try await fetchItems(pageNumber: pageNumber)
            }
        } catch {
            itemsViewState.containerState = .content
            itemsViewState.itemsStack = ItemsStackState(root: .inlineError(currentItems,
                                                                           error: .errorOnLoadingProductsNextPage(error: error),
                                                                           context: .pagination),
                                                        itemStates: currentItemStates)
        }
    }

    @MainActor
    private func loadChildItems(for parent: POSItem) async {
        let paginationTracker = paginationTracker(for: parent)
        do {
            try await paginationTracker.resync { [weak self] pageNumber in
                guard let self else { return true }
                return try await fetchChildItems(for: parent, pageNumber: Store.Default.firstPageNumber, appendToExistingItems: false)
            }
        } catch {
            updateState(for: parent, to: .error(.errorOnLoadingVariations(error: error)))
        }
    }

    @MainActor
    private func loadNextChildItems(for parent: POSItem) async {
        let paginationTracker = paginationTracker(for: parent)

        guard paginationTracker.hasNextPage else {
            return
        }
        let currentItems = itemsViewState.itemsStack.itemStates[parent]?.items ?? []
        updateState(for: parent, to: .loading(currentItems))

        do {
            _ = try await paginationTracker.ensureNextPageIsSynced { [weak self] pageNumber in
                guard let self else { return true }
                return try await fetchChildItems(for: parent, pageNumber: pageNumber, appendToExistingItems: true)
            }
        } catch {
            updateState(for: parent, to: .inlineError(currentItems,
                                                      error: PointOfSaleErrorState.errorOnLoadingVariationsNextPage(error: error),
                                                      context: .pagination))
        }
    }

    @MainActor
    private func fetchChildItems(for parent: POSItem, pageNumber: Int, appendToExistingItems: Bool) async throws -> Bool {
        switch parent {
        case let .variableParentProduct(parentProduct):
            return try await fetchVariationItems(parentProduct: parentProduct,
                                                 parentItem: parent,
                                                 pageNumber: pageNumber,
                                                 appendToExistingItems: appendToExistingItems)
        case .simpleProduct, .variation, .searchResultVariation, .coupon:
            assertionFailure("Unsupported parent type for loading child items: \(parent)")
            return false
        }
    }

    private func paginationTracker(for parent: POSItem) -> AsyncPaginationTracker {
        if let childPaginationTracker = childPaginationTrackers[parent] {
            return childPaginationTracker
        } else {
            let newChildPaginationTracker = AsyncPaginationTracker()
            childPaginationTrackers[parent] = newChildPaginationTracker
            return newChildPaginationTracker
        }
    }
}

private extension PointOfSaleItemsController {
    func setLoadingState(base: ItemListBaseItem) {
        switch base {
        case .root:
            setRootLoadingState()
        case .parent(let parent):
            setChildLoadingState(for: parent)
        }
    }

    func setRootLoadingState() {
        let items = itemsViewState.itemsStack.root.items

        let isInitialState = itemsViewState.containerState == .loading() && itemsViewState.itemsStack.root == .initial
        if isInitialState {
            // Transition from initial to loading on first load
            itemsViewState.itemsStack.root = .loading([])
        } else {
            // Preserve items during refresh
            itemsViewState.itemsStack.root = .loading(items)
        }
    }

    func setChildLoadingState(for parent: POSItem) {
        let items = itemsViewState.itemsStack.itemStates[parent]?.items ?? []
        updateState(for: parent, to: .loading(items))
    }

    func setSearchingState(base: ItemListBaseItem) {
        switch base {
        case .root:
            setRootSearchingState()
        case .parent(let parent):
            setChildSearchingState(for: parent)
        }
    }

    func setRootSearchingState() {
        itemsViewState.itemsStack.root = .loading([])
    }

    func setChildSearchingState(for parent: POSItem) {
        updateState(for: parent, to: .loading([]))
    }
}

private extension PointOfSaleItemsController {
    /// Fetches items given a page number and appends new unique items to the `allItems` array.
    /// - Parameter pageNumber: Page number to fetch items from.
    /// - Parameter appendToExistingItems: Default true – set this to false when refreshing to make the new page the only page.
    /// - Returns: A boolean that indicates whether there is next page for the paginated items.
    @MainActor
    func fetchItems(pageNumber: Int, appendToExistingItems: Bool = true) async throws -> Bool {
        do {
            let pagedItems = try await itemProvider.providePointOfSaleItems(pageNumber: pageNumber,
                                                                            fetchStrategy: fetchStrategy)

            let newItems = pagedItems.items
            var allItems = appendToExistingItems ? itemsViewState.itemsStack.root.items : []
            let uniqueNewItems = newItems.filter { newItem in
                // Note that this uniquing won't currently work, as POSItem has a UUID.
                !allItems.contains(newItem)
            }
            allItems.append(contentsOf: uniqueNewItems)
            if allItems.isEmpty {
                itemsViewState.containerState = .content
                itemsViewState.itemsStack = ItemsStackState(root: .empty, itemStates: [:])
            } else {
                let itemStates = itemsViewState.itemsStack.itemStates
                    .filter { allItems.contains($0.key) }
                itemsViewState.containerState = .content
                itemsViewState.itemsStack = ItemsStackState(root: .loaded(allItems, hasMoreItems: pagedItems.hasMorePages),
                                                            itemStates: itemStates)
            }
            return pagedItems.hasMorePages
        } catch PointOfSaleItemServiceError.requestCancelled {
            // Assume that we have more pages since we'd made a request, and it was cancelled
            return true
        }
    }

    /// Fetches variation items given a page number and appends new unique items to the existing items array.
    /// - Parameter pageNumber: Page number to fetch items from.
    /// - Parameter appendToExistingItems: Default true – set this to false when refreshing to make the new page the only page.
    @MainActor
    private func fetchVariationItems(parentProduct: POSVariableParentProduct,
                                     parentItem: POSItem,
                                     pageNumber: Int,
                                     appendToExistingItems: Bool = true) async throws -> Bool {
        do {
            let pagedItems = try await itemProvider.providePointOfSaleVariationItems(
                for: parentProduct,
                pageNumber: pageNumber,
                fetchStrategy: fetchStrategy
            )
            let newItems = pagedItems.items
            var allItems: [POSItem] = appendToExistingItems ? (itemsViewState.itemsStack.itemStates[parentItem]?.items ?? []) : []
            let uniqueNewItems = newItems.filter { newItem in
                // Note that this uniquing won't currently work, as POSItem has a UUID.
                !allItems.contains(newItem)
            }
            allItems.append(contentsOf: uniqueNewItems)

            updateState(for: parentItem, to: .loaded(allItems, hasMoreItems: pagedItems.hasMorePages))
            return pagedItems.hasMorePages
        } catch PointOfSaleItemServiceError.requestCancelled {
            // Assume that we have more pages since we'd made a request, and it was cancelled
            return true
        }
    }
}

// MARK: - ItemsViewState Updates
private extension PointOfSaleItemsController {
    func updateState(for parent: POSItem, to state: ItemListState) {
        let viewState = itemsViewState
        let itemStates: [POSItem: ItemListState] = {
            var states = viewState.itemsStack.itemStates
            states[parent] = state
            return states
        }()
        itemsViewState.itemsStack.itemStates = itemStates
    }
}
