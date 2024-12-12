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
    func loadChildItems(for parentItem: POSParentProduct) async -> ItemListState
}

class PointOfSaleItemsController: PointOfSaleItemsControllerProtocol {
    private(set) var itemsViewStatePublisher: any Publisher<ItemsViewState, Never>
    private var itemsViewStateSubject: PassthroughSubject<ItemsViewState, Never> = .init()
    private var itemsStackState: ItemsStackState
    private let rootItemProvider: PointOfSaleItemServiceProtocol

    private var allChildItems: [UUID: [POSItem]] = [:]
    private let variationProvider: PointOfSaleVariationServiceProtocol

    init(rootItemProvider: PointOfSaleItemServiceProtocol,
         variationProvider: PointOfSaleVariationServiceProtocol) {
        self.rootItemProvider = rootItemProvider
        self.variationProvider = variationProvider
        itemsViewStatePublisher = itemsViewStateSubject.eraseToAnyPublisher()
        self.itemsStackState = .init(rootState: .loading([], pageInfo: .init(currentPage: Constants.initialPage, hasMorePages: true)), itemStates: [:])
    }

    @MainActor
    func loadInitialItems() async {
        itemsStackState = .init(rootState: .loading([], pageInfo: .init(currentPage: Constants.initialPage, hasMorePages: true)), itemStates: [:])
        itemsViewStateSubject.send(ItemsViewState(containerState: .initialLoading,
                                                  itemsStackState: itemsStackState))
        do {
            try await load(pageNumber: Constants.initialPage)
        } catch {
            itemsStackState = .init(rootState: .loaded([], pageInfo: .init(currentPage: Constants.initialPage, hasMorePages: false)), itemStates: [:])
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
            itemsStackState = .init(rootState: .loading(itemsStackState.rootState.items, pageInfo: .init(currentPage: itemsStackState.rootState.pageInfo.currentPage, hasMorePages: true)),
                                    itemStates: itemsStackState.itemStates)
            itemsViewStateSubject.send(ItemsViewState(containerState: .content, itemsStackState: itemsStackState))


            try await load(pageNumber: nextPage)
            itemsStackState = .init(rootState: .loaded(itemsStackState.rootState.items, pageInfo: .init(currentPage: nextPage, hasMorePages: true)),
                                    itemStates: itemsStackState.itemStates)
        } catch {
            // Handle errors without incrementing currentPage.
        }
    }

    @MainActor
    func reload() async {
        itemsStackState.rootState = .loading([], pageInfo: .init(currentPage: Constants.initialPage, hasMorePages: true))
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
        let existingItems = itemsStackState.itemStates[parent]?.items ?? []

        let uniqueNewItems = newItems.filter { newItem in
            !existingItems.contains(newItem)
        }

        itemsStackState.itemStates[parent] = .loaded(existingItems + uniqueNewItems,
                                                     pageInfo: .init(currentPage: pageNumber, hasMorePages: true))
}

    @MainActor
    private func fetchItems(pageNumber: Int) async throws {
        let newItems = try await rootItemProvider.providePointOfSaleItems(pageNumber: pageNumber)
        let existingItems = itemsStackState.rootState.items

        let uniqueNewItems = newItems.filter { newItem in
            !existingItems.contains(newItem)
        }

        itemsStackState.rootState = .loaded(existingItems + uniqueNewItems,
                                            pageInfo: .init(currentPage: pageNumber, hasMorePages: true))
    }

    private func updateItemViewStateAfterLoadAttempt(parent: POSItem? = nil, mightHaveMorePages: Bool = true) {
        if !mightHaveMorePages {
            if let parent {
                if let currentState = itemsStackState.itemStates[parent] {
                    itemsStackState.itemStates[parent] = .loaded(currentState.items, pageInfo: .init(currentPage: currentState.pageInfo.currentPage, hasMorePages: false))
                }
            } else {
                itemsStackState.rootState = .loaded(itemsStackState.rootState.items, pageInfo: .init(currentPage: itemsStackState.rootState.pageInfo.currentPage, hasMorePages: false))
            }
        }
        if itemsStackState.rootState.items.isEmpty {
            itemsViewStateSubject.send(.init(containerState: .empty, itemsStackState: itemsStackState))
        } else {
            itemsViewStateSubject.send(.init(containerState: .content, itemsStackState: itemsStackState))
        }
    }

    @MainActor
    func loadChildItems(for parentProduct: POSParentProduct) async -> ItemListState {
        do {
            let existingItems = allChildItems[parentProduct.id] ?? []
            if existingItems.isNotEmpty {
                return ItemListState.loaded(existingItems, pageInfo: .init(currentPage: Constants.initialPage, hasMorePages: true))
            }

            let newItems = try await variationProvider.providePointOfSaleItems(for: parentProduct, pageNumber: Constants.initialPage)
            let updatedItems = existingItems + newItems

            allChildItems[parentProduct.id] = updatedItems
            return ItemListState.loaded(updatedItems, pageInfo: .init(currentPage: Constants.initialPage, hasMorePages: true))
        } catch {
            DDLogError("Error loading child items for \(parentProduct): \(error)")
        }
        return ItemListState.loaded([], pageInfo: .init(currentPage: Constants.initialPage, hasMorePages: true))
    }

    private enum Constants {
        static let initialPage: Int = 1
    }
}

enum PointOfSaleItemsControllerError: Error {
    case cannotFetchChildrenForNonParentItem
}

extension ItemListState {
    var items: [POSItem] {
        switch self {
        case .loading(let items, _),
                .loaded(let items, _):
            return items
        }
    }

    var pageInfo: PageInfo {
        switch self {
        case .loading(_, pageInfo: let pageInfo),
                .loaded(_, pageInfo: let pageInfo):
            return pageInfo
        }
    }
}
