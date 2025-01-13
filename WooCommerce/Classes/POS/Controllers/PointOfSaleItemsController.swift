import Foundation
import Combine
import enum Yosemite.POSItem
import protocol Yosemite.PointOfSaleItemServiceProtocol
import struct Yosemite.POSVariableParentProduct
import class Yosemite.Store

protocol PointOfSaleItemsControllerProtocol {
    var itemsViewStatePublisher: any Publisher<ItemsViewState, Never> { get }
    func loadInitialItems(base: ItemListBaseItem) async
    func loadNextItems(base: ItemListBaseItem) async
    func reload() async
}

class PointOfSaleItemsController: PointOfSaleItemsControllerProtocol {
    var itemsViewStatePublisher: any Publisher<ItemsViewState, Never> {
        $itemsViewState.eraseToAnyPublisher()
    }
    @Published private var itemsViewState: ItemsViewState =
    ItemsViewState(containerState: .loading,
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
    func loadInitialItems(base: ItemListBaseItem) async {
        switch base {
        case .root:
            await loadInitialRootItems()
        case .parent(let parent):
            await loadInitialChildItems(for: parent)
        }
    }

    @MainActor
    private func loadInitialRootItems() async {
        itemsViewState = .init(containerState: .loading, itemsStack: ItemsStackState(root: .loading([]),
                                                                                     itemStates: [:]))
        do {
            try await paginationTracker.syncFirstPage { [weak self] pageNumber in
                guard let self else { return true }
                return try await fetchItems(pageNumber: pageNumber)
            }
        } catch {
            itemsViewState = .init(containerState: .error(PointOfSaleErrorState.errorOnLoadingProducts()),
                                   itemsStack: ItemsStackState(root: .loaded([], hasMoreItems: false),
                                                               itemStates: [:]))
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
        itemsViewState = .init(containerState: .content, itemsStack: ItemsStackState(root: .loading(currentItems),
                                                                                     itemStates: currentItemStates))
        do {
            _ = try await paginationTracker.ensureNextPageIsSynced { [weak self] pageNumber in
                guard let self else { return true }
                return try await fetchItems(pageNumber: pageNumber)
            }
        } catch {
            itemsViewState = .init(containerState: .content,
                                   itemsStack: ItemsStackState(root: .inlineError(currentItems,
                                                                                  error: .errorOnLoadingProductsNextPage()),
                                                               itemStates: currentItemStates))
        }
    }

    @MainActor
    func reload() async {
        do {
            try await paginationTracker.resync { [weak self] pageNumber in
                guard let self else { return true }
                return try await fetchItems(pageNumber: pageNumber, appendToExistingItems: false)
            }
        } catch {
            // TODO: 14694 - Handle error from pull-to-refresh, like showing an error UI at the beginning or as an overlay.
            itemsViewState = .init(containerState: .error(PointOfSaleErrorState.errorOnLoadingProducts()),
                                   itemsStack: ItemsStackState(root: .loaded([], hasMoreItems: false),
                                                               itemStates: [:]))
        }
    }

    @MainActor
    private func loadInitialChildItems(for parent: POSItem) async {
        updateState(for: parent, to: .loading([]))

        let paginationTracker = paginationTracker(for: parent)
        do {
            try await paginationTracker.syncFirstPage { [weak self] pageNumber in
                guard let self else { return true }
                return try await fetchChildItems(for: parent, pageNumber: Store.Default.firstPageNumber)
            }
        } catch {
            // TODO: 14694 - Handle error from loading initial variations.
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
                return try await fetchChildItems(for: parent, pageNumber: pageNumber)
            }
        } catch {
            updateState(for: parent, to: .inlineError(currentItems,
                                                      error: PointOfSaleErrorState.errorOnLoadingVariationsNextPage()))
        }
    }

    @MainActor
    private func fetchChildItems(for parent: POSItem, pageNumber: Int) async throws -> Bool {
        switch parent {
        case let .variableParentProduct(parentProduct):
            return try await fetchVariationItems(parentProduct: parentProduct, parentItem: parent, pageNumber: pageNumber)
        case .simpleProduct, .variation:
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
    /// Fetches items given a page number and appends new unique items to the `allItems` array.
    /// - Parameter pageNumber: Page number to fetch items from.
    /// - Parameter appendToExistingItems: Default true – set this to false when refreshing to make the new page the only page.
    /// - Returns: A boolean that indicates whether there is next page for the paginated items.
    @MainActor
    func fetchItems(pageNumber: Int, appendToExistingItems: Bool = true) async throws -> Bool {
        let pagedItems = try await itemProvider.providePointOfSaleItems(pageNumber: pageNumber)
        let newItems = pagedItems.items
        var allItems = appendToExistingItems ? itemsViewState.itemsStack.root.items : []
        let uniqueNewItems = newItems.filter { newItem in
            // Note that this uniquing won't currently work, as POSItem has a UUID.
            !allItems.contains(newItem)
        }
        allItems.append(contentsOf: uniqueNewItems)
        if allItems.isEmpty {
            itemsViewState = .init(containerState: .empty,
                                   itemsStack: ItemsStackState(root: .loaded([], hasMoreItems: false),
                                                               itemStates: [:]))
        } else {
            let itemStates = itemsViewState.itemsStack.itemStates
                .filter { allItems.contains($0.key) }
            itemsViewState = .init(containerState: .content,
                                   itemsStack: ItemsStackState(root: .loaded(allItems, hasMoreItems: pagedItems.hasMorePages),
                                                               itemStates: itemStates))
        }
        return pagedItems.hasMorePages
    }

    /// Fetches variation items given a page number and appends new unique items to the existing items array.
    /// - Parameter pageNumber: Page number to fetch items from.
    /// - Parameter appendToExistingItems: Default true – set this to false when refreshing to make the new page the only page.
    @MainActor
    private func fetchVariationItems(parentProduct: POSVariableParentProduct,
                                     parentItem: POSItem,
                                     pageNumber: Int,
                                     appendToExistingItems: Bool = true) async throws -> Bool {
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
        itemsViewState = viewState.copy(itemsStack: viewState.itemsStack.copy(itemStates: itemStates))
    }
}
