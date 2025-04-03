import Foundation
import Observation
import enum Yosemite.POSItem
import protocol Yosemite.PointOfSaleItemServiceProtocol
import enum Yosemite.PointOfSaleItemServiceError
import struct Yosemite.POSVariableParentProduct
import class Yosemite.Store

enum ItemType {
    case products
    case coupons
}

@available(iOS 17.0, *)
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



@available(iOS 17.0, *)
@Observable final class PointOfSaleItemsController: PointOfSaleItemsControllerProtocol {
    var itemsViewState: ItemsViewState = ItemsViewState(containerState: .loading,
                                                        itemsStack: ItemsStackState(root: .loading([]),
                                                                                    itemStates: [:]))
    private let paginationTracker: AsyncPaginationTracker
    private var childPaginationTrackers: [POSItem: AsyncPaginationTracker] = [:]
    private let itemProvider: PointOfSaleItemServiceProtocol

    init(itemProvider: PointOfSaleItemServiceProtocol) {
        self.itemProvider = itemProvider
        self.paginationTracker = .init()
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
    private func loadFirstPage(base: ItemListBaseItem) async {
        switch base {
        case .root:
            await loadRootItems()
        case .parent(let parent, _):
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
            itemsViewState.containerState = .error(PointOfSaleErrorState.errorOnLoadingProducts())
            itemsViewState.itemsStack = ItemsStackState(root: .loaded([], hasMoreItems: false),
                                                       itemStates: [:])
        }
    }

    @MainActor
    func loadNextItems(base: ItemListBaseItem) async {
        switch base {
        case .root:
            await loadNextRootItems()
        case .parent(let parent, _):
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
                                                                           error: .errorOnLoadingProductsNextPage()),
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
            updateState(for: parent, to: .error(.errorOnLoadingVariations()))
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
                                                      error: PointOfSaleErrorState.errorOnLoadingVariationsNextPage()))
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
        case .simpleProduct, .variation, .coupon:
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

@available(iOS 17.0, *)
private extension PointOfSaleItemsController {
    func setLoadingState(base: ItemListBaseItem) {
        switch base {
        case .root:
            setRootLoadingState()
        case .parent(let parent, _):
            setChildLoadingState(for: parent)
        }
    }

    func setRootLoadingState() {
        let items = itemsViewState.itemsStack.root.items
        if items.isEmpty {
            itemsViewState.containerState = .loading
        } else {
            itemsViewState.itemsStack.root = .loading(items)
        }
    }

    func setChildLoadingState(for parent: POSItem) {
        let items = itemsViewState.itemsStack.itemStates[parent]?.items ?? []
        updateState(for: parent, to: .loading(items))
    }
}

@available(iOS 17.0, *)
private extension PointOfSaleItemsController {
    /// Fetches items given a page number and appends new unique items to the `allItems` array.
    /// - Parameter pageNumber: Page number to fetch items from.
    /// - Parameter appendToExistingItems: Default true – set this to false when refreshing to make the new page the only page.
    /// - Returns: A boolean that indicates whether there is next page for the paginated items.
    @MainActor
    func fetchItems(pageNumber: Int, appendToExistingItems: Bool = true) async throws -> Bool {
        do {
            let pagedItems = try await itemProvider.providePointOfSaleItems(pageNumber: pageNumber)

            let newItems = pagedItems.items
            var allItems = appendToExistingItems ? itemsViewState.itemsStack.root.items : []
            let uniqueNewItems = newItems.filter { newItem in
                // Note that this uniquing won't currently work, as POSItem has a UUID.
                !allItems.contains(newItem)
            }
            allItems.append(contentsOf: uniqueNewItems)
            if allItems.isEmpty {
                itemsViewState.containerState = .empty
                itemsViewState.itemsStack = ItemsStackState(root: .loaded([], hasMoreItems: false),
                                                            itemStates: [:])
            } else {
                let itemStates = itemsViewState.itemsStack.itemStates
                    .filter { allItems.contains($0.key) }
                itemsViewState.containerState = .content
                itemsViewState.itemsStack = ItemsStackState(root: .loaded(allItems, hasMoreItems: pagedItems.hasMorePages),
                                                            itemStates: itemStates)
            }
            return pagedItems.hasMorePages
        } catch PointOfSaleItemServiceError.requestCancelled {
            itemsViewState.containerState = .content
            itemsViewState.itemsStack.root = .loaded(itemsViewState.itemsStack.root.items, hasMoreItems: true)
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
                pageNumber: pageNumber
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
            itemsViewState.containerState = .content
            updateState(for: parentItem, to: .loaded(itemsViewState.itemsStack.itemStates[parentItem]?.items ?? [],
                                                     hasMoreItems: true))
            // Assume that we have more pages since we'd made a request, and it was cancelled
            return true
        }
    }
}

// MARK: - ItemsViewState Updates
@available(iOS 17.0, *)
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
