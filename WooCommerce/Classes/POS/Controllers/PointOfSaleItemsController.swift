import Foundation
import Combine
import enum Yosemite.POSItem
import struct Yosemite.POSParentProduct
import protocol Yosemite.PointOfSaleItemServiceProtocol
import enum Yosemite.PointOfSaleProductServiceError
import protocol Yosemite.PointOfSaleVariationServiceProtocol

protocol PointOfSaleItemsControllerProtocol {
    var itemsViewStatePublisher: any Publisher<ItemsViewState, Never> { get }
    func loadInitialItems() async
    func loadNextItems() async
    func reload() async
    func childState(for parent: POSItem) -> ItemListState
}

class PointOfSaleItemsController: PointOfSaleItemsControllerProtocol {
    private(set) var itemsViewStatePublisher: any Publisher<ItemsViewState, Never>
    private var itemsViewStateSubject: PassthroughSubject<ItemsViewState, Never> = .init()
    private var itemsStackState: ItemsStackState
    private let rootItemProvider: PointOfSaleItemServiceProtocol

    private let variationProvider: PointOfSaleVariationServiceProtocol

    init(rootItemProvider: PointOfSaleItemServiceProtocol,
         variationProvider: PointOfSaleVariationServiceProtocol) {
        self.rootItemProvider = rootItemProvider
        self.variationProvider = variationProvider
        itemsViewStatePublisher = itemsViewStateSubject.eraseToAnyPublisher()
        self.itemsStackState = .init(rootState: .init(loadState: .loading, items: [], pageInfo: .init(currentPage: Constants.initialPage, hasMorePages: true)),
                                     itemStates: [:])
    }

    @MainActor
    func loadInitialItems() async {
        itemsStackState = .init(rootState: .init(loadState: .loading, items: [], pageInfo: .init(currentPage: Constants.initialPage, hasMorePages: true)),
                                itemStates: [:])
        itemsViewStateSubject.send(ItemsViewState(containerState: .initialLoading,
                                                  itemsStackState: itemsStackState))
        do {
            try await load(pageNumber: Constants.initialPage)
        } catch {
            itemsStackState.rootState.loadState = .loaded
            itemsViewStateSubject.send(ItemsViewState(containerState: .error(PointOfSaleErrorState.errorOnLoadingProducts()),
                                                      itemsStackState: itemsStackState))
        }
    }

    @MainActor
    func loadNextItems() async {
        do {
            guard itemsStackState.rootState.pageInfo.hasMorePages else {
                return
            }
            let nextPage = itemsStackState.rootState.pageInfo.currentPage + 1
            itemsStackState.rootState.loadState = .loading
            itemsViewStateSubject.send(ItemsViewState(containerState: .content, itemsStackState: itemsStackState))


            try await load(pageNumber: nextPage)
            itemsStackState.rootState.pageInfo = PageInfo(currentPage: nextPage, hasMorePages: itemsStackState.rootState.pageInfo.hasMorePages)
        } catch {
            // Handle errors without incrementing currentPage.
        }
    }

    @MainActor
    func reload() async {
        itemsStackState.rootState = ItemListState(loadState: .loading, items: [], pageInfo: .init(currentPage: Constants.initialPage, hasMorePages: true))
        itemsViewStateSubject.send(ItemsViewState(containerState: .content, itemsStackState: itemsStackState))
        try? await load(pageNumber: Constants.initialPage)
    }

    @MainActor
    private func load(pageNumber: Int, parent: POSItem? = nil) async throws {
        do {
            if let parent {
                try await fetchItems(pageNumber: pageNumber, parent: parent)
            } else {
                try await fetchItems(pageNumber: pageNumber)
            }
            updateItemViewStateAfterLoadAttempt()
        } catch PointOfSaleProductServiceError.pageOutOfRange {
            updateItemViewStateAfterLoadAttempt(parent: parent, mightHaveMorePages: false)
            throw PointOfSaleProductServiceError.pageOutOfRange
        }
    }

    @MainActor
    private func fetchItems(pageNumber: Int, parent: POSItem) async throws {
        guard case .parentProduct(let parentProduct) = parent else {
            throw PointOfSaleItemsControllerError.cannotFetchChildrenForNonParentItem
        }
        let newItems = try await variationProvider.providePointOfSaleItems(for: parentProduct, pageNumber: pageNumber)
        let existingItemState = itemsStackState.itemStates[parent]
        let existingItems = existingItemState?.items ?? []

        let uniqueNewItems = newItems.filter { newItem in
            !existingItems.contains(newItem)
        }

        if var existingItemState {
            existingItemState.loadState = .loaded
            existingItemState.items = existingItems + uniqueNewItems
            itemsStackState.itemStates[parent] = existingItemState
        } else {
            let newItemState = ItemListState(loadState: .loaded,
                                             items: uniqueNewItems,
                                             pageInfo: .init(currentPage: pageNumber, hasMorePages: true))
            itemsStackState.itemStates[parent] = newItemState
        }
}

    @MainActor
    private func fetchItems(pageNumber: Int) async throws {
        let newItems = try await rootItemProvider.providePointOfSaleItems(pageNumber: pageNumber)
        let existingItems = itemsStackState.rootState.items

        let uniqueNewItems = newItems.filter { newItem in
            !existingItems.contains(newItem)
        }

        itemsStackState.rootState.loadState = .loaded
        itemsStackState.rootState.items = existingItems + uniqueNewItems
    }

    private func updateItemViewStateAfterLoadAttempt(parent: POSItem? = nil, mightHaveMorePages: Bool = true) {
        if let parent {
            if let currentState = itemsStackState.itemStates[parent] {
                let newState = ItemListState(loadState: currentState.loadState,
                                             items: currentState.items,
                                             pageInfo: PageInfo(currentPage: currentState.pageInfo.currentPage,
                                                                hasMorePages: mightHaveMorePages))
                itemsStackState.itemStates[parent] = newState
            }
        } else {
            itemsStackState.rootState.pageInfo = PageInfo(currentPage: itemsStackState.rootState.pageInfo.currentPage,
                                                          hasMorePages: mightHaveMorePages)
        }
        if itemsStackState.rootState.items.isEmpty {
            itemsViewStateSubject.send(.init(containerState: .empty, itemsStackState: itemsStackState))
        } else {
            itemsViewStateSubject.send(.init(containerState: .content, itemsStackState: itemsStackState))
        }
    }

    func childState(for parent: POSItem) -> ItemListState {
        if let existingState = itemsStackState.itemStates[parent] {
            return existingState
        } else {
            Task { @MainActor in
                try await load(pageNumber: Constants.initialPage, parent: parent)
            }

            return .init(loadState: .loading, items: [], pageInfo: .init(currentPage: Constants.initialPage, hasMorePages: true))
        }
    }

    private enum Constants {
        static let initialPage: Int = 1
    }
}

enum PointOfSaleItemsControllerError: Error {
    case cannotFetchChildrenForNonParentItem
    case noChildItemsFound
}
