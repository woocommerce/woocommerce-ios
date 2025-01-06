import Foundation
import Combine
import enum Yosemite.POSItem
import protocol Yosemite.PointOfSaleItemServiceProtocol
import enum Yosemite.PointOfSaleProductServiceError
import struct Yosemite.POSParentProduct
import class Yosemite.Store

protocol PointOfSaleItemsControllerProtocol {
    var itemsViewStatePublisher: any Publisher<ItemsViewState, Never> { get }
    func loadInitialItems() async
    func loadNextItems() async
    func reload() async
    func loadInitialChildItems(for parent: POSItem) async
}

class PointOfSaleItemsController: PointOfSaleItemsControllerProtocol {
    let itemsViewStatePublisher: any Publisher<ItemsViewState, Never>
    private let itemsViewStateSubject: CurrentValueSubject<ItemsViewState, Never> =
        .init(ItemsViewState(containerState: .loading,
                             itemsStack: ItemsStackState(root: .loading([]),
                                                         itemStates: [:])) )
    private let paginationTracker: AsyncPaginationTracker
    private let itemProvider: PointOfSaleItemServiceProtocol

    init(itemProvider: PointOfSaleItemServiceProtocol) {
        self.itemProvider = itemProvider
        self.paginationTracker = .init()
        itemsViewStatePublisher = itemsViewStateSubject.eraseToAnyPublisher()
    }

    @MainActor
    func loadInitialItems() async {
        itemsViewStateSubject.send(ItemsViewState(containerState: .loading, itemsStack: ItemsStackState(root: .loading([]),
                                                                                                        itemStates: [:])))
        do {
            try await paginationTracker.syncFirstPage { [weak self] pageNumber in
                guard let self else { return true }
                return try await fetchItems(pageNumber: pageNumber)
            }
        } catch {
            itemsViewStateSubject.send(ItemsViewState(containerState: .error(PointOfSaleErrorState.errorOnLoadingProducts()),
                                                      itemsStack: ItemsStackState(root: .loaded([]),
                                                                                  itemStates: [:])))
        }
    }

    @MainActor
    func loadNextItems() async {
        guard paginationTracker.hasNextPage else {
            return
        }
        let currentItems = itemsViewStateSubject.value.itemsStack.root.items
        let currentItemStates = itemsViewStateSubject.value.itemsStack.itemStates
        itemsViewStateSubject.send(ItemsViewState(containerState: .content, itemsStack: ItemsStackState(root: .loading(currentItems),
                                                                                                        itemStates: currentItemStates)))
        do {
            _ = try await paginationTracker.ensureNextPageIsSynced { [weak self] pageNumber in
                guard let self else { return true }
                return try await fetchItems(pageNumber: pageNumber)
            }
        } catch {
            // TODO: 14694 - Handle error from loading the next page, like showing an error UI at the end or as an overlay.
            itemsViewStateSubject.send(ItemsViewState(containerState: .error(PointOfSaleErrorState.errorOnLoadingProducts()),
                                                      itemsStack: ItemsStackState(root: .loaded(currentItems),
                                                                                  itemStates: currentItemStates)))
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
            itemsViewStateSubject.send(ItemsViewState(containerState: .error(PointOfSaleErrorState.errorOnLoadingProducts()),
                                                      itemsStack: ItemsStackState(root: .loaded([]),
                                                                                  itemStates: [:])))
        }
    }

    @MainActor
    func loadInitialChildItems(for parent: POSItem) async {
        guard case let .parentProduct(parentProduct) = parent else {
            return
        }

        itemsViewStateSubject.send(itemsViewStateSubject.value.copy(itemsStack: itemsViewStateSubject.value.itemsStack.copy(itemStates: [parent: .loading([])])))

        switch parentProduct.type {
        case .variable:
            do {
                // TODO-14696: pagination support for variations lists
                try await fetchVariationItems(parentProduct: parentProduct, parentItem: parent, pageNumber: Store.Default.firstPageNumber)
            } catch {
                // TODO: 14694 - Handle error from loading initial variations.
            }
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
        var allItems = appendToExistingItems ? itemsViewStateSubject.value.itemsStack.root.items : []
        let uniqueNewItems = newItems.filter { newItem in
            // Note that this uniquing won't currently work, as POSItem has a UUID.
            !allItems.contains(newItem)
        }
        allItems.append(contentsOf: uniqueNewItems)
        if allItems.isEmpty {
            itemsViewStateSubject.send(ItemsViewState(containerState: .empty,
                                                      itemsStack: ItemsStackState(root: .loaded([]),
                                                                                  itemStates: [:])))
        } else {
            let itemStates = itemsViewStateSubject.value.itemsStack.itemStates
                .filter { allItems.contains($0.key) }
            itemsViewStateSubject.send(ItemsViewState(containerState: .content,
                                                      itemsStack: ItemsStackState(root: .loaded(allItems),
                                                                                  itemStates: itemStates)))
        }
        return pagedItems.hasMorePages
    }

    /// Fetches variation items given a page number and appends new unique items to the existing items array.
    /// - Parameter pageNumber: Page number to fetch items from.
    /// - Parameter appendToExistingItems: Default true – set this to false when refreshing to make the new page the only page.
    @MainActor
    private func fetchVariationItems(parentProduct: POSParentProduct,
                                     parentItem: POSItem,
                                     pageNumber: Int,
                                     appendToExistingItems: Bool = true) async throws {
        let pagedItems = try await itemProvider.providePointOfSaleVariationItems(
            for: parentProduct,
            pageNumber: pageNumber
        )
        let newItems = pagedItems.items
        var allItems: [POSItem] = appendToExistingItems ? (itemsViewStateSubject.value.itemsStack.itemStates[parentItem]?.items ?? []) : []
        let uniqueNewItems = newItems.filter { newItem in
            // Note that this uniquing won't currently work, as POSItem has a UUID.
            !allItems.contains(newItem)
        }
        allItems.append(contentsOf: uniqueNewItems)

        let itemsViewState = itemsViewStateSubject.value
        let itemStates: [POSItem: ItemListState] = {
            var states = itemsViewState.itemsStack.itemStates
            states[parentItem] = .loaded(allItems)
            return states
        }()
        itemsViewStateSubject.send(itemsViewStateSubject.value.copy(itemsStack: itemsViewState.itemsStack.copy(itemStates: itemStates)))
    }
}
